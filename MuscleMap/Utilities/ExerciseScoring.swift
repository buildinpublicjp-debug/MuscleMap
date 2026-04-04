import Foundation

// MARK: - パーソナライゼーションスコアリングエンジン

/// 種目ごとのスコア計算結果
struct ExerciseScore {
    let exercise: ExerciseDefinition
    let score: Double
    let baseEffect: Double
    let difficultyFit: Double
    let equipmentFilter: Double
    let goalFit: Double
    let focusBoost: Double
    let randomFactor: Double
}

/// ユーザーの目標・経験・環境に基づいて種目をスコアリングし、最適な種目を選出する
@MainActor
struct ExerciseScoring {

    // MARK: - メインAPI

    /// 種目リストをスコアリングし、スコア降順でソートして返す
    /// - Parameters:
    ///   - exercises: 候補種目
    ///   - experience: ユーザーのトレーニング経験
    ///   - location: トレーニング場所（"gym", "home", "bodyweight", "both"）
    ///   - goalWeights: 目標ごとの重み（goalRawValue: 0.0〜1.0）
    ///   - priorityMuscles: 重点筋肉のrawValue配列
    /// - Returns: スコア降順でソートされた種目リスト（スコア0の種目は除外）
    static func scoreExercises(
        _ exercises: [ExerciseDefinition],
        experience: TrainingExperience,
        location: String,
        goalWeights: [String: Double],
        priorityMuscles: [String]
    ) -> [ExerciseDefinition] {
        let prioritySet = Set(priorityMuscles)

        // 各種目をスコアリング
        var scored = exercises.compactMap { exercise -> ExerciseScore? in
            let base = baseEffect(for: exercise)
            let diff = difficultyFit(experience: experience, difficulty: exercise.difficulty)
            let equip = equipmentFilter(exercise: exercise, location: location)
            let goal = goalFit(exercise: exercise, goalWeights: goalWeights)
            let focus = focusBoost(exercise: exercise, priorityMuscles: prioritySet)
            let rand = Double.random(in: 0.85...1.15)

            let total = base * diff * equip * goal * focus * rand

            // スコア0は完全除外（difficultyFit=0 or equipmentFilter=0）
            guard total > 0 else { return nil }

            return ExerciseScore(
                exercise: exercise,
                score: total,
                baseEffect: base,
                difficultyFit: diff,
                equipmentFilter: equip,
                goalFit: goal,
                focusBoost: focus,
                randomFactor: rand
            )
        }

        // スコア降順ソート
        scored.sort { $0.score > $1.score }

        // 動作パターン多様性ペナルティ（同じmovementPatternが3つ以上なら×0.5）
        scored = applyMovementPatternPenalty(scored)

        return scored.map(\.exercise)
    }

    // MARK: - 係数計算

    /// baseEffect: muscleMappingの最大値 / 100.0。コンパウンドなら×1.2
    private static func baseEffect(for exercise: ExerciseDefinition) -> Double {
        let maxStimulation = Double(exercise.muscleMapping.values.max() ?? 0) / 100.0
        let isCompound = exercise.muscleMapping.count >= 3
        return maxStimulation * (isCompound ? 1.2 : 1.0)
    }

    /// difficultyFit: 経験×難易度マトリクスから適合度を返す
    private static func difficultyFit(experience: TrainingExperience, difficulty: String) -> Double {
        // 難易度を正規化（日本語・英語両対応）
        let level: DifficultyLevel
        switch difficulty.lowercased() {
        case "初級", "beginner":
            level = .beginner
        case "上級", "advanced":
            level = .advanced
        default:
            level = .intermediate
        }

        return difficultyMatrix[experience]?[level] ?? 1.0
    }

    /// equipmentFilter: 場所に応じて使える種目かどうか
    private static func equipmentFilter(exercise: ExerciseDefinition, location: String) -> Double {
        switch location {
        case "gym", "both":
            return 1.0
        case "home":
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            return homeEquipment.contains(exercise.equipment) ? 1.0 : 0.0
        case "bodyweight":
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            return bwEquipment.contains(exercise.equipment) ? 1.0 : 0.0
        default:
            return 1.0
        }
    }

    /// goalFit: 目標ごとのcompound/isolation重みをgoalWeightsで加重平均
    private static func goalFit(exercise: ExerciseDefinition, goalWeights: [String: Double]) -> Double {
        let isCompound = exercise.muscleMapping.count >= 3

        // goalWeightsが空の場合はデフォルト1.0
        let activeGoals = goalWeights.filter { $0.value > 0 }
        guard !activeGoals.isEmpty else { return 1.0 }

        var totalWeight = 0.0
        var weightedFit = 0.0

        for (goalRaw, weight) in activeGoals {
            guard let goal = OnboardingGoal(rawValue: goalRaw) else { continue }
            let multiplier = goalCompoundIsolationWeight(goal: goal, isCompound: isCompound)
            weightedFit += multiplier * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return 1.0 }
        return weightedFit / totalWeight
    }

    /// focusBoost: 重点筋肉をターゲットにしている種目に×1.5
    private static func focusBoost(exercise: ExerciseDefinition, priorityMuscles: Set<String>) -> Double {
        guard !priorityMuscles.isEmpty else { return 1.0 }
        let hits = exercise.muscleMapping.keys.contains { priorityMuscles.contains($0) }
        return hits ? 1.5 : 1.0
    }

    // MARK: - 動作パターン多様性

    /// 同じカテゴリが3つ以上あれば3つ目以降のスコアを×0.5にして再ソート
    private static func applyMovementPatternPenalty(_ scored: [ExerciseScore]) -> [ExerciseScore] {
        // カテゴリをmovementPatternの代替として使用（exercisesにmovementPatternフィールドがないため）
        var categoryCounts: [String: Int] = [:]
        var result: [ExerciseScore] = []

        for item in scored {
            let pattern = item.exercise.category
            let count = categoryCounts[pattern, default: 0]
            categoryCounts[pattern] = count + 1

            if count >= 2 {
                // 3つ目以降はスコア半減
                let penalized = ExerciseScore(
                    exercise: item.exercise,
                    score: item.score * 0.5,
                    baseEffect: item.baseEffect,
                    difficultyFit: item.difficultyFit,
                    equipmentFilter: item.equipmentFilter,
                    goalFit: item.goalFit,
                    focusBoost: item.focusBoost,
                    randomFactor: item.randomFactor
                )
                result.append(penalized)
            } else {
                result.append(item)
            }
        }

        // 再ソート
        result.sort { $0.score > $1.score }
        return result
    }

    // MARK: - データテーブル

    private enum DifficultyLevel {
        case beginner, intermediate, advanced
    }

    /// experience × difficulty マトリクス
    private static let difficultyMatrix: [TrainingExperience: [DifficultyLevel: Double]] = [
        .beginner:    [.beginner: 1.0, .intermediate: 0.3, .advanced: 0.0],
        .halfYear:    [.beginner: 0.8, .intermediate: 1.0, .advanced: 0.3],
        .oneYearPlus: [.beginner: 0.5, .intermediate: 1.0, .advanced: 0.8],
        .veteran:     [.beginner: 0.3, .intermediate: 0.8, .advanced: 1.0],
    ]

    /// 目標ごとのcompound/isolation重み
    private static func goalCompoundIsolationWeight(goal: OnboardingGoal, isCompound: Bool) -> Double {
        switch goal {
        case .getBig:
            return isCompound ? 1.3 : 0.9
        case .dontGetDisrespected:
            return isCompound ? 1.2 : 1.0
        case .martialArts:
            return isCompound ? 1.4 : 0.5
        case .sports:
            return isCompound ? 1.3 : 0.6
        case .getAttractive:
            return isCompound ? 1.0 : 1.2
        case .moveWell:
            return isCompound ? 1.3 : 0.7
        case .health:
            return isCompound ? 0.8 : 1.0
        }
    }
}

// MARK: - デバッグ用printテスト

#if DEBUG
@MainActor
func testExerciseScoring() {
    let store = ExerciseStore.shared
    store.loadIfNeeded()

    let allExercises = store.exercises

    // パターン1: デカくなりたい × ベテラン × ジム × 週3
    let pattern1 = ExerciseScoring.scoreExercises(
        allExercises,
        experience: .veteran,
        location: "gym",
        goalWeights: [OnboardingGoal.getBig.rawValue: 1.0],
        priorityMuscles: GoalMusclePriority.data(for: .getBig).muscles.map(\.rawValue)
    )
    print("=== パターン1: デカくなりたい × ベテラン × ジム ===")
    for ex in pattern1.prefix(10) {
        print("  \(ex.localizedName) [\(ex.difficulty)] \(ex.equipment)")
    }

    // パターン2: モテたい × 初心者 × 自宅(器具なし) × 週3
    let pattern2 = ExerciseScoring.scoreExercises(
        allExercises,
        experience: .beginner,
        location: "bodyweight",
        goalWeights: [OnboardingGoal.getAttractive.rawValue: 1.0],
        priorityMuscles: GoalMusclePriority.data(for: .getAttractive).muscles.map(\.rawValue)
    )
    print("=== パターン2: モテたい × 初心者 × 自宅(器具なし) ===")
    for ex in pattern2.prefix(10) {
        print("  \(ex.localizedName) [\(ex.difficulty)] \(ex.equipment)")
    }

    // パターン3: 健康に長生き × 半年 × ジム × 週2
    let pattern3 = ExerciseScoring.scoreExercises(
        allExercises,
        experience: .halfYear,
        location: "gym",
        goalWeights: [OnboardingGoal.health.rawValue: 1.0],
        priorityMuscles: GoalMusclePriority.data(for: .health).muscles.map(\.rawValue)
    )
    print("=== パターン3: 健康に長生き × 半年 × ジム ===")
    for ex in pattern3.prefix(10) {
        print("  \(ex.localizedName) [\(ex.difficulty)] \(ex.equipment)")
    }
}
#endif

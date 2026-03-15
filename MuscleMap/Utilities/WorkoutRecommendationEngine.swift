import Foundation
import SwiftData

// MARK: - 提案ワークアウト

/// メニュー自動提案の出力: 筋肉グループ + 具体的な種目リスト
struct RecommendedWorkout {
    let muscleGroup: String       // "背中・腕" など
    let exercises: [RecommendedExercise]
}

/// 提案種目（重量・レップ・セット数を含む）
struct RecommendedExercise: Identifiable {
    let exerciseId: String
    let exerciseName: String
    let suggestedWeight: Double   // 提案重量（kg）
    let suggestedReps: Int
    let suggestedSets: Int
    let previousWeight: Double?   // 前回重量（nil = 履歴なし）
    let weightIncrease: Double    // +2.5 or +1.25

    var id: String { exerciseId }
}

// MARK: - 分割法パート定義

/// 分割法の1パート（例: "Push" → 胸・肩前部・三頭）
struct SplitPart {
    let name: String
    let muscleGroups: [MuscleGroup]
}

// MARK: - ワークアウト提案エンジン

/// 回復データ・過去の記録から具体的なメニュー（種目+重量+セット）を提案
/// パーソナライズ: 分割法・重点筋肉・トレーニング場所に対応
struct WorkoutRecommendationEngine {

    // MARK: - メイン提案メソッド

    /// 回復済みグループから具体的なメニューを生成
    @MainActor
    static func generateRecommendation(
        suggestedMenu: SuggestedMenu,
        modelContext: ModelContext
    ) -> RecommendedWorkout {
        let profile = AppState.shared.userProfile
        let exerciseStore = ExerciseStore.shared
        let favoritesManager = FavoritesManager.shared
        let pairedGroups = MenuSuggestionService.pairedGroups(for: suggestedMenu.primaryGroup)

        // グループ名を結合
        let groupName = pairedGroups.map { $0.localizedName }.joined(separator: "・")

        // 1. 回復済みグループの筋肉に対応する種目を収集
        var candidateExercises: [ExerciseDefinition] = []
        var seenIds: Set<String> = []

        for group in pairedGroups {
            for muscle in group.muscles {
                let exercises = exerciseStore.exercises(targeting: muscle)
                for ex in exercises {
                    if !seenIds.contains(ex.id) {
                        seenIds.insert(ex.id)
                        candidateExercises.append(ex)
                    }
                }
            }
        }

        // 2. トレーニング場所フィルタリング
        candidateExercises = filterByLocation(
            exercises: candidateExercises,
            location: profile.trainingLocation
        )

        // 3. 重点筋肉の優先順位付け + お気に入り優先ソート
        candidateExercises = sortByPriority(
            exercises: candidateExercises,
            priorityMuscles: profile.goalPriorityMuscles,
            favoritesManager: favoritesManager
        )

        // 4. 上位3種目を選出
        let topExercises = Array(candidateExercises.prefix(3))

        // 5. 各種目の前回記録を取得し、重量提案を計算
        let recommended = buildRecommendedExercises(
            exercises: topExercises,
            modelContext: modelContext
        )

        return RecommendedWorkout(
            muscleGroup: groupName,
            exercises: recommended
        )
    }

    // MARK: - 分割法の自動決定

    /// weeklyFrequencyに基づく分割法パートリストを返す
    static func splitParts(for frequency: Int) -> [SplitPart] {
        switch frequency {
        case 2:
            // 上半身 / 下半身
            return [
                SplitPart(name: "上半身", muscleGroups: [.chest, .back, .shoulders, .arms]),
                SplitPart(name: "下半身", muscleGroups: [.lowerBody, .core]),
            ]
        case 3:
            // Push / Pull / Legs
            return [
                SplitPart(name: "Push", muscleGroups: [.chest, .shoulders]),
                SplitPart(name: "Pull", muscleGroups: [.back, .arms]),
                SplitPart(name: "Legs", muscleGroups: [.lowerBody, .core]),
            ]
        case 4:
            // 胸肩三頭 / 背中二頭 / 脚 / 肩腕
            return [
                SplitPart(name: "胸・肩・三頭", muscleGroups: [.chest, .shoulders]),
                SplitPart(name: "背中・二頭", muscleGroups: [.back, .arms]),
                SplitPart(name: "脚", muscleGroups: [.lowerBody, .core]),
                SplitPart(name: "肩・腕", muscleGroups: [.shoulders, .arms]),
            ]
        case 5:
            // 胸 / 背中 / 脚 / 肩 / 腕
            return [
                SplitPart(name: "胸", muscleGroups: [.chest]),
                SplitPart(name: "背中", muscleGroups: [.back]),
                SplitPart(name: "脚", muscleGroups: [.lowerBody, .core]),
                SplitPart(name: "肩", muscleGroups: [.shoulders]),
                SplitPart(name: "腕", muscleGroups: [.arms]),
            ]
        default:
            // デフォルト: 3分割
            return splitParts(for: 3)
        }
    }

    // MARK: - 今日のパート決定

    /// 直近のワークアウトから次にやるべきパートを判定
    /// - Returns: 推奨パートのインデックスとSplitPart
    @MainActor
    static func todaysPart(modelContext: ModelContext) -> SplitPart? {
        let profile = AppState.shared.userProfile
        let parts = splitParts(for: profile.weeklyFrequency)
        guard !parts.isEmpty else { return nil }

        // 直近セッションのセットを取得
        var descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let lastSession = try? modelContext.fetch(descriptor).first,
              !lastSession.sets.isEmpty else {
            // 履歴なし → 最初のパートを返す
            return parts[0]
        }

        // 直近セッションで鍛えた筋肉グループを特定
        let lastGroups = muscleGroupsFromSets(lastSession.sets)

        // どのパートに最も一致するか判定
        let lastPartIndex = bestMatchingPartIndex(
            parts: parts,
            trainedGroups: lastGroups
        )

        // 次のパートを返す（循環）
        let nextIndex = (lastPartIndex + 1) % parts.count
        return parts[nextIndex]
    }

    // MARK: - トレーニング場所フィルタリング

    /// trainingLocationに基づいて種目をフィルタ
    /// "home" → バーベル・マシン・ケーブルを除外、自重・ダンベルのみ
    private static func filterByLocation(
        exercises: [ExerciseDefinition],
        location: String
    ) -> [ExerciseDefinition] {
        guard location == "home" else { return exercises }

        // 自宅トレーニング: 自重・ダンベル・ケトルベルのみ許可
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]
        let filtered = exercises.filter { homeEquipment.contains($0.equipment) }

        // フィルタ後に空にならないよう最低限を保証
        return filtered.isEmpty ? exercises : filtered
    }

    // MARK: - 重点筋肉の優先順位付け

    /// goalPriorityMusclesに含まれる筋肉をターゲットにする種目を上位に
    /// さらにお気に入りを最優先
    @MainActor
    private static func sortByPriority(
        exercises: [ExerciseDefinition],
        priorityMuscles: [String],
        favoritesManager: FavoritesManager
    ) -> [ExerciseDefinition] {
        let prioritySet = Set(priorityMuscles)

        return exercises.sorted { a, b in
            let aFav = favoritesManager.isFavorite(a.id)
            let bFav = favoritesManager.isFavorite(b.id)

            // 1. お気に入り優先
            if aFav != bFav { return aFav }

            // 2. 重点筋肉にヒットする種目を優先
            let aHits = priorityMuscleScore(exercise: a, prioritySet: prioritySet)
            let bHits = priorityMuscleScore(exercise: b, prioritySet: prioritySet)
            if aHits != bHits { return aHits > bHits }

            // 3. 元の順序を維持（安定ソート）
            return false
        }
    }

    /// 種目の重点筋肉スコア（重点筋肉への合計刺激度%）
    private static func priorityMuscleScore(
        exercise: ExerciseDefinition,
        prioritySet: Set<String>
    ) -> Int {
        exercise.muscleMapping
            .filter { prioritySet.contains($0.key) }
            .reduce(0) { $0 + $1.value }
    }

    // MARK: - 種目→提案変換

    /// 種目リストから前回記録ベースの提案を生成
    @MainActor
    private static func buildRecommendedExercises(
        exercises: [ExerciseDefinition],
        modelContext: ModelContext
    ) -> [RecommendedExercise] {
        let workoutRepo = WorkoutRepository(modelContext: modelContext)
        var recommended: [RecommendedExercise] = []

        for exercise in exercises {
            let isCompound = isCompoundExercise(exercise)
            let increment = isCompound ? 2.5 : 1.25

            let lastRecord = workoutRepo.fetchLastRecord(exerciseId: exercise.id)
            let previousWeight = lastRecord?.weight
            let previousReps = lastRecord?.reps ?? 10
            let previousSets: Int

            // 前回セット数を取得
            if let record = lastRecord,
               let session = record.session {
                let setsInSession = session.sets.filter { $0.exerciseId == exercise.id }
                previousSets = max(setsInSession.count, 3)
            } else {
                previousSets = 3
            }

            // 重量提案: 前回重量 + increment（前回記録なしの場合は0）
            let suggestedWeight: Double
            if let prev = previousWeight, prev > 0 {
                suggestedWeight = prev + increment
            } else {
                suggestedWeight = 0
            }

            recommended.append(RecommendedExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.localizedName,
                suggestedWeight: suggestedWeight,
                suggestedReps: previousReps,
                suggestedSets: previousSets,
                previousWeight: previousWeight,
                weightIncrease: increment
            ))
        }

        return recommended
    }

    // MARK: - ヘルパー

    /// セットリストから鍛えた筋肉グループのセットを返す
    @MainActor
    private static func muscleGroupsFromSets(_ sets: [WorkoutSet]) -> Set<MuscleGroup> {
        let exerciseStore = ExerciseStore.shared
        var groups: Set<MuscleGroup> = []

        for set in sets {
            guard let exercise = exerciseStore.exercise(for: set.exerciseId) else { continue }
            for (muscleId, _) in exercise.muscleMapping {
                if let muscle = Muscle(rawValue: muscleId) {
                    groups.insert(muscle.group)
                }
            }
        }
        return groups
    }

    /// 鍛えたグループに最もマッチするパートのインデックスを返す
    private static func bestMatchingPartIndex(
        parts: [SplitPart],
        trainedGroups: Set<MuscleGroup>
    ) -> Int {
        var bestIndex = 0
        var bestScore = 0

        for (index, part) in parts.enumerated() {
            let partGroups = Set(part.muscleGroups)
            let overlap = partGroups.intersection(trainedGroups).count
            if overlap > bestScore {
                bestScore = overlap
                bestIndex = index
            }
        }

        return bestIndex
    }

    /// 種目がコンパウンド（多関節）かアイソレーション（単関節）かを判定
    private static func isCompoundExercise(_ exercise: ExerciseDefinition) -> Bool {
        exercise.muscleMapping.count >= 3
    }
}

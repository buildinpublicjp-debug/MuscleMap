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
    let name: String        // 日本語名（既存コードとの互換性維持）
    let nameEN: String      // 英語名
    let muscleGroups: [MuscleGroup]
    /// 日本語の説明（例: 「押す動作の筋肉をまとめて効率UP」）
    let descriptionJA: String
    /// 英語の説明（例: "Push muscles grouped for efficiency"）
    let descriptionEN: String
    /// 難易度: "beginner" / "intermediate" / "advanced"
    let difficulty: String

    @MainActor var localizedName: String {
        let lang = LocalizationManager.shared.currentLanguage
        return lang == .japanese ? name : nameEN
    }

    @MainActor var localizedDescription: String {
        let lang = LocalizationManager.shared.currentLanguage
        return lang == .japanese ? descriptionJA : descriptionEN
    }
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

        // 1. 回復済みグループの筋肉に対応する種目を収集（主要ターゲットフィルタ付き）
        let targetGroupSet = Set(pairedGroups)
        var candidateExercises: [ExerciseDefinition] = []
        var seenIds: Set<String> = []

        for group in pairedGroups {
            for muscle in group.muscles {
                let exercises = exerciseStore.exercises(targeting: muscle)
                for ex in exercises {
                    if !seenIds.contains(ex.id) {
                        // 主要ターゲット筋肉のグループがpairedGroupsに含まれるかチェック
                        if let primary = ex.primaryMuscle,
                           targetGroupSet.contains(primary.group) {
                            seenIds.insert(ex.id)
                            candidateExercises.append(ex)
                        }
                    }
                }
            }
        }

        #if DEBUG
        print("[MenuEngine] pairedGroups: \(pairedGroups.map { $0.rawValue })")
        print("[MenuEngine] candidates after primaryMuscle filter: \(candidateExercises.map { "\($0.localizedName)(\($0.primaryMuscle?.group.rawValue ?? "?"))" })")
        #endif

        // 2. トレーニング場所フィルタリング
        candidateExercises = filterByLocation(
            exercises: candidateExercises,
            location: profile.trainingLocation
        )

        // 3. グループ適合度 + 重点筋肉 + お気に入り優先ソート
        candidateExercises = sortByPriority(
            exercises: candidateExercises,
            priorityMuscles: profile.goalPriorityMuscles,
            favoritesManager: favoritesManager,
            targetGroups: targetGroupSet
        )

        // 4. 上位3種目を選出
        let topExercises = Array(candidateExercises.prefix(3))

        #if DEBUG
        print("[MenuEngine] top3: \(topExercises.map { $0.localizedName })")
        #endif

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

    // MARK: - 初回ユーザー向けフォールバック提案

    /// 回復データがない初回ユーザー向けに、目標の重点筋肉からメニューを生成
    @MainActor
    static func generateFirstTimeRecommendation(
        modelContext: ModelContext
    ) -> RecommendedWorkout? {
        let profile = AppState.shared.userProfile
        let exerciseStore = ExerciseStore.shared

        // goalPriorityMusclesから最初のMuscleGroupを取得
        let targetGroup: MuscleGroup
        if let firstMuscleRaw = profile.goalPriorityMuscles.first,
           let firstMuscle = Muscle(rawValue: firstMuscleRaw) {
            targetGroup = firstMuscle.group
        } else {
            // goalPriorityMusclesも空 → デフォルトで胸
            targetGroup = .chest
        }

        let pairedGroups = MenuSuggestionService.pairedGroups(for: targetGroup)
        let targetGroupSet = Set(pairedGroups)

        // グループ名: 「初回おすすめ」
        let groupName = L10n.firstTimeRecommendation

        // 対象グループの種目を収集（主要ターゲットフィルタ付き）
        var candidateExercises: [ExerciseDefinition] = []
        var seenIds: Set<String> = []

        for group in pairedGroups {
            for muscle in group.muscles {
                let exercises = exerciseStore.exercises(targeting: muscle)
                for ex in exercises {
                    if !seenIds.contains(ex.id) {
                        if let primary = ex.primaryMuscle,
                           targetGroupSet.contains(primary.group) {
                            seenIds.insert(ex.id)
                            candidateExercises.append(ex)
                        }
                    }
                }
            }
        }

        // トレーニング場所フィルタリング
        candidateExercises = filterByLocation(
            exercises: candidateExercises,
            location: profile.trainingLocation
        )

        // グループ適合度 + 重点筋肉 + お気に入り優先ソート
        candidateExercises = sortByPriority(
            exercises: candidateExercises,
            priorityMuscles: profile.goalPriorityMuscles,
            favoritesManager: FavoritesManager.shared,
            targetGroups: targetGroupSet
        )

        guard !candidateExercises.isEmpty else { return nil }

        // 上位3種目を選出
        let topExercises = Array(candidateExercises.prefix(3))

        #if DEBUG
        print("[MenuEngine] firstTime targetGroup: \(targetGroup.rawValue), pairedGroups: \(pairedGroups.map { $0.rawValue })")
        print("[MenuEngine] firstTime top3: \(topExercises.map { $0.localizedName })")
        #endif

        // 前回記録なしの初回ユーザーなのでデフォルト値で生成
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
                SplitPart(
                    name: "上半身",
                    nameEN: "Upper Body",
                    muscleGroups: [.chest, .back, .shoulders, .arms],
                    descriptionJA: "胸・背中・肩・腕をまとめて鍛える",
                    descriptionEN: "Train chest, back, shoulders & arms together",
                    difficulty: "beginner"
                ),
                SplitPart(
                    name: "下半身",
                    nameEN: "Lower Body",
                    muscleGroups: [.lowerBody, .core],
                    descriptionJA: "脚と体幹を集中的に鍛える",
                    descriptionEN: "Focus on legs and core",
                    difficulty: "beginner"
                ),
            ]
        case 3:
            // Push / Pull / Legs
            return [
                SplitPart(
                    name: "Push",
                    nameEN: "Push",
                    muscleGroups: [.chest, .shoulders],
                    descriptionJA: "押す動作の筋肉をまとめて効率UP",
                    descriptionEN: "Push muscles grouped for efficiency",
                    difficulty: "beginner"
                ),
                SplitPart(
                    name: "Pull",
                    nameEN: "Pull",
                    muscleGroups: [.back, .arms],
                    descriptionJA: "引く動作の筋肉を集中トレーニング",
                    descriptionEN: "Pull muscles trained in one session",
                    difficulty: "beginner"
                ),
                SplitPart(
                    name: "Legs",
                    nameEN: "Legs",
                    muscleGroups: [.lowerBody, .core],
                    descriptionJA: "下半身と体幹で土台を作る",
                    descriptionEN: "Build your foundation with legs & core",
                    difficulty: "beginner"
                ),
            ]
        case 4:
            // 胸肩三頭 / 背中二頭 / 脚 / 肩腕
            return [
                SplitPart(
                    name: "胸・肩・三頭",
                    nameEN: "Chest · Shoulders · Triceps",
                    muscleGroups: [.chest, .shoulders],
                    descriptionJA: "ベンチプレス系で胸と肩を追い込む",
                    descriptionEN: "Chest & shoulders with pressing movements",
                    difficulty: "intermediate"
                ),
                SplitPart(
                    name: "背中・二頭",
                    nameEN: "Back · Biceps",
                    muscleGroups: [.back, .arms],
                    descriptionJA: "ロウ・プル系で背中と二頭を連動",
                    descriptionEN: "Back & biceps with rowing & pulling",
                    difficulty: "intermediate"
                ),
                SplitPart(
                    name: "脚",
                    nameEN: "Legs",
                    muscleGroups: [.lowerBody, .core],
                    descriptionJA: "スクワット中心で脚全体を強化",
                    descriptionEN: "Squat-focused leg development",
                    difficulty: "intermediate"
                ),
                SplitPart(
                    name: "肩・腕",
                    nameEN: "Shoulders · Arms",
                    muscleGroups: [.shoulders, .arms],
                    descriptionJA: "肩と腕のアイソレーション重視",
                    descriptionEN: "Isolation work for shoulders & arms",
                    difficulty: "intermediate"
                ),
            ]
        case 5:
            // 胸 / 背中 / 脚 / 肩 / 腕
            return [
                SplitPart(
                    name: "胸",
                    nameEN: "Chest",
                    muscleGroups: [.chest],
                    descriptionJA: "胸だけに集中して徹底的に追い込む",
                    descriptionEN: "Dedicated chest session for maximum volume",
                    difficulty: "advanced"
                ),
                SplitPart(
                    name: "背中",
                    nameEN: "Back",
                    muscleGroups: [.back],
                    descriptionJA: "広背筋・僧帽筋をフル刺激",
                    descriptionEN: "Full stimulation for lats & traps",
                    difficulty: "advanced"
                ),
                SplitPart(
                    name: "脚",
                    nameEN: "Legs",
                    muscleGroups: [.lowerBody, .core],
                    descriptionJA: "脚と体幹を高ボリュームで鍛える",
                    descriptionEN: "High-volume legs & core training",
                    difficulty: "advanced"
                ),
                SplitPart(
                    name: "肩",
                    nameEN: "Shoulders",
                    muscleGroups: [.shoulders],
                    descriptionJA: "三角筋の前部・側部・後部を個別攻略",
                    descriptionEN: "Target all three deltoid heads",
                    difficulty: "advanced"
                ),
                SplitPart(
                    name: "腕",
                    nameEN: "Arms",
                    muscleGroups: [.arms],
                    descriptionJA: "二頭・三頭・前腕をバランスよく強化",
                    descriptionEN: "Balanced biceps, triceps & forearms",
                    difficulty: "advanced"
                ),
            ]
        default:
            // デフォルト: 3分割
            return splitParts(for: 3)
        }
    }

    // MARK: - 追加Day候補の生成

    /// 既存Dayでカバーされていない筋肉グループから追加Day候補を生成
    @MainActor
    static func suggestAdditionalDay(existingDays: [RoutineDay]) -> SplitPart? {
        // 既存Dayがカバーしている筋肉グループを収集
        let coveredGroups: Set<MuscleGroup> = {
            var groups: Set<MuscleGroup> = []
            for day in existingDays {
                for rawValue in day.muscleGroups {
                    if let group = MuscleGroup(rawValue: rawValue) {
                        groups.insert(group)
                    }
                }
            }
            return groups
        }()

        // 全グループとの差分
        let allGroups = Set(MuscleGroup.allCases)
        let uncovered = allGroups.subtracting(coveredGroups)

        guard !uncovered.isEmpty else {
            // 全グループカバー済み → ボリューム不足のグループを提案
            // 出現回数が最も少ないグループを選出
            var counts: [MuscleGroup: Int] = [:]
            for group in MuscleGroup.allCases { counts[group] = 0 }
            for day in existingDays {
                for rawValue in day.muscleGroups {
                    if let group = MuscleGroup(rawValue: rawValue) {
                        counts[group, default: 0] += 1
                    }
                }
            }
            guard let leastGroup = counts.min(by: { $0.value < $1.value })?.key else {
                return nil
            }
            return SplitPart(
                name: L10n.focusGroupName(leastGroup.localizedName),
                nameEN: "\(leastGroup.englishName) Focus",
                muscleGroups: [leastGroup],
                descriptionJA: "\(leastGroup.japaneseName)のボリュームを増やして弱点克服",
                descriptionEN: "Extra volume for \(leastGroup.englishName.lowercased()) to address weak point",
                difficulty: "intermediate"
            )
        }

        // 未カバーグループをまとめて1つのDayに
        let sortedUncovered = MuscleGroup.allCases.filter { uncovered.contains($0) }
        let name = sortedUncovered.map { $0.localizedName }.joined(separator: "・")
        let nameEN = sortedUncovered.map { $0.englishName }.joined(separator: " & ")

        return SplitPart(
            name: name,
            nameEN: nameEN,
            muscleGroups: sortedUncovered,
            descriptionJA: "カバーされていない部位を補完する追加Day",
            descriptionEN: "Additional day to cover untrained muscle groups",
            difficulty: sortedUncovered.count >= 3 ? "intermediate" : "beginner"
        )
    }

    // MARK: - 分割法の曜日×部位テキスト（オンボーディング表示用）

    /// 頻度に応じた曜日と部位の組み合わせを返す
    @MainActor
    static func splitDescription(for frequency: Int) -> [(day: String, part: String)] {
        switch frequency {
        case 2:
            return [
                (L10n.splitMonday, L10n.splitUpperBody),
                (L10n.splitThursday, L10n.splitLowerBody),
            ]
        case 3:
            return [
                (L10n.splitMonday, L10n.splitPush),
                (L10n.splitWednesday, L10n.splitPull),
                (L10n.splitFriday, L10n.splitLegs),
            ]
        case 4:
            return [
                (L10n.splitMonday, L10n.splitChestShouldersTri),
                (L10n.splitTuesday, L10n.splitBackBiceps),
                (L10n.splitThursday, L10n.splitLegsOnly),
                (L10n.splitFriday, L10n.splitShouldersArms),
            ]
        default:
            return [
                (L10n.splitMonday, L10n.splitChest),
                (L10n.splitTuesday, L10n.splitBack),
                (L10n.splitWednesday, L10n.splitLegsOnly),
                (L10n.splitThursday, L10n.splitShoulders),
                (L10n.splitFriday, L10n.splitArms),
            ]
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
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
        let filtered = exercises.filter { homeEquipment.contains($0.equipment) }

        // フィルタ後に空にならないよう最低限を保証
        return filtered.isEmpty ? exercises : filtered
    }

    // MARK: - 重点筋肉の優先順位付け（ExerciseScoringエンジン使用）

    /// スコアリングエンジンで種目を優先順位付け（お気に入りは後処理で優先）
    @MainActor
    private static func sortByPriority(
        exercises: [ExerciseDefinition],
        priorityMuscles: [String],
        favoritesManager: FavoritesManager,
        targetGroups: Set<MuscleGroup>
    ) -> [ExerciseDefinition] {
        let profile = AppState.shared.userProfile

        // スコアリングエンジンで種目を選出
        var sorted = ExerciseScoring.scoreExercises(
            exercises,
            experience: profile.trainingExperience,
            location: profile.trainingLocation,
            goalWeights: profile.goalWeights,
            priorityMuscles: priorityMuscles
        )

        // お気に入り種目を先頭に移動（スコア順序を維持しつつ）
        let favorites = sorted.filter { favoritesManager.isFavorite($0.id) }
        let nonFavorites = sorted.filter { !favoritesManager.isFavorite($0.id) }
        sorted = favorites + nonFavorites

        return sorted
    }

    /// 種目の対象グループ適合度（targetGroupsの筋肉へのmuscleMapping合計%）
    private static func groupRelevanceScore(
        exercise: ExerciseDefinition,
        targetGroups: Set<MuscleGroup>
    ) -> Int {
        let targetMuscleIds = Set(targetGroups.flatMap { $0.muscles.map { $0.rawValue } })
        return exercise.muscleMapping
            .filter { targetMuscleIds.contains($0.key) }
            .reduce(0) { $0 + $1.value }
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
        let profile = AppState.shared.userProfile
        var recommended: [RecommendedExercise] = []

        // トレ歴に基づくデフォルトのレップ数・セット数
        let defaultReps: Int
        let defaultSets: Int
        switch profile.trainingExperience {
        case .beginner:
            defaultReps = 12  // 初心者はフォーム習得のため高レップ
            defaultSets = 3
        case .halfYear:
            defaultReps = 10
            defaultSets = 3
        case .oneYearPlus:
            defaultReps = 8   // 中級者は中レップ
            defaultSets = 4
        case .veteran:
            defaultReps = 6   // ベテランは高重量低レップ
            defaultSets = 4
        }

        for exercise in exercises {
            let isCompound = isCompoundExercise(exercise)
            let increment = isCompound ? 2.5 : 1.25

            let lastRecord = workoutRepo.fetchLastRecord(exerciseId: exercise.id)
            let previousWeight = lastRecord?.weight
            let previousReps: Int
            let previousSets: Int

            // 前回記録があればそれを使用、なければトレ歴ベースのデフォルト値
            if let record = lastRecord,
               let session = record.session {
                previousReps = record.reps
                let setsInSession = session.sets.filter { $0.exerciseId == exercise.id }
                previousSets = max(setsInSession.count, defaultSets)
            } else {
                previousReps = defaultReps
                previousSets = defaultSets
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

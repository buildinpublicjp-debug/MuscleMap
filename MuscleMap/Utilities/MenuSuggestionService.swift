import Foundation

// MARK: - 今日のメニュー提案サービス

struct MenuSuggestionService {

    /// 今日のメニューを提案
    @MainActor
    static func suggestTodayMenu(
        stimulations: [Muscle: MuscleStimulation],
        exerciseStore: ExerciseStore
    ) -> SuggestedMenu {
        // 初回ユーザー（刺激データなし）: 目標の重点筋肉からグループを決定
        if stimulations.isEmpty {
            let primaryGroup = primaryGroupFromGoal()
            #if DEBUG
            print("[MenuService] stimulations empty → goal-based group: \(primaryGroup.rawValue)")
            #endif
            return buildMenuForGroup(primaryGroup: primaryGroup, stimulations: stimulations, exerciseStore: exerciseStore)
        }

        // 1. 各グループの回復状態を評価
        let groupScores = evaluateGroups(stimulations: stimulations)

        // 2. 最も回復が進んでいる（長く刺激されていない）グループを選択
        guard let primaryGroup = groupScores
            .sorted(by: { $0.value > $1.value })
            .first?.key else {
            return SuggestedMenu(
                primaryGroup: .chest,
                reason: L10n.letsStartTraining,
                exercises: [],
                neglectedWarning: nil
            )
        }

        return buildMenuForGroup(primaryGroup: primaryGroup, stimulations: stimulations, exerciseStore: exerciseStore)
    }

    /// 指定グループからメニューを構築（通常フロー・初回ユーザー共通）
    @MainActor
    private static func buildMenuForGroup(
        primaryGroup: MuscleGroup,
        stimulations: [Muscle: MuscleStimulation],
        exerciseStore: ExerciseStore
    ) -> SuggestedMenu {
        // ペアリング
        let paired = pairedGroups(for: primaryGroup)

        // 各グループの主要種目を選出
        var suggestedExercises: [SuggestedExercise] = []
        for group in paired {
            let muscles = group.muscles
            for muscle in muscles {
                let exercises = exerciseStore.exercises(targeting: muscle)
                if let best = exercises.first {
                    // 重複チェック
                    if !suggestedExercises.contains(where: { $0.definition.id == best.id }) {
                        suggestedExercises.append(SuggestedExercise(
                            definition: best,
                            suggestedSets: 3,
                            suggestedReps: 10,
                            lastWeight: nil,
                            isNeglectedFix: false
                        ))
                    }
                }
                // グループあたり最大3種目
                if suggestedExercises.count >= paired.count * 3 {
                    break
                }
            }
        }

        // 未刺激7日+があれば1種目追加
        let neglected = findNeglectedMuscle(stimulations: stimulations)
        if let neglectedMuscle = neglected {
            let exercises = exerciseStore.exercises(targeting: neglectedMuscle)
            if let fix = exercises.first,
               !suggestedExercises.contains(where: { $0.definition.id == fix.id }) {
                suggestedExercises.append(SuggestedExercise(
                    definition: fix,
                    suggestedSets: 2,
                    suggestedReps: 12,
                    lastWeight: nil,
                    isNeglectedFix: true
                ))
            }
        }

        // 最大6種目に制限
        suggestedExercises = Array(suggestedExercises.prefix(6))

        let reason = generateReason(group: primaryGroup, neglected: neglected, stimulations: stimulations)

        return SuggestedMenu(
            primaryGroup: primaryGroup,
            reason: reason,
            exercises: suggestedExercises,
            neglectedWarning: neglected
        )
    }

    // MARK: - 内部ロジック

    /// goalPriorityMusclesから最も重要なグループを取得（初回ユーザー用）
    @MainActor
    private static func primaryGroupFromGoal() -> MuscleGroup {
        let priorityMuscles = AppState.shared.userProfile.goalPriorityMuscles
        if let firstRaw = priorityMuscles.first,
           let firstMuscle = Muscle(rawValue: firstRaw) {
            return firstMuscle.group
        }
        // goalPriorityMusclesも空 → 分割法の最初のパートを使用
        let frequency = AppState.shared.userProfile.weeklyFrequency
        let parts = WorkoutRecommendationEngine.splitParts(for: frequency)
        return parts.first?.muscleGroups.first ?? .chest
    }

    /// 各グループの「刺激の必要度」スコアを計算（高い=より刺激が必要）
    private static func evaluateGroups(
        stimulations: [Muscle: MuscleStimulation]
    ) -> [MuscleGroup: Double] {
        var scores: [MuscleGroup: Double] = [:]

        for group in MuscleGroup.allCases {
            let muscles = group.muscles
            var totalScore: Double = 0

            for muscle in muscles {
                if let stim = stimulations[muscle] {
                    let progress = RecoveryCalculator.recoveryProgress(
                        stimulationDate: stim.stimulationDate,
                        muscle: muscle,
                        totalSets: stim.totalSets
                    )
                    // 回復が進むほどスコアが高い（= 刺激が必要）
                    totalScore += progress
                } else {
                    // 刺激記録なし = 最も必要
                    totalScore += 2.0
                }
            }

            scores[group] = totalScore / Double(muscles.count)
        }

        return scores
    }

    /// ペアリング（分割法に基づく）
    @MainActor
    static func pairedGroups(for primary: MuscleGroup) -> [MuscleGroup] {
        let profile = AppState.shared.userProfile
        let parts = WorkoutRecommendationEngine.splitParts(for: profile.weeklyFrequency)

        // primaryGroupを含むパートを検索
        if let matchingPart = parts.first(where: { $0.muscleGroups.contains(primary) }) {
            return matchingPart.muscleGroups
        }

        // フォールバック（パートが見つからない場合）
        switch primary {
        case .chest:     return [.chest, .arms]
        case .back:      return [.back, .arms]
        case .shoulders: return [.shoulders, .core]
        case .lowerBody: return [.lowerBody]
        case .arms:      return [.arms, .shoulders]
        case .core:      return [.core, .shoulders]
        }
    }

    /// 未刺激7日以上の筋肉を検出
    private static func findNeglectedMuscle(
        stimulations: [Muscle: MuscleStimulation]
    ) -> Muscle? {
        for muscle in Muscle.allCases {
            if let stim = stimulations[muscle] {
                let days = RecoveryCalculator.daysSinceStimulation(stim.stimulationDate)
                if days >= 7 {
                    return muscle
                }
            }
        }
        return nil
    }

    /// 提案理由の文言を生成
    @MainActor
    private static func generateReason(
        group: MuscleGroup,
        neglected: Muscle?,
        stimulations: [Muscle: MuscleStimulation]
    ) -> String {
        let localization = LocalizationManager.shared
        let groupName = localization.currentLanguage == .japanese ? group.japaneseName : group.englishName
        var reason = L10n.groupMostRecovered(groupName)

        if let muscle = neglected, let stim = stimulations[muscle] {
            let days = RecoveryCalculator.daysSinceStimulation(stim.stimulationDate)
            let muscleName = localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName
            reason += L10n.muscleNeglectedDays(muscleName, days)
        }
        return reason
    }
}

// MARK: - 提案メニュー

struct SuggestedMenu {
    let primaryGroup: MuscleGroup
    let reason: String
    let exercises: [SuggestedExercise]
    let neglectedWarning: Muscle?
}

struct SuggestedExercise: Identifiable {
    let definition: ExerciseDefinition
    let suggestedSets: Int
    let suggestedReps: Int
    let lastWeight: Double?
    let isNeglectedFix: Bool

    var id: String { definition.id }
}

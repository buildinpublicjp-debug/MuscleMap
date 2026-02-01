import Foundation

// MARK: - 今日のメニュー提案サービス

struct MenuSuggestionService {

    /// 今日のメニューを提案
    @MainActor
    static func suggestTodayMenu(
        stimulations: [Muscle: MuscleStimulation],
        exerciseStore: ExerciseStore
    ) -> SuggestedMenu {
        // 1. 各グループの回復状態を評価
        let groupScores = evaluateGroups(stimulations: stimulations)

        // 2. 最も回復が進んでいる（長く刺激されていない）グループを選択
        guard let primaryGroup = groupScores
            .sorted(by: { $0.value > $1.value })
            .first?.key else {
            return SuggestedMenu(
                primaryGroup: .chest,
                reason: "トレーニングを始めましょう",
                exercises: [],
                neglectedWarning: nil
            )
        }

        // 3. ペアリング
        let pairedGroups = pairGroups(primary: primaryGroup)

        // 4. 各グループの主要種目を選出
        var suggestedExercises: [SuggestedExercise] = []
        for group in pairedGroups {
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
                if suggestedExercises.count >= pairedGroups.count * 3 {
                    break
                }
            }
        }

        // 5. 未刺激7日+があれば1種目追加
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

    /// ペアリング
    private static func pairGroups(primary: MuscleGroup) -> [MuscleGroup] {
        switch primary {
        case .chest:     return [.chest, .arms]       // 胸+三頭
        case .back:      return [.back, .arms]        // 背中+二頭
        case .shoulders: return [.shoulders, .core]    // 肩+体幹
        case .lowerBody: return [.lowerBody]           // 脚単独
        case .arms:      return [.arms, .shoulders]    // 腕+肩
        case .core:      return [.core, .shoulders]    // 体幹+肩
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
    private static func generateReason(
        group: MuscleGroup,
        neglected: Muscle?,
        stimulations: [Muscle: MuscleStimulation]
    ) -> String {
        var reason = "\(group.japaneseName)が最も回復しています"
        if let muscle = neglected, let stim = stimulations[muscle] {
            let days = RecoveryCalculator.daysSinceStimulation(stim.stimulationDate)
            reason += "。\(muscle.japaneseName)は\(days)日以上未刺激です"
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

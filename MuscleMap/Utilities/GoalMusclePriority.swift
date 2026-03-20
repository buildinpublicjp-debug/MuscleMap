import Foundation

// MARK: - 目標別の重点筋肉データ（Utility）

struct GoalMusclePriority {
    let muscles: [Muscle]
    let headline: String
    let reasons: [MuscleReason]
    /// 各目標の代表種目ID（重点筋肉のトップ種目から最大3つ）
    let sampleExerciseIds: [String]

    struct MuscleReason {
        let muscle: String
        let reason: String
    }

    /// 目標rawValueから重点筋肉データを取得
    @MainActor
    static func priority(for goalRawValue: String) -> GoalMusclePriority {
        guard let goal = OnboardingGoal(rawValue: goalRawValue) else {
            return data(for: .getBig)
        }
        return data(for: goal)
    }

    /// OnboardingGoalから重点筋肉データを取得
    @MainActor
    static func data(for goal: OnboardingGoal) -> GoalMusclePriority {
        let base = baseData(for: goal)
        let sampleIds = resolveSampleExerciseIds(muscles: base.muscles)
        return GoalMusclePriority(
            muscles: base.muscles,
            headline: base.headline,
            reasons: base.reasons,
            sampleExerciseIds: sampleIds
        )
    }

    // MARK: - サンプル種目ID解決

    /// 重点筋肉の上位3筋肉からそれぞれの代表種目を取得（重複除去、最大3種目）
    @MainActor
    private static func resolveSampleExerciseIds(muscles: [Muscle]) -> [String] {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        var result: [String] = []
        for muscle in muscles.prefix(3) {
            let matching = store.exercises(targeting: muscle)
            if let first = matching.first, !result.contains(first.id) {
                result.append(first.id)
            }
            if result.count >= 3 { break }
        }
        return result
    }

    // MARK: - 7パターンの静的データ

    private struct BaseData {
        let muscles: [Muscle]
        let headline: String
        let reasons: [MuscleReason]
    }

    @MainActor
    private static func baseData(for goal: OnboardingGoal) -> BaseData {
        let isJa = LocalizationManager.shared.currentLanguage == .japanese
        switch goal {
        case .getBig:
            return BaseData(
                muscles: [.chestUpper, .chestLower, .lats, .quadriceps, .hamstrings, .glutes],
                headline: isJa ? "大きい筋肉から鍛えれば効率最大" : "Target big muscles for maximum efficiency",
                reasons: [
                    MuscleReason(muscle: isJa ? "大胸筋" : "Chest", reason: isJa ? "上半身のボリューム" : "Upper body volume"),
                    MuscleReason(muscle: isJa ? "広背筋" : "Lats", reason: isJa ? "背中の広がり" : "Back width"),
                    MuscleReason(muscle: isJa ? "脚" : "Legs", reason: isJa ? "体の60%の筋肉量" : "60% of total muscle mass"),
                ]
            )
        case .dontGetDisrespected:
            return BaseData(
                muscles: [.deltoidAnterior, .deltoidLateral, .chestUpper, .trapsUpper],
                headline: isJa ? "存在感は上半身の幅で決まる" : "Presence comes from upper body width",
                reasons: [
                    MuscleReason(muscle: isJa ? "三角筋" : "Delts", reason: isJa ? "肩幅を広げる" : "Widen your shoulders"),
                    MuscleReason(muscle: isJa ? "大胸筋" : "Chest", reason: isJa ? "厚みを出す" : "Add thickness"),
                    MuscleReason(muscle: isJa ? "僧帽筋" : "Traps", reason: isJa ? "首回りの迫力" : "Neck presence"),
                ]
            )
        case .martialArts:
            return BaseData(
                muscles: [.lats, .quadriceps, .hamstrings, .rectusAbdominis, .obliques],
                headline: isJa ? "打撃力は背中と脚から生まれる" : "Striking power comes from back & legs",
                reasons: [
                    MuscleReason(muscle: isJa ? "広背筋" : "Lats", reason: isJa ? "パンチの引き" : "Punch retraction"),
                    MuscleReason(muscle: isJa ? "脚" : "Legs", reason: isJa ? "踏み込みの力" : "Drive-in power"),
                    MuscleReason(muscle: isJa ? "体幹" : "Core", reason: isJa ? "打撃の安定性" : "Strike stability"),
                ]
            )
        case .sports:
            return BaseData(
                muscles: [.quadriceps, .hamstrings, .glutes, .rectusAbdominis, .deltoidAnterior],
                headline: isJa ? "パフォーマンスは下半身と体幹が土台" : "Performance starts with legs & core",
                reasons: [
                    MuscleReason(muscle: isJa ? "脚" : "Legs", reason: isJa ? "爆発的なパワー" : "Explosive power"),
                    MuscleReason(muscle: isJa ? "体幹" : "Core", reason: isJa ? "動きの安定性" : "Movement stability"),
                    MuscleReason(muscle: isJa ? "肩" : "Shoulders", reason: isJa ? "腕の振りの起点" : "Arm swing origin"),
                ]
            )
        case .getAttractive:
            return BaseData(
                muscles: [.chestUpper, .deltoidAnterior, .deltoidLateral, .biceps, .rectusAbdominis],
                headline: isJa ? "Tシャツ映えは胸と肩のシルエット" : "Great silhouette starts with chest & shoulders",
                reasons: [
                    MuscleReason(muscle: isJa ? "大胸筋" : "Chest", reason: isJa ? "胸板の厚み" : "Chest thickness"),
                    MuscleReason(muscle: isJa ? "三角筋" : "Delts", reason: isJa ? "肩のライン" : "Shoulder line"),
                    MuscleReason(muscle: isJa ? "腹直筋" : "Abs", reason: isJa ? "引き締まったウエスト" : "Tight waistline"),
                ]
            )
        case .moveWell:
            return BaseData(
                muscles: [.quadriceps, .glutes, .rectusAbdominis, .erectorSpinae, .lats],
                headline: isJa ? "日常の動きは全部ここから" : "Everyday movement starts here",
                reasons: [
                    MuscleReason(muscle: isJa ? "脚" : "Legs", reason: isJa ? "階段・歩行の基盤" : "Stairs & walking foundation"),
                    MuscleReason(muscle: isJa ? "体幹" : "Core", reason: isJa ? "姿勢の維持" : "Posture support"),
                    MuscleReason(muscle: isJa ? "背中" : "Back", reason: isJa ? "物を持つ力" : "Lifting strength"),
                ]
            )
        case .health:
            return BaseData(
                muscles: [.quadriceps, .hamstrings, .glutes, .erectorSpinae, .rectusAbdominis],
                headline: isJa ? "抗老化に最も効くのは大筋群" : "Large muscles are key to anti-aging",
                reasons: [
                    MuscleReason(muscle: isJa ? "脚" : "Legs", reason: isJa ? "転倒予防・代謝維持" : "Fall prevention & metabolism"),
                    MuscleReason(muscle: isJa ? "背中" : "Back", reason: isJa ? "姿勢と骨密度" : "Posture & bone density"),
                    MuscleReason(muscle: isJa ? "体幹" : "Core", reason: isJa ? "腰痛予防" : "Lower back protection"),
                ]
            )
        }
    }
}

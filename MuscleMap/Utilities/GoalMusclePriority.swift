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

    private static func baseData(for goal: OnboardingGoal) -> BaseData {
        switch goal {
        case .getBig:
            return BaseData(
                muscles: [.chestUpper, .chestLower, .lats, .quadriceps, .hamstrings, .glutes],
                headline: "大きい筋肉から鍛えれば効率最大",
                reasons: [
                    MuscleReason(muscle: "大胸筋", reason: "上半身のボリューム"),
                    MuscleReason(muscle: "広背筋", reason: "背中の広がり"),
                    MuscleReason(muscle: "脚", reason: "体の60%の筋肉量"),
                ]
            )
        case .dontGetDisrespected:
            return BaseData(
                muscles: [.deltoidAnterior, .deltoidLateral, .chestUpper, .trapsUpper],
                headline: "存在感は上半身の幅で決まる",
                reasons: [
                    MuscleReason(muscle: "三角筋", reason: "肩幅を広げる"),
                    MuscleReason(muscle: "大胸筋", reason: "厚みを出す"),
                    MuscleReason(muscle: "僧帽筋", reason: "首回りの迫力"),
                ]
            )
        case .martialArts:
            return BaseData(
                muscles: [.lats, .quadriceps, .hamstrings, .rectusAbdominis, .obliques],
                headline: "打撃力は背中と脚から生まれる",
                reasons: [
                    MuscleReason(muscle: "広背筋", reason: "パンチの引き"),
                    MuscleReason(muscle: "脚", reason: "踏み込みの力"),
                    MuscleReason(muscle: "体幹", reason: "打撃の安定性"),
                ]
            )
        case .sports:
            return BaseData(
                muscles: [.quadriceps, .hamstrings, .glutes, .rectusAbdominis, .deltoidAnterior],
                headline: "パフォーマンスは下半身と体幹が土台",
                reasons: [
                    MuscleReason(muscle: "脚", reason: "爆発的なパワー"),
                    MuscleReason(muscle: "体幹", reason: "動きの安定性"),
                    MuscleReason(muscle: "肩", reason: "腕の振りの起点"),
                ]
            )
        case .getAttractive:
            return BaseData(
                muscles: [.chestUpper, .deltoidAnterior, .deltoidLateral, .biceps, .rectusAbdominis],
                headline: "Tシャツ映えは胸と肩のシルエット",
                reasons: [
                    MuscleReason(muscle: "大胸筋", reason: "胸板の厚み"),
                    MuscleReason(muscle: "三角筋", reason: "肩のライン"),
                    MuscleReason(muscle: "腹直筋", reason: "引き締まったウエスト"),
                ]
            )
        case .moveWell:
            return BaseData(
                muscles: [.quadriceps, .glutes, .rectusAbdominis, .erectorSpinae, .lats],
                headline: "日常の動きは全部ここから",
                reasons: [
                    MuscleReason(muscle: "脚", reason: "階段・歩行の基盤"),
                    MuscleReason(muscle: "体幹", reason: "姿勢の維持"),
                    MuscleReason(muscle: "背中", reason: "物を持つ力"),
                ]
            )
        case .health:
            return BaseData(
                muscles: [.quadriceps, .hamstrings, .glutes, .erectorSpinae, .rectusAbdominis],
                headline: "抗老化に最も効くのは大筋群",
                reasons: [
                    MuscleReason(muscle: "脚", reason: "転倒予防・代謝維持"),
                    MuscleReason(muscle: "背中", reason: "姿勢と骨密度"),
                    MuscleReason(muscle: "体幹", reason: "腰痛予防"),
                ]
            )
        }
    }
}

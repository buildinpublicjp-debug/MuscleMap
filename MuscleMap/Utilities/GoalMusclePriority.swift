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
        switch goal {
        case .getBig:
            return BaseData(
                muscles: [.chestUpper, .chestLower, .lats, .trapsMiddleLower, .quadriceps, .hamstrings, .glutes, .triceps],
                headline: L10n.goalHeadlineBig,
                reasons: [
                    MuscleReason(muscle: L10n.muscleChest, reason: L10n.reasonUpperVolume),
                    MuscleReason(muscle: L10n.muscleLats, reason: L10n.reasonBackWidth),
                    MuscleReason(muscle: L10n.muscleLegs, reason: L10n.reasonMuscleMass60),
                ]
            )
        case .dontGetDisrespected:
            return BaseData(
                muscles: [.deltoidAnterior, .deltoidLateral, .chestUpper, .trapsUpper, .triceps, .biceps, .forearms],
                headline: L10n.goalHeadlinePresence,
                reasons: [
                    MuscleReason(muscle: L10n.muscleDelts, reason: L10n.reasonWidenShoulders),
                    MuscleReason(muscle: L10n.muscleChest, reason: L10n.reasonAddThickness),
                    MuscleReason(muscle: L10n.muscleTraps, reason: L10n.reasonNeckPresence),
                ]
            )
        case .martialArts:
            return BaseData(
                muscles: [.lats, .quadriceps, .hamstrings, .rectusAbdominis, .obliques, .deltoidPosterior, .forearms, .gastrocnemius, .glutes],
                headline: L10n.goalHeadlineFight,
                reasons: [
                    MuscleReason(muscle: L10n.muscleLats, reason: L10n.reasonPunchRetraction),
                    MuscleReason(muscle: L10n.muscleLegs, reason: L10n.reasonDriveInPower),
                    MuscleReason(muscle: L10n.muscleCore, reason: L10n.reasonStrikeStability),
                ]
            )
        case .sports:
            return BaseData(
                muscles: [.quadriceps, .hamstrings, .glutes, .rectusAbdominis, .deltoidAnterior, .gastrocnemius, .soleus, .adductors],
                headline: L10n.goalHeadlineSports,
                reasons: [
                    MuscleReason(muscle: L10n.muscleLegs, reason: L10n.reasonExplosivePower),
                    MuscleReason(muscle: L10n.muscleCore, reason: L10n.reasonMovementStability),
                    MuscleReason(muscle: L10n.muscleShoulders, reason: L10n.reasonArmSwing),
                ]
            )
        case .getAttractive:
            return BaseData(
                muscles: [.chestUpper, .deltoidAnterior, .deltoidLateral, .biceps, .rectusAbdominis, .obliques, .triceps],
                headline: L10n.goalHeadlineAttractive,
                reasons: [
                    MuscleReason(muscle: L10n.muscleChest, reason: L10n.reasonChestThickness),
                    MuscleReason(muscle: L10n.muscleDelts, reason: L10n.reasonShoulderLine),
                    MuscleReason(muscle: L10n.muscleAbs, reason: L10n.reasonTightWaist),
                ]
            )
        case .moveWell:
            return BaseData(
                muscles: [.quadriceps, .glutes, .rectusAbdominis, .erectorSpinae, .lats, .hipFlexors, .soleus, .adductors],
                headline: L10n.goalHeadlineMoveWell,
                reasons: [
                    MuscleReason(muscle: L10n.muscleLegs, reason: L10n.reasonStairsWalking),
                    MuscleReason(muscle: L10n.muscleCore, reason: L10n.reasonPosture),
                    MuscleReason(muscle: L10n.muscleBack, reason: L10n.reasonLifting),
                ]
            )
        case .health:
            return BaseData(
                muscles: [.quadriceps, .hamstrings, .glutes, .erectorSpinae, .rectusAbdominis, .hipFlexors, .gastrocnemius, .soleus],
                headline: L10n.goalHeadlineHealth,
                reasons: [
                    MuscleReason(muscle: L10n.muscleLegs, reason: L10n.reasonFallPrevention),
                    MuscleReason(muscle: L10n.muscleBack, reason: L10n.reasonBoneDensity),
                    MuscleReason(muscle: L10n.muscleCore, reason: L10n.reasonLowerBackProtection),
                ]
            )
        }
    }
}

import SwiftUI

// MARK: - ミニ筋肉マップ（種目リスト用）

/// 種目リストで使用する小さい筋肉マップ
struct MiniMuscleMapView: View {
    /// 筋肉ID → 刺激度% (0-100)
    let muscleMapping: [String: Int]

    /// 表示する面（前面/背面、デフォルトは主要筋肉に応じて自動判定）
    var showFront: Bool?

    private var shouldShowFront: Bool {
        if let showFront = showFront {
            return showFront
        }
        // 筋肉マッピングから自動判定
        let frontMuscles = Set(MusclePathData.frontMuscles.map { $0.muscle.rawValue.toSnakeCase() })
        let backMuscles = Set(MusclePathData.backMuscles.map { $0.muscle.rawValue.toSnakeCase() })

        var frontScore = 0
        var backScore = 0

        for (muscleId, intensity) in muscleMapping {
            if frontMuscles.contains(muscleId) {
                frontScore += intensity
            }
            if backMuscles.contains(muscleId) {
                backScore += intensity
            }
        }

        return frontScore >= backScore
    }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                // シルエット（背景）
                if shouldShowFront {
                    MusclePathData.bodyOutlineFront(in: rect)
                        .fill(Color.mmBgSecondary.opacity(0.3))
                } else {
                    MusclePathData.bodyOutlineBack(in: rect)
                        .fill(Color.mmBgSecondary.opacity(0.3))
                }

                // 筋肉パス
                let muscles = shouldShowFront
                    ? MusclePathData.frontMuscles
                    : MusclePathData.backMuscles

                ForEach(muscles, id: \.muscle) { entry in
                    let stimulation = stimulationFor(entry.muscle)

                    entry.path(rect)
                        .fill(colorFor(stimulation: stimulation))
                }
            }
        }
    }

    // MARK: - 刺激度の取得

    private func stimulationFor(_ muscle: Muscle) -> Int {
        if let value = muscleMapping[muscle.rawValue] {
            return value
        }
        let snakeCase = muscle.rawValue.toSnakeCase()
        if let value = muscleMapping[snakeCase] {
            return value
        }
        return 0
    }

    // MARK: - 刺激度に応じた色

    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            return Color.clear
        }

        let opacity = 0.4 + (Double(stimulation) / 100.0) * 0.6

        switch stimulation {
        case 80...:
            return Color.mmMuscleJustWorked.opacity(opacity)
        case 50..<80:
            return Color.mmMuscleAmber.opacity(opacity)
        case 20..<50:
            return Color.mmMuscleLime.opacity(opacity)
        default:
            return Color.mmMuscleLime.opacity(0.5)
        }
    }
}

// MARK: - String Extension (camelCase → snake_case)

private extension String {
    func toSnakeCase() -> String {
        var result = ""
        for (index, char) in self.enumerated() {
            if char.isUppercase {
                if index > 0 {
                    result += "_"
                }
                result += char.lowercased()
            } else {
                result += String(char)
            }
        }
        return result
    }
}

// MARK: - 種目適合性バッジ

enum ExerciseCompatibility {
    case recommended       // 全ての対象筋肉が回復済み
    case partiallyRecovering  // 一部回復中
    case recovering        // 主要筋肉が回復中
    case restSuggested     // 高負荷の筋肉あり（休息推奨）
    case neutral           // データなし

    @MainActor
    var badge: (text: String, color: Color)? {
        switch self {
        case .recommended:
            return (L10n.recommended, .mmAccentPrimary)
        case .partiallyRecovering:
            return (L10n.partiallyRecovering, .orange)
        case .recovering:
            return (L10n.recovering, .mmMuscleAmber)
        case .restSuggested:
            return (L10n.restSuggested, .mmMuscleJustWorked)
        case .neutral:
            return nil
        }
    }
}

// MARK: - 種目適合性計算

struct ExerciseCompatibilityCalculator {

    /// 種目の適合性を計算
    static func calculate(
        exercise: ExerciseDefinition,
        muscleStates: [Muscle: MuscleStimulation]
    ) -> ExerciseCompatibility {
        let targetMuscles = exercise.muscleMapping.keys.compactMap { muscleId -> Muscle? in
            // snake_case → Muscle enum
            for muscle in Muscle.allCases {
                if muscle.rawValue == muscleId || muscle.rawValue.toSnakeCase() == muscleId {
                    return muscle
                }
            }
            return nil
        }

        guard !targetMuscles.isEmpty else {
            return .neutral
        }

        var fullyRecoveredCount = 0
        var recoveringCount = 0
        var highLoadCount = 0

        for muscle in targetMuscles {
            if let stim = muscleStates[muscle] {
                let progress = RecoveryCalculator.recoveryProgress(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets
                )

                if progress >= 1.0 {
                    fullyRecoveredCount += 1
                } else if progress < 0.3 {
                    highLoadCount += 1
                } else {
                    recoveringCount += 1
                }
            } else {
                // 刺激記録なし → 回復済みとみなす
                fullyRecoveredCount += 1
            }
        }

        let total = targetMuscles.count

        // 高負荷の筋肉がある場合は休息推奨
        if highLoadCount > 0 {
            return .restSuggested
        }

        // 全て回復済み
        if fullyRecoveredCount == total {
            return .recommended
        }

        // 一部回復中
        if recoveringCount > 0 && fullyRecoveredCount > 0 {
            return .partiallyRecovering
        }

        // 主に回復中
        if recoveringCount > 0 {
            return .recovering
        }

        return .neutral
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()

        HStack(spacing: 20) {
            // ベンチプレス（胸メイン）
            VStack {
                MiniMuscleMapView(muscleMapping: [
                    "chest_upper": 65,
                    "chest_lower": 100,
                    "deltoid_anterior": 50,
                    "triceps": 40
                ])
                .frame(width: 50, height: 80)

                Text("Bench Press")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // デッドリフト（背中メイン）
            VStack {
                MiniMuscleMapView(muscleMapping: [
                    "lats": 80,
                    "traps_upper": 60,
                    "erector_spinae": 100,
                    "glutes": 70,
                    "hamstrings": 50
                ])
                .frame(width: 50, height: 80)

                Text("Deadlift")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding()
    }
}

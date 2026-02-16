import SwiftUI

// MARK: - 種目の対象筋肉マップビュー

struct ExerciseMuscleMapView: View {
    /// 筋肉ID → 刺激度% (0-100)
    let muscleMapping: [String: Int]

    var body: some View {
        VStack(spacing: 8) {
            // 前面・背面の横並びラベル
            HStack {
                Text(L10n.front)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                Text(L10n.back)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)

            // 前面・背面の横並び筋肉マップ
            HStack(spacing: 8) {
                // 前面マップ
                SingleBodyMapView(
                    muscleMapping: muscleMapping,
                    muscles: MusclePathData.frontMuscles,
                    stimulationFor: stimulationFor,
                    colorFor: colorFor
                )
                .frame(height: 200)

                // 背面マップ
                SingleBodyMapView(
                    muscleMapping: muscleMapping,
                    muscles: MusclePathData.backMuscles,
                    stimulationFor: stimulationFor,
                    colorFor: colorFor
                )
                .frame(height: 200)
            }
            .padding(.horizontal, 8)

            // 凡例
            legendView
        }
    }
    
    // MARK: - 刺激度の取得
    
    private func stimulationFor(_ muscle: Muscle) -> Int {
        // muscle.rawValue は "chestUpper" 形式
        // muscleMapping のキーは "chest_upper" 形式の可能性があるので両方チェック
        if let value = muscleMapping[muscle.rawValue] {
            return value
        }
        // スネークケースに変換してチェック
        let snakeCase = muscle.rawValue.toSnakeCase()
        if let value = muscleMapping[snakeCase] {
            return value
        }
        return 0
    }
    
    // MARK: - 刺激度に応じた色

    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            // 刺激されない筋肉 = 暗いグレー（シルエットが見える程度）
            return Color.mmTextSecondary.opacity(0.2)
        }

        // 刺激度に応じてグラデーション
        // 低 → 黄緑、中 → 黄、高 → オレンジ/赤
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
    
    // MARK: - 凡例
    
    private var legendView: some View {
        HStack(spacing: 20) {
            LegendItem(color: .mmMuscleJustWorked, label: L10n.highStimulation)
            LegendItem(color: .mmMuscleAmber, label: L10n.mediumStimulation)
            LegendItem(color: .mmMuscleLime, label: L10n.lowStimulation)
        }
        .font(.caption2)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - 単一ボディマップビュー（前面または背面）

private struct SingleBodyMapView: View {
    let muscleMapping: [String: Int]
    let muscles: [(muscle: Muscle, path: (CGRect) -> Path)]
    let stimulationFor: (Muscle) -> Int
    let colorFor: (Int) -> Color

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let stimulation = stimulationFor(entry.muscle)
                    let path = entry.path(rect)

                    path
                        .fill(colorFor(stimulation))
                    path
                        .stroke(Color.mmMuscleBorder.opacity(0.4), lineWidth: 0.8)
                }
            }
        }
        .aspectRatio(0.6, contentMode: .fit)
    }
}

// MARK: - 凡例アイテム

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Color.mmTextSecondary)
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

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        
        ExerciseMuscleMapView(muscleMapping: [
            "chest_upper": 65,
            "chest_lower": 100,
            "deltoid_anterior": 50,
            "triceps": 40
        ])
        .padding()
    }
}

import SwiftUI

// MARK: - シェアカード用静的筋肉マップ
// ImageRenderer用に最適化。@State、アニメーション、タップ処理なし。

struct ShareMuscleMapView: View {
    /// 筋肉ID → 刺激度% (0-100)
    let muscleMapping: [String: Int]

    /// 固定サイズ（ImageRenderer安定性のため）
    private let mapSize = CGSize(width: 140, height: 280)

    var body: some View {
        HStack(spacing: 20) {
            // 前面
            staticMuscleMap(muscles: MusclePathData.frontMuscles)
                .frame(width: mapSize.width, height: mapSize.height)

            // 背面
            staticMuscleMap(muscles: MusclePathData.backMuscles)
                .frame(width: mapSize.width, height: mapSize.height)
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - 静的筋肉マップ描画

    private func staticMuscleMap(muscles: [(muscle: Muscle, path: (CGRect) -> Path)]) -> some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            for entry in muscles {
                let path = entry.path(rect)
                let stimulation = stimulationFor(entry.muscle)
                let color = colorFor(stimulation: stimulation)

                // 塗りつぶし
                context.fill(path, with: .color(color))

                // 境界線
                context.stroke(
                    path,
                    with: .color(Color.mmMuscleBorder.opacity(0.4)),
                    lineWidth: 0.5
                )
            }
        }
    }

    // MARK: - 刺激度取得

    private func stimulationFor(_ muscle: Muscle) -> Int {
        // rawValue で検索
        if let value = muscleMapping[muscle.rawValue] {
            return value
        }
        // snake_case 変換で検索
        let snakeCase = muscle.rawValue.toSnakeCaseForShare()
        if let value = muscleMapping[snakeCase] {
            return value
        }
        return 0
    }

    // MARK: - 刺激度に応じた色

    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            // 未刺激 = 暗いグレー
            return Color.mmBgSecondary
        }

        // 刺激度に応じた色分け
        switch stimulation {
        case 80...100:
            // 高刺激 = 赤
            return Color.mmMuscleJustWorked
        case 50..<80:
            // 中刺激 = コーラル
            return Color.mmMuscleCoral
        case 20..<50:
            // 低刺激 = アンバー
            return Color.mmMuscleAmber
        default:
            // 微刺激 = 薄い緑
            return Color.mmAccentPrimary.opacity(0.5)
        }
    }
}

// MARK: - String Extension (camelCase → snake_case)

private extension String {
    func toSnakeCaseForShare() -> String {
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()

        ShareMuscleMapView(muscleMapping: [
            "chest_upper": 100,
            "chest_lower": 85,
            "deltoid_anterior": 60,
            "triceps": 45,
            "biceps": 30,
            "lats": 70,
            "glutes": 50
        ])
    }
}

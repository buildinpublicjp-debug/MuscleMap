import SwiftUI

// MARK: - シェアカード用静的筋肉マップ
// ImageRenderer用に最適化。@State、アニメーション、タップ処理なし。

struct ShareMuscleMapView: View {
    /// 筋肉ID → 刺激度% (0-100)
    let muscleMapping: [String: Int]
    /// マップ全体の高さ（呼び出し元で指定可能）
    var mapHeight: CGFloat = 280
    /// グロー効果を有効にするか（シェアカード用）
    var glowEnabled: Bool = false

    /// 各マップの幅は高さの0.5倍（人体比率を維持）
    private var mapSize: CGSize {
        CGSize(width: mapHeight * 0.5, height: mapHeight)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 前面
            staticMuscleMap(muscles: MusclePathData.frontMuscles)
                .frame(width: mapSize.width, height: mapSize.height)

            // 背面
            staticMuscleMap(muscles: MusclePathData.backMuscles)
                .frame(width: mapSize.width, height: mapSize.height)
        }
        .frame(height: mapHeight)
    }

    // MARK: - 静的筋肉マップ描画

    private func staticMuscleMap(muscles: [(muscle: Muscle, path: (CGRect) -> Path)]) -> some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            for entry in muscles {
                let path = entry.path(rect)
                let stimulation = stimulationFor(entry.muscle)
                let color = colorFor(stimulation: stimulation)

                // グロー効果（刺激された筋肉のみ）
                if glowEnabled && stimulation >= 50 {
                    // 外側グロー（大きめのぼかし）
                    context.drawLayer { ctx in
                        ctx.addFilter(.shadow(color: glowColor(stimulation: stimulation).opacity(0.6), radius: 8, x: 0, y: 0))
                        ctx.fill(path, with: .color(color.opacity(0.01)))
                    }
                    // 内側グロー（小さめのぼかし）
                    context.drawLayer { ctx in
                        ctx.addFilter(.shadow(color: glowColor(stimulation: stimulation).opacity(0.4), radius: 4, x: 0, y: 0))
                        ctx.fill(path, with: .color(color.opacity(0.01)))
                    }
                }

                // 塗りつぶし
                context.fill(path, with: .color(color))

                // 境界線
                let borderOpacity: Double = stimulation > 0 ? 0.5 : 0.8
                context.stroke(
                    path,
                    with: .color(Color(hex: "#808080").opacity(borderOpacity)),
                    lineWidth: stimulation >= 80 ? 1.2 : 0.8
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

    // MARK: - 刺激度に応じた色（3段階）

    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            // 未刺激 = 暗いグレー
            return Color(hex: "#2A2A2E")
        }

        switch stimulation {
        case 80...100:
            return Color(hex: "#E57373")
        case 50..<80:
            return Color(hex: "#FFD54F")
        case 20..<50:
            return Color(hex: "#81C784")
        default:
            return Color(hex: "#81C784").opacity(0.6)
        }
    }

    /// グロー用の色（刺激度に応じて変化）
    private func glowColor(stimulation: Int) -> Color {
        switch stimulation {
        case 80...100:
            return Color(hex: "#E57373")
        case 50..<80:
            return Color(hex: "#FFD54F")
        default:
            return Color(hex: "#81C784")
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
        Color(hex: "#0A0A0A").ignoresSafeArea()

        ShareMuscleMapView(
            muscleMapping: [
                "chest_upper": 100,
                "chest_lower": 85,
                "deltoid_anterior": 60,
                "triceps": 45,
                "biceps": 30,
                "lats": 70,
                "glutes": 50
            ],
            glowEnabled: true
        )
    }
}

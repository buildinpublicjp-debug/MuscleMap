import SwiftUI

// MARK: - カレンダー用マイクロボディマップ（前面+背面 2体表示）

/// 6ゾーンの超簡略ボディシルエットを前後2体並べて表示
/// カレンダーセル（約45x58pt）内に収まるサイズ設計
struct MicroBodyMapView: View {
    let muscleGroups: Set<MuscleGroup>

    var body: some View {
        HStack(spacing: 2) {
            // 前面
            SingleMicroBody(
                muscleGroups: muscleGroups,
                isFront: true
            )
            // 背面
            SingleMicroBody(
                muscleGroups: muscleGroups,
                isFront: false
            )
        }
    }
}

// MARK: - 単体マイクロボディ（前面 or 背面）

private struct SingleMicroBody: View {
    let muscleGroups: Set<MuscleGroup>
    let isFront: Bool

    // ゾーンごとの色判定
    private func zoneColor(_ group: MuscleGroup) -> Color {
        muscleGroups.contains(group)
            ? muscleGroupColor(group)
            : Color.mmTextSecondary.opacity(0.15)
    }

    // 胴体中央: 前面=chest, 背面=back
    private var torsoColor: Color {
        if isFront {
            return zoneColor(.chest)
        } else {
            return zoneColor(.back)
        }
    }

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // --- レイアウト定義 ---
            // 頭: 上部の小円
            let headCenter = CGPoint(x: w * 0.5, y: h * 0.08)
            let headRadius = w * 0.12

            // 肩: 頭の下、左右に広い帯
            let shoulderY = h * 0.17
            let shoulderH = h * 0.08
            let shoulderRect = CGRect(
                x: w * 0.12, y: shoulderY,
                width: w * 0.76, height: shoulderH
            )

            // 腕: 肩の外側、縦長
            let armW = w * 0.14
            let armH = h * 0.28
            let armY = shoulderY + shoulderH * 0.2
            let leftArmRect = CGRect(x: w * 0.02, y: armY, width: armW, height: armH)
            let rightArmRect = CGRect(x: w - w * 0.02 - armW, y: armY, width: armW, height: armH)

            // 胴体（胸 or 背中）: 肩の下、中央
            let torsoY = shoulderY + shoulderH
            let torsoH = h * 0.2
            let torsoRect = CGRect(
                x: w * 0.2, y: torsoY,
                width: w * 0.6, height: torsoH
            )

            // 体幹（腹 or 腰）: 胴体の下
            let coreY = torsoY + torsoH
            let coreH = h * 0.14
            let coreRect = CGRect(
                x: w * 0.22, y: coreY,
                width: w * 0.56, height: coreH
            )

            // 脚: 体幹の下、左右に分かれた2本
            let legY = coreY + coreH + h * 0.01
            let legH = h * 0.32
            let legW = w * 0.22
            let legGap = w * 0.04
            let leftLegRect = CGRect(
                x: w * 0.5 - legGap / 2 - legW, y: legY,
                width: legW, height: legH
            )
            let rightLegRect = CGRect(
                x: w * 0.5 + legGap / 2, y: legY,
                width: legW, height: legH
            )

            // --- 描画 ---
            // 頭（常にダークグレー）
            let headPath = Path(ellipseIn: CGRect(
                x: headCenter.x - headRadius,
                y: headCenter.y - headRadius,
                width: headRadius * 2,
                height: headRadius * 2
            ))
            context.fill(headPath, with: .color(Color.mmTextSecondary.opacity(0.2)))

            // 肩
            let shoulderPath = RoundedRectPath(rect: shoulderRect, cornerRadius: 3)
            context.fill(shoulderPath, with: .color(zoneColor(.shoulders)))

            // 腕
            let leftArmPath = RoundedRectPath(rect: leftArmRect, cornerRadius: 2)
            let rightArmPath = RoundedRectPath(rect: rightArmRect, cornerRadius: 2)
            context.fill(leftArmPath, with: .color(zoneColor(.arms)))
            context.fill(rightArmPath, with: .color(zoneColor(.arms)))

            // 胴体中央（前面=chest, 背面=back）
            let torsoPath = RoundedRectPath(rect: torsoRect, cornerRadius: 3)
            context.fill(torsoPath, with: .color(torsoColor))

            // 体幹
            let corePath = RoundedRectPath(rect: coreRect, cornerRadius: 2)
            context.fill(corePath, with: .color(zoneColor(.core)))

            // 脚
            let leftLegPath = RoundedRectPath(rect: leftLegRect, cornerRadius: 3)
            let rightLegPath = RoundedRectPath(rect: rightLegRect, cornerRadius: 3)
            context.fill(leftLegPath, with: .color(zoneColor(.lowerBody)))
            context.fill(rightLegPath, with: .color(zoneColor(.lowerBody)))
        }
        .frame(width: 14, height: 24)
    }
}

// MARK: - 角丸矩形パス生成ヘルパー

private func RoundedRectPath(rect: CGRect, cornerRadius: CGFloat) -> Path {
    Path(roundedRect: rect, cornerRadius: cornerRadius)
}

// MARK: - 筋肉グループ色

private func muscleGroupColor(_ group: MuscleGroup) -> Color {
    switch group {
    case .chest: return .mmMuscleJustWorked      // 赤系
    case .back: return .mmAccentSecondary        // 青系
    case .shoulders: return .mmMuscleAmber       // 黄系
    case .arms: return .mmMuscleCoral            // オレンジ系
    case .core: return .mmMuscleLime             // 黄緑系
    case .lowerBody: return .mmAccentPrimary     // 緑系
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()

        VStack(spacing: 24) {
            // 胸トレの日
            HStack(spacing: 16) {
                MicroBodyMapView(muscleGroups: [.chest, .arms, .shoulders])
                Text("胸トレ → 前面の胸・肩・腕が光る")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // 背中トレの日
            HStack(spacing: 16) {
                MicroBodyMapView(muscleGroups: [.back, .arms])
                Text("背中トレ → 背面の背中・腕が光る")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // 脚トレの日
            HStack(spacing: 16) {
                MicroBodyMapView(muscleGroups: [.lowerBody, .core])
                Text("脚トレ → 脚・体幹が光る")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // フル（全部位）
            HStack(spacing: 16) {
                MicroBodyMapView(muscleGroups: [.chest, .back, .shoulders, .arms, .core, .lowerBody])
                Text("全部位 → 全部光る")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // 空（休息日）
            HStack(spacing: 16) {
                MicroBodyMapView(muscleGroups: [])
                Text("休息日 → 全部グレー")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // カレンダーセルサイズのデモ
            Text("↓ カレンダーセルサイズでの見え方")
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .padding(.top, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 2) {
                        Text("\(i + 1)")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)

                        if i == 0 || i == 3 || i == 5 {
                            MicroBodyMapView(muscleGroups: i == 0 ? [.chest, .arms] : i == 3 ? [.back, .shoulders] : [.lowerBody])
                        } else {
                            Color.clear.frame(height: 24)
                        }
                    }
                    .frame(height: 58)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

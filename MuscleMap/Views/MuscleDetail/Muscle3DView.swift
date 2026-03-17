import SwiftUI

// MARK: - 筋肉詳細マップビュー（2Dハイライト + 同グループ薄表示）

struct Muscle3DView: View {
    let muscle: Muscle
    let visualState: MuscleVisualState

    /// 筋肉がフロント/バックどちらにあるか判定
    private var isBackMuscle: Bool {
        let backOnly = MusclePathData.backMuscles.contains(where: { $0.muscle == muscle })
        let frontAlso = MusclePathData.frontMuscles.contains(where: { $0.muscle == muscle })
        return backOnly && !frontAlso
    }

    /// メインサイドの筋肉エントリ（前面 or 背面）
    private var primaryEntries: [(muscle: Muscle, path: (CGRect) -> Path)] {
        isBackMuscle ? MusclePathData.backMuscles : MusclePathData.frontMuscles
    }

    /// サブサイドの筋肉エントリ
    private var secondaryEntries: [(muscle: Muscle, path: (CGRect) -> Path)] {
        isBackMuscle ? MusclePathData.frontMuscles : MusclePathData.backMuscles
    }

    /// 同グループの筋肉（自分自身を除く）
    private var sameGroupMuscles: Set<Muscle> {
        Set(Muscle.allCases.filter { $0.group == muscle.group && $0 != muscle })
    }

    /// ハイライト色（回復状態ベース、inactiveならアクセント）
    private var highlightColor: Color {
        switch visualState {
        case .inactive:
            return .mmAccentPrimary
        default:
            return visualState.color
        }
    }

    /// 筋肉グループに応じたズーム設定
    private var zoomConfig: (scale: CGFloat, offsetY: CGFloat) {
        switch muscle.group {
        case .chest, .shoulders, .arms, .back:
            // 上半身 → 上方向にズーム
            return (scale: 1.8, offsetY: 80)
        case .core:
            // 体幹 → 中央にズーム
            return (scale: 1.5, offsetY: 20)
        case .lowerBody:
            // 下半身 → 下方向にズーム
            return (scale: 1.8, offsetY: -80)
        }
    }

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [Color.mmBgPrimary, Color.mmBgCard],
                startPoint: .top,
                endPoint: .bottom
            )

            // 前面(60%) + 背面(40%) または逆 — メインサイドを大きく
            HStack(spacing: 0) {
                // メインサイド（対象筋肉がある側）— 60%
                GeometryReader { geo in
                    let rect = CGRect(origin: .zero, size: geo.size)
                    muscleMapLayer(entries: primaryEntries, in: rect, isPrimary: true)
                }
                .aspectRatio(0.55, contentMode: .fit)

                // サブサイド — 40%（スケールで縮小）
                GeometryReader { geo in
                    let rect = CGRect(origin: .zero, size: geo.size)
                    muscleMapLayer(entries: secondaryEntries, in: rect, isPrimary: false)
                        .opacity(0.5)
                }
                .aspectRatio(0.55, contentMode: .fit)
                .scaleEffect(0.85)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .scaleEffect(zoomConfig.scale)
            .offset(y: zoomConfig.offsetY)
        }
        .frame(height: 200)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 筋肉マップレイヤー

    @ViewBuilder
    private func muscleMapLayer(
        entries: [(muscle: Muscle, path: (CGRect) -> Path)],
        in rect: CGRect,
        isPrimary: Bool
    ) -> some View {
        ZStack {
            ForEach(entries, id: \.muscle) { entry in
                let isTarget = entry.muscle == muscle
                let isRelated = sameGroupMuscles.contains(entry.muscle)

                // 塗りつぶし
                entry.path(rect)
                    .fill(muscleColor(isTarget: isTarget, isRelated: isRelated, isPrimary: isPrimary))

                // ストローク
                entry.path(rect)
                    .stroke(
                        isTarget && isPrimary
                            ? highlightColor.opacity(0.8)
                            : Color.mmMuscleBorder.opacity(isTarget || isRelated ? 0.4 : 0.15),
                        lineWidth: isTarget && isPrimary ? 1.5 : 0.6
                    )
            }

            // グローエフェクト（メインサイドの対象筋肉のみ）
            if isPrimary {
                ForEach(entries, id: \.muscle) { entry in
                    if entry.muscle == muscle {
                        entry.path(rect)
                            .fill(highlightColor.opacity(0.3))
                            .blur(radius: 8)
                    }
                }
            }
        }
        .drawingGroup()
    }

    /// 筋肉ごとの塗り色を返す
    private func muscleColor(isTarget: Bool, isRelated: Bool, isPrimary: Bool) -> Color {
        if isTarget && isPrimary {
            return highlightColor
        } else if isTarget && !isPrimary {
            // サブサイドに同じ筋肉がある場合（前腕など両面に存在）
            return highlightColor.opacity(0.4)
        } else if isRelated {
            return highlightColor.opacity(0.15)
        } else {
            return Color.mmMuscleInactive.opacity(0.4)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Muscle3DView(muscle: .chestUpper, visualState: .recovering(progress: 0.3))
        Muscle3DView(muscle: .lats, visualState: .neglected(fast: false))
    }
    .padding()
    .background(Color.mmBgPrimary)
}

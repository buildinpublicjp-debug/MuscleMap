import SwiftUI

// MARK: - 凡例（3×2グリッド）

struct MuscleMapLegend: View {
    private var items: [(Color, String)] {
        [
            (.mmMuscleCoral, L10n.highLoad),
            (.mmMuscleAmber, L10n.earlyRecovery),
            (.mmMuscleYellow, L10n.midRecovery),
            (.mmMuscleLime, L10n.lateRecovery),
            (.mmMuscleBioGreen, L10n.almostRecovered),
            (.mmMuscleNeglected, L10n.notStimulated),
        ]
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.0)
                        .frame(width: 10, height: 10)
                    Text(item.1)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }
}

// MARK: - 初回コーチマーク

/// 筋肉マップの上に表示する矢印付きコーチマーク
/// WorkoutSet 0件のユーザーにのみ1回だけ表示
struct HomeCoachMarkView: View {
    let onDismiss: () -> Void

    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 4) {
            // テキストバッジ
            Text("まずワークアウトを記録しよう 👆")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.mmAccentPrimary)
                .clipShape(Capsule())

            // 下向き矢印
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
                .offset(y: arrowOffset)
        }
        .shadow(color: Color.mmAccentPrimary.opacity(0.4), radius: 8, y: 4)
        .padding(.top, 16)
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                arrowOffset = 6
            }
        }
    }
}

// MARK: - Strength Mapチラ見せバナー（非Proユーザー向け）

/// isPremium == false 時に回復マップ直下に表示するロック済みプレビュー
struct StrengthMapPreviewBanner: View {
    let onTap: () -> Void

    /// ダミースコア（プレビュー用の見本データ）
    private let demoScores: [String: Double] = [
        "chest_upper": 0.65, "chest_lower": 0.55,
        "lats": 0.70, "deltoid_anterior": 0.50,
        "deltoid_lateral": 0.40, "biceps": 0.60,
        "triceps": 0.55, "quadriceps": 0.75,
        "hamstrings": 0.45, "glutes": 0.50,
    ]

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // ヘッダー
                HStack(spacing: 8) {
                    Text("\u{1F4AA}")
                        .font(.title3)
                    Text(L10n.strengthMapBannerTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // ぼかし筋肉マップ プレビュー
                ZStack {
                    HStack(spacing: 8) {
                        demoMapView(muscles: MusclePathData.frontMuscles)
                        demoMapView(muscles: MusclePathData.backMuscles)
                    }
                    .padding(.horizontal, 32)
                    .blur(radius: 8)

                    // ロックオーバーレイ
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(Color.mmAccentPrimary)

                        HStack(spacing: 4) {
                            Text(L10n.unlockWithPro)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mmBgPrimary.opacity(0.85))
                    )
                }
                .frame(height: 160)
                .clipped()
                .padding(.bottom, 16)
            }
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    /// ダミーマップ描画（StrengthMapViewの表示パラメータを流用）
    private func demoMapView(muscles: [(muscle: Muscle, path: (CGRect) -> Path)]) -> some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let score = demoScores[entry.muscle.rawValue] ?? 0
                    let params = StrengthScoreCalculator.shared.displayParams(score: score)
                    entry.path(rect)
                        .fill(params.color.opacity(params.opacity))
                    entry.path(rect)
                        .stroke(
                            score > 0
                                ? params.color.opacity(0.4)
                                : Color.mmMuscleInactive,
                            lineWidth: params.strokeWidth * 0.7
                        )
                }
            }
        }
        .aspectRatio(0.5, contentMode: .fit)
    }
}

// MARK: - FlowLayout（タグ表示用）

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

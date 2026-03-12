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

// MARK: - 今日のおすすめインライン（筋肉マップ直下）

/// 筋肉マップの直下に常時表示する1行のおすすめカード
struct TodayRecommendationInline: View {
    let suggestedMenu: SuggestedMenu?
    let hasWorkoutHistory: Bool
    let onStart: () -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 10) {
                if hasWorkoutHistory, let menu = suggestedMenu {
                    // 回復済み筋肉のおすすめ表示
                    let groupNames = inlineGroupNames(menu: menu)
                    let reason = inlineReason(menu: menu)

                    Image(systemName: "lightbulb.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmAccentPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.todayRecommendation)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                        Text(groupNames)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                            .lineLimit(1)
                        if !reason.isEmpty {
                            Text(reason)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                                .lineLimit(1)
                        }
                    }
                } else {
                    // 履歴なし → 初回ユーザー向けメッセージ
                    Image(systemName: "target")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmAccentPrimary)

                    Text("筋肉マップを赤くしてみよう")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Spacer()

                Text(L10n.startWorkout)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmBgPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mmAccentPrimary)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    /// ペアリングされたグループ名を表示用に結合
    private func inlineGroupNames(menu: SuggestedMenu) -> String {
        let groups = MenuSuggestionService.pairedGroups(for: menu.primaryGroup)
        let names = groups.map { group in
            localization.currentLanguage == .japanese ? group.japaneseName : group.englishName
        }
        return names.joined(separator: "・")
    }

    /// 回復状態の簡潔な理由テキスト
    private func inlineReason(menu: SuggestedMenu) -> String {
        let groupName = localization.currentLanguage == .japanese
            ? menu.primaryGroup.japaneseName
            : menu.primaryGroup.englishName
        return localization.currentLanguage == .japanese
            ? "\(groupName)が回復済み"
            : "\(groupName) recovered"
    }
}

// MARK: - Strength Mapストリップバナー（非Proユーザー向け）

/// isPremium == false 時に回復マップ直下に表示するコンパクトな1行ストリップ
struct StrengthMapPreviewBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Strength Map")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text("90日後、変化を証明する")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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

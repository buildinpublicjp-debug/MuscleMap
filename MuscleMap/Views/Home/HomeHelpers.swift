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
                        .font(.caption)
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

/// 筋肉マップの直下に常時表示するおすすめカード
/// Pro: 種目リスト+重量+セット表示 / 無料: 部位名のみ+Proバッジ
struct TodayRecommendationInline: View {
    let suggestedMenu: SuggestedMenu?
    let recommendation: RecommendedWorkout?
    let hasWorkoutHistory: Bool
    let isPremium: Bool
    let onStart: () -> Void
    let onStartWithMenu: ([RecommendedExercise]) -> Void
    let onShowPaywall: () -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        if hasWorkoutHistory, let menu = suggestedMenu {
            if isPremium, let rec = recommendation, !rec.exercises.isEmpty {
                // Pro: 詳細メニュー提案
                proRecommendationCard(menu: menu, recommendation: rec)
            } else if !isPremium {
                // 無料: 部位名のみ + Proバッジ
                freeRecommendationCard(menu: menu)
            } else {
                // Pro だが提案なし → 従来の1行表示
                simpleRecommendationCard(menu: menu)
            }
        } else {
            // 履歴なし → 初回ユーザー向け
            firstTimeCard
        }
    }

    // MARK: - Pro版 詳細提案カード

    private func proRecommendationCard(menu: SuggestedMenu, recommendation: RecommendedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(spacing: 8) {
                Text(L10n.todayMenu)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Text(recommendation.muscleGroup)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmAccentPrimary)

                Spacer()
            }

            // 目標連動コピー
            if let goalCopy = goalLinkedCopy(muscleGroup: recommendation.muscleGroup) {
                Text(goalCopy)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)
            }

            // 種目リスト（最大3種目）
            ForEach(recommendation.exercises) { exercise in
                HStack(spacing: 10) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    if exercise.suggestedWeight > 0 {
                        Text(weightText(exercise))
                            .font(.system(size: 14).monospacedDigit())
                            .foregroundStyle(Color.mmTextSecondary)

                        if exercise.previousWeight != nil {
                            Text(L10n.weightChallenge(formatWeight(exercise.weightIncrease)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    } else {
                        Text("\(exercise.suggestedSets) × \(exercise.suggestedReps)")
                            .font(.system(size: 14).monospacedDigit())
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }

            // 「このメニューで始める」ボタン
            Button {
                HapticManager.lightTap()
                onStartWithMenu(recommendation.exercises)
            } label: {
                Text(L10n.startWithThisMenu)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 無料版カード（ブラー付き）

    private func freeRecommendationCard(menu: SuggestedMenu) -> some View {
        Button {
            HapticManager.lightTap()
            onShowPaywall()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack(spacing: 8) {
                    Text(L10n.todayMenu)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)

                    Text(inlineGroupNames(menu: menu))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentPrimary)

                    Spacer()
                }

                // 目標連動コピー
                if let goalCopy = goalLinkedCopy(muscleGroup: inlineGroupNames(menu: menu)) {
                    Text(goalCopy)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(1)
                }

                // ブラー付き種目プレビュー
                ZStack {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(menu.exercises.prefix(3), id: \.id) { ex in
                            let name = localization.currentLanguage == .japanese ? ex.definition.nameJA : ex.definition.nameEN
                            HStack {
                                Text(name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.mmTextPrimary)
                                Spacer()
                                Text("\(ex.suggestedSets) × \(ex.suggestedReps)")
                                    .font(.system(size: 14).monospacedDigit())
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                    }
                    .blur(radius: 6)

                    // ブラー上のCTA
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Proでメニューを見る")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - シンプルカード（Pro提案なし時のフォールバック）

    private func simpleRecommendationCard(menu: SuggestedMenu) -> some View {
        Button {
            HapticManager.lightTap()
            onStart()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.todayRecommendation)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(inlineGroupNames(menu: menu))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)
                    let reason = inlineReason(menu: menu)
                    if !reason.isEmpty {
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                            .lineLimit(1)
                    }
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

    // MARK: - 初回ユーザー向けカード

    private var firstTimeCard: some View {
        Button {
            HapticManager.lightTap()
            onStart()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "target")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                Text("筋肉マップを赤くしてみよう")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

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

    // MARK: - ヘルパー

    /// 目標連動コピー生成
    private func goalLinkedCopy(muscleGroup: String) -> String? {
        guard let goalRaw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: goalRaw) else { return nil }
        switch goal {
        case .getBig:
            return "\(goal.localizedName) → 今日は\(muscleGroup)でサイズアップ"
        case .dontGetDisrespected:
            return "威圧感・存在感 → 今日は\(muscleGroup)で幅を作る"
        case .martialArts:
            return "\(goal.localizedName) → 今日は\(muscleGroup)でパワー強化"
        case .sports:
            return "\(goal.localizedName) → 今日は\(muscleGroup)でパフォーマンスアップ"
        case .getAttractive:
            return "\(goal.localizedName) → 今日は\(muscleGroup)でシルエット強化"
        case .moveWell:
            return "\(goal.localizedName) → 今日は\(muscleGroup)で動ける体に"
        case .health:
            return "\(goal.localizedName) → 今日は\(muscleGroup)で基礎体力アップ"
        }
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

    /// 重量テキスト（例: "62.5kg × 10 × 3"）
    private func weightText(_ exercise: RecommendedExercise) -> String {
        let w = formatWeight(exercise.suggestedWeight)
        return "\(w)kg × \(exercise.suggestedReps) × \(exercise.suggestedSets)"
    }

    /// 重量フォーマット（小数点以下不要なら省略）
    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Strength Mapストリップバナー（非Proユーザー向け）

/// isPremium == false 時に回復マップ直下に表示するコンパクトな1行ストリップ
struct StrengthMapPreviewBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.lightTap()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Strength Map")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)

                        // Proバッジ
                        Text("Pro")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmBgPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmAccentPrimary)
                            .clipShape(Capsule())
                    }
                    Text("筋力レベルを見る")
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

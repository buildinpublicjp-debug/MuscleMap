import SwiftUI

// MARK: - オンボーディング用目標（7つのエモーショナルな選択肢・複数選択可）

@MainActor
enum OnboardingGoal: String, CaseIterable, Identifiable {
    case getBig = "get_big"
    case dontGetDisrespected = "dont_get_disrespected"
    case martialArts = "martial_arts"
    case sports = "sports"
    case getAttractive = "get_attractive"
    case moveWell = "move_well"
    case health = "health"

    nonisolated var id: String { rawValue }

    var emoji: String {
        switch self {
        case .getBig: return "💪"
        case .dontGetDisrespected: return "😎"
        case .martialArts: return "🥊"
        case .sports: return "⛳"
        case .getAttractive: return "❤️‍🔥"
        case .moveWell: return "🏃"
        case .health: return "❤️"
        }
    }

    var localizedName: String {
        switch self {
        case .getBig: return "デカくなりたい"
        case .dontGetDisrespected: return "舐められたくない"
        case .martialArts: return "格闘技・武道"
        case .sports: return "スポーツに活かす"
        case .getAttractive: return "モテたい"
        case .moveWell: return "動ける体がほしい"
        case .health: return "健康に長生き"
        }
    }

    var localizedDescription: String {
        switch self {
        case .getBig: return "Tシャツが似合う体に"
        case .dontGetDisrespected: return "存在感のある体で生きる"
        case .martialArts: return "パンチ力・タックル・組み力"
        case .sports: return "ゴルフ飛距離、スイング速度"
        case .getAttractive: return "自信のある体が全てを変える"
        case .moveWell: return "階段で息切れしない"
        case .health: return "家族のために"
        }
    }

    var iconColor: Color {
        switch self {
        case .getBig: return Color.mmOnboardingAccent
        case .dontGetDisrespected: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .martialArts: return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .sports: return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .getAttractive: return Color(red: 1.0, green: 0.3, blue: 0.5)
        case .moveWell: return Color(red: 0.5, green: 0.9, blue: 0.5)
        case .health: return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }
}

// MARK: - 目標選択画面（エモーショナル版 — 単一選択）

struct GoalSelectionPage: View {
    let onNext: () -> Void

    @State private var selectedGoal: OnboardingGoal?
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: OnboardingGoal.allCases.count)
    @State private var isProceeding = false
    @State private var headerAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // エモーショナルなヘッダー
            VStack(spacing: 8) {
                Text(L10n.goalSelectionHeadline)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.goalSelectionSub)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 24)

            // 目標カード（スクロール可能）
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                        EmotionalGoalCard(
                            goal: goal,
                            isSelected: selectedGoal == goal,
                            onTap: {
                                guard !isProceeding else { return }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedGoal = goal
                                }
                                HapticManager.lightTap()

                                AppState.shared.primaryOnboardingGoal = goal.rawValue
                            }
                        )
                        .opacity(cardAppearances.indices.contains(index) && cardAppearances[index] ? 1 : 0)
                        .offset(y: cardAppearances.indices.contains(index) && cardAppearances[index] ? 0 : 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // 次へボタン
            Button {
                guard !isProceeding, selectedGoal != nil else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedGoal != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedGoal != nil ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selectedGoal == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selectedGoal)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            // Staggered fade-in
            for index in OnboardingGoal.allCases.indices {
                withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.3)) {
                    cardAppearances[index] = true
                }
            }
        }
    }
}

// MARK: - エモーショナル目標カード（100pt高）

private struct EmotionalGoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 絵文字アイコン
                Text(goal.emoji)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(goal.iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.localizedName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text(goal.localizedDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }

                Spacer()

                // チェックマーク
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.mmOnboardingAccent)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingBg)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Color.mmOnboardingTextSub.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 80)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalSelectionPage(onNext: {})
    }
}

import SwiftUI

// MARK: - 目標設定画面（Fitbod風カードデザイン）

struct PersonalizationPage: View {
    let onGoalSelected: () -> Void

    @State private var selectedGoal: OnboardingGoal?
    @State private var cardAppearances: [Bool] = [false, false, false, false]
    @State private var isProceeding = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトルエリア
            VStack(spacing: 8) {
                Text(L10n.goalPageTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.goalPageSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            // 目標カード（縦並び）
            VStack(spacing: 12) {
                ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    LargeGoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedGoal = goal
                            }
                            HapticManager.lightTap()

                            // UserDefaultsに保存
                            UserDefaults.standard.set(goal.rawValue, forKey: "selectedTrainingGoal")
                        }
                    )
                    .opacity(cardAppearances[index] ? 1 : 0)
                    .offset(y: cardAppearances[index] ? 0 : 20)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding, selectedGoal != nil else { return }
                isProceeding = true
                HapticManager.lightTap()
                onGoalSelected()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedGoal != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedGoal != nil ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(selectedGoal == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selectedGoal != nil)
        }
        .onAppear {
            // Staggered fade-in animation
            for index in 0..<4 {
                withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.1 + 0.2)) {
                    cardAppearances[index] = true
                }
            }
        }
    }
}

// MARK: - オンボーディング用目標（4つの選択肢）

@MainActor
enum OnboardingGoal: String, CaseIterable, Identifiable {
    case muscleGrowth = "muscle_growth"
    case strength = "strength"
    case recovery = "recovery"
    case health = "health"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .muscleGrowth: return "figure.strengthtraining.traditional"
        case .strength: return "dumbbell.fill"
        case .recovery: return "bolt.heart.fill"
        case .health: return "heart.fill"
        }
    }

    var localizedName: String {
        switch self {
        case .muscleGrowth: return L10n.goalMuscleGrowth
        case .strength: return L10n.goalStrength
        case .recovery: return L10n.goalRecovery
        case .health: return L10n.goalHealthMaintenance
        }
    }

    var localizedDescription: String {
        switch self {
        case .muscleGrowth: return L10n.goalMuscleGrowthDesc
        case .strength: return L10n.goalStrengthDesc
        case .recovery: return L10n.goalRecoveryDesc
        case .health: return L10n.goalHealthMaintenanceDesc
        }
    }

    var iconColor: Color {
        switch self {
        case .muscleGrowth: return Color.mmOnboardingAccent
        case .strength: return Color(red: 1.0, green: 0.6, blue: 0.2) // オレンジ
        case .recovery: return Color(red: 0.4, green: 0.8, blue: 1.0) // ライトブルー
        case .health: return Color(red: 1.0, green: 0.4, blue: 0.5) // ピンク
        }
    }
}

// MARK: - 大型目標カード

private struct LargeGoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(goal.iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: goal.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(goal.iconColor)
                }

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.localizedName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text(goal.localizedDescription)
                        .font(.subheadline)
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
                }
            }
            .padding(16)
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
        PersonalizationPage(onGoalSelected: {})
    }
}

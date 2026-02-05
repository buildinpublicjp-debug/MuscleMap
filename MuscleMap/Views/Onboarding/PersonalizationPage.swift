import SwiftUI

// MARK: - Page 2: パーソナライゼーション（目標選択）

struct PersonalizationPage: View {
    let onGoalSelected: () -> Void

    @State private var selectedGoal: OnboardingGoal?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 質問
            Text(L10n.onboardingGoalQuestion)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .multilineTextAlignment(.center)

            // 選択肢カード
            VStack(spacing: 12) {
                ForEach(OnboardingGoal.allCases) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        onTap: {
                            guard selectedGoal == nil else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedGoal = goal
                            }
                            HapticManager.lightTap()

                            // UserDefaultsに保存
                            UserDefaults.standard.set(goal.rawValue, forKey: "selectedTrainingGoal")

                            // 1秒後に次のページへ
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                onGoalSelected()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - オンボーディング用目標（既存TrainingGoalと別定義）

@MainActor
enum OnboardingGoal: String, CaseIterable, Identifiable {
    case muscleGain = "muscle_gain"
    case fatLoss = "fat_loss"
    case stayHealthy = "stay_healthy"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .muscleGain: return "💪"
        case .fatLoss: return "🔥"
        case .stayHealthy: return "🏃"
        }
    }

    var localizedName: String {
        switch self {
        case .muscleGain: return L10n.goalMuscleGain
        case .fatLoss: return L10n.goalFatLoss
        case .stayHealthy: return L10n.goalHealth
        }
    }
}

// MARK: - 目標カード

private struct GoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(goal.emoji)
                    .font(.system(size: 28))

                Text(goal.localizedName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
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

import SwiftUI

// MARK: - トレーニング経験選択画面

struct TrainingHistoryPage: View {
    let onNext: () -> Void

    @State private var selectedExperience: TrainingExperience?
    @State private var cardAppearances: [Bool] = [false, false, false, false]
    @State private var isProceeding = false

    /// 選択肢の定義
    private let options: [(experience: TrainingExperience, emoji: String, title: String, subtitle: String)] = [
        (.beginner, "🌱", L10n.trainingExpBeginner, L10n.trainingExpBeginnerSub),
        (.halfYear, "💪", L10n.trainingExpHalfYear, L10n.trainingExpHalfYearSub),
        (.oneYearPlus, "🔥", L10n.trainingExpOneYearPlus, L10n.trainingExpOneYearPlusSub),
        (.veteran, "⚡", L10n.trainingExpVeteran, L10n.trainingExpVeteranSub),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトルエリア
            VStack(spacing: 8) {
                Text(L10n.trainingExpTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.trainingExpSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            // 経験カード（縦並び）
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.element.experience.id) { index, option in
                    ExperienceCard(
                        emoji: option.emoji,
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: selectedExperience == option.experience,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedExperience = option.experience
                            }
                            HapticManager.lightTap()

                            // UserProfileに保存
                            AppState.shared.userProfile.trainingExperience = option.experience
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
                guard !isProceeding, selectedExperience != nil else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedExperience != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedExperience != nil ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selectedExperience == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selectedExperience != nil)
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

// MARK: - 経験カード

private struct ExperienceCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 絵文字アイコン
                Text(emoji)
                    .font(.system(size: 32))
                    .frame(width: 56, height: 56)
                    .background(Color.mmOnboardingBg.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text(subtitle)
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
        TrainingHistoryPage(onNext: {})
    }
}

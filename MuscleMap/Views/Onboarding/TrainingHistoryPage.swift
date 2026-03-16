import SwiftUI

// MARK: - トレーニング経験選択画面（左バー方式・絵文字なし）

struct TrainingHistoryPage: View {
    let onNext: () -> Void

    @State private var selectedExperience: TrainingExperience?
    @State private var cardAppearances: [Bool] = [false, false, false, false]
    @State private var isProceeding = false

    /// 選択肢の定義（SF Symbols使用）
    private let options: [(experience: TrainingExperience, icon: String, title: String, subtitle: String)] = [
        (.beginner, "leaf.fill", L10n.trainingExpBeginner, L10n.trainingExpBeginnerSub),
        (.halfYear, "dumbbell.fill", L10n.trainingExpHalfYear, L10n.trainingExpHalfYearSub),
        (.oneYearPlus, "flame.fill", L10n.trainingExpOneYearPlus, L10n.trainingExpOneYearPlusSub),
        (.veteran, "bolt.fill", L10n.trainingExpVeteran, L10n.trainingExpVeteranSub),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトルエリア
            VStack(spacing: 8) {
                Text(L10n.trainingExpTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.trainingExpSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            // 経験カード（左バー方式）
            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.element.experience.id) { index, option in
                    ExperienceCard(
                        icon: option.icon,
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
                    .background(
                        Group {
                            if selectedExperience != nil {
                                LinearGradient(
                                    colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.mmOnboardingCard
                            }
                        }
                    )
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

// MARK: - 経験カード（左バー方式）

private struct ExperienceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 12)

                HStack(spacing: 12) {
                    // SFシンボルアイコン
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 36, height: 36)

                    // テキスト
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingTextMain)

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 60)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
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

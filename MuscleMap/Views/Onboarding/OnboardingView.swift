import SwiftUI

// MARK: - オンボーディング画面（5ページ）

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedGoal: TrainingGoal = .hypertrophy
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var nickname: String = ""
    var onComplete: () -> Void

    private let totalPages = 5

    private var introPages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "figure.stand",
                iconColors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                title: L10n.onboardingTitle1,
                subtitle: L10n.onboardingSubtitle1,
                detail: L10n.onboardingDetail1
            ),
            OnboardingPage(
                icon: "sparkles",
                iconColors: [Color.mmMuscleAmber, Color.mmMuscleCoral],
                title: L10n.onboardingTitle2,
                subtitle: L10n.onboardingSubtitle2,
                detail: L10n.onboardingDetail2
            ),
            OnboardingPage(
                icon: "chart.bar.fill",
                iconColors: [Color.mmAccentSecondary, Color.mmAccentPrimary],
                title: L10n.onboardingTitle3,
                subtitle: L10n.onboardingSubtitle3,
                detail: L10n.onboardingDetail3
            ),
        ]
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // ページコンテンツ
                TabView(selection: $currentPage) {
                    // イントロ3ページ
                    ForEach(Array(introPages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }

                    // ゴール選択
                    GoalSelectionPage(selectedGoal: $selectedGoal)
                        .tag(3)

                    // 経験レベル選択
                    ExperienceLevelPage(
                        nickname: $nickname,
                        selectedLevel: $selectedLevel
                    )
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // ページインジケーター
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // ボタン
                Button {
                    HapticManager.lightTap()
                    if currentPage < totalPages - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        saveProfileAndComplete()
                    }
                } label: {
                    Text(buttonLabel)
                        .font(.headline)
                        .foregroundStyle(Color.mmBgPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.mmAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                // スキップ（イントロのみ）
                if currentPage < 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage = 3
                        }
                    } label: {
                        Text(L10n.skip)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.top, 8)
                }

                Spacer().frame(height: 24)
            }
        }
    }

    private var buttonLabel: String {
        switch currentPage {
        case 0...3: return L10n.next
        default: return L10n.start
        }
    }

    private func saveProfileAndComplete() {
        var profile = UserProfile(
            nickname: nickname,
            trainingGoal: selectedGoal,
            experienceLevel: selectedLevel
        )
        profile.save()
        AppState.shared.userProfile = profile
        onComplete()
    }
}

// MARK: - ページデータ

private struct OnboardingPage {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let detail: String
}

// MARK: - イントロページビュー

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColors.first?.opacity(0.1) ?? Color.mmAccentPrimary.opacity(0.1))
                    .frame(width: 96, height: 96)

                Image(systemName: page.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(page.iconColors.first ?? Color.mmAccentPrimary)
            }

            Text(page.title)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.mmAccentPrimary)
                .multilineTextAlignment(.center)

            Text(page.detail)
                .font(.footnote)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - ゴール選択ページ

private struct GoalSelectionPage: View {
    @Binding var selectedGoal: TrainingGoal

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(L10n.trainingGoalQuestion)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text(L10n.goalSuggestionHint)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)

            VStack(spacing: 8) {
                ForEach(TrainingGoal.allCases) { goal in
                    GoalOptionRow(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        HapticManager.lightTap()
                        selectedGoal = goal
                    }
                }
            }
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.2), value: selectedGoal)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - ゴール選択行

private struct GoalOptionRow: View {
    let goal: TrainingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.mmAccentPrimary : Color.mmTextSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.localizedName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(goal.descriptionText)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.mmAccentPrimary.opacity(0.08) : Color.mmBgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.mmAccentPrimary : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
    }
}

// MARK: - 経験レベルページ

private struct ExperienceLevelPage: View {
    @Binding var nickname: String
    @Binding var selectedLevel: ExperienceLevel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(L10n.aboutYouQuestion)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            // ニックネーム入力
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.nicknameOptional)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                TextField("", text: $nickname, prompt: Text(L10n.nickname).foregroundStyle(Color.mmTextSecondary.opacity(0.5)))
                    .font(.body)
                    .foregroundStyle(Color.mmTextPrimary)
                    .padding(16)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            // 経験レベル
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.trainingExperience)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    ForEach(ExperienceLevel.allCases) { level in
                        LevelOptionRow(
                            level: level,
                            isSelected: selectedLevel == level
                        ) {
                            HapticManager.lightTap()
                            selectedLevel = level
                        }
                    }
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: selectedLevel)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - 経験レベル選択行

private struct LevelOptionRow: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.mmAccentPrimary : Color.mmTextSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.localizedName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(level.descriptionText)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.mmAccentPrimary.opacity(0.08) : Color.mmBgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.mmAccentPrimary : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

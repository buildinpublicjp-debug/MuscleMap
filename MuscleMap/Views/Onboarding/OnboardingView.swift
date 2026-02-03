import SwiftUI

// MARK: - オンボーディング画面（5ページ）

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedGoal: TrainingGoal = .hypertrophy
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var nickname: String = ""
    var onComplete: () -> Void

    private let totalPages = 5

    private let introPages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.stand",
            iconColors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
            title: "筋肉の状態が見える",
            subtitle: "21の筋肉の回復状態を\nリアルタイムで可視化",
            detail: "トレーニング後の筋肉は色で回復度を表示。\n赤→緑へのグラデーションで一目瞭然。"
        ),
        OnboardingPage(
            icon: "sparkles",
            iconColors: [Color.mmMuscleAmber, Color.mmMuscleCoral],
            title: "迷わないメニュー提案",
            subtitle: "回復データから\n今日のベストメニューを自動提案",
            detail: "ジムで開いた瞬間にスタートできる。\n未刺激の部位も見逃しません。"
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColors: [Color.mmAccentSecondary, Color.mmAccentPrimary],
            title: "成長を記録・分析",
            subtitle: "80種目のEMGベース刺激マッピングで\n科学的なトレーニング管理",
            detail: "セット数・ボリューム・部位カバー率を\nチャートで確認。"
        ),
    ]

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
                        Circle()
                            .fill(index == currentPage ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // ボタン
                Button {
                    HapticManager.lightTap()
                    if currentPage < totalPages - 1 {
                        withAnimation {
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
                        .frame(height: 56)
                        .background(Color.mmAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)

                // スキップ（イントロのみ）
                if currentPage < 3 {
                    Button {
                        withAnimation {
                            currentPage = 3
                        }
                    } label: {
                        Text("スキップ")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.top, 12)
                }

                Spacer().frame(height: 32)
            }
        }
    }

    private var buttonLabel: String {
        switch currentPage {
        case 0...2: return String(localized: "次へ")
        case 3: return String(localized: "次へ")
        default: return String(localized: "始める")
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
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.15)
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(page.title)
                .font(.title.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(Color.mmAccentPrimary)
                .multilineTextAlignment(.center)

            Text(page.detail)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

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
        VStack(spacing: 24) {
            Spacer()

            Text("トレーニングの目標は？")
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text("あなたに合ったメニューを提案します")
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)

            VStack(spacing: 12) {
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mmBgCard)
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
        VStack(spacing: 24) {
            Spacer()

            Text("あなたについて教えてください")
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            // ニックネーム入力
            VStack(alignment: .leading, spacing: 8) {
                Text("ニックネーム（任意）")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                TextField("", text: $nickname, prompt: Text("ニックネーム").foregroundStyle(Color.mmTextSecondary.opacity(0.5)))
                    .font(.body)
                    .foregroundStyle(Color.mmTextPrimary)
                    .padding()
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            // 経験レベル
            VStack(alignment: .leading, spacing: 8) {
                Text("トレーニング経験")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mmBgCard)
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

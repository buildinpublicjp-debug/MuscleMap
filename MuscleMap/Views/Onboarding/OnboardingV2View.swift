import SwiftUI

// MARK: - オンボーディングV2（最大7ページ横スワイプ: 目標 → トレ歴 → [PR入力] → ジム確認 → 分岐 → 体重 → CTA）

struct OnboardingV2View: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    /// PR入力ページを表示するか（トレ歴選択後に動的判定）
    private var showPRInput: Bool {
        AppState.shared.userProfile.trainingExperience.shouldShowPRInput
    }

    /// トレ歴ページの「次へ」遷移先を決定
    private func afterTrainingHistory() {
        if showPRInput {
            currentPage = 2 // PR入力ページへ
        } else {
            currentPage = 3 // GymCheckPageへスキップ
        }
    }

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                // ページ0: 目標選択（エモーショナル版）
                GoalSelectionPage {
                    currentPage = 1
                }
                .tag(0)

                // ページ1: トレーニング歴
                TrainingHistoryPage {
                    afterTrainingHistory()
                }
                .tag(1)

                // ページ2: PR入力（経験者のみ: oneYearPlus / veteran）
                PRInputPage {
                    currentPage = 3
                }
                .tag(2)

                // ページ3: 「今ジムにいる？」
                GymCheckPage {
                    currentPage = 4
                }
                .tag(3)

                // ページ4: 分岐先（ジム→ガイド付きワークアウト / 家→直近トレーニング入力）
                OnboardingBranchPage {
                    currentPage = 5
                }
                .tag(4)

                // ページ5: 体重・ニックネーム入力
                WeightInputPage {
                    currentPage = 6
                }
                .tag(5)

                // ページ6: 機能紹介 & 開始（パーソナライズ版）
                CallToActionPage(onComplete: onComplete)
                    .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            // ページインジケーター（PR入力スキップ時はページ2を除外）
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(indicatorPages, id: \.self) { page in
                        Capsule()
                            .fill(page == currentPage ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub.opacity(0.3))
                            .frame(width: page == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    /// インジケーターに表示するページ番号（PR入力スキップ時はページ2を除外）
    private var indicatorPages: [Int] {
        if showPRInput {
            return Array(0..<7)
        } else {
            return [0, 1, 3, 4, 5, 6]
        }
    }
}

// MARK: - オンボーディング用カラーパレット

extension Color {
    static let mmOnboardingAccent = Color(hex: "#00E676")
    static let mmOnboardingAccentDark = Color(hex: "#00B35F")
    static let mmOnboardingBg = Color(hex: "#1A1A1E")
    static let mmOnboardingCard = Color(hex: "#2C2C2E")
    static let mmOnboardingTextMain = Color.white.opacity(0.9)
    static let mmOnboardingTextSub = Color(hex: "#8E8E93")
}

#Preview {
    OnboardingV2View(onComplete: {})
}

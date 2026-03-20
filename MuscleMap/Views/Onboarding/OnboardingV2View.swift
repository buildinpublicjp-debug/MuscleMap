import SwiftUI

// MARK: - オンボーディングV2（最大8ページ横スワイプ: 目標 → 頻度 → 場所 → プロフィール → [PR入力] → 目標×筋肉 → ルーティンビルダー → ルーティン完了）

struct OnboardingV2View: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    /// PR入力ページを表示するか（トレ歴選択後に動的判定）
    private var showPRInput: Bool {
        AppState.shared.userProfile.trainingExperience.shouldShowPRInput
    }

    /// プロフィールページの「次へ」遷移先を決定
    private func afterProfileInput() {
        if showPRInput {
            currentPage = 4 // PR入力ページへ
        } else {
            currentPage = 5 // GoalMusclePreviewPageへスキップ
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

                // ページ1: 週間トレーニング頻度
                FrequencySelectionPage { frequency in
                    AppState.shared.userProfile.weeklyFrequency = frequency.rawValue
                    currentPage = 2
                }
                .tag(1)

                // ページ2: トレーニング場所
                LocationSelectionPage { location in
                    AppState.shared.userProfile.trainingLocation = location.rawValue
                    currentPage = 3
                }
                .tag(2)

                // ページ3: プロフィール入力（トレ歴 + 体重 + ニックネーム統合）
                ProfileInputPage {
                    afterProfileInput()
                }
                .tag(3)

                // ページ4: PR入力（経験者のみ: oneYearPlus / veteran）
                PRInputPage {
                    currentPage = 5
                }
                .tag(4)

                // ページ5: 目標×筋肉ビジュアル（★ クライマックス）
                // goalPriorityMuscles は GoalSelectionPage で全目標の合算を保存済み
                GoalMusclePreviewPage {
                    currentPage = 6
                }
                .tag(5)

                // ページ6: ルーティンビルダー（サンクコスト最大化後）
                RoutineBuilderPage {
                    currentPage = 7
                }
                .tag(6)

                // ページ7: ルーティン完了 + ハードペイウォール
                RoutineCompletionPage(onComplete: onComplete)
                    .tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            // ページインジケーター（PR入力スキップ時はページ4を除外）
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

    /// インジケーターに表示するページ番号（PR入力スキップ時はページ4を除外）
    private var indicatorPages: [Int] {
        if showPRInput {
            return Array(0..<8)
        } else {
            return [0, 1, 2, 3, 5, 6, 7]
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

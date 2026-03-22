import SwiftUI

// MARK: - オンボーディングV2（最大9ページ: 目標 → 頻度 → 場所 → プロフィール → [PR] → 生成演出 → メニュー → 通知 → 完了）

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
            currentPage = 5 // MenuGeneratingPageへスキップ
        }
    }

    /// メニュー生成ページかどうか（戻るボタン・インジケーター非表示用）
    private var isGeneratingPage: Bool {
        currentPage == 5
    }

    /// 遷移方向を追跡（アニメーション方向制御用）
    @State private var navigatingForward = true

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            // スワイプ無効化: TabViewの代わりにZStack + カスタム遷移
            ZStack {
                pageView(for: currentPage)
                    .id(currentPage)
                    .transition(.asymmetric(
                        insertion: .move(edge: navigatingForward ? .trailing : .leading),
                        removal: .move(edge: navigatingForward ? .leading : .trailing)
                    ))
            }
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // 戻るボタン（Page 1以降、生成ページでは非表示）
            if currentPage > 0 && !isGeneratingPage {
                VStack {
                    HStack {
                        Button {
                            navigatingForward = false
                            withAnimation(.easeInOut(duration: 0.3)) {
                                goBack()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(L10n.back)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(Color.mmOnboardingTextSub)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 8)
                        Spacer()
                    }
                    Spacer()
                }
            }

            // ページインジケーター（PR入力スキップ時はページ4を除外、生成ページでは非表示）
            if !isGeneratingPage {
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
    }

    // MARK: - ページ表示

    @ViewBuilder
    private func pageView(for page: Int) -> some View {
        switch page {
        case 0:
            GoalSelectionPage(currentPage: currentPage) {
                navigatingForward = true
                currentPage = 1
            }
        case 1:
            FrequencySelectionPage(currentPage: currentPage) { frequency in
                AppState.shared.userProfile.weeklyFrequency = frequency.rawValue
                navigatingForward = true
                currentPage = 2
            }
        case 2:
            LocationSelectionPage(currentPage: currentPage) { location in
                AppState.shared.userProfile.trainingLocation = location.rawValue
                navigatingForward = true
                currentPage = 3
            }
        case 3:
            ProfileInputPage {
                navigatingForward = true
                afterProfileInput()
            }
        case 4:
            PRInputPage {
                navigatingForward = true
                currentPage = 5
            }
        case 5:
            MenuGeneratingPage {
                navigatingForward = true
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage = 6
                }
            }
        case 6:
            RoutineBuilderPage {
                navigatingForward = true
                currentPage = 7
            }
        case 7:
            NotificationPermissionView {
                navigatingForward = true
                currentPage = 8
            }
        case 8:
            RoutineCompletionPage(onComplete: onComplete)
        default:
            EmptyView()
        }
    }

    // MARK: - 戻るナビゲーション

    /// 戻るボタンのページ遷移（生成ページをスキップ、PR入力スキップ時はページ4も飛ばす）
    private func goBack() {
        guard currentPage > 0 else { return }
        if currentPage == 6 {
            // RoutineBuilder(6)から戻る → 生成ページ(5)をスキップ
            if showPRInput {
                currentPage = 4 // PR入力へ
            } else {
                currentPage = 3 // プロフィールへ
            }
        } else if currentPage == 5 {
            // 生成ページ(5)には戻るボタンがないが念のため
            if showPRInput {
                currentPage = 4
            } else {
                currentPage = 3
            }
        } else {
            currentPage -= 1
        }
    }

    /// インジケーターに表示するページ番号（生成ページ5を除外、PR入力スキップ時はページ4も除外）
    private var indicatorPages: [Int] {
        if showPRInput {
            return [0, 1, 2, 3, 4, 6, 7, 8]
        } else {
            return [0, 1, 2, 3, 6, 7, 8]
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

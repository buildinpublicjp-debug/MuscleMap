import SwiftUI

// MARK: - オンボーディングV2（4ページ横スワイプ: 体験 → 目標 → 体重 → 機能）

struct OnboardingV2View: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                // ページ1: 体験（筋肉マップをタップして体験）
                InteractiveDemoPage {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 1
                    }
                }
                .tag(0)

                // ページ2: 目標選択
                PersonalizationPage {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 2
                    }
                }
                .tag(1)

                // ページ3: 体重・ニックネーム入力
                WeightInputPage {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 3
                    }
                }
                .tag(2)

                // ページ4: 機能紹介 & 開始
                CallToActionPage(onComplete: onComplete)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // ページインジケーター
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub.opacity(0.3))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.bottom, 16)
            }
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

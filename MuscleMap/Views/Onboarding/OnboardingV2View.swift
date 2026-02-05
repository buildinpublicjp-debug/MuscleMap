import SwiftUI

// MARK: - オンボーディングV2（4ページ横スワイプ）

struct OnboardingV2View: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ValuePropositionPage()
                    .tag(0)

                PersonalizationPage {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage = 2
                    }
                }
                .tag(1)

                InteractiveDemoPage()
                    .tag(2)

                CallToActionPage(onComplete: onComplete)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

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
    static let mmOnboardingAccent = Color(red: 0, green: 0.902, blue: 0.463) // #00E676
    static let mmOnboardingAccentDark = Color(red: 0, green: 0.702, blue: 0.373) // #00B35F
    static let mmOnboardingBg = Color(red: 0.102, green: 0.102, blue: 0.118) // #1A1A1E
    static let mmOnboardingCard = Color(red: 0.173, green: 0.173, blue: 0.180) // #2C2C2E
    static let mmOnboardingTextMain = Color.white.opacity(0.9)
    static let mmOnboardingTextSub = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
}

#Preview {
    OnboardingV2View(onComplete: {})
}

import SwiftUI

// MARK: - オンボーディング画面（スプラッシュ → V2フロー）

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var splashComplete = false

    var body: some View {
        ZStack {
            if !splashComplete {
                // スプラッシュ画面（言語は自動検出済み）
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        splashComplete = true
                    }
                }
                .transition(.opacity)
            } else {
                // V2オンボーディングフロー（3ページ: 体験 → 目標 → 機能）
                OnboardingV2View(onComplete: onComplete)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

import SwiftUI

// MARK: - オンボーディング画面（スプラッシュ → V2フロー）

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPhase: OnboardingPhase = .splash

    private enum OnboardingPhase {
        case splash
        case mainFlow
    }

    var body: some View {
        ZStack {
            switch currentPhase {
            case .splash:
                // スプラッシュ画面（言語は自動検出済み）
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPhase = .mainFlow
                    }
                }
                .transition(.opacity)

            case .mainFlow:
                // V2オンボーディングフロー（通知許可もV2内に含む）
                OnboardingV2View {
                    onComplete()
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

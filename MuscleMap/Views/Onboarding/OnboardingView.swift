import SwiftUI

// MARK: - オンボーディング画面（スプラッシュ → V2フロー → 通知許可）

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPhase: OnboardingPhase = .splash

    private enum OnboardingPhase {
        case splash
        case mainFlow
        case notification
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
                // V2オンボーディングフロー（3ページ: 体験 → 目標 → 機能）
                OnboardingV2View {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPhase = .notification
                    }
                }
                .transition(.opacity)

            case .notification:
                // 通知許可画面
                NotificationPermissionView {
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

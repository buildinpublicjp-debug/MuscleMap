import SwiftUI

// MARK: - Page 1: バリュープロポジション

struct ValuePropositionPage: View {
    @State private var textVisible = false
    @State private var bgPulse = false

    /// デモ用の筋肉状態
    private var demoStates: [Muscle: MuscleVisualState] {
        [
            .chestUpper: .recovering(progress: 0.2),
            .chestLower: .recovering(progress: 0.15),
            .deltoidAnterior: .recovering(progress: 0.35),
            .deltoidLateral: .recovering(progress: 0.4),
            .biceps: .recovering(progress: 0.5),
            .triceps: .recovering(progress: 0.55),
            .lats: .recovering(progress: 0.65),
            .quadriceps: .recovering(progress: 0.3),
            .rectusAbdominis: .recovering(progress: 0.45),
        ]
    }

    var body: some View {
        ZStack {
            // 背景: ぼかし筋肉マップ + パルス
            MuscleMapView(muscleStates: demoStates)
                .scaleEffect(bgPulse ? 1.05 : 1.0)
                .opacity(0.3)
                .blur(radius: 12)
                .ignoresSafeArea()

            // 中央テキスト
            VStack(spacing: 16) {
                Spacer()

                Text(L10n.onboardingV2Title1)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.onboardingV2Subtitle1)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .opacity(textVisible ? 1 : 0)
            .scaleEffect(textVisible ? 1.0 : 0.9)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                textVisible = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bgPulse = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        ValuePropositionPage()
    }
}

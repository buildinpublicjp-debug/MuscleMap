import SwiftUI

// MARK: - Page 3: インタラクティブデモ

struct InteractiveDemoPage: View {
    @State private var tappedMuscles: Set<Muscle> = []
    @State private var showTitle = false

    /// タップした筋肉を光らせる状態マップ
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if tappedMuscles.contains(muscle) {
                states[muscle] = .recovering(progress: 0.15)
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)

            // タイトル（初回タップ後にフェードイン）
            Text(L10n.onboardingDemoTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .multilineTextAlignment(.center)
                .opacity(showTitle ? 1 : 0)
                .frame(height: 30)
                .padding(.horizontal, 24)

            // インタラクティブ筋肉マップ
            MuscleMapView(
                muscleStates: muscleStates,
                onMuscleTapped: { muscle in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if tappedMuscles.contains(muscle) {
                            tappedMuscles.remove(muscle)
                        } else {
                            tappedMuscles.insert(muscle)
                        }
                    }

                    // 初回タップ時にタイトル表示
                    if !showTitle {
                        withAnimation(.easeIn(duration: 0.8)) {
                            showTitle = true
                        }
                    }

                    HapticManager.lightTap()
                }
            )
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .padding(.horizontal, 16)

            // ヒントテキスト
            Text(L10n.onboardingDemoHint)
                .font(.caption)
                .foregroundStyle(Color.mmOnboardingTextSub)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        InteractiveDemoPage()
    }
}

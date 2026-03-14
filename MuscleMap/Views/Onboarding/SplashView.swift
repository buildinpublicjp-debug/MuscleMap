import SwiftUI

// MARK: - スプラッシュ画面（筋肉マップがヒーロー）

struct SplashView: View {
    let onComplete: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var taglineOpacity: Double = 0
    @State private var muscleMapOpacity: Double = 0
    @State private var muscleMapScale: Double = 0.9
    @State private var showContinue: Bool = false

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // アプリ名（コンパクト）
                Text("MuscleMap")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Spacer().frame(height: 24)

                // ヒーロー: 筋肉マップ（大きく表示）
                SplashMuscleMapHero()
                    .frame(height: 360)
                    .opacity(muscleMapOpacity)
                    .scaleEffect(muscleMapScale)

                Spacer().frame(height: 24)

                // タグライン（エモーショナル）
                VStack(spacing: 8) {
                    Text("鍛えた筋肉が光る。")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text("あなたの体の変化を、目で見る。")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .opacity(taglineOpacity)
                .multilineTextAlignment(.center)

                Spacer()

                // 続行ボタン
                if showContinue {
                    Button {
                        HapticManager.lightTap()
                        onComplete()
                    } label: {
                        Text("始める")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            runSplashAnimation()
        }
    }

    private func runSplashAnimation() {
        // タイトル（0-0.6秒）
        withAnimation(.easeOut(duration: 0.6)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        // 筋肉マップ（0.3-1.0秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                muscleMapOpacity = 1.0
                muscleMapScale = 1.0
            }
        }

        // タグライン（0.8秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                taglineOpacity = 1.0
            }
        }

        // 続行ボタン（1.5秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showContinue = true
            }
        }
    }
}

// MARK: - スプラッシュ用ヒーロー筋肉マップ

private struct SplashMuscleMapHero: View {
    @State private var highlightedMuscles: Set<Muscle> = []

    private let frontWave: [Muscle] = [
        .chestUpper, .chestLower, .deltoidAnterior, .biceps, .rectusAbdominis, .quadriceps
    ]
    private let backWave: [Muscle] = [
        .lats, .trapsUpper, .trapsMiddleLower, .glutes, .hamstrings, .triceps
    ]

    var body: some View {
        HStack(spacing: 16) {
            // フロント
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    ForEach(MusclePathData.frontMuscles, id: \.muscle) { entry in
                        let isHighlighted = highlightedMuscles.contains(entry.muscle)
                        entry.path(rect)
                            .fill(isHighlighted
                                ? Color.mmOnboardingAccent.opacity(0.85)
                                : Color.mmOnboardingCard.opacity(0.4))
                            .overlay {
                                entry.path(rect)
                                    .stroke(
                                        isHighlighted
                                            ? Color.mmOnboardingAccent.opacity(0.9)
                                            : Color.mmOnboardingTextSub.opacity(0.2),
                                        lineWidth: isHighlighted ? 1.5 : 0.5
                                    )
                            }
                            .shadow(
                                color: isHighlighted ? Color.mmOnboardingAccent.opacity(0.6) : .clear,
                                radius: isHighlighted ? 8 : 0
                            )
                            .animation(.easeInOut(duration: 0.5), value: isHighlighted)
                    }
                }
            }
            .aspectRatio(0.55, contentMode: .fit)

            // バック
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    ForEach(MusclePathData.backMuscles, id: \.muscle) { entry in
                        let isHighlighted = highlightedMuscles.contains(entry.muscle)
                        entry.path(rect)
                            .fill(isHighlighted
                                ? Color.mmOnboardingAccent.opacity(0.85)
                                : Color.mmOnboardingCard.opacity(0.4))
                            .overlay {
                                entry.path(rect)
                                    .stroke(
                                        isHighlighted
                                            ? Color.mmOnboardingAccent.opacity(0.9)
                                            : Color.mmOnboardingTextSub.opacity(0.2),
                                        lineWidth: isHighlighted ? 1.5 : 0.5
                                    )
                            }
                            .shadow(
                                color: isHighlighted ? Color.mmOnboardingAccent.opacity(0.6) : .clear,
                                radius: isHighlighted ? 8 : 0
                            )
                            .animation(.easeInOut(duration: 0.5), value: isHighlighted)
                    }
                }
            }
            .aspectRatio(0.55, contentMode: .fit)
        }
        .padding(.horizontal, 40)
        .onAppear {
            runMuscleWave()
        }
    }

    private func runMuscleWave() {
        // 前面を順に点灯
        for (index, muscle) in frontWave.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15 + 0.5) {
                _ = highlightedMuscles.insert(muscle)
            }
        }
        // 背面を順に点灯
        for (index, muscle) in backWave.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15 + 1.2) {
                _ = highlightedMuscles.insert(muscle)
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}

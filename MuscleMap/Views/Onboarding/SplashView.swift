import SwiftUI

// MARK: - プレミアムスプラッシュ画面

struct SplashView: View {
    let onComplete: () -> Void

    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.8
    @State private var taglineOpacity: Double = 0
    @State private var muscleMapOpacity: Double = 0
    @State private var muscleGlow: Bool = false
    @State private var showContinue: Bool = false

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ロゴエリア
                VStack(spacing: 16) {
                    // プレミアムアイコン
                    ZStack {
                        // 外側のグロー
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.mmOnboardingAccent.opacity(muscleGlow ? 0.4 : 0.2),
                                        Color.mmOnboardingAccent.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(muscleGlow ? 1.1 : 1.0)

                        // 内側の円
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.mmOnboardingAccent.opacity(0.15),
                                        Color.mmOnboardingAccentDark.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)

                        // アイコン
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // アプリ名
                    Text("MuscleMap")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                Spacer().frame(height: 40)

                // ミニ筋肉マップ（デモ）
                SplashMuscleMapDemo()
                    .frame(height: 200)
                    .opacity(muscleMapOpacity)

                Spacer().frame(height: 32)

                // タグライン
                Text(L10n.splashTagline)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)
                    .opacity(taglineOpacity)

                Spacer()

                // 続行ボタン
                if showContinue {
                    Button {
                        HapticManager.lightTap()
                        onComplete()
                    } label: {
                        Text(L10n.splashContinue)
                            .font(.headline)
                            .foregroundStyle(Color.mmOnboardingBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.mmOnboardingAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
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
        // ロゴフェードイン（0-0.8秒）
        withAnimation(.easeOut(duration: 0.8)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }

        // 筋肉マップ表示（0.5-1.3秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                muscleMapOpacity = 1.0
            }
        }

        // グローアニメーション開始（1.0秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                muscleGlow = true
            }
        }

        // タグライン表示（1.5秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                taglineOpacity = 1.0
            }
        }

        // 続行ボタン表示（2.5秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showContinue = true
            }
        }
    }
}

// MARK: - スプラッシュ用ミニ筋肉マップデモ

private struct SplashMuscleMapDemo: View {
    @State private var highlightedMuscles: Set<Muscle> = []
    @State private var animationPhase = 0

    private let demoMuscles: [Muscle] = [
        .chestUpper, .chestLower, .deltoidAnterior, .biceps, .rectusAbdominis, .quadriceps
    ]

    var body: some View {
        HStack(spacing: 24) {
            // フロント
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    ForEach(MusclePathData.frontMuscles, id: \.muscle) { entry in
                        let isHighlighted = highlightedMuscles.contains(entry.muscle)
                        entry.path(rect)
                            .fill(isHighlighted ? Color.mmOnboardingAccent.opacity(0.8) : Color.mmOnboardingCard.opacity(0.5))
                            .overlay {
                                entry.path(rect)
                                    .stroke(
                                        isHighlighted ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub.opacity(0.3),
                                        lineWidth: isHighlighted ? 1.2 : 0.5
                                    )
                            }
                            .shadow(
                                color: isHighlighted ? Color.mmOnboardingAccent.opacity(0.5) : .clear,
                                radius: isHighlighted ? 6 : 0
                            )
                            .animation(.easeInOut(duration: 0.4), value: isHighlighted)
                    }
                }
            }
            .aspectRatio(0.5, contentMode: .fit)

            // バック
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    ForEach(MusclePathData.backMuscles, id: \.muscle) { entry in
                        let isHighlighted = highlightedMuscles.contains(entry.muscle)
                        entry.path(rect)
                            .fill(isHighlighted ? Color.mmOnboardingAccent.opacity(0.8) : Color.mmOnboardingCard.opacity(0.5))
                            .overlay {
                                entry.path(rect)
                                    .stroke(
                                        isHighlighted ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub.opacity(0.3),
                                        lineWidth: isHighlighted ? 1.2 : 0.5
                                    )
                            }
                            .shadow(
                                color: isHighlighted ? Color.mmOnboardingAccent.opacity(0.5) : .clear,
                                radius: isHighlighted ? 6 : 0
                            )
                            .animation(.easeInOut(duration: 0.4), value: isHighlighted)
                    }
                }
            }
            .aspectRatio(0.5, contentMode: .fit)
        }
        .onAppear {
            runMuscleAnimation()
        }
    }

    private func runMuscleAnimation() {
        // 順番に筋肉を点灯
        for (index, muscle) in demoMuscles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3 + 0.5) {
                withAnimation {
                    _ = highlightedMuscles.insert(muscle)
                }
            }
        }

        // 背面の筋肉も点灯
        let backMuscles: [Muscle] = [.lats, .trapsUpper, .glutes, .hamstrings]
        for (index, muscle) in backMuscles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3 + 2.0) {
                withAnimation {
                    _ = highlightedMuscles.insert(muscle)
                }
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}

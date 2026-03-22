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
    @State private var glowOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // 背景: 上部が少し明るいグラデーション
            LinearGradient(
                colors: [
                    Color(hex: "#222226"),
                    Color.mmOnboardingBg,
                    Color.mmOnboardingBg
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // アプリ名
                Text("MuscleMap")
                    .font(.system(size: 36, weight: .heavy))
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

                // ヒーロー: 筋肉マップ（全筋肉ウェーブアニメーション）
                SplashMuscleMapHero()
                    .frame(height: 360)
                    .opacity(muscleMapOpacity)
                    .scaleEffect(muscleMapScale)

                Spacer().frame(height: 24)

                // タグライン（エモーショナル、大きめ）
                VStack(spacing: 8) {
                    Text(L10n.splashHeadline)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text(L10n.splashSubheadline)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .opacity(taglineOpacity)
                .multilineTextAlignment(.center)

                Spacer()

                // 続行ボタン（グロー効果付き）
                if showContinue {
                    Button {
                        HapticManager.mediumTap()
                        onComplete()
                    } label: {
                        Text(L10n.getStarted)
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
                            .shadow(
                                color: Color.mmOnboardingAccent.opacity(glowOpacity),
                                radius: 16, x: 0, y: 4
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .onAppear {
                        // 脈動グロー
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            glowOpacity = 0.8
                        }
                    }
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

// MARK: - スプラッシュ用ヒーロー筋肉マップ（全筋肉ウェーブ + ループ）

private struct SplashMuscleMapHero: View {
    @State private var animatedMuscles: Set<Muscle> = []
    @State private var waveTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 16) {
            // フロント
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    ForEach(MusclePathData.frontMuscles, id: \.muscle) { entry in
                        let isHighlighted = animatedMuscles.contains(entry.muscle)
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
                            .animation(.easeInOut(duration: 0.3), value: isHighlighted)
                    }
                }
            }
            .aspectRatio(0.55, contentMode: .fit)

            // バック
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    ForEach(MusclePathData.backMuscles, id: \.muscle) { entry in
                        let isHighlighted = animatedMuscles.contains(entry.muscle)
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
                            .animation(.easeInOut(duration: 0.3), value: isHighlighted)
                    }
                }
            }
            .aspectRatio(0.55, contentMode: .fit)
        }
        .padding(.horizontal, 40)
        .onAppear {
            startWaveAnimation()
        }
        .onDisappear {
            waveTask?.cancel()
            waveTask = nil
        }
    }

    private func startWaveAnimation() {
        waveTask?.cancel()
        let allMuscles = Muscle.allCases

        waveTask = Task { @MainActor in
            // 初回は少し待ってから開始
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            // ループ: 全筋肉を順番に点灯 → 待機 → リセット → 繰り返し
            while !Task.isCancelled {
                // 全筋肉を0.05秒間隔で順番に点灯
                for muscle in allMuscles {
                    guard !Task.isCancelled else { return }
                    animatedMuscles.insert(muscle)
                    try? await Task.sleep(for: .milliseconds(50))
                }

                // 全部光ったら2秒待つ
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }

                // リセット → 1秒待って再開
                animatedMuscles.removeAll()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}

import SwiftUI

// MARK: - 筋肉マップビュー（フロント/バック切り替え）

struct MuscleMapView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    var onMuscleTapped: ((Muscle) -> Void)?
    var demoMode: Bool = false

    @State private var showingFront = true
    @State private var demoHighlighted: Set<Muscle> = []
    @State private var demoPulse = false

    var body: some View {
        VStack(spacing: 8) {
            // 切り替えラベル
            HStack {
                Text(showingFront ? L10n.front : L10n.back)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFront.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text(showingFront ? L10n.viewBack : L10n.viewFront)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.mmAccentSecondary)
                }
            }
            .padding(.horizontal, 8)

            // 人体図
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)

                ZStack {
                    // 筋肉パス
                    let muscles = showingFront
                        ? MusclePathData.frontMuscles
                        : MusclePathData.backMuscles

                    ForEach(muscles, id: \.muscle) { entry in
                        let isDemoHighlighted = demoHighlighted.contains(entry.muscle)
                        let effectiveState: MuscleVisualState = isDemoHighlighted
                            ? .recovering(progress: 0.1)
                            : (muscleStates[entry.muscle] ?? .inactive)

                        MusclePathView(
                            path: entry.path(rect),
                            state: effectiveState,
                            muscle: entry.muscle,
                            isDemoHighlighted: isDemoHighlighted && demoPulse
                        ) {
                            onMuscleTapped?(entry.muscle)
                            HapticManager.lightTap()
                        }
                    }
                }
            }
            .aspectRatio(0.6, contentMode: .fit)
        }
        .onChange(of: demoMode) { _, isDemo in
            if isDemo {
                runDemoAnimation()
            }
        }
        .onAppear {
            if demoMode {
                runDemoAnimation()
            }
        }
    }

    // MARK: - デモアニメーション（控えめに調整）

    private func runDemoAnimation() {
        let frontMuscles = MusclePathData.frontMuscles.map(\.muscle)
        let backMuscles = MusclePathData.backMuscles.map(\.muscle)
        let allMuscles = frontMuscles + backMuscles

        // 筋肉を1つずつ点灯（ゆっくりめに）
        for (index, muscle) in allMuscles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = demoHighlighted.insert(muscle)
                }
            }
        }

        // 全点灯後にパルス
        let totalLightUpTime = Double(allMuscles.count) * 0.06 + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + totalLightUpTime) {
            withAnimation(.easeInOut(duration: 0.4)) {
                demoPulse = true
            }
        }

        // パルス後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + totalLightUpTime + 0.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                demoPulse = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalLightUpTime + 1.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                demoHighlighted.removeAll()
            }
        }
    }
}

// MARK: - 個別筋肉パスビュー（アニメーション付き）

private struct MusclePathView: View {
    let path: Path
    let state: MuscleVisualState
    let muscle: Muscle
    var isDemoHighlighted: Bool = false
    let onTap: () -> Void

    @State private var isPulsing = false
    @State private var isTapped = false

    private var isActive: Bool {
        switch state {
        case .inactive:
            return false
        case .recovering, .neglected:
            return true
        }
    }

    var body: some View {
        path
            .fill(state.color)
            .overlay {
                // アクティブな筋肉は明るいボーダー、そうでなければ通常ボーダー
                path.stroke(
                    isActive ? Color.mmMuscleActiveBorder.opacity(0.6) : Color.mmMuscleBorder,
                    lineWidth: isActive ? 1.2 : 0.8
                )
            }
            // グローエフェクト（パルス時に強調）
            .shadow(
                color: isActive ? state.color.opacity(isPulsing ? 0.6 : 0.3) : .clear,
                radius: isPulsing ? 6 : 3
            )
            // タップ時のみスケール、通常パルスはopacityで表現
            .scaleEffect(isTapped ? 1.02 : 1.0)
            .opacity(isPulsing ? 0.85 : 1.0)
            .brightness(isDemoHighlighted ? 0.15 : 0)
            .animation(.easeInOut(duration: 0.2), value: isTapped)
            .animation(pulseAnimation, value: isPulsing)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTapped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = false
                    }
                }
                onTap()
            }
            .onAppear {
                if state.shouldPulse {
                    // 少し遅延させてから開始（全体がバラバラにならないよう）
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.3)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: state.shouldPulse) { _, shouldPulse in
                isPulsing = shouldPulse
            }
    }

    private var pulseAnimation: Animation? {
        guard state.shouldPulse else { return nil }
        // より滑らかなアニメーション
        return .easeInOut(duration: state.pulseInterval * 1.2)
            .repeatForever(autoreverses: true)
    }
}

#Preview {
    let states: [Muscle: MuscleVisualState] = [
        .chestUpper: .recovering(progress: 0.1),
        .chestLower: .recovering(progress: 0.3),
        .deltoidAnterior: .recovering(progress: 0.5),
        .biceps: .recovering(progress: 0.7),
        .quadriceps: .recovering(progress: 0.9),
        .rectusAbdominis: .neglected(fast: false),
        .obliques: .inactive,
    ]

    return ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        MuscleMapView(muscleStates: states)
            .padding()
    }
}

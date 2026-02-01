import SwiftUI

// MARK: - 筋肉マップビュー（フロント/バック切り替え）

struct MuscleMapView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    var onMuscleTapped: ((Muscle) -> Void)?

    @State private var showingFront = true

    var body: some View {
        VStack(spacing: 8) {
            // 切り替えラベル
            HStack {
                Text(showingFront ? "前面" : "背面")
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
                        Text(showingFront ? "背面を見る" : "前面を見る")
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
                    // シルエット（背景）
                    if showingFront {
                        MusclePathData.bodyOutlineFront(in: rect)
                            .fill(Color.mmBgCard.opacity(0.5))
                    } else {
                        MusclePathData.bodyOutlineBack(in: rect)
                            .fill(Color.mmBgCard.opacity(0.5))
                    }

                    // 筋肉パス
                    let muscles = showingFront
                        ? MusclePathData.frontMuscles
                        : MusclePathData.backMuscles

                    ForEach(muscles, id: \.muscle) { entry in
                        MusclePathView(
                            path: entry.path(rect),
                            state: muscleStates[entry.muscle] ?? .inactive,
                            muscle: entry.muscle
                        ) {
                            onMuscleTapped?(entry.muscle)
                        }
                    }
                }
            }
            .aspectRatio(0.5, contentMode: .fit)
        }
    }
}

// MARK: - 個別筋肉パスビュー（アニメーション付き）

private struct MusclePathView: View {
    let path: Path
    let state: MuscleVisualState
    let muscle: Muscle
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        path
            .fill(fillColor)
            .opacity(opacity)
            .scaleEffect(isPulsing ? 1.03 : 1.0)
            .animation(pulseAnimation, value: isPulsing)
            .onTapGesture(perform: onTap)
            .onAppear {
                if state.shouldPulse {
                    isPulsing = true
                }
            }
            .onChange(of: state.shouldPulse) { _, shouldPulse in
                isPulsing = shouldPulse
            }
    }

    private var fillColor: Color {
        state.color
    }

    private var opacity: Double {
        switch state {
        case .inactive: return 0.1
        case .recovering: return 0.85
        case .neglected: return 0.9
        }
    }

    private var pulseAnimation: Animation? {
        guard state.shouldPulse else { return nil }
        return .easeInOut(duration: state.pulseInterval)
            .repeatForever(autoreverses: true)
    }
}

#Preview {
    // プレビュー用のサンプルデータ
    let states: [Muscle: MuscleVisualState] = [
        .chestUpper: .recovering(progress: 0.2),
        .chestLower: .recovering(progress: 0.05),
        .deltoidAnterior: .recovering(progress: 0.6),
        .biceps: .recovering(progress: 0.8),
        .quadriceps: .neglected(fast: false),
        .rectusAbdominis: .inactive,
    ]

    return ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        MuscleMapView(muscleStates: states)
            .padding()
    }
}

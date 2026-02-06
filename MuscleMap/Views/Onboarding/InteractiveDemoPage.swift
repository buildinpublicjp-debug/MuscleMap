import SwiftUI

// MARK: - 価値体験画面（筋肉マップデモ）

struct InteractiveDemoPage: View {
    @State private var tappedMuscles: Set<Muscle> = []
    @State private var showingFront = true
    @State private var appeared = false
    @State private var selectedMuscleInfo: MuscleRecoveryInfo?

    /// タップした筋肉を光らせる状態マップ
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if tappedMuscles.contains(muscle) {
                states[muscle] = .recovering(progress: 0.1) // 赤に近い色
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ヘッダー（スキップボタン）
                HStack {
                    Spacer()
                    // スキップは不要になったので削除（ページスワイプで移動可能）
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .frame(height: 44)

                // タイトルエリア
                VStack(spacing: 8) {
                    Text(L10n.demoPrimaryTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .multilineTextAlignment(.center)

                    Text(L10n.demoSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)

                Spacer().frame(height: 16)

                // 前面/背面トグル
                HStack(spacing: 0) {
                    ToggleButton(
                        title: L10n.front,
                        icon: "person.fill",
                        isSelected: showingFront
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFront = true
                        }
                        HapticManager.lightTap()
                    }

                    ToggleButton(
                        title: L10n.back,
                        icon: "person.fill",
                        isSelected: !showingFront,
                        isFlipped: true
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFront = false
                        }
                        HapticManager.lightTap()
                    }
                }
                .padding(4)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

                // 筋肉マップ（スワイプ対応）
                TabView(selection: $showingFront) {
                    // 前面
                    DemoMuscleMapView(
                        muscleStates: muscleStates,
                        showFront: true,
                        onMuscleTapped: handleMuscleTap
                    )
                    .tag(true)

                    // 背面
                    DemoMuscleMapView(
                        muscleStates: muscleStates,
                        showFront: false,
                        onMuscleTapped: handleMuscleTap
                    )
                    .tag(false)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height * 0.50)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.95)

                Spacer()
            }

            // 回復情報カード（下からスライドアップ）
            VStack {
                Spacer()

                if let info = selectedMuscleInfo {
                    RecoveryInfoCard(info: info) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMuscleInfo = nil
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFront = false
                        }
                    } else if value.translation.width > 50 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFront = true
                        }
                    }
                }
        )
    }

    private func handleMuscleTap(_ muscle: Muscle) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if tappedMuscles.contains(muscle) {
                tappedMuscles.remove(muscle)
                if selectedMuscleInfo?.muscle == muscle {
                    selectedMuscleInfo = nil
                }
            } else {
                tappedMuscles.insert(muscle)
                // 回復情報を表示
                selectedMuscleInfo = MuscleRecoveryInfo(
                    muscle: muscle,
                    recoveryHours: muscle.baseRecoveryHours
                )
            }
        }
        HapticManager.lightTap()
    }
}

// MARK: - 回復情報モデル

private struct MuscleRecoveryInfo: Equatable {
    let muscle: Muscle
    let recoveryHours: Int
}

// MARK: - トグルボタン

private struct ToggleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var isFlipped: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .scaleEffect(x: isFlipped ? -1 : 1, y: 1)

                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.mmOnboardingAccent : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - デモ用筋肉マップビュー

private struct DemoMuscleMapView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let showFront: Bool
    let onMuscleTapped: (Muscle) -> Void

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let muscles = showFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let state = muscleStates[entry.muscle] ?? .inactive
                    let isActive = state != .inactive

                    entry.path(rect)
                        .fill(state.color)
                        .overlay {
                            entry.path(rect)
                                .stroke(
                                    isActive ? Color.mmMuscleActiveBorder.opacity(0.8) : Color.mmOnboardingTextSub.opacity(0.3),
                                    lineWidth: isActive ? 1.5 : 0.5
                                )
                        }
                        .shadow(
                            color: isActive ? state.color.opacity(0.5) : .clear,
                            radius: isActive ? 8 : 0
                        )
                        .onTapGesture {
                            onMuscleTapped(entry.muscle)
                        }
                }
            }
        }
        .aspectRatio(0.55, contentMode: .fit)
        .padding(.horizontal, 40)
    }
}

// MARK: - 回復情報カード

private struct RecoveryInfoCard: View {
    let info: MuscleRecoveryInfo
    let onDismiss: () -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 16) {
            // 筋肉アイコン
            ZStack {
                Circle()
                    .fill(Color.mmMuscleJustWorked.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundStyle(Color.mmMuscleJustWorked)
            }

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.currentLanguage == .japanese ? info.muscle.japaneseName : info.muscle.englishName)
                    .font(.headline)
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(L10n.recoveryTimeRemaining(info.recoveryHours))
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            Spacer()

            // 閉じるボタン
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        InteractiveDemoPage()
    }
}

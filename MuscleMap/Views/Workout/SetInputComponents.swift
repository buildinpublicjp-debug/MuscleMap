import SwiftUI
import SwiftData

// MARK: - セット入力関連コンポーネント

/// セット入力カード
struct SetInputCard: View {
    @Bindable var viewModel: WorkoutViewModel
    let exercise: ExerciseDefinition
    @Environment(\.modelContext) private var modelContext
    @State private var useAdditionalWeight = false
    @State private var showPRCelebration = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var isBodyweight: Bool {
        exercise.equipment == "自重" || exercise.equipment == "Bodyweight"
    }

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.id, context: modelContext)
    }

    var body: some View {
        ScrollView {
        VStack(spacing: 12) {
            // 種目名 + セット番号（コンパクトヘッダー）
            HStack {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(L10n.setNumber(viewModel.currentSetNumber))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            // GIFアニメーション（タイマー・PR オーバーレイ付き）
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .bottomTrailing) {
                        ExerciseGifView(exerciseId: exercise.id, size: .fullWidth)
                            .frame(maxHeight: 150)

                        // PR表示（GIF右下にオーバーレイ）
                        if let pr = prWeight, !isBodyweight {
                            HStack(spacing: 2) {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                Text("\(pr, specifier: "%.1f")kg")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(8)
                        }
                    }

                    // タイマー（GIF右上にオーバーレイ）
                    if viewModel.isRestTimerRunning {
                        CompactTimerBadge(
                            seconds: viewModel.restTimerSeconds,
                            onStop: { viewModel.stopRestTimer() }
                        )
                        .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // GIFがない場合のタイマー表示
                if viewModel.isRestTimerRunning {
                    CompactTimerBadge(
                        seconds: viewModel.restTimerSeconds,
                        onStop: { viewModel.stopRestTimer() }
                    )
                }
            }

            // 前回記録（コンパクト表示）
            if let lastW = viewModel.lastWeight, let lastR = viewModel.lastReps {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentSecondary)

                    if isBodyweight && lastW == 0 {
                        Text(L10n.previousRepsOnly(lastR))
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                    } else {
                        Text(L10n.previousRecord(lastW, lastR))
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }

            // 重量の提案チップ
            if let lastW = viewModel.lastWeight, lastW > 0, !isBodyweight {
                let suggested = lastW + 2.5
                Button {
                    viewModel.currentWeight = suggested
                    HapticManager.lightTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                        Text(L10n.tryHeavier(lastW, suggested))
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .foregroundStyle(Color.mmAccentPrimary)
                    .clipShape(Capsule())
                }
            }

            // 自重種目の場合
            if isBodyweight {
                // 自重ラベル
                if !useAdditionalWeight {
                    Text(L10n.bodyweight)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextSecondary)
                        .padding(.vertical, 8)
                }

                // 加重トグル
                Toggle(isOn: $useAdditionalWeight) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                        Text(L10n.addWeight)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                }
                .tint(Color.mmAccentPrimary)
                .padding(.horizontal, 8)
                .onChange(of: useAdditionalWeight) { _, newValue in
                    if !newValue {
                        viewModel.currentWeight = 0
                    }
                }
            }

            // 重量入力（通常種目 or 加重時）
            if !isBodyweight || useAdditionalWeight {
                HStack(spacing: 16) {
                    WeightStepperButton(systemImage: "minus") {
                        viewModel.adjustWeight(by: -0.25)  // タップ = 細かく
                    } onLongPress: {
                        viewModel.adjustWeight(by: -2.5)   // 長押し = 大きく
                    }

                    WeightInputView(
                        weight: $viewModel.currentWeight,
                        label: isBodyweight ? L10n.kgAdditional : L10n.kg
                    )
                    .frame(minWidth: 100)

                    WeightStepperButton(systemImage: "plus") {
                        viewModel.adjustWeight(by: 0.25)   // タップ = 細かく
                    } onLongPress: {
                        viewModel.adjustWeight(by: 2.5)    // 長押し = 大きく
                    }
                }
            }

            // レップ数入力
            HStack(spacing: 16) {
                StepperButton(systemImage: "minus") {
                    viewModel.adjustReps(by: -1)
                }

                VStack(spacing: 2) {
                    Text("\(viewModel.currentReps)")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.reps)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .frame(minWidth: 100)

                StepperButton(systemImage: "plus") {
                    viewModel.adjustReps(by: 1)
                }
            }

            // 記録ボタン
            Button {
                let isPR = viewModel.recordSet()
                if isPR {
                    HapticManager.prAchieved()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showPRCelebration = true
                    }
                    // 2秒後に自動で閉じる
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showPRCelebration = false
                        }
                    }
                } else {
                    HapticManager.setCompleted()
                }
            } label: {
                Text(L10n.recordSet)
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        }
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .overlay {
            // PR達成祝福オーバーレイ
            if showPRCelebration {
                PRCelebrationOverlay()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - PR達成祝福オーバーレイ

/// PR達成時の祝福オーバーレイ
struct PRCelebrationOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -10
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // 背景のぼかし
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // トロフィーアイコン
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 10)

                // PRテキスト
                Text("🎉 NEW PR! 🎉")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("自己ベスト更新！")
                    .font(.headline)
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                scale = 1.0
                rotation = 0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview

//#Preview {
//    // Preview requires full app context with Swift Data
//}

#Preview("PR Celebration") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        PRCelebrationOverlay()
    }
}

import SwiftUI
import SwiftData

// MARK: - セット入力関連コンポーネント

/// セット入力カード（リファクタ版）
/// 核: 重量入力 + レップ入力 + 記録ボタン
struct SetInputCard: View {
    @Bindable var viewModel: WorkoutViewModel
    let exercise: ExerciseDefinition
    @Environment(\.modelContext) private var modelContext
    @State private var useAdditionalWeight = false
    @State private var savedAdditionalWeight: Double = 0
    @State private var showPRCelebration = false
    @State private var recordButtonScale: CGFloat = 1.0
    @State private var showExerciseDetail = false
    @State private var showPreviousSession = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var isBodyweight: Bool {
        exercise.isBodyweight
    }

    /// ダンベル種目かどうか
    private var isDumbbell: Bool {
        exercise.equipment == "ダンベル"
    }

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.id, context: modelContext)
    }

    /// 前回記録から値が変更されていないか（ゴースト表示判定用）
    private var isWeightGhost: Bool {
        guard let lastW = viewModel.lastWeight else { return false }
        return viewModel.currentWeight == lastW
    }

    private var isRepsGhost: Bool {
        guard let lastR = viewModel.lastReps else { return false }
        return viewModel.currentReps == lastR
    }

    var body: some View {
        ScrollView {
        VStack(spacing: 12) {
            // 種目名 + info + レベルアイコン + セット番号
            HStack {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Button {
                    HapticManager.lightTap()
                    showExerciseDetail = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)

                Spacer()

                Text(L10n.setNumber(viewModel.currentSetNumber))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .sheet(isPresented: $showExerciseDetail) {
                NavigationStack {
                    ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
                }
            }

            // GIF: 全セット統一レイアウト（gridCard + オーバーレイ）
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .bottomTrailing) {
                        ExerciseGifView(exerciseId: exercise.id, size: .gridCard)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: viewModel.currentSetNumber == 1 ? 150 : 120)
                            .background(Color.white)
                            .clipped()

                        // PR表示（GIF右下にオーバーレイ）
                        if let pr = prWeight, !isBodyweight {
                            HStack(spacing: 2) {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.mmPRGold)
                                Text("\(pr, specifier: "%.1f")kg")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mmBgPrimary.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(8)
                        }
                    }

                    // タイマー（GIF右上にオーバーレイ）
                    if viewModel.isRestTimerRunning {
                        CompactTimerBadge(
                            seconds: viewModel.restTimerSeconds,
                            isOvertime: viewModel.isRestTimerOvertime,
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
                        isOvertime: viewModel.isRestTimerOvertime,
                        onStop: { viewModel.stopRestTimer() }
                    )
                }
            }

            // 前回セッション参照（折りたたみ式、デフォルト閉じ）
            if !viewModel.previousSessionSets.isEmpty {
                PreviousSessionReference(
                    sets: viewModel.previousSessionSets,
                    isBodyweight: isBodyweight,
                    isExpanded: $showPreviousSession
                )
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
                        savedAdditionalWeight = viewModel.currentWeight
                        viewModel.currentWeight = 0
                    } else {
                        viewModel.currentWeight = savedAdditionalWeight
                    }
                }
            }

            // 重量入力（通常種目 or 加重時）
            if !isBodyweight || useAdditionalWeight {
                // ダンベル片手ラベル
                if isDumbbell {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption2)
                        Text(localization.currentLanguage == .japanese ? "片手" : "Per hand")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(Color.mmAccentSecondary)
                }

                HStack(spacing: 16) {
                    WeightStepperButton(systemImage: "minus") {
                        viewModel.adjustWeight(by: -0.25)
                    } onLongPress: {
                        viewModel.adjustWeight(by: -2.5)
                    } onAcceleratedPress: {
                        viewModel.adjustWeight(by: -5.0)
                    }

                    WeightInputView(
                        weight: $viewModel.currentWeight,
                        label: isBodyweight ? L10n.kgAdditional : L10n.kg,
                        isGhost: isWeightGhost
                    )
                    .frame(minWidth: 100)

                    WeightStepperButton(systemImage: "plus") {
                        viewModel.adjustWeight(by: 0.25)
                    } onLongPress: {
                        viewModel.adjustWeight(by: 2.5)
                    } onAcceleratedPress: {
                        viewModel.adjustWeight(by: 5.0)
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
                        .foregroundStyle(isRepsGhost ? Color.mmTextSecondary.opacity(0.5) : Color.mmTextPrimary)
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
                // バウンスアニメーション
                withAnimation(.easeInOut(duration: 0.08)) {
                    recordButtonScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                        recordButtonScale = 1.0
                    }
                }

                // ダンベル種目: 内部的に×2で記録
                if isDumbbell && !isBodyweight {
                    let perHand = viewModel.currentWeight
                    viewModel.currentWeight = perHand * 2
                    let isPR = viewModel.recordSet()
                    viewModel.currentWeight = perHand // 表示を片手に戻す
                    handlePRResult(isPR)
                } else {
                    let isPR = viewModel.recordSet()
                    handlePRResult(isPR)
                }
            } label: {
                HStack(spacing: 6) {
                    Text(L10n.recordSet)
                        .font(.headline)
                    if isDumbbell && !isBodyweight {
                        Text("(\(String(format: "%.1f", viewModel.currentWeight * 2))kg)")
                            .font(.caption.bold())
                            .opacity(0.7)
                    }
                }
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .scaleEffect(recordButtonScale)
            .contentShape(Rectangle())
            .buttonStyle(.plain)

        }
        .padding()
        }
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .overlay(alignment: .top) {
            if showPRCelebration {
                PRCelebrationOverlay()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - PR結果ハンドリング

    private func handlePRResult(_ isPR: Bool) {
        if isPR {
            HapticManager.prAchieved()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showPRCelebration = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showPRCelebration = false
                }
            }
        } else {
            HapticManager.setCompleted()
        }
    }
}

// MARK: - 前回セッション参照表示（折りたたみ式）

/// 前回セッションのセット一覧（デフォルト閉じ）
struct PreviousSessionReference: View {
    let sets: [WorkoutSet]
    let isBodyweight: Bool
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ヘッダー（タップで開閉）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                HapticManager.lightTap()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text(L10n.previousSessionHeader)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                    Text("(\(sets.count))")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                }
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)

            // セット一覧（展開時のみ）
            if isExpanded {
                ForEach(sets, id: \.id) { set in
                    HStack(spacing: 6) {
                        Text(L10n.setNumber(set.setNumber))
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                            .frame(width: 44, alignment: .leading)
                        if isBodyweight && set.weight == 0 {
                            Text(L10n.repsOnly(set.reps))
                                .font(.caption2.monospaced())
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        } else {
                            Text(L10n.weightReps(set.weight, set.reps))
                                .font(.caption2.monospaced())
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        }
                        Image(systemName: "checkmark")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PR達成祝福オーバーレイ

struct PRCelebrationOverlay: View {
    @State private var offset: CGFloat = -60
    @State private var opacity: Double = 0
    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmPRGold)

                Text(isJapanese ? "自己ベスト更新" : "New Personal Record")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.mmPRGold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.mmPRGold.opacity(0.15), Color.mmPRGold.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.mmPRGold.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .offset(y: offset)
            .opacity(opacity)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("PR Celebration") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        PRCelebrationOverlay()
    }
}

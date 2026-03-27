import SwiftUI
import SwiftData

// MARK: - セット入力関連コンポーネント

/// セット入力カード
struct SetInputCard: View {
    @Bindable var viewModel: WorkoutViewModel
    let exercise: ExerciseDefinition
    @Environment(\.modelContext) private var modelContext
    @State private var useAdditionalWeight = false
    @State private var savedAdditionalWeight: Double = 0
    @State private var showPRCelebration = false
    @State private var recordButtonScale: CGFloat = 1.0
    @State private var showExerciseDetail = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var isBodyweight: Bool {
        exercise.isBodyweight
    }

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.id, context: modelContext)
    }

    /// 現在の種目の強さレベル情報
    private var strengthLevelInfo: (level: StrengthLevel, kgToNext: Double?, nextLevel: StrengthLevel?)? {
        let bodyweight = AppState.shared.userProfile.weightKg
        guard let best1RM = PRManager.shared.getBestEffective1RM(
            exerciseId: exercise.id, bodyweightKg: bodyweight, context: modelContext
        ) else {
            return nil
        }
        return StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: exercise.id,
            estimated1RM: best1RM,
            bodyweightKg: bodyweight
        )
    }

    var body: some View {
        ScrollView {
        VStack(spacing: 12) {
            // 種目名 + info + レベルバッジ + セット番号
            VStack(alignment: .leading, spacing: 4) {
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
                    .buttonStyle(.plain)

                    Spacer()

                    Text(L10n.setNumber(viewModel.currentSetNumber))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                // レベルバッジ（種目名の下に配置）
                if let info = strengthLevelInfo {
                    HStack(spacing: 4) {
                        Text(info.level.emoji)
                            .font(.caption2)
                        Text(info.level.localizedName)
                            .font(.caption2.bold())
                            .foregroundStyle(info.level.color)
                        if let kgToNext = info.kgToNext,
                           let nextLevel = info.nextLevel {
                            Text("→ \(nextLevel.localizedName)まで\(Int(ceil(kgToNext)))kg")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExerciseDetail) {
                NavigationStack {
                    ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
                }
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

            // 前回セッションの全セット参照表示
            if !viewModel.previousSessionSets.isEmpty {
                PreviousSessionReference(
                    sets: viewModel.previousSessionSets,
                    isBodyweight: isBodyweight
                )
            }

            // 前回記録（コンパクト表示）+ 「同じ」ボタン
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

                    Spacer()

                    // 前回と同じボタン
                    Button {
                        viewModel.currentWeight = lastW
                        viewModel.currentReps = lastR
                        HapticManager.lightTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                            Text(L10n.copyLastSet)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.mmAccentSecondary.opacity(0.15))
                        .foregroundStyle(Color.mmAccentSecondary)
                        .clipShape(Capsule())
                    }
                }
            }

            // 重量の提案（控えめテキスト）
            if let lastW = viewModel.lastWeight, lastW > 0, !isBodyweight {
                let suggested = lastW + 2.5
                Button {
                    viewModel.currentWeight = suggested
                    HapticManager.lightTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                        Text(L10n.tryHeavier(lastW, suggested))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.mmTextSecondary)
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
                        // トグルOFF: 現在の加重を保存してからゼロにする
                        savedAdditionalWeight = viewModel.currentWeight
                        viewModel.currentWeight = 0
                    } else {
                        // トグルON: 保存していた加重を復元
                        viewModel.currentWeight = savedAdditionalWeight
                    }
                }
            }

            // 重量入力（通常種目 or 加重時）
            if !isBodyweight || useAdditionalWeight {
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
                        label: isBodyweight ? L10n.kgAdditional : L10n.kg
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

                // クイックセット重量ボタン（直近3つの重量）
                if !viewModel.recentWeights.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentWeights, id: \.self) { weight in
                            Button {
                                viewModel.currentWeight = weight
                                HapticManager.lightTap()
                            } label: {
                                Text(String(format: "%.1f", weight))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(
                                        viewModel.currentWeight == weight
                                            ? Color.mmBgPrimary
                                            : Color.mmAccentPrimary
                                    )
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.currentWeight == weight
                                            ? Color.mmAccentPrimary
                                            : Color.mmAccentPrimary.opacity(0.15)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
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

            // レップ数クイックセットピル
            HStack(spacing: 8) {
                ForEach([5, 8, 10, 12, 15], id: \.self) { rep in
                    Button {
                        viewModel.currentReps = rep
                        HapticManager.lightTap()
                    } label: {
                        Text("\(rep)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(
                                viewModel.currentReps == rep
                                    ? Color.mmBgPrimary
                                    : Color.mmTextSecondary
                            )
                            .frame(width: 40, height: 32)
                            .background(
                                viewModel.currentReps == rep
                                    ? Color.mmAccentPrimary
                                    : Color.mmBgSecondary
                            )
                            .clipShape(Capsule())
                    }
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

                let isPR = viewModel.recordSet()
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
            } label: {
                Text(L10n.recordSet)
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .scaleEffect(recordButtonScale)
            .buttonStyle(.plain)


        }
        .padding()
        }
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .overlay {
            if showPRCelebration {
                PRCelebrationOverlay()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - 前回セッション参照表示

/// 前回セッションのセット一覧（ゴースト表示）
struct PreviousSessionReference: View {
    let sets: [WorkoutSet]
    let isBodyweight: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.previousSessionHeader)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.6))

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

            Divider()
                .overlay(Color.mmTextSecondary.opacity(0.2))

            Text(L10n.currentSessionHeader)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PR達成祝福オーバーレイ

struct PRCelebrationOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -10
    @State private var opacity: Double = 0
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.mmPRGold)
                    .shadow(color: Color.mmPRGold.opacity(0.5), radius: 10)

                Text("🎉 NEW PR! 🎉")
                    .font(.title.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text(localization.currentLanguage == .japanese ? "自己ベスト更新！" : "Personal Record!")
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

#Preview("PR Celebration") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        PRCelebrationOverlay()
    }
}

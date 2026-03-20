import SwiftUI

// MARK: - PR入力画面（筋肉マップ→種目選択→重量入力）

struct PRInputPage: View {
    let onNext: () -> Void

    /// 入力済みPR（exerciseId: weight）
    @State private var recordedPRs: [String: Double] = [:]
    @State private var appeared = false
    @State private var isProceeding = false

    /// 筋肉タップ → 種目選択シート
    @State private var tappedMuscle: Muscle?

    /// 種目選択 → 重量入力シート
    @State private var selectedExercise: ExerciseDefinition?

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var isJapanese: Bool { localization.currentLanguage == .japanese }

    /// デフォルト体重
    private var bodyweightKg: Double {
        let w = AppState.shared.userProfile.weightKg
        return w > 0 ? w : 70.0
    }

    /// 入力済みPRに対応する筋肉のハイライト
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        // 入力済み種目がターゲットにする筋肉をグリーンに
        var highlightedMuscles: Set<Muscle> = []
        let store = ExerciseStore.shared
        for exerciseId in recordedPRs.keys {
            if let exercise = store.exercise(for: exerciseId) {
                for (muscleId, _) in exercise.muscleMapping {
                    if let muscle = Muscle(rawValue: muscleId) {
                        highlightedMuscles.insert(muscle)
                    }
                }
            }
        }
        for muscle in Muscle.allCases {
            states[muscle] = highlightedMuscles.contains(muscle) ? .recovering(progress: 0.1) : .inactive
        }
        return states
    }

    /// デフォルト表示するBIG3種目
    private var defaultExercises: [ExerciseDefinition] {
        let ids = ["barbell_bench_press", "barbell_squat", "barbell_deadlift"]
        let store = ExerciseStore.shared
        return ids.compactMap { store.exercise(for: $0) }
    }

    /// 総合レベル
    private var overallLevel: StrengthLevel? {
        guard !recordedPRs.isEmpty else { return nil }
        var totalScore = 0.0
        for (exerciseId, weight) in recordedPRs {
            let result = StrengthScoreCalculator.exerciseStrengthLevel(
                exerciseId: exerciseId,
                estimated1RM: weight,
                bodyweightKg: bodyweightKg
            )
            totalScore += result.level.minimumScore
        }
        let avgScore = totalScore / Double(recordedPRs.count)
        return StrengthScoreCalculator.level(score: avgScore)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            // ヘッダー
            VStack(spacing: 4) {
                Text(L10n.prInputTitle)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Text(L10n.prInputSubtitle)
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer().frame(height: 8)

            // 筋肉マップ（タップ可能 + 未入力時タップガイド）
            ZStack {
                MuscleMapView(
                    muscleStates: muscleStates,
                    onMuscleTapped: { muscle in
                        tappedMuscle = muscle
                        HapticManager.lightTap()
                    }
                )
                .frame(height: 300)

                // 未入力時のタップガイド（マップ中央下部）
                if recordedPRs.isEmpty {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 12))
                            Text(isJapanese ? "筋肉をタップして重量を入力" : "Tap muscles to enter weights")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.mmOnboardingBg.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: recordedPRs.count)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 4)

            // BIG3コンパクトチップ（横スクロール）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(defaultExercises, id: \.id) { exercise in
                        Button {
                            selectedExercise = exercise
                            HapticManager.lightTap()
                        } label: {
                            HStack(spacing: 6) {
                                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(exercise.localizedName)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.mmOnboardingTextMain)
                                        .lineLimit(1)

                                    if let weight = recordedPRs[exercise.id] {
                                        Text("\(Int(weight))kg")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.mmOnboardingAccent)
                                    } else {
                                        Text(isJapanese ? "タップで入力" : "Tap to enter")
                                            .font(.system(size: 9))
                                            .foregroundStyle(Color.mmOnboardingTextSub)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                recordedPRs[exercise.id] != nil
                                    ? Color.mmOnboardingAccent.opacity(0.08)
                                    : Color.mmOnboardingCard
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 4)

            // 入力済みPRチップ（横スクロール）
            if !recordedPRs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text(isJapanese ? "登録済み" : "Recorded")
                            .font(.caption2)
                            .foregroundStyle(Color.mmOnboardingTextSub)

                        ForEach(recordedPRs.sorted(by: { $0.key < $1.key }), id: \.key) { exerciseId, weight in
                            let name = ExerciseStore.shared.exerciseName(for: exerciseId) ?? exerciseId
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.mmOnboardingAccent)
                                    .frame(width: 6, height: 6)
                                Text("\(name) \(Int(weight))kg")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.mmOnboardingTextMain)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mmOnboardingCard)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 28)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.3), value: recordedPRs.count)
            }

            // 強さレベルプレビュー or 動機付けテキスト
            if recordedPRs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.mmOnboardingAccent.opacity(0.4))
                    Text(isJapanese
                        ? "重量を入力すると、あなたの強さレベルが判定されます"
                        : "Enter your weights to see your strength level")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .opacity(appeared ? 1 : 0)
            } else if let level = overallLevel {
                VStack(spacing: 8) {
                    Text(isJapanese ? "現在のレベル" : "Your Level")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mmOnboardingTextSub)

                    HStack(spacing: 8) {
                        ForEach(StrengthLevel.allCases, id: \.self) { l in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(l == level ? l.color : Color.mmOnboardingCard)
                                    .frame(width: l == level ? 28 : 16, height: l == level ? 28 : 16)
                                    .overlay(
                                        Group {
                                            if l == level {
                                                Text(l.emoji).font(.system(size: 12))
                                            }
                                        }
                                    )
                                if l == level {
                                    Text(l.localizedName)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(l.color)
                                }
                            }
                        }
                    }

                    Text(isJapanese
                        ? "もっと入力すると精度が上がります"
                        : "More entries = more accurate")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .padding(16)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: overallLevel?.rawValue)
                .opacity(appeared ? 1 : 0)
            }

            Spacer(minLength: 8)

            // 次へ + スキップ
            VStack(spacing: 8) {
                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    savePRs()
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(L10n.next)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingBg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(isJapanese ? "わからない場合はスキップ →" : "Skip if unsure →")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            isProceeding = false  // スワイプ戻り時にボタンを有効化
            ExerciseStore.shared.loadIfNeeded()
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
        // 筋肉タップ → 種目選択シート
        .sheet(item: $tappedMuscle) { muscle in
            MuscleExerciseSheet(
                muscle: muscle,
                recordedPRs: recordedPRs,
                onSelectExercise: { exercise in
                    tappedMuscle = nil
                    // 少し遅延して次のシートを表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedExercise = exercise
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        // 種目選択 → 重量入力シート
        .sheet(item: $selectedExercise) { exercise in
            WeightInputSheet(
                exercise: exercise,
                initialWeight: recordedPRs[exercise.id],
                bodyweightKg: bodyweightKg,
                onSave: { weight in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        recordedPRs[exercise.id] = weight
                    }
                    HapticManager.stepperChanged()
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    /// PR入力値をUserProfileに保存
    private func savePRs() {
        AppState.shared.userProfile.initialPRs = recordedPRs
    }
}

// MARK: - 筋肉タップ → 種目選択シート

private struct MuscleExerciseSheet: View {
    let muscle: Muscle
    let recordedPRs: [String: Double]
    let onSelectExercise: (ExerciseDefinition) -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var isJapanese: Bool { localization.currentLanguage == .japanese }

    private var exercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            HStack {
                Text(isJapanese ? muscle.japaneseName : muscle.englishName)
                    .font(.headline.bold())
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Spacer()
                Text(isJapanese ? "\(exercises.count)種目" : "\(exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // 種目リスト
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(exercises) { exercise in
                        Button {
                            onSelectExercise(exercise)
                        } label: {
                            HStack(spacing: 12) {
                                // GIF 100x100
                                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                } else {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.mmOnboardingBg)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "dumbbell")
                                                .font(.title2)
                                                .foregroundStyle(Color.mmOnboardingTextSub)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.localizedName)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.mmOnboardingTextMain)
                                        .lineLimit(1)
                                    Text(exercise.localizedEquipment)
                                        .font(.caption2)
                                        .foregroundStyle(Color.mmOnboardingTextSub)
                                }

                                Spacer()

                                // 入力済みマーク
                                if let weight = recordedPRs[exercise.id] {
                                    Text("\(Int(weight))kg")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.mmOnboardingAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.mmOnboardingAccent.opacity(0.12))
                                        .clipShape(Capsule())
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color.mmOnboardingTextSub)
                                }
                            }
                            .padding(12)
                            .background(Color.mmOnboardingCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(Color.mmOnboardingBg)
    }
}

// MARK: - 重量入力シート

private struct WeightInputSheet: View {
    let exercise: ExerciseDefinition
    let initialWeight: Double?
    let bodyweightKg: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double = 0

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var isJapanese: Bool { localization.currentLanguage == .japanese }

    /// 現在の重量でのレベル判定
    private var currentLevel: StrengthLevel? {
        guard weight > 0 else { return nil }
        return StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: exercise.id,
            estimated1RM: weight,
            bodyweightKg: bodyweightKg
        ).level
    }

    var body: some View {
        VStack(spacing: 16) {
            // 種目ヘッダー（GIF + 名前）
            HStack(spacing: 12) {
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.mmOnboardingCard)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "dumbbell")
                                .font(.title3)
                                .foregroundStyle(Color.mmOnboardingTextSub)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.localizedName)
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .lineLimit(1)
                    Text(exercise.localizedEquipment)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }

                Spacer()

                // レベルバッジ
                if let level = currentLevel {
                    Text(level.localizedName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(level.color)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: level.rawValue)
                }
            }

            // 重量入力エリア
            VStack(spacing: 12) {
                Text(isJapanese ? "最大重量 (1RM)" : "Max Weight (1RM)")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)

                Text(isJapanese ? "1回だけ挙げられる最大の重量" : "The heaviest weight you can lift once")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))

                HStack(spacing: 16) {
                    // マイナスボタン
                    Button {
                        weight = max(0, weight - 2.5)
                        HapticManager.stepperChanged()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }
                    .buttonStyle(.plain)

                    // 重量表示
                    VStack(spacing: 0) {
                        Text(weight.truncatingRemainder(dividingBy: 1) == 0
                             ? "\(Int(weight))"
                             : String(format: "%.1f", weight))
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundStyle(Color.mmOnboardingTextMain)
                            .frame(minWidth: 80)
                            .contentTransition(.numericText())

                        Text("kg")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    // プラスボタン
                    Button {
                        weight += 2.5
                        HapticManager.stepperChanged()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.mmOnboardingAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 記録するボタン
            Button {
                guard weight > 0 else { return }
                onSave(weight)
                dismiss()
            } label: {
                Text(isJapanese ? "記録する" : "Record")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(weight > 0 ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(weight > 0 ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(weight <= 0)
            .animation(.easeInOut(duration: 0.2), value: weight > 0)
        }
        .padding(20)
        .background(Color.mmOnboardingBg)
        .onAppear {
            weight = initialWeight ?? 0
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        PRInputPage(onNext: {})
    }
}

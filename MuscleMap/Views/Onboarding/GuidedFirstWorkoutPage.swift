import SwiftUI
import SwiftData

// MARK: - ガイド付き初回ワークアウト（オンボーディング内）

struct GuidedFirstWorkoutPage: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: WorkoutStep = .selectExercise
    @State private var selectedExercise: PopularExercise?
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var appeared = false
    @State private var setRecorded = false
    @State private var showCelebration = false
    @State private var celebrationScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0
    @State private var recordedSets: Int = 0

    /// 記録されたセッション（追加セット用に保持）
    @State private var currentSession: WorkoutSession?

    private enum WorkoutStep {
        case selectExercise
        case inputSet
        case completion
    }

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            switch currentStep {
            case .selectExercise:
                exerciseSelectionView
                    .transition(.opacity)
            case .inputSet:
                setInputView
                    .transition(.opacity)
            case .completion:
                completionView
                    .transition(.opacity)
            }
        }
        .onAppear {
            ExerciseStore.shared.loadIfNeeded()
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Step 1: 種目選択

    private var exerciseSelectionView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトル
            VStack(spacing: 8) {
                Text("何を鍛える？")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text("まず1セットだけ記録してみよう")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : -10)

            Spacer().frame(height: 32)

            // 人気種目6つのグリッド
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(PopularExercise.allCases.enumerated()), id: \.element) { index, exercise in
                    ExerciseCard(
                        exercise: exercise,
                        isSelected: selectedExercise == exercise
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedExercise = exercise
                        }
                        HapticManager.lightTap()
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.5).delay(Double(index) * 0.08 + 0.2),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // 次へボタン
            Button {
                HapticManager.lightTap()
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStep = .inputSet
                }
            } label: {
                Text("次へ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        selectedExercise != nil
                            ? Color.mmOnboardingAccent
                            : Color.mmOnboardingTextSub.opacity(0.3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selectedExercise == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
        }
    }

    // MARK: - Step 2: セット入力

    private var setInputView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // 選んだ種目名
            if let exercise = selectedExercise {
                VStack(spacing: 8) {
                    Image(systemName: exercise.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(Color.mmOnboardingAccent)

                    Text(exercise.localizedName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text("重量とレップ数を入力しよう")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }

            Spacer().frame(height: 40)

            // 入力フィールド
            VStack(spacing: 16) {
                // 重量入力
                InputField(
                    label: "重量",
                    unit: "kg",
                    text: $weightText,
                    placeholder: "60"
                )

                // レップ数入力
                InputField(
                    label: "レップ数",
                    unit: "回",
                    text: $repsText,
                    placeholder: "10"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // セット記録ボタン
            Button {
                recordSet()
            } label: {
                Text("セット記録")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        isInputValid
                            ? LinearGradient(
                                colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [Color.mmOnboardingTextSub.opacity(0.3), Color.mmOnboardingTextSub.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(!isInputValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Step 3: 記録完了

    private var completionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                // 祝福テキスト
                Text("\u{1F389} 最初の1セット！")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .scaleEffect(showCelebration ? 1.0 : 0.5)
                    .opacity(showCelebration ? 1 : 0)

                // 筋肉マップ（鍛えた部位が光る）
                if let exercise = selectedExercise,
                   let definition = ExerciseStore.shared.exercise(for: exercise.exerciseId) {
                    stimulatedMuscleMap(muscleMapping: definition.muscleMapping)
                        .frame(height: 300)
                        .scaleEffect(showCelebration ? 1.0 : celebrationScale)
                        .opacity(showCelebration ? 1 : 0)
                        .shadow(
                            color: Color.mmMuscleFatigued.opacity(glowOpacity),
                            radius: 20
                        )
                }

                // 説明テキスト
                VStack(spacing: 8) {
                    Text("これがMuscleMap。")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text("トレーニングするたびにマップが育ちます。")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .multilineTextAlignment(.center)
                }
                .opacity(showCelebration ? 1 : 0)
                .offset(y: showCelebration ? 0 : 10)
                .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                // ボタン群
                VStack(spacing: 12) {
                    // もう1セットやるボタン
                    Button {
                        HapticManager.lightTap()
                        // 入力リセットしてStep 2に戻る
                        weightText = ""
                        repsText = ""
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentStep = .inputSet
                            showCelebration = false
                        }
                    } label: {
                        Text("もう1セットやる")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.mmOnboardingAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.mmOnboardingAccent, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                    // 次へ進むボタン
                    Button {
                        HapticManager.lightTap()
                        // セッション終了
                        finalizeSession()
                        onComplete()
                    } label: {
                        Text("次へ進む")
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
                }
                .padding(.horizontal, 24)
                .opacity(showCelebration ? 1 : 0)

                Spacer().frame(height: 48)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            // 祝福アニメーション
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showCelebration = true
                celebrationScale = 1.0
            }
            // グロー効果のパルス
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowOpacity = 0.6
            }
            // Haptic
            HapticManager.setRecorded()
        }
    }

    // MARK: - 筋肉マップ（刺激部位ハイライト）

    private func stimulatedMuscleMap(muscleMapping: [String: Int]) -> some View {
        // 前面と背面の筋肉で刺激度が高い方を自動判定
        let frontMuscles: Set<String> = [
            "chest_upper", "chest_lower", "deltoid_anterior", "deltoid_lateral",
            "biceps", "rectus_abdominis", "obliques", "quadriceps",
            "adductors", "hip_flexors"
        ]
        let backMuscles: Set<String> = [
            "lats", "traps_upper", "traps_middle_lower", "erector_spinae",
            "deltoid_posterior", "triceps", "glutes", "hamstrings",
            "gastrocnemius", "soleus"
        ]

        let frontScore = muscleMapping.filter { frontMuscles.contains($0.key) }.values.reduce(0, +)
        let backScore = muscleMapping.filter { backMuscles.contains($0.key) }.values.reduce(0, +)
        let showFront = frontScore >= backScore

        // MuscleVisualState マップを構築（刺激された部位は疲労色 = 赤く光る）
        var muscleStates: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if let intensity = muscleMapping[muscle.rawValue] {
                // 刺激度に応じて回復進捗を0.0〜0.15に（赤に近い色で「鍛えた直後」を表現）
                let progress = max(0.0, min(0.15, Double(intensity) / 1000.0))
                muscleStates[muscle] = .recovering(progress: progress)
            } else {
                muscleStates[muscle] = .inactive
            }
        }

        return GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let muscles = showFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let state = muscleStates[entry.muscle] ?? .inactive
                    let isStimulated = state != .inactive

                    entry.path(rect)
                        .fill(state.color)
                        .overlay {
                            entry.path(rect)
                                .stroke(
                                    isStimulated
                                        ? Color.mmMuscleFatigued.opacity(0.8)
                                        : Color.mmOnboardingTextSub.opacity(0.2),
                                    lineWidth: isStimulated ? 1.5 : 0.5
                                )
                        }
                        .shadow(
                            color: isStimulated ? Color.mmMuscleFatigued.opacity(0.5) : .clear,
                            radius: isStimulated ? 10 : 0
                        )
                }
            }
        }
        .aspectRatio(0.5, contentMode: .fit)
        .padding(.horizontal, 40)
    }

    // MARK: - データ保存ロジック

    private var isInputValid: Bool {
        guard let weight = Double(weightText), weight > 0,
              let reps = Int(repsText), reps > 0 else {
            return false
        }
        return true
    }

    private func recordSet() {
        guard let exercise = selectedExercise,
              let weight = Double(weightText), weight > 0,
              let reps = Int(repsText), reps > 0 else { return }

        // セッションが未作成なら新規作成
        if currentSession == nil {
            let session = WorkoutSession()
            modelContext.insert(session)
            currentSession = session
        }

        guard let session = currentSession else { return }

        recordedSets += 1

        // WorkoutSet を作成・保存
        let workoutSet = WorkoutSet(
            session: session,
            exerciseId: exercise.exerciseId,
            setNumber: recordedSets,
            weight: weight,
            reps: reps
        )
        modelContext.insert(workoutSet)
        session.sets.append(workoutSet)

        // MuscleStimulation を記録
        if let definition = ExerciseStore.shared.exercise(for: exercise.exerciseId) {
            let muscleRepo = MuscleStateRepository(modelContext: modelContext)
            for (muscleRaw, intensity) in definition.muscleMapping {
                muscleRepo.upsertStimulation(
                    muscle: Muscle(rawValue: muscleRaw) ?? .chestUpper,
                    sessionId: session.id,
                    maxIntensity: Double(intensity) / 100.0,
                    totalSets: recordedSets,
                    saveImmediately: false
                )
            }
            muscleRepo.save()
        }

        // SwiftData保存
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[GuidedFirstWorkout] Failed to save set: \(error)")
            #endif
        }

        // Haptic + 完了画面へ遷移
        HapticManager.setCompleted()
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = .completion
        }
    }

    private func finalizeSession() {
        // セッション終了
        currentSession?.endDate = Date()
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[GuidedFirstWorkout] Failed to finalize session: \(error)")
            #endif
        }
        // 初回ワークアウト完了フラグ
        AppState.shared.hasCompletedFirstWorkout = true
    }
}

// MARK: - 人気種目定義

private enum PopularExercise: String, CaseIterable {
    case benchPress
    case squat
    case deadlift
    case pullUp
    case shoulderPress
    case dumbbellCurl

    var exerciseId: String {
        switch self {
        case .benchPress: return "barbell_bench_press"
        case .squat: return "barbell_back_squat"
        case .deadlift: return "deadlift"
        case .pullUp: return "pull_up"
        case .shoulderPress: return "dumbbell_shoulder_press"
        case .dumbbellCurl: return "dumbbell_curl"
        }
    }

    var localizedName: String {
        switch self {
        case .benchPress: return "ベンチプレス"
        case .squat: return "スクワット"
        case .deadlift: return "デッドリフト"
        case .pullUp: return "懸垂"
        case .shoulderPress: return "ショルダープレス"
        case .dumbbellCurl: return "ダンベルカール"
        }
    }

    var icon: String {
        switch self {
        case .benchPress: return "figure.strengthtraining.traditional"
        case .squat: return "figure.squats"
        case .deadlift: return "figure.deadlift"
        case .pullUp: return "figure.pull.up"
        case .shoulderPress: return "figure.arms.open"
        case .dumbbellCurl: return "dumbbell.fill"
        }
    }

    var categoryLabel: String {
        switch self {
        case .benchPress: return "胸"
        case .squat: return "脚"
        case .deadlift: return "背中"
        case .pullUp: return "背中"
        case .shoulderPress: return "肩"
        case .dumbbellCurl: return "腕"
        }
    }
}

// MARK: - 種目選択カード

private struct ExerciseCard: View {
    let exercise: PopularExercise
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? Color.mmOnboardingAccent.opacity(0.2)
                                : Color.mmOnboardingTextSub.opacity(0.1)
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: exercise.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(
                            isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub
                        )
                }

                // 種目名
                Text(exercise.localizedName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        isSelected ? Color.mmOnboardingTextMain : Color.mmOnboardingTextSub
                    )

                // カテゴリラベル
                Text(exercise.categoryLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mmOnboardingCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.mmOnboardingAccent : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 入力フィールド

private struct InputField: View {
    let label: String
    let unit: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .frame(width: 80, alignment: .leading)

            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)

                Text(unit)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    GuidedFirstWorkoutPage(onComplete: {})
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

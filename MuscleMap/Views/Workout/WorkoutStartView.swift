import SwiftUI
import SwiftData

// MARK: - ワークアウト開始画面（メニュー提案 → 種目選択 → セット記録）

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingExercisePicker = false
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    if vm.isSessionActive {
                        // セッション進行中
                        ActiveWorkoutView(viewModel: vm, showingExercisePicker: $showingExercisePicker)
                    } else {
                        // セッション未開始
                        WorkoutIdleView(
                            muscleStates: muscleStates,
                            onStart: {
                                vm.startOrResumeSession()
                            },
                            onSelectExercise: { exercise in
                                vm.startOrResumeSession()
                                vm.selectExercise(exercise)
                            }
                        )
                    }
                }
            }
            .navigationTitle(L10n.workout)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.workout)
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = WorkoutViewModel(modelContext: modelContext)
                }
                loadMuscleStates()
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    viewModel?.selectExercise(exercise)
                    showingExercisePicker = false
                }
            }
        }
    }

    private func loadMuscleStates() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        let stimulations = repo.fetchLatestStimulations()
        loadMuscleStates(from: stimulations)
    }

    private func loadMuscleStates(from stimulations: [Muscle: MuscleStimulation]) {
        var states: [Muscle: MuscleVisualState] = [:]

        for muscle in Muscle.allCases {
            if let stim = stimulations[muscle] {
                let status = RecoveryCalculator.recoveryStatus(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets
                )

                switch status {
                case .recovering(let progress):
                    states[muscle] = .recovering(progress: progress)
                case .fullyRecovered:
                    states[muscle] = .inactive
                case .neglected:
                    states[muscle] = .neglected(fast: false)
                case .neglectedSevere:
                    states[muscle] = .neglected(fast: true)
                }
            } else {
                states[muscle] = .inactive
            }
        }

        muscleStates = states
    }
}

// MARK: - セッション未開始

private struct WorkoutIdleView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onStart: () -> Void
    let onSelectExercise: (ExerciseDefinition) -> Void

    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var selectedMuscle: Muscle?
    @State private var showMuscleExercises = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var favoriteExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        return favorites.favoriteIds.compactMap { store.exercise(for: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 筋肉マップ（タップで種目選択）
                    MuscleMapView(
                        muscleStates: muscleStates,
                        onMuscleTapped: { muscle in
                            selectedMuscle = muscle
                            showMuscleExercises = true
                        }
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .padding(.horizontal)

                    // お気に入り種目
                    if !favoriteExercises.isEmpty {
                        FavoriteExercisesSection(
                            exercises: favoriteExercises,
                            onSelect: onSelectExercise
                        )
                    }
                }
                .padding(.vertical)
            }

            // 開始ボタン（固定）
            Button(action: onStart) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text(L10n.startFreeWorkout)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showMuscleExercises) {
            if let muscle = selectedMuscle {
                MuscleExercisePickerSheet(muscle: muscle) { exercise in
                    onSelectExercise(exercise)
                    showMuscleExercises = false
                }
            }
        }
    }
}

// MARK: - お気に入り種目セクション

private struct FavoriteExercisesSection: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.yellow)
                Text(L10n.favoriteExercises)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        Button {
                            onSelect(exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Image(systemName: "dumbbell")
                                    Text(exercise.localizedEquipment)
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)

                                if let primary = exercise.primaryMuscle {
                                    Text(primary.localizedName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.mmAccentPrimary.opacity(0.15))
                                        .foregroundStyle(Color.mmAccentPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(width: 140, alignment: .leading)
                            .padding(12)
                            .background(Color.mmBgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 筋肉タップ時の種目選択シート

private struct MuscleExercisePickerSheet: View {
    let muscle: Muscle
    let onSelect: (ExerciseDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var relatedExercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if relatedExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        Text(L10n.noData)
                            .font(.headline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                } else {
                    List(relatedExercises) { exercise in
                        Button {
                            onSelect(exercise)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.mmTextPrimary)

                                    HStack(spacing: 8) {
                                        Label(exercise.localizedEquipment, systemImage: "dumbbell")
                                        Label(exercise.localizedDifficulty, systemImage: "chart.bar")
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(Color.mmTextSecondary)
                                }

                                Spacer()

                                // 刺激度%
                                let percentage = exercise.stimulationPercentage(for: muscle)
                                Text("\(percentage)%")
                                    .font(.subheadline.monospaced().bold())
                                    .foregroundStyle(stimulationColor(percentage))

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.mmBgCard)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(muscle.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func stimulationColor(_ percentage: Int) -> Color {
        switch percentage {
        case 80...: return .mmMuscleJustWorked
        case 50..<80: return .mmMuscleAmber
        default: return .mmMuscleLime
        }
    }
}

// MARK: - セッション進行中

private struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Binding var showingExercisePicker: Bool
    @State private var showingEndConfirm = false
    @State private var completedSession: WorkoutSession?
    @State private var showingCompletionView = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 選択中の種目のセット入力
                    if let exercise = viewModel.selectedExercise {
                        SetInputCard(viewModel: viewModel, exercise: exercise)
                    }

                    // 種目追加ボタン
                    Button {
                        showingExercisePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(L10n.addExercise)
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // 記録済みセット一覧
                    if !viewModel.exerciseSets.isEmpty {
                        RecordedSetsView(
                            exerciseSets: viewModel.exerciseSets,
                            onDeleteSet: { set in
                                viewModel.deleteSet(set)
                            }
                        )
                    }
                }
                .padding(.vertical)
            }

            // 終了ボタン
            Button {
                showingEndConfirm = true
            } label: {
                Text(L10n.endWorkout)
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.mmAccentPrimary)
            }
            .confirmationDialog(L10n.endWorkoutConfirm, isPresented: $showingEndConfirm, titleVisibility: .visible) {
                Button(L10n.saveAndEnd) {
                    // セッションを保存して完了画面を表示
                    if let session = viewModel.activeSession {
                        completedSession = session
                        viewModel.endSession()
                        HapticManager.workoutEnded()
                        showingCompletionView = true
                    }
                }
                Button(L10n.discardAndEnd, role: .destructive) {
                    viewModel.discardSession()
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showingCompletionView) {
                if let session = completedSession {
                    WorkoutCompletionView(session: session) {
                        showingCompletionView = false
                        completedSession = nil
                    }
                }
            }
        }
    }
}

// MARK: - セット入力カード

private struct SetInputCard: View {
    @Bindable var viewModel: WorkoutViewModel
    let exercise: ExerciseDefinition
    @Environment(\.modelContext) private var modelContext
    @State private var useAdditionalWeight = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var isBodyweight: Bool {
        exercise.equipment == "自重" || exercise.equipment == "Bodyweight"
    }

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.id, context: modelContext)
    }

    var body: some View {
        VStack(spacing: 16) {
            // 種目名
            Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // 前回記録
            if let lastW = viewModel.lastWeight, let lastR = viewModel.lastReps {
                if isBodyweight && lastW == 0 {
                    Text(L10n.previousRepsOnly(lastR))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                } else {
                    Text(L10n.previousRecord(lastW, lastR))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            // PR表示（前回記録と違う場合のみ）
            if let pr = prWeight, pr != viewModel.lastWeight, !isBodyweight {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("PR: \(pr, specifier: "%.1f")kg")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            // セット番号
            Text(L10n.setNumber(viewModel.currentSetNumber))
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmAccentSecondary)

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
                        viewModel.adjustWeight(by: -2.5)
                    } onLongPress: {
                        viewModel.adjustWeight(by: -0.25)
                    }

                    WeightInputView(
                        weight: $viewModel.currentWeight,
                        label: isBodyweight ? L10n.kgAdditional : L10n.kg
                    )
                    .frame(minWidth: 100)

                    WeightStepperButton(systemImage: "plus") {
                        viewModel.adjustWeight(by: 2.5)
                    } onLongPress: {
                        viewModel.adjustWeight(by: 0.25)
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
                viewModel.recordSet()
                HapticManager.setRecorded()
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
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - +/-ボタン

private struct StepperButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
            HapticManager.stepperChanged()
        } label: {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .foregroundStyle(Color.mmAccentPrimary)
                .frame(width: 60, height: 60)
                .background(Color.mmBgSecondary)
                .clipShape(Circle())
        }
    }
}

// MARK: - 重量入力ビュー（タップで直接入力可能）

private struct WeightInputView: View {
    @Binding var weight: Double
    let label: String

    @State private var isEditing = false
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 2) {
            if isEditing {
                TextField("", text: $inputText)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.mmTextPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onSubmit { finishEditing() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { finishEditing() }
                    }
            } else {
                Text("\(weight, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.mmTextPrimary)
                    .onTapGesture {
                        inputText = String(format: "%.2f", weight)
                        isEditing = true
                        isFocused = true
                        HapticManager.lightTap()
                    }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    private func finishEditing() {
        if let newWeight = Double(inputText.replacingOccurrences(of: ",", with: ".")) {
            weight = max(0, newWeight)
        }
        isEditing = false
    }
}

// MARK: - 重量用+/-ボタン（長押しで0.25kg刻み）

private struct WeightStepperButton: View {
    let systemImage: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2.bold())
            .foregroundStyle(Color.mmAccentPrimary)
            .frame(width: 60, height: 60)
            .background(Color.mmBgSecondary)
            .clipShape(Circle())
            .scaleEffect(isLongPressing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isLongPressing)
            .onTapGesture {
                onTap()
                HapticManager.stepperChanged()
            }
            .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                isLongPressing = pressing
                if pressing {
                    startLongPressTimer()
                } else {
                    stopLongPressTimer()
                }
            }, perform: {})
    }

    private func startLongPressTimer() {
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [onLongPress] _ in
            Task { @MainActor in
                onLongPress()
                HapticManager.lightTap()
            }
        }
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
}

// MARK: - 記録済みセット一覧

private struct RecordedSetsView: View {
    let exerciseSets: [(exercise: ExerciseDefinition, sets: [WorkoutSet])]
    let onDeleteSet: (WorkoutSet) -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    @State private var setToDelete: WorkoutSet?
    @State private var showingDeleteConfirm = false

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    /// セッション内で最大重量のセット（最初に出現したもののみ）
    private func isPRSet(_ set: WorkoutSet, in sets: [WorkoutSet]) -> Bool {
        guard set.weight > 0 else { return false }
        let maxWeight = sets.map(\.weight).max() ?? 0
        return set.weight == maxWeight &&
               sets.first(where: { $0.weight == maxWeight })?.id == set.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.recorded)
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .padding(.horizontal)

            ForEach(exerciseSets, id: \.exercise.id) { entry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(localization.currentLanguage == .japanese ? entry.exercise.nameJA : entry.exercise.nameEN)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    List {
                        ForEach(entry.sets, id: \.id) { set in
                            HStack {
                                Text(L10n.setNumber(set.setNumber))
                                    .font(.caption)
                                    .foregroundStyle(Color.mmTextSecondary)
                                Spacer()
                                if (entry.exercise.equipment == "自重" || entry.exercise.equipment == "Bodyweight") && set.weight == 0 {
                                    Text(L10n.repsOnly(set.reps))
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.mmTextPrimary)
                                } else {
                                    Text(L10n.weightReps(set.weight, set.reps))
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.mmTextPrimary)
                                }
                                // PRマーク（セッション内最大重量）
                                if isPRSet(set, in: entry.sets) {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                                Text(timeFormatter.string(from: set.completedAt))
                                    .font(.caption2)
                                    .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                                    .padding(.leading, 8)
                            }
                            .listRowBackground(Color.mmBgCard)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    setToDelete = set
                                    showingDeleteConfirm = true
                                } label: {
                                    Label(L10n.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(height: CGFloat(entry.sets.count) * 44)
                }
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .confirmationDialog(
            L10n.deleteSetConfirm,
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let set = setToDelete {
                    onDeleteSet(set)
                    setToDelete = nil
                }
            }
            Button(L10n.cancel, role: .cancel) {
                setToDelete = nil
            }
        }
    }
}

#Preview {
    WorkoutStartView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

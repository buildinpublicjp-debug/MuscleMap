import SwiftUI
import SwiftData

// MARK: - ワークアウト開始画面（メニュー提案 → 種目選択 → セット記録）

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingExercisePicker = false
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]

    // 完了画面用の状態（親ビューで管理してビュー遷移後も維持）
    @State private var completedSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    if vm.isSessionActive {
                        // セッション進行中
                        ActiveWorkoutView(
                            viewModel: vm,
                            showingExercisePicker: $showingExercisePicker,
                            onWorkoutCompleted: { session in
                                vm.endSession()
                                HapticManager.workoutEnded()
                                completedSession = session
                            }
                        )
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
                handlePendingRoutineDay()
                handlePendingExercise()
                handlePendingRecommendation()
            }
            .onChange(of: RoutineManager.shared.pendingStartDay?.id) {
                handlePendingRoutineDay()
            }
            .onChange(of: AppState.shared.pendingExerciseId) {
                handlePendingExercise()
            }
            .onChange(of: AppState.shared.pendingRecommendationTrigger) {
                handlePendingRecommendation()
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    viewModel?.selectExercise(exercise)
                    showingExercisePicker = false
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L10n.done) {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .fullScreenCover(item: $completedSession) { session in
                WorkoutCompletionView(session: session) {
                    completedSession = nil
                    loadMuscleStates() // 筋肉状態を更新
                }
            }
        }
    }

    /// ルーティンモードでワークアウト開始（HomeViewから遷移）
    private func handlePendingRoutineDay() {
        guard let pendingDay = RoutineManager.shared.pendingStartDay,
              let vm = viewModel else { return }
        RoutineManager.shared.pendingStartDay = nil
        vm.startWithRoutine(day: pendingDay)
    }

    /// 種目詳細画面から遷移してきた場合、セッション開始 + 種目選択
    private func handlePendingExercise() {
        guard let exerciseId = AppState.shared.pendingExerciseId,
              let vm = viewModel,
              let exercise = ExerciseStore.shared.exercise(for: exerciseId) else { return }
        AppState.shared.pendingExerciseId = nil
        vm.startOrResumeSession()
        vm.selectExercise(exercise)
    }

    /// メニュー自動提案からの遷移: セッション開始 + 提案種目を自動セット
    private func handlePendingRecommendation() {
        guard let exercises = AppState.shared.pendingRecommendedExercises,
              !exercises.isEmpty,
              let vm = viewModel else { return }
        AppState.shared.pendingRecommendedExercises = nil
        vm.startOrResumeSession()
        vm.applyRecommendedExercises(exercises)
        AppState.shared.pendingRecommendationTrigger = nil
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

// MARK: - セッション未開始時および実行中のコンポーネントは別ファイルに分割
// - WorkoutIdleComponents.swift: WorkoutIdleView, RecentExercisesSection, MuscleExercisePickerSheet
// - ActiveWorkoutComponents.swift: ActiveWorkoutView, SetEditSheet, EmptyWorkoutGuidance
// - SetInputComponents.swift: SetInputCard, PRCelebrationOverlay
// - WorkoutTimerComponents.swift: RestTimerView, CompactTimerBadge
// - WorkoutInputHelpers.swift: StepperButton, WeightInputView, WeightStepperButton
// - RecordedSetsComponents.swift: RecordedSetsView

#Preview {
    WorkoutStartView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

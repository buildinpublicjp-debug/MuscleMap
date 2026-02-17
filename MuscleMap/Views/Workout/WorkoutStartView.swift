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
    @State private var showingCompletionView = false

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
                                completedSession = session
                                vm.endSession()
                                HapticManager.workoutEnded()
                                showingCompletionView = true
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
            .fullScreenCover(isPresented: $showingCompletionView) {
                if let session = completedSession {
                    WorkoutCompletionView(session: session) {
                        showingCompletionView = false
                        completedSession = nil
                        loadMuscleStates() // 筋肉状態を更新
                    }
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

// MARK: - セッション未開始時および実行中のコンポーネントは別ファイルに分割
// - WorkoutIdleComponents.swift: WorkoutIdleView, FavoriteExercisesSection, MuscleExercisePickerSheet
// - ActiveWorkoutComponents.swift: ActiveWorkoutView, SetEditSheet, EmptyWorkoutGuidance
// - SetInputComponents.swift: SetInputCard, PRCelebrationOverlay
// - WorkoutTimerComponents.swift: RestTimerView, CompactTimerBadge
// - WorkoutInputHelpers.swift: StepperButton, WeightInputView, WeightStepperButton
// - RecordedSetsComponents.swift: RecordedSetsView

#Preview {
    WorkoutStartView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

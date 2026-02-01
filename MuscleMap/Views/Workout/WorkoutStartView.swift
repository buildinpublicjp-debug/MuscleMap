import SwiftUI
import SwiftData

// MARK: - ワークアウト開始画面（メニュー提案 → 種目選択 → セット記録）

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingExercisePicker = false
    @State private var suggestedMenu: SuggestedMenu?

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
                            suggestedMenu: suggestedMenu,
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
            .navigationTitle("ワークアウト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ワークアウト")
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = WorkoutViewModel(modelContext: modelContext)
                }
                loadSuggestion()
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    viewModel?.selectExercise(exercise)
                    showingExercisePicker = false
                }
            }
        }
    }

    private func loadSuggestion() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        let stims = repo.fetchLatestStimulations()
        suggestedMenu = MenuSuggestionService.suggestTodayMenu(
            stimulations: stims,
            exerciseStore: ExerciseStore.shared
        )
    }
}

// MARK: - セッション未開始

private struct WorkoutIdleView: View {
    let suggestedMenu: SuggestedMenu?
    let onStart: () -> Void
    let onSelectExercise: (ExerciseDefinition) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 今日の提案
                if let menu = suggestedMenu, !menu.exercises.isEmpty {
                    SuggestedMenuCard(menu: menu, onSelectExercise: onSelectExercise)
                }

                // 開始ボタン
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                        Text("自由にトレーニング開始")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - 提案メニューカード

private struct SuggestedMenuCard: View {
    let menu: SuggestedMenu
    let onSelectExercise: (ExerciseDefinition) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.mmAccentPrimary)
                Text("今日のおすすめ: \(menu.primaryGroup.japaneseName)")
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }

            Text(menu.reason)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)

            // 種目リスト
            ForEach(menu.exercises) { exercise in
                Button {
                    onSelectExercise(exercise.definition)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.definition.nameJA)
                                .font(.subheadline)
                                .foregroundStyle(Color.mmTextPrimary)
                            Text("\(exercise.suggestedSets)セット × \(exercise.suggestedReps)レップ")
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }

                        Spacer()

                        if exercise.isNeglectedFix {
                            Text("未刺激")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mmMuscleNeglected.opacity(0.2))
                                .foregroundStyle(Color.mmMuscleNeglected)
                                .clipShape(Capsule())
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - セッション進行中

private struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Binding var showingExercisePicker: Bool
    @State private var showingEndConfirm = false

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
                            Text("種目を追加")
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
                        RecordedSetsView(exerciseSets: viewModel.exerciseSets)
                    }
                }
                .padding(.vertical)
            }

            // 終了ボタン
            Button {
                showingEndConfirm = true
            } label: {
                Text("ワークアウト終了")
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.mmAccentPrimary)
            }
            .confirmationDialog("ワークアウトを終了しますか？", isPresented: $showingEndConfirm) {
                Button("終了する") {
                    viewModel.endSession()
                    HapticManager.workoutEnded()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}

// MARK: - セット入力カード

private struct SetInputCard: View {
    @Bindable var viewModel: WorkoutViewModel
    let exercise: ExerciseDefinition

    var body: some View {
        VStack(spacing: 16) {
            // 種目名
            Text(exercise.nameJA)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // 前回記録
            if let lastW = viewModel.lastWeight, let lastR = viewModel.lastReps {
                Text("前回: \(lastW, specifier: "%.1f")kg × \(lastR)回")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // セット番号
            Text("セット \(viewModel.currentSetNumber)")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmAccentSecondary)

            // 重量入力
            HStack(spacing: 16) {
                StepperButton(systemImage: "minus") {
                    viewModel.adjustWeight(by: -2.5)
                }

                VStack(spacing: 2) {
                    Text("\(viewModel.currentWeight, specifier: "%.1f")")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.mmTextPrimary)
                    Text("kg")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .frame(minWidth: 100)

                StepperButton(systemImage: "plus") {
                    viewModel.adjustWeight(by: 2.5)
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
                    Text("回")
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
                Text("セットを記録")
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

// MARK: - 記録済みセット一覧

private struct RecordedSetsView: View {
    let exerciseSets: [(exercise: ExerciseDefinition, sets: [WorkoutSet])]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記録済み")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .padding(.horizontal)

            ForEach(exerciseSets, id: \.exercise.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.exercise.nameJA)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)

                    ForEach(entry.sets, id: \.id) { set in
                        HStack {
                            Text("セット\(set.setNumber)")
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                            Spacer()
                            Text("\(set.weight, specifier: "%.1f")kg × \(set.reps)回")
                                .font(.caption.monospaced())
                                .foregroundStyle(Color.mmTextPrimary)
                        }
                    }
                }
                .padding()
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    WorkoutStartView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

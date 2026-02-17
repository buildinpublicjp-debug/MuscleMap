import SwiftUI
import SwiftData

// MARK: - ワークアウト実行中のコンポーネント

/// ワークアウト実行中のメインビュー
struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Binding var showingExercisePicker: Bool
    let onWorkoutCompleted: (WorkoutSession) -> Void

    @State private var showingEndConfirm = false
    @State private var editingSet: WorkoutSet?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 選択中の種目のセット入力
                    if let exercise = viewModel.selectedExercise {
                        // 戻るボタン
                        HStack {
                            Button {
                                viewModel.selectedExercise = nil
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text(L10n.selectExercise)
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.mmAccentPrimary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

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

                    // 空状態のガイダンス（種目未選択かつセット未記録）
                    if viewModel.selectedExercise == nil && viewModel.exerciseSets.isEmpty {
                        EmptyWorkoutGuidance {
                            showingExercisePicker = true
                        }
                    }

                    // 記録済みセット一覧
                    if !viewModel.exerciseSets.isEmpty {
                        RecordedSetsView(
                            exerciseSets: viewModel.exerciseSets,
                            onSelectExercise: { exercise in
                                viewModel.selectExercise(exercise)
                            },
                            onEditSet: { set in
                                editingSet = set
                            },
                            onDeleteSet: { set in
                                viewModel.deleteSet(set)
                            }
                        )
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 16)
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
                    // セッションを親ビューに渡して完了画面を表示
                    if let session = viewModel.activeSession {
                        onWorkoutCompleted(session)
                    }
                }
                Button(L10n.discardAndEnd, role: .destructive) {
                    viewModel.discardSession()
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .onChange(of: scenePhase) { _, newPhase in
                // バックグラウンドから復帰時にタイマーを補正
                if newPhase == .active {
                    viewModel.recalculateRestTimerAfterBackground()
                }
            }
            .sheet(item: $editingSet) { set in
                SetEditSheet(
                    workoutSet: set,
                    onSave: { weight, reps in
                        set.weight = weight
                        set.reps = reps
                        editingSet = nil
                    },
                    onCancel: {
                        editingSet = nil
                    }
                )
                .presentationDetents([.height(280)])
            }
        }
    }
}

// MARK: - セット編集シート

struct SetEditSheet: View {
    let workoutSet: WorkoutSet
    let onSave: (Double, Int) -> Void
    let onCancel: () -> Void

    @State private var editWeight: Double
    @State private var editReps: Int

    init(workoutSet: WorkoutSet, onSave: @escaping (Double, Int) -> Void, onCancel: @escaping () -> Void) {
        self.workoutSet = workoutSet
        self.onSave = onSave
        self.onCancel = onCancel
        _editWeight = State(initialValue: workoutSet.weight)
        _editReps = State(initialValue: workoutSet.reps)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 重量入力
                VStack(spacing: 8) {
                    Text(L10n.kg)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    HStack(spacing: 16) {
                        Button {
                            editWeight = max(0, editWeight - 2.5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                        Text(String(format: "%.2f", editWeight))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.mmTextPrimary)
                            .frame(minWidth: 100)
                        Button {
                            editWeight += 2.5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                }

                // レップ数入力
                VStack(spacing: 8) {
                    Text(L10n.reps)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    HStack(spacing: 16) {
                        Button {
                            editReps = max(1, editReps - 1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                        Text("\(editReps)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.mmTextPrimary)
                            .frame(minWidth: 60)
                        Button {
                            editReps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.top, 24)
            .background(Color.mmBgSecondary)
            .navigationTitle(L10n.editSet)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) {
                        onCancel()
                    }
                    .foregroundStyle(Color.mmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.save) {
                        HapticManager.lightTap()
                        onSave(editWeight, editReps)
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - 空状態のガイダンス

struct EmptyWorkoutGuidance: View {
    let onAddExercise: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            // アイコン
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))

            // メインテキスト
            Text(L10n.emptyWorkoutTitle)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // サブテキスト
            Text(L10n.emptyWorkoutHint)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // 種目追加ボタン（目立つバージョン）
            Button(action: onAddExercise) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.addFirstExercise)
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.mmAccentPrimary)
                .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

//#Preview("Active Workout") {
//    // Preview requires full app context
//}

#Preview("Empty Guidance") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        EmptyWorkoutGuidance {
            print("Add exercise tapped")
        }
    }
}

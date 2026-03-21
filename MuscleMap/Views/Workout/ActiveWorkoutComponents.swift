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
                    // ルーティン進捗バー（ルーティンモード時のみ）
                    if let routineDay = viewModel.activeRoutineDay {
                        RoutineProgressBar(
                            day: routineDay,
                            completion: viewModel.routineExerciseCompletion,
                            currentExerciseId: viewModel.selectedExercise?.id,
                            onExerciseTap: { exerciseId in
                                if let def = ExerciseStore.shared.exercise(for: exerciseId) {
                                    viewModel.selectExercise(def)
                                    HapticManager.lightTap()
                                }
                            }
                        )
                        .padding(.horizontal)
                    }

                    // 選択中の種目のセット入力
                    if let exercise = viewModel.selectedExercise {
                        // 戻るボタン
                        HStack {
                            Button {
                                HapticManager.lightTap()
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
                        HapticManager.lightTap()
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
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    // ルーティン完了メッセージ
                    if viewModel.isRoutineComplete {
                        RoutineCompleteCard()
                            .padding(.horizontal)
                    }

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
                HapticManager.lightTap()
                showingEndConfirm = true
            } label: {
                Text(L10n.endWorkout)
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.mmAccentPrimary)
            }
            .buttonStyle(.plain)
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
                            HapticManager.stepperChanged()
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
                            HapticManager.stepperChanged()
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
                            HapticManager.stepperChanged()
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
                            HapticManager.stepperChanged()
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

// MARK: - ルーティン進捗バー

struct RoutineProgressBar: View {
    let day: RoutineDay
    let completion: [String: Bool]
    let currentExerciseId: String?
    let onExerciseTap: (String) -> Void

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var completedCount: Int {
        day.exercises.filter { completion[$0.exerciseId] == true }.count
    }

    private var totalCount: Int {
        day.exercises.count
    }

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー: Day名 + 進捗カウント
            HStack {
                Text(day.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

                Spacer()

                Text(isJapanese
                    ? "\(completedCount)/\(totalCount) 種目完了"
                    : "\(completedCount)/\(totalCount) done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            // 種目チップ（横スクロール）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(day.exercises) { routineEx in
                        let isDone = completion[routineEx.exerciseId] == true
                        let isCurrent = routineEx.exerciseId == currentExerciseId
                        let def = ExerciseStore.shared.exercise(for: routineEx.exerciseId)
                        let name = def?.localizedName ?? routineEx.exerciseId

                        Button {
                            onExerciseTap(routineEx.exerciseId)
                        } label: {
                            HStack(spacing: 4) {
                                // GIFサムネイル（丸）
                                if ExerciseGifView.hasGif(exerciseId: routineEx.exerciseId) {
                                    ExerciseGifView(exerciseId: routineEx.exerciseId, size: .thumbnail)
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                }

                                // ステータスアイコン + 名前
                                if isDone {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.mmAccentPrimary)
                                } else if isCurrent {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(Color.mmAccentPrimary)
                                } else {
                                    Circle()
                                        .stroke(Color.mmTextSecondary.opacity(0.4), lineWidth: 1.5)
                                        .frame(width: 10, height: 10)
                                }

                                Text(name)
                                    .font(.system(size: 11, weight: isDone || isCurrent ? .bold : .medium))
                                    .foregroundStyle(
                                        isDone ? Color.mmAccentPrimary :
                                        isCurrent ? Color.mmTextPrimary :
                                        Color.mmTextSecondary
                                    )
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                isCurrent ? Color.mmAccentPrimary.opacity(0.2) :
                                isDone ? Color.mmAccentPrimary.opacity(0.08) :
                                Color.mmBgSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isCurrent ? Color.mmAccentPrimary : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(isCurrent ? 1.05 : 1.0)
                            .opacity(isDone ? 0.7 : isCurrent ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 0.2), value: isCurrent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.mmBgSecondary)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.mmAccentPrimary)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ルーティン完了カード

struct RoutineCompleteCard: View {
    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.mmAccentPrimary)
            Text(isJapanese ? "ルーティン完了!" : "Routine Complete!")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)
            Text(isJapanese
                ? "追加で種目を記録するか、ワークアウトを終了できます"
                : "Add more exercises or finish your workout")
                .font(.system(size: 12))
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.mmAccentPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

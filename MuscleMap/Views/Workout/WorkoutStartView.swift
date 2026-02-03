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

    @ObservedObject private var favorites = FavoritesManager.shared

    private var favoriteExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        return favorites.favoriteIds.compactMap { store.exercise(for: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 今日の提案
                if let menu = suggestedMenu, !menu.exercises.isEmpty {
                    SuggestedMenuCard(menu: menu, onSelectExercise: onSelectExercise)
                }

                // お気に入り種目
                if !favoriteExercises.isEmpty {
                    FavoriteExercisesSection(
                        exercises: favoriteExercises,
                        onSelect: onSelectExercise
                    )
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

// MARK: - お気に入り種目セクション

private struct FavoriteExercisesSection: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.yellow)
                Text("お気に入り種目")
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
                                Text(exercise.nameJA)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Image(systemName: "dumbbell")
                                    Text(exercise.equipment)
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)

                                if let primary = exercise.primaryMuscle {
                                    Text(primary.japaneseName)
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

// MARK: - 提案メニューカード

private struct SuggestedMenuCard: View {
    let menu: SuggestedMenu
    let onSelectExercise: (ExerciseDefinition) -> Void

    /// 推奨筋肉群のマッピングを生成
    private var groupMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        for muscle in menu.primaryGroup.muscles {
            mapping[muscle.rawValue] = 80
        }
        // ペアグループの筋肉も低めに追加
        let paired = MenuSuggestionService.pairedGroups(for: menu.primaryGroup)
        for group in paired where group != menu.primaryGroup {
            for muscle in group.muscles {
                if mapping[muscle.rawValue] == nil {
                    mapping[muscle.rawValue] = 40
                }
            }
        }
        return mapping
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー + ミニボディマップ
            HStack(alignment: .top, spacing: 12) {
                // ミニボディマップ
                ExerciseMuscleMapView(muscleMapping: groupMuscleMapping)
                    .frame(width: 100, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // テキスト情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text("今日のおすすめ")
                            .font(.headline)
                            .foregroundStyle(Color.mmTextPrimary)
                    }

                    Text(menu.primaryGroup.japaneseName)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmAccentPrimary)

                    Text(menu.reason)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .overlay(Color.mmBgSecondary)

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
                Text("ワークアウト終了")
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.mmAccentPrimary)
            }
            .confirmationDialog("ワークアウトを終了しますか？", isPresented: $showingEndConfirm, titleVisibility: .visible) {
                Button("記録を保存して終了") {
                    viewModel.endSession()
                    HapticManager.workoutEnded()
                }
                Button("記録を破棄して終了", role: .destructive) {
                    viewModel.discardSession()
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
    @State private var useAdditionalWeight = false

    private var isBodyweight: Bool {
        exercise.equipment == "自重"
    }

    var body: some View {
        VStack(spacing: 16) {
            // 種目名
            Text(exercise.nameJA)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // 前回記録
            if let lastW = viewModel.lastWeight, let lastR = viewModel.lastReps {
                if isBodyweight && lastW == 0 {
                    Text("前回: \(lastR)回")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                } else {
                    Text("前回: \(lastW, specifier: "%.1f")kg × \(lastR)回")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            // セット番号
            Text("セット \(viewModel.currentSetNumber)")
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
                        Text("前回\(lastW, specifier: "%.1f")kg → \(suggested, specifier: "%.1f")kgに挑戦？")
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
                    Text("自重")
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextSecondary)
                        .padding(.vertical, 8)
                }

                // 加重トグル
                Toggle(isOn: $useAdditionalWeight) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                        Text("加重する")
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
                    StepperButton(systemImage: "minus") {
                        viewModel.adjustWeight(by: -2.5)
                    }

                    VStack(spacing: 2) {
                        Text("\(viewModel.currentWeight, specifier: "%.1f")")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(isBodyweight ? "kg (加重)" : "kg")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .frame(minWidth: 100)

                    StepperButton(systemImage: "plus") {
                        viewModel.adjustWeight(by: 2.5)
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
    let onDeleteSet: (WorkoutSet) -> Void

    @State private var setToDelete: WorkoutSet?
    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記録済み")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .padding(.horizontal)

            ForEach(exerciseSets, id: \.exercise.id) { entry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.exercise.nameJA)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    List {
                        ForEach(entry.sets, id: \.id) { set in
                            HStack {
                                Text("セット\(set.setNumber)")
                                    .font(.caption)
                                    .foregroundStyle(Color.mmTextSecondary)
                                Spacer()
                                if entry.exercise.equipment == "自重" && set.weight == 0 {
                                    Text("\(set.reps)回")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.mmTextPrimary)
                                } else {
                                    Text("\(set.weight, specifier: "%.1f")kg × \(set.reps)回")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.mmTextPrimary)
                                }
                            }
                            .listRowBackground(Color.mmBgCard)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    setToDelete = set
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("削除", systemImage: "trash")
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
            "このセットを削除しますか？",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                if let set = setToDelete {
                    onDeleteSet(set)
                    setToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                setToDelete = nil
            }
        }
    }
}

#Preview {
    WorkoutStartView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

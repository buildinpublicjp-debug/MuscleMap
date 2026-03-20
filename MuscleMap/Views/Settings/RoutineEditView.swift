import SwiftUI

// MARK: - ルーティン編集画面（設定画面から遷移）

struct RoutineEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var days: [RoutineDay] = []
    @State private var selectedDayIndex: Int = 0
    @State private var showingExercisePicker = false
    @State private var editingExercise: RoutineExercise?
    @State private var hasChanges = false

    /// 1日あたりの最大種目数
    private let maxExercisesPerDay = 8

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            if days.isEmpty {
                // ルーティン未設定時（通常は到達しない）
                ContentUnavailableView(
                    "ルーティンがありません",
                    systemImage: "list.bullet.clipboard",
                    description: Text("オンボーディングでルーティンを作成してください")
                )
            } else {
                VStack(spacing: 0) {
                    // Day タブバー
                    dayTabBar
                        .padding(.top, 8)

                    // 種目カウンター + 追加ボタン
                    if days.indices.contains(selectedDayIndex) {
                        exerciseHeader
                    }

                    // 種目リスト
                    if days.indices.contains(selectedDayIndex) {
                        exerciseList
                    }
                }
            }
        }
        .navigationTitle("マイルーティン")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            days = RoutineManager.shared.routine.days
        }
        .sheet(isPresented: $showingExercisePicker) {
            if days.indices.contains(selectedDayIndex) {
                RoutineEditExercisePickerSheet(
                    day: days[selectedDayIndex],
                    maxExercises: maxExercisesPerDay,
                    onAdd: { exercise in
                        addExercise(exercise)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.mmBgSecondary)
            }
        }
        .sheet(item: $editingExercise) { routineExercise in
            RoutineExerciseEditSheet(
                routineExercise: routineExercise,
                onSave: { updated in
                    updateExercise(updated)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.mmBgSecondary)
        }
    }

    // MARK: - Day タブバー

    private var dayTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDayIndex = index
                        }
                        HapticManager.lightTap()
                    } label: {
                        VStack(spacing: 4) {
                            Text("Day \(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                            Text(days[index].name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            selectedDayIndex == index
                                ? Color.mmBgPrimary
                                : Color.mmTextPrimary
                        )
                        .frame(minWidth: 72)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            selectedDayIndex == index
                                ? Color.mmAccentPrimary
                                : Color.mmBgCard
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 種目ヘッダー（カウンター + 追加ボタン）

    private var exerciseHeader: some View {
        HStack {
            Text(L10n.routineExerciseCount(days[selectedDayIndex].exercises.count, maxExercisesPerDay))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)

            Spacer()

            if days[selectedDayIndex].exercises.count < maxExercisesPerDay {
                Button {
                    showingExercisePicker = true
                    HapticManager.lightTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text(L10n.routineAddExercise)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mmAccentPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 種目リスト

    private var exerciseList: some View {
        List {
            ForEach(days[selectedDayIndex].exercises) { routineExercise in
                if let def = ExerciseStore.shared.exercise(for: routineExercise.exerciseId) {
                    Button {
                        editingExercise = routineExercise
                    } label: {
                        RoutineEditExerciseRow(exercise: def, routineExercise: routineExercise)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.mmBgCard)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .onDelete { indexSet in
                deleteExercises(at: indexSet)
            }
            .onMove { from, to in
                moveExercises(from: from, to: to)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - アクション

    private func addExercise(_ exerciseDef: ExerciseDefinition) {
        guard days.indices.contains(selectedDayIndex),
              days[selectedDayIndex].exercises.count < maxExercisesPerDay else { return }
        guard !days[selectedDayIndex].exercises.contains(where: { $0.exerciseId == exerciseDef.id }) else { return }

        days[selectedDayIndex].exercises.append(
            RoutineExercise(
                exerciseId: exerciseDef.id,
                suggestedSets: 3,
                suggestedReps: 10
            )
        )
        saveRoutine()
        HapticManager.lightTap()
    }

    private func deleteExercises(at offsets: IndexSet) {
        guard days.indices.contains(selectedDayIndex) else { return }
        days[selectedDayIndex].exercises.remove(atOffsets: offsets)
        saveRoutine()
        HapticManager.lightTap()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        guard days.indices.contains(selectedDayIndex) else { return }
        days[selectedDayIndex].exercises.move(fromOffsets: source, toOffset: destination)
        saveRoutine()
    }

    private func updateExercise(_ updated: RoutineExercise) {
        guard days.indices.contains(selectedDayIndex),
              let idx = days[selectedDayIndex].exercises.firstIndex(where: { $0.id == updated.id }) else { return }
        days[selectedDayIndex].exercises[idx] = updated
        saveRoutine()
    }

    private func saveRoutine() {
        let routine = UserRoutine(days: days, createdAt: RoutineManager.shared.routine.createdAt)
        RoutineManager.shared.saveRoutine(routine)
    }
}

// MARK: - 種目行

private struct RoutineEditExerciseRow: View {
    let exercise: ExerciseDefinition
    let routineExercise: RoutineExercise

    var body: some View {
        HStack(spacing: 12) {
            // GIF 100x100
            exerciseThumbnail

            // 種目名 + 器具 + セット×レップ
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.localizedName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(2)

                Text(exercise.localizedEquipment)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                Text("\(routineExercise.suggestedSets)×\(routineExercise.suggestedReps)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var exerciseThumbnail: some View {
        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
            ExerciseGifView(exerciseId: exercise.id, size: .previewCard)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.mmBgSecondary)
                    .frame(width: 100, height: 100)
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
            }
        }
    }
}

// MARK: - セット・レップ編集シート

private struct RoutineExerciseEditSheet: View {
    let routineExercise: RoutineExercise
    let onSave: (RoutineExercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sets: Int = 3
    @State private var reps: Int = 10

    private var exerciseName: String {
        ExerciseStore.shared.exercise(for: routineExercise.exerciseId)?.localizedName ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // 種目名
                    Text(exerciseName)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .padding(.top, 16)

                    // セット数
                    VStack(spacing: 8) {
                        Text("セット数")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                        HStack(spacing: 16) {
                            Button {
                                if sets > 1 { sets -= 1; HapticManager.lightTap() }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(sets > 1 ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            }
                            .disabled(sets <= 1)

                            Text("\(sets)")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundStyle(Color.mmTextPrimary)
                                .frame(width: 60)

                            Button {
                                if sets < 10 { sets += 1; HapticManager.lightTap() }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(sets < 10 ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            }
                            .disabled(sets >= 10)
                        }
                    }

                    // レップ数
                    VStack(spacing: 8) {
                        Text("レップ数")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                        HStack(spacing: 16) {
                            Button {
                                if reps > 1 { reps -= 1; HapticManager.lightTap() }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(reps > 1 ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            }
                            .disabled(reps <= 1)

                            Text("\(reps)")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundStyle(Color.mmTextPrimary)
                                .frame(width: 60)

                            Button {
                                if reps < 30 { reps += 1; HapticManager.lightTap() }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(reps < 30 ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            }
                            .disabled(reps >= 30)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("セット・レップ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) { dismiss() }
                        .foregroundStyle(Color.mmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.save) {
                        var updated = routineExercise
                        updated.suggestedSets = sets
                        updated.suggestedReps = reps
                        onSave(updated)
                        HapticManager.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                sets = routineExercise.suggestedSets
                reps = routineExercise.suggestedReps
            }
        }
    }
}

// MARK: - 種目追加ピッカーシート

private struct RoutineEditExercisePickerSheet: View {
    let day: RoutineDay
    let maxExercises: Int
    let onAdd: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    /// 対象グループの種目
    private var targetExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        let groups = day.muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
        let targetGroupSet = Set(groups)
        var result: [ExerciseDefinition] = []
        var seen: Set<String> = []

        for group in groups {
            for muscle in group.muscles {
                for ex in store.exercises(targeting: muscle) {
                    if !seen.contains(ex.id) {
                        if let primary = ex.primaryMuscle,
                           targetGroupSet.contains(primary.group) {
                            seen.insert(ex.id)
                            result.append(ex)
                        }
                    }
                }
            }
        }

        // 場所フィルタ
        let location = AppState.shared.userProfile.trainingLocation
        if location == "home" {
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            let filtered = result.filter { homeEquipment.contains($0.equipment) }
            if !filtered.isEmpty { result = filtered }
        }

        return result
    }

    /// 検索フィルター適用済み
    private var filteredExercises: [ExerciseDefinition] {
        if searchText.isEmpty { return targetExercises }
        let query = searchText.lowercased()
        return targetExercises.filter {
            $0.localizedName.lowercased().contains(query) ||
            $0.nameEN.lowercased().contains(query)
        }
    }

    /// 既に追加済みの種目ID
    private var addedIds: Set<String> {
        Set(day.exercises.map { $0.exerciseId })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 検索バー
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.mmTextSecondary)
                    TextField("", text: $searchText, prompt: Text(L10n.searchExercises).foregroundColor(Color.mmTextSecondary))
                        .foregroundStyle(Color.mmTextPrimary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 種目リスト
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            let isAdded = addedIds.contains(exercise.id)
                            Button {
                                guard !isAdded else { return }
                                onAdd(exercise)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    // GIFサムネイル
                                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                        ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.mmBgSecondary)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "dumbbell.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.localizedName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.mmTextPrimary)
                                            .lineLimit(1)

                                        Text(exercise.equipment)
                                            .font(.caption)
                                            .foregroundStyle(Color.mmTextSecondary)
                                    }

                                    Spacer()

                                    if isAdded {
                                        Text(L10n.routineAlreadyAdded)
                                            .font(.caption)
                                            .foregroundStyle(Color.mmTextSecondary)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color.mmAccentPrimary)
                                    }
                                }
                                .padding(12)
                                .background(isAdded ? Color.mmBgCard.opacity(0.5) : Color.mmBgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .disabled(isAdded)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(L10n.routineAddExercise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) {
                        dismiss()
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoutineEditView()
    }
}

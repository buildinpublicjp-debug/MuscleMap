import SwiftUI
import SwiftData

// MARK: - マイルーティン画面（カタログ表示 + Dayカードタップで編集シート）

struct RoutineEditView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var days: [RoutineDay] = []
    @State private var selectedDay: RoutineDay?
    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            if days.isEmpty {
                ContentUnavailableView(
                    isJapanese ? "ルーティンがありません" : "No Routine",
                    systemImage: "list.bullet.clipboard",
                    description: Text(isJapanese ? "オンボーディングでルーティンを作成してください" : "Create a routine in onboarding")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                            DayCatalogCard(
                                day: day,
                                dayIndex: index,
                                modelContext: modelContext
                            )
                            .onTapGesture {
                                selectedDay = day
                                HapticManager.lightTap()
                            }
                        }

                        // + Dayを追加
                        Button {
                            addDay()
                            HapticManager.lightTap()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(isJapanese ? "Dayを追加" : "Add Day")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.mmAccentPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(isJapanese ? "マイルーティン" : "My Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    renderShareCard()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                .disabled(days.isEmpty)
            }
        }
        .onAppear {
            days = RoutineManager.shared.routine.days
        }
        .sheet(item: $selectedDay) { day in
            DayEditSheet(
                day: day,
                dayIndex: days.firstIndex(where: { $0.id == day.id }) ?? 0,
                onUpdate: { updatedDay in
                    if let idx = days.firstIndex(where: { $0.id == updatedDay.id }) {
                        days[idx] = updatedDay
                        saveRoutine()
                    }
                },
                onDelete: {
                    if let idx = days.firstIndex(where: { $0.id == day.id }) {
                        days.remove(at: idx)
                        saveRoutine()
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.mmBgSecondary)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [image, isJapanese ? "MuscleMap で作成したマイルーティン" : "My routine created with MuscleMap"])
            }
        }
    }

    // MARK: - アクション

    private func addDay() {
        let newDay = RoutineDay(
            name: isJapanese ? "新しいDay" : "New Day",
            muscleGroups: [],
            exercises: [],
            location: "gym"
        )
        days.append(newDay)
        saveRoutine()
        selectedDay = newDay
    }

    private func saveRoutine() {
        let routine = UserRoutine(days: days, createdAt: RoutineManager.shared.routine.createdAt)
        RoutineManager.shared.saveRoutine(routine)
    }

    // MARK: - シェアカード生成

    private func renderShareCard() {
        let card = RoutineShareCardContent(
            days: days,
            modelContext: modelContext
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            renderedImage = image
            showShareSheet = true
        }
    }
}

// MARK: - Dayカタログカード（メイン画面の各Dayカード）

private struct DayCatalogCard: View {
    let day: RoutineDay
    let dayIndex: Int
    let modelContext: ModelContext

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var muscleGroupNames: [String] {
        day.muscleGroups.compactMap { rawValue in
            guard let group = MuscleGroup(rawValue: rawValue) else { return nil }
            return isJapanese ? group.japaneseName : group.englishName
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー: Day番号 + 部位チップ
            HStack(spacing: 6) {
                Text("Day \(dayIndex + 1)")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                ForEach(muscleGroupNames, id: \.self) { name in
                    Text(name)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.mmAccentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // GIF横スクロール
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(day.exercises) { exercise in
                        RoutineExerciseCard(
                            exercise: exercise,
                            modelContext: modelContext
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - 種目GIFカード（各Dayカード内の横スクロール用）

private struct RoutineExerciseCard: View {
    let exercise: RoutineExercise
    let modelContext: ModelContext

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var exerciseName: String {
        guard let def = ExerciseStore.shared.exercise(for: exercise.exerciseId) else {
            return exercise.exerciseId
        }
        return isJapanese ? def.nameJA : def.nameEN
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // GIF
                if ExerciseGifView.hasGif(exerciseId: exercise.exerciseId) {
                    ExerciseGifView(exerciseId: exercise.exerciseId, size: .gridCard)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 100)
                        .background(Color.white)
                        .clipped()
                } else {
                    Color.mmBgCard
                        .frame(width: 110, height: 100)
                        .overlay(
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                        )
                }

                // 下部グラデーション + 種目名
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 35)

                Text(exerciseName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
            .frame(width: 110, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // セット×レップ
            Text("\(exercise.suggestedSets)×\(exercise.suggestedReps)")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmTextSecondary)
        }
    }
}

// MARK: - Day編集シート（タップで開く）

private struct DayEditSheet: View {
    let day: RoutineDay
    let dayIndex: Int
    let onUpdate: (RoutineDay) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedDay: RoutineDay
    @State private var showingExercisePicker = false
    @State private var replacingExerciseIndex: Int?
    @State private var showingRenameAlert = false
    @State private var newDayName = ""
    @State private var showingDeleteConfirm = false

    private let maxExercisesPerDay = 8

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var muscleGroupNames: String {
        editedDay.muscleGroups.compactMap { rawValue in
            guard let group = MuscleGroup(rawValue: rawValue) else { return nil }
            return isJapanese ? group.japaneseName : group.englishName
        }.joined(separator: " · ")
    }

    init(day: RoutineDay, dayIndex: Int, onUpdate: @escaping (RoutineDay) -> Void, onDelete: @escaping () -> Void) {
        self.day = day
        self.dayIndex = dayIndex
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedDay = State(initialValue: day)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgSecondary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 種目リスト
                        ForEach(Array(editedDay.exercises.enumerated()), id: \.element.id) { index, routineExercise in
                            if let def = ExerciseStore.shared.exercise(for: routineExercise.exerciseId) {
                                DayEditExerciseRow(
                                    exercise: def,
                                    routineExercise: routineExercise,
                                    onReplace: {
                                        replacingExerciseIndex = index
                                        showingExercisePicker = true
                                        HapticManager.lightTap()
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        editedDay.exercises.remove(at: index)
                                        onUpdate(editedDay)
                                        HapticManager.lightTap()
                                    } label: {
                                        Label(L10n.delete, systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .onMove { from, to in
                            editedDay.exercises.move(fromOffsets: from, toOffset: to)
                            onUpdate(editedDay)
                        }

                        // + 種目を追加
                        if editedDay.exercises.count < maxExercisesPerDay {
                            Button {
                                replacingExerciseIndex = nil
                                showingExercisePicker = true
                                HapticManager.lightTap()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.body)
                                    Text(L10n.routineAddExercise)
                                        .font(.subheadline.bold())
                                }
                                .foregroundStyle(Color.mmAccentPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.mmAccentPrimary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }

                        // Day管理セクション
                        VStack(spacing: 0) {
                            Divider()
                                .padding(.vertical, 16)

                            // Day名を変更
                            Button {
                                newDayName = editedDay.name
                                showingRenameAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text(isJapanese ? "Day名を変更" : "Rename Day")
                                    Spacer()
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.mmTextPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            // このDayを削除
                            Button {
                                showingDeleteConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text(isJapanese ? "このDayを削除" : "Delete this Day")
                                    Spacer()
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.mmDestructive)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Day \(dayIndex + 1): \(muscleGroupNames)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                RoutineEditExercisePickerSheet(
                    day: editedDay,
                    maxExercises: maxExercisesPerDay,
                    onAdd: { exerciseDef in
                        if let replaceIdx = replacingExerciseIndex {
                            // 入替え
                            editedDay.exercises[replaceIdx].exerciseId = exerciseDef.id
                        } else {
                            // 追加
                            guard !editedDay.exercises.contains(where: { $0.exerciseId == exerciseDef.id }) else { return }
                            editedDay.exercises.append(
                                RoutineExercise(
                                    exerciseId: exerciseDef.id,
                                    suggestedSets: 3,
                                    suggestedReps: 10
                                )
                            )
                        }
                        onUpdate(editedDay)
                        HapticManager.lightTap()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.mmBgSecondary)
            }
            .alert(isJapanese ? "Day名を変更" : "Rename Day", isPresented: $showingRenameAlert) {
                TextField("", text: $newDayName)
                Button(L10n.save) {
                    editedDay.name = newDayName
                    onUpdate(editedDay)
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .alert(isJapanese ? "このDayを削除しますか？" : "Delete this Day?", isPresented: $showingDeleteConfirm) {
                Button(L10n.delete, role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button(L10n.cancel, role: .cancel) {}
            }
        }
    }
}

// MARK: - Day編集シート内の種目行

private struct DayEditExerciseRow: View {
    let exercise: ExerciseDefinition
    let routineExercise: RoutineExercise
    let onReplace: () -> Void

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // GIF
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .gridCard)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 80)
                        .background(Color.white)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.mmBgCard)
                        .frame(width: 100, height: 80)
                        .overlay(
                            Image(systemName: "dumbbell.fill")
                                .font(.title3)
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                        )
                }

                // 種目情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.localizedName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(2)

                    Text("\(exercise.localizedEquipment) · \(routineExercise.suggestedSets)×\(routineExercise.suggestedReps)")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 入替えボタン
                Button(action: onReplace) {
                    Text(isJapanese ? "入替え" : "Replace")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // セパレーター
            Rectangle()
                .fill(Color.mmBgCard.opacity(0.5))
                .frame(height: 0.5)
                .padding(.leading, 128)
        }
    }
}

// MARK: - 種目追加ピッカーシート（既存再利用）

private struct RoutineEditExercisePickerSheet: View {
    let day: RoutineDay
    let maxExercises: Int
    let onAdd: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

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

        // muscleGroupsが空の場合（新規Day）は全種目
        if result.isEmpty {
            result = Array(store.exercises.prefix(50))
        }

        return result
    }

    private var filteredExercises: [ExerciseDefinition] {
        if searchText.isEmpty { return targetExercises }
        let query = searchText.lowercased()
        return targetExercises.filter {
            $0.localizedName.lowercased().contains(query) ||
            $0.nameEN.lowercased().contains(query)
        }
    }

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

                // 種目グリッド
                ScrollView(.vertical, showsIndicators: false) {
                    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(filteredExercises) { exercise in
                            let isAdded = addedIds.contains(exercise.id)
                            Button {
                                guard !isAdded else { return }
                                onAdd(exercise)
                                dismiss()
                            } label: {
                                ZStack {
                                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                        ExerciseGifView(exerciseId: exercise.id, size: .gridCard)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 170)
                                            .background(Color.white)
                                            .clipped()
                                    } else {
                                        ZStack {
                                            Color.mmBgSecondary
                                            Image(systemName: "dumbbell.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                        }
                                        .frame(height: 170)
                                    }

                                    VStack {
                                        Spacer()
                                        LinearGradient(
                                            colors: [.clear, .black.opacity(0.75)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 60)
                                    }

                                    VStack {
                                        Spacer()
                                        VStack(spacing: 2) {
                                            Text(exercise.localizedName)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                            Text(exercise.localizedEquipment)
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.mmAccentPrimary)
                                        }
                                        .padding(.bottom, 8)
                                    }

                                    VStack {
                                        HStack {
                                            Spacer()
                                            if isAdded {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(Color.mmAccentPrimary.opacity(0.6))
                                            } else {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(Color.mmAccentPrimary)
                                            }
                                        }
                                        .padding(6)
                                        Spacer()
                                    }
                                }
                                .frame(height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .opacity(isAdded ? 0.5 : 1.0)
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

// MARK: - ルーティンシェアカード（ImageRenderer用、静的ビュー）

private struct RoutineShareCardContent: View {
    let days: [RoutineDay]
    let modelContext: ModelContext

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }

    private var totalExercises: Int {
        days.reduce(0) { $0 + $1.exercises.count }
    }

    /// ルーティンがカバーする筋肉マッピング
    private var coverageMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        for day in days {
            for ex in day.exercises {
                if let def = ExerciseStore.shared.exercise(for: ex.exerciseId) {
                    for (muscleId, intensity) in def.muscleMapping {
                        mapping[muscleId] = max(mapping[muscleId] ?? 0, intensity)
                    }
                }
            }
        }
        return mapping
    }

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダー
            HStack {
                Text("MY ROUTINE")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(2)
                Spacer()
                Text(dateString)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // Day別カード
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                ShareDayCard(
                    day: day,
                    dayIndex: index,
                    modelContext: modelContext
                )
            }

            // カバレッジマップ
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    MiniMuscleMapView(muscleMapping: coverageMuscleMapping, showFront: true)
                        .frame(width: 35, height: 60)
                    MiniMuscleMapView(muscleMapping: coverageMuscleMapping, showFront: false)
                        .frame(width: 35, height: 60)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(totalExercises) exercises")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                    Text(isJapanese ? "全身カバレッジ" : "Full body coverage")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                Spacer()
            }

            // ウォーターマーク
            Text("MuscleMap")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
        }
        .padding(16)
        .frame(width: 360, height: 640)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.05), Color(red: 0.1, green: 0.1, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - シェアカード内のDayカード

private struct ShareDayCard: View {
    let day: RoutineDay
    let dayIndex: Int
    let modelContext: ModelContext

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var muscleGroupNames: String {
        day.muscleGroups.compactMap { rawValue in
            guard let group = MuscleGroup(rawValue: rawValue) else { return nil }
            return isJapanese ? group.japaneseName : group.englishName
        }.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Day \(dayIndex + 1): \(muscleGroupNames)")
                .font(.caption.bold())
                .foregroundStyle(Color.mmAccentPrimary)

            HStack(spacing: 6) {
                ForEach(Array(day.exercises.prefix(4).enumerated()), id: \.element.id) { _, exercise in
                    ShareExerciseMiniCard(
                        exercise: exercise,
                        modelContext: modelContext
                    )
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.16, green: 0.16, blue: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - シェアカード内のミニ種目カード

private struct ShareExerciseMiniCard: View {
    let exercise: RoutineExercise
    let modelContext: ModelContext

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var exerciseDef: ExerciseDefinition? {
        ExerciseStore.shared.exercise(for: exercise.exerciseId)
    }

    private var shortenedName: String {
        guard let def = exerciseDef else { return "" }
        let name = isJapanese ? def.nameJA : def.nameEN
        return name.count > 10 ? String(name.prefix(9)) + "…" : name
    }

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.exerciseId, context: modelContext)
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .bottom) {
                if ExerciseGifView.hasGif(exerciseId: exercise.exerciseId) {
                    ExerciseGifView(exerciseId: exercise.exerciseId, size: .card)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 60)
                        .background(Color.white)
                        .clipped()
                } else {
                    Color(red: 0.2, green: 0.2, blue: 0.2)
                        .frame(width: 70, height: 60)
                        .overlay(
                            Image(systemName: "dumbbell.fill")
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                        )
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 25)

                Text(shortenedName)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
            }
            .frame(width: 70, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if let weight = prWeight {
                Text("\(weight, specifier: "%.0f")kg")
                    .font(.system(size: 8, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.mmAccentPrimary)
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

import SwiftUI

// MARK: - オンボーディング: ルーティンビルダーページ

/// 週間ルーティンをGIF付きで組めるページ
/// splitParts(for: frequency) から日数分のタブを自動生成
struct RoutineBuilderPage: View {
    let onNext: () -> Void

    @State private var days: [RoutineDay] = []
    @State private var selectedDayIndex: Int = 0
    @State private var headerAppeared = false
    @State private var showingExercisePicker = false

    /// 1日あたりの最大種目数
    private let maxExercisesPerDay = 8

    /// 分割法パーツ
    private var splitParts: [SplitPart] {
        let frequency = AppState.shared.userProfile.weeklyFrequency
        return WorkoutRecommendationEngine.splitParts(for: frequency)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text(L10n.routineBuilderTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.routineBuilderSub)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 16)

            // Day タブバー
            dayTabBar

            Spacer().frame(height: 12)

            // 種目リスト
            if days.indices.contains(selectedDayIndex) {
                exerciseListView
            }

            Spacer(minLength: 0)

            // ボタンエリア
            VStack(spacing: 12) {
                // 次へボタン
                Button {
                    saveAndProceed()
                } label: {
                    Text(isLastDay ? L10n.routineBuilderComplete : L10n.routineBuilderNextDay)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(canProceed ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canProceed ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!canProceed)
                .animation(.easeInOut(duration: 0.2), value: canProceed)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            initializeDays()
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            if days.indices.contains(selectedDayIndex) {
                RoutineExercisePickerSheet(
                    day: days[selectedDayIndex],
                    maxExercises: maxExercisesPerDay,
                    onAdd: { exercise in
                        addExercise(exercise)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.mmOnboardingBg)
            }
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
                                ? Color.mmOnboardingBg
                                : Color.mmOnboardingTextMain
                        )
                        .frame(minWidth: 72)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            selectedDayIndex == index
                                ? Color.mmOnboardingAccent
                                : Color.mmOnboardingCard
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 種目リスト

    private var exerciseListView: some View {
        VStack(spacing: 0) {
            // 種目数カウンター
            HStack {
                Text(L10n.routineExerciseCount(days[selectedDayIndex].exercises.count, maxExercisesPerDay))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingAccent)

                Spacer()

                // 追加ボタン
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
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mmOnboardingAccent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            // 種目一覧
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(days[selectedDayIndex].exercises) { routineExercise in
                        if let def = ExerciseStore.shared.exercise(for: routineExercise.exerciseId) {
                            RoutineExerciseRow(
                                exercise: def,
                                routineExercise: routineExercise,
                                onRemove: {
                                    removeExercise(routineExercise.id)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - 状態

    private var isLastDay: Bool {
        selectedDayIndex == days.count - 1
    }

    private var canProceed: Bool {
        guard days.indices.contains(selectedDayIndex) else { return false }
        return !days[selectedDayIndex].exercises.isEmpty
    }

    // MARK: - ロジック

    /// 分割法から日を初期化 + 自動ピック
    private func initializeDays() {
        guard days.isEmpty else { return }

        let parts = splitParts
        let profile = AppState.shared.userProfile
        let exerciseStore = ExerciseStore.shared
        exerciseStore.loadIfNeeded()

        var result: [RoutineDay] = []

        for part in parts {
            var day = RoutineDay(
                name: part.name,
                muscleGroups: part.muscleGroups.map { $0.rawValue }
            )

            // 自動ピック: 各グループの種目を収集
            let targetGroupSet = Set(part.muscleGroups)
            var candidateExercises: [ExerciseDefinition] = []
            var seenIds: Set<String> = []

            for group in part.muscleGroups {
                for muscle in group.muscles {
                    let exercises = exerciseStore.exercises(targeting: muscle)
                    for ex in exercises {
                        if !seenIds.contains(ex.id) {
                            // 主要ターゲット筋肉のグループがこのパートに含まれるかチェック
                            if let primary = ex.primaryMuscle,
                               targetGroupSet.contains(primary.group) {
                                seenIds.insert(ex.id)
                                candidateExercises.append(ex)
                            }
                        }
                    }
                }
            }

            // 場所フィルタ
            candidateExercises = filterByLocation(
                exercises: candidateExercises,
                location: profile.trainingLocation
            )

            // 重点筋肉 + お気に入り優先ソート
            candidateExercises = sortByPriority(
                exercises: candidateExercises,
                priorityMuscles: profile.goalPriorityMuscles,
                targetGroups: targetGroupSet
            )

            // 上位3〜4種目を自動選択
            let count = part.muscleGroups.count >= 2 ? 4 : 3
            let topExercises = Array(candidateExercises.prefix(count))

            // デフォルトのレップ/セット
            let (defaultSets, defaultReps) = defaultSetsAndReps(for: profile.trainingExperience)

            day.exercises = topExercises.map { ex in
                RoutineExercise(
                    exerciseId: ex.id,
                    suggestedSets: defaultSets,
                    suggestedReps: defaultReps
                )
            }

            result.append(day)
        }

        days = result

        #if DEBUG
        for day in days {
            let names = day.exercises.compactMap { ExerciseStore.shared.exercise(for: $0.exerciseId)?.localizedName }
            print("[RoutineBuilder] \(day.name): \(names)")
        }
        #endif
    }

    /// 種目を追加
    private func addExercise(_ exerciseDef: ExerciseDefinition) {
        guard days.indices.contains(selectedDayIndex),
              days[selectedDayIndex].exercises.count < maxExercisesPerDay else { return }

        // 重複チェック
        guard !days[selectedDayIndex].exercises.contains(where: { $0.exerciseId == exerciseDef.id }) else { return }

        let (defaultSets, defaultReps) = defaultSetsAndReps(for: AppState.shared.userProfile.trainingExperience)

        days[selectedDayIndex].exercises.append(
            RoutineExercise(
                exerciseId: exerciseDef.id,
                suggestedSets: defaultSets,
                suggestedReps: defaultReps
            )
        )
        HapticManager.lightTap()
    }

    /// 種目を削除
    private func removeExercise(_ routineExerciseId: UUID) {
        guard days.indices.contains(selectedDayIndex) else { return }
        days[selectedDayIndex].exercises.removeAll { $0.id == routineExerciseId }
        HapticManager.lightTap()
    }

    /// 保存して次へ（次のDayタブ or 完了）
    private func saveAndProceed() {
        HapticManager.lightTap()

        if isLastDay {
            // 全Day完了 → ルーティン保存して次のオンボーディングページへ
            let routine = UserRoutine(days: days, createdAt: Date())
            RoutineManager.shared.saveRoutine(routine)

            // お気に入りにも登録
            for day in days {
                for exercise in day.exercises {
                    FavoritesManager.shared.add(exercise.exerciseId)
                }
            }

            onNext()
        } else {
            // 次のDayタブへ
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDayIndex += 1
            }
        }
    }

    // MARK: - ヘルパー

    private func defaultSetsAndReps(for experience: TrainingExperience) -> (sets: Int, reps: Int) {
        switch experience {
        case .beginner:   return (3, 12)
        case .halfYear:   return (3, 10)
        case .oneYearPlus: return (4, 8)
        case .veteran:    return (4, 6)
        }
    }

    private func filterByLocation(
        exercises: [ExerciseDefinition],
        location: String
    ) -> [ExerciseDefinition] {
        guard location == "home" else { return exercises }
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]
        let filtered = exercises.filter { homeEquipment.contains($0.equipment) }
        return filtered.isEmpty ? exercises : filtered
    }

    @MainActor
    private func sortByPriority(
        exercises: [ExerciseDefinition],
        priorityMuscles: [String],
        targetGroups: Set<MuscleGroup>
    ) -> [ExerciseDefinition] {
        let prioritySet = Set(priorityMuscles)
        let favoritesManager = FavoritesManager.shared

        return exercises.sorted { a, b in
            let aFav = favoritesManager.isFavorite(a.id)
            let bFav = favoritesManager.isFavorite(b.id)
            if aFav != bFav { return aFav }

            let aGroupScore = groupRelevanceScore(exercise: a, targetGroups: targetGroups)
            let bGroupScore = groupRelevanceScore(exercise: b, targetGroups: targetGroups)
            if aGroupScore != bGroupScore { return aGroupScore > bGroupScore }

            let aHits = priorityMuscleScore(exercise: a, prioritySet: prioritySet)
            let bHits = priorityMuscleScore(exercise: b, prioritySet: prioritySet)
            if aHits != bHits { return aHits > bHits }

            return false
        }
    }

    private func groupRelevanceScore(exercise: ExerciseDefinition, targetGroups: Set<MuscleGroup>) -> Int {
        let targetMuscleIds = Set(targetGroups.flatMap { $0.muscles.map { $0.rawValue } })
        return exercise.muscleMapping
            .filter { targetMuscleIds.contains($0.key) }
            .reduce(0) { $0 + $1.value }
    }

    private func priorityMuscleScore(exercise: ExerciseDefinition, prioritySet: Set<String>) -> Int {
        exercise.muscleMapping
            .filter { prioritySet.contains($0.key) }
            .reduce(0) { $0 + $1.value }
    }
}

// MARK: - ルーティン種目行

private struct RoutineExerciseRow: View {
    let exercise: ExerciseDefinition
    let routineExercise: RoutineExercise
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 左アクセントバー
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.mmOnboardingAccent)
                .frame(width: 3)
                .padding(.vertical, 8)

            HStack(spacing: 12) {
                // GIFサムネイル
                exerciseThumbnail

                // 種目名 + セット×レップ
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.localizedName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(exercise.equipment)
                            .font(.caption)
                            .foregroundStyle(Color.mmOnboardingTextSub)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmOnboardingCard)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("\(routineExercise.suggestedSets)x\(routineExercise.suggestedReps)")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmOnboardingAccent)
                    }
                }

                Spacer()

                // 削除ボタン
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .frame(minHeight: 56)
        .background(Color.mmOnboardingAccent.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var exerciseThumbnail: some View {
        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
            ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mmOnboardingBg)
                    .frame(width: 40, height: 40)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
            }
        }
    }
}

// MARK: - 種目追加シート

private struct RoutineExercisePickerSheet: View {
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
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]
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
                        .foregroundStyle(Color.mmOnboardingTextSub)
                    TextField("", text: $searchText, prompt: Text(L10n.searchExercises).foregroundColor(Color.mmOnboardingTextSub))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.mmOnboardingTextSub)
                        }
                    }
                }
                .padding(12)
                .background(Color.mmOnboardingCard)
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
                                                .fill(Color.mmOnboardingBg)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "dumbbell.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.localizedName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color.mmOnboardingTextMain)
                                            .lineLimit(1)

                                        Text(exercise.equipment)
                                            .font(.caption)
                                            .foregroundStyle(Color.mmOnboardingTextSub)
                                    }

                                    Spacer()

                                    if isAdded {
                                        Text(L10n.routineAlreadyAdded)
                                            .font(.caption)
                                            .foregroundStyle(Color.mmOnboardingTextSub)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color.mmOnboardingAccent)
                                    }
                                }
                                .padding(12)
                                .background(isAdded ? Color.mmOnboardingCard.opacity(0.5) : Color.mmOnboardingCard)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) {
                        dismiss()
                    }
                    .foregroundStyle(Color.mmOnboardingAccent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        RoutineBuilderPage(onNext: {})
    }
}

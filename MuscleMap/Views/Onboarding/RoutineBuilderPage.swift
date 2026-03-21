import SwiftUI

// MARK: - オンボーディング: ルーティンビルダーページ（種目の追加・削除可能プレビュー）

/// 自動生成されたルーティンをプレビュー表示し、種目の追加・削除後「このメニューで始める」で確定
struct RoutineBuilderPage: View {
    let onNext: () -> Void

    @State private var days: [RoutineDay] = []
    @State private var selectedDayIndex: Int = 0
    @State private var headerAppeared = false
    @State private var selectedExerciseDefinition: ExerciseDefinition?
    @State private var showingExercisePicker = false

    private let maxExercisesPerDay = 6

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 分割法パーツ
    private var splitParts: [SplitPart] {
        let frequency = AppState.shared.userProfile.weeklyFrequency
        return WorkoutRecommendationEngine.splitParts(for: frequency)
    }

    /// カバーされる筋肉の割合
    private var coveragePercent: Int {
        let allMuscles = Set(splitParts.flatMap { $0.muscleGroups.flatMap { $0.muscles } })
        let total = Muscle.allCases.count
        guard total > 0 else { return 0 }
        return Int(Double(allMuscles.count) / Double(total) * 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            // ヘッダー（コンパクト）
            VStack(spacing: 4) {
                Text(L10n.routineBuilderTitle)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(isJapanese
                    ? "あなたの目標に合わせて自動提案しました"
                    : "Auto-generated for your goals")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmOnboardingAccent.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 12)

            Spacer().frame(height: 6)

            // カバー率バッジ（GoalMusclePreviewから移植）
            Text(isJapanese ? "\(coveragePercent)%の筋肉をカバー" : "\(coveragePercent)% muscle coverage")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mmOnboardingAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.mmOnboardingAccent.opacity(0.12))
                .clipShape(Capsule())
                .opacity(headerAppeared ? 1 : 0)

            Spacer().frame(height: 6)

            // Day タブバー（閲覧のみ）
            dayTabBar

            Spacer().frame(height: 6)

            // 種目プレビュー
            if days.indices.contains(selectedDayIndex) {
                exercisePreview
            }

            Spacer(minLength: 0)

            // ボタンエリア
            VStack(spacing: 8) {
                // サマリー行
                let totalExercises = days.flatMap(\.exercises).count
                let totalDays = days.count
                Text(isJapanese
                    ? "合計 \(totalExercises)種目 / 週\(totalDays)回"
                    : "\(totalExercises) exercises / \(totalDays) days per week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.mmOnboardingTextSub)

                // CTA: 「このメニューで始める」
                Button {
                    HapticManager.mediumTap()
                    let routine = UserRoutine(days: days, createdAt: Date())
                    RoutineManager.shared.saveRoutine(routine)
                    for day in days {
                        for exercise in day.exercises {
                            FavoritesManager.shared.add(exercise.exerciseId)
                        }
                    }
                    onNext()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                        Text(isJapanese ? "このメニューで始める" : "Start with This Menu")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                // 変更可能テキスト
                Text(isJapanese ? "メニューは後から設定で変更できます" : "You can customize your routine later in Settings")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmOnboardingTextSub)
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
        .sheet(item: $selectedExerciseDefinition) { exercise in
            ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
        }
        .sheet(isPresented: $showingExercisePicker) {
            if days.indices.contains(selectedDayIndex) {
                RoutineExercisePickerSheet(
                    day: days[selectedDayIndex],
                    maxExercises: maxExercisesPerDay,
                    onAdd: { exercise in
                        addExercise(exercise)
                    },
                    currentExerciseIds: Set(days[selectedDayIndex].exercises.map(\.exerciseId))
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.mmOnboardingBg)
            }
        }
    }

    // MARK: - Day タブバー（閲覧のみ）

    private var dayTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(days.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDayIndex = index
                        }
                        HapticManager.lightTap()
                    } label: {
                        VStack(spacing: 2) {
                            Text("Day \(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                            Text(days[index].name)
                                .font(.system(size: 10))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            selectedDayIndex == index
                                ? Color.mmOnboardingBg
                                : Color.mmOnboardingTextMain
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedDayIndex == index
                                ? Color.mmOnboardingAccent
                                : Color.mmOnboardingCard
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 種目プレビュー（読み取り専用）

    @ViewBuilder
    private var exercisePreview: some View {
        if days.indices.contains(selectedDayIndex) {
            let day = days[selectedDayIndex]

            VStack(spacing: 0) {
                // 教育ヒント
                Text(educationHint(for: day))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmOnboardingAccent.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.mmOnboardingAccent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)

                // 種目グリッド + 筋肉マップ（スクロール可能）
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // 筋肉マップ（コンパクト）
                        MuscleMapView(
                            muscleStates: muscleStatesForDay(day)
                        )
                        .frame(height: 120)
                        .padding(.horizontal, 24)

                        // 2列GIFグリッド（カード拡大）
                        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(day.exercises, id: \.id) { routineExercise in
                                exerciseCard(routineExercise: routineExercise)
                            }

                            // 種目追加カード（グリッド末尾）
                            if day.exercises.count < maxExercisesPerDay {
                                Button {
                                    showingExercisePicker = true
                                    HapticManager.lightTap()
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 28))
                                        Text(isJapanese ? "追加" : "Add")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundStyle(Color.mmOnboardingTextSub)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .background(Color.mmOnboardingCard.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.3))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }

    // MARK: - 種目カード（2列グリッド用、削除可能）

    private func exerciseCard(routineExercise: RoutineExercise) -> some View {
        let def = ExerciseStore.shared.exercise(for: routineExercise.exerciseId)
        let name = def?.localizedName ?? routineExercise.exerciseId
        let canDelete = days.indices.contains(selectedDayIndex) && days[selectedDayIndex].exercises.count > 1

        return VStack(spacing: 4) {
            ZStack {
                // GIFカード（タップで詳細表示）
                Button {
                    if let def {
                        HapticManager.lightTap()
                        selectedExerciseDefinition = def
                    }
                } label: {
                    ZStack(alignment: .bottom) {
                        if ExerciseGifView.hasGif(exerciseId: routineExercise.exerciseId) {
                            ExerciseGifView(exerciseId: routineExercise.exerciseId, size: .card)
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                        } else {
                            ZStack {
                                Color.mmOnboardingBg
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                            }
                            .frame(height: 150)
                        }

                        // 名前オーバーレイ（グラデーション上）
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 50)

                        // 種目名 + セット×レップ
                        VStack(spacing: 2) {
                            Text(name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(routineExercise.suggestedSets)×\(routineExercise.suggestedReps)")
                                .font(.system(size: 10, weight: .bold).monospacedDigit())
                                .foregroundStyle(Color.mmOnboardingAccent)
                        }
                        .padding(.bottom, 8)
                    }
                }
                .buttonStyle(.plain)

                // 削除ボタン（右上）
                if canDelete {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                removeExercise(routineExercise.id)
                                HapticManager.lightTap()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .background(Circle().fill(Color.black.opacity(0.4)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(4)
                        Spacer()
                    }
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 筋肉マップ状態

    private func muscleStatesForDay(_ day: RoutineDay) -> [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for exercise in day.exercises {
            if let def = ExerciseStore.shared.exercise(for: exercise.exerciseId) {
                for (muscleId, _) in def.muscleMapping {
                    if let muscle = Muscle(rawValue: muscleId) {
                        states[muscle] = .recovering(progress: 0.1)
                    }
                }
            }
        }
        return states
    }

    // MARK: - 種目の追加・削除

    private func addExercise(_ exercise: ExerciseDefinition) {
        guard days.indices.contains(selectedDayIndex) else { return }
        let profile = AppState.shared.userProfile
        let (defaultSets, defaultReps) = defaultSetsAndReps(for: profile.trainingExperience)
        let newExercise = RoutineExercise(
            exerciseId: exercise.id,
            suggestedSets: defaultSets,
            suggestedReps: defaultReps
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            days[selectedDayIndex].exercises.append(newExercise)
        }
        HapticManager.lightTap()
    }

    private func removeExercise(_ exerciseId: UUID) {
        guard days.indices.contains(selectedDayIndex),
              days[selectedDayIndex].exercises.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            days[selectedDayIndex].exercises.removeAll { $0.id == exerciseId }
        }
    }

    // MARK: - ロジック

    /// 分割法から日を初期化 + 自動ピック
    private func initializeDays() {
        guard days.isEmpty else { return }

        let parts = splitParts
        let profile = AppState.shared.userProfile
        let exerciseStore = ExerciseStore.shared
        exerciseStore.loadIfNeeded()

        let userLocation = profile.trainingLocation

        var result: [RoutineDay] = []

        for part in parts {
            var day = RoutineDay(
                name: part.name,
                muscleGroups: part.muscleGroups.map { $0.rawValue },
                location: userLocation
            )

            let exercises = autoPickExercises(
                muscleGroups: part.muscleGroups,
                location: userLocation,
                priorityMuscles: profile.goalPriorityMuscles,
                experience: profile.trainingExperience
            )
            day.exercises = exercises

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

    /// 自動ピック共通ロジック
    private func autoPickExercises(
        muscleGroups: [MuscleGroup],
        location: String,
        priorityMuscles: [String],
        experience: TrainingExperience
    ) -> [RoutineExercise] {
        let exerciseStore = ExerciseStore.shared
        exerciseStore.loadIfNeeded()

        let targetGroupSet = Set(muscleGroups)
        var candidateExercises: [ExerciseDefinition] = []
        var seenIds: Set<String> = []

        for group in muscleGroups {
            for muscle in group.muscles {
                let exercises = exerciseStore.exercises(targeting: muscle)
                for ex in exercises {
                    if !seenIds.contains(ex.id) {
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
            location: location
        )

        // 重点筋肉 + お気に入り優先ソート
        candidateExercises = sortByPriority(
            exercises: candidateExercises,
            priorityMuscles: priorityMuscles,
            targetGroups: targetGroupSet
        )

        // 上位3〜4種目を自動選択
        let count = muscleGroups.count >= 2 ? 4 : 3
        let topExercises = Array(candidateExercises.prefix(count))

        let (defaultSets, defaultReps) = defaultSetsAndReps(for: experience)

        return topExercises.map { ex in
            RoutineExercise(
                exerciseId: ex.id,
                suggestedSets: defaultSets,
                suggestedReps: defaultReps
            )
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
        switch location {
        case "home":
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            let filtered = exercises.filter { homeEquipment.contains($0.equipment) }
            return filtered.isEmpty ? exercises : filtered
        case "bodyweight":
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            let filtered = exercises.filter { bwEquipment.contains($0.equipment) }
            return filtered.isEmpty ? exercises : filtered
        default:
            return exercises
        }
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

    // MARK: - 教育ヒント

    /// Dayの筋肉グループに応じた分割法の教育ヒント
    private func educationHint(for day: RoutineDay) -> String {
        let groups = Set(day.muscleGroups)
        if groups.contains("chest") && groups.contains("shoulders") {
            return isJapanese
                ? "\u{1F4A1} 「押す」動作の筋肉をまとめて効率UP"
                : "\u{1F4A1} Push muscles grouped for efficiency"
        }
        if groups.contains("back") {
            return isJapanese
                ? "\u{1F4A1} 「引く」動作の筋肉で背中を厚く"
                : "\u{1F4A1} Pull muscles for a thick back"
        }
        if groups.contains("lowerBody") {
            return isJapanese
                ? "\u{1F4A1} 下半身は代謝UPの最重要パーツ"
                : "\u{1F4A1} Legs are key for boosting metabolism"
        }
        if groups.contains("shoulders") {
            return isJapanese
                ? "\u{1F4A1} 肩を鍛えると全体のシルエットが変わる"
                : "\u{1F4A1} Shoulders transform your overall silhouette"
        }
        if groups.contains("arms") {
            return isJapanese
                ? "\u{1F4A1} 腕はTシャツから見える「名刺」"
                : "\u{1F4A1} Arms are your visible \"business card\""
        }
        return isJapanese
            ? "\u{1F4A1} 補助筋もまとめてカバー"
            : "\u{1F4A1} Synergist muscles covered together"
    }
}

// MARK: - セット×レップ編集シート（設定画面のRoutineEditViewで使用）

struct SetRepEditorSheet: View {
    @Binding var sets: Int
    @Binding var reps: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("\(sets)×\(reps)")
                .font(.system(size: 32, weight: .heavy).monospacedDigit())
                .foregroundStyle(Color.mmOnboardingAccent)
                .padding(.top, 20)

            VStack(spacing: 16) {
                HStack {
                    Text(L10n.routineSetRepSets)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                    Spacer()
                    Stepper("\(sets)", value: $sets, in: 1...6)
                        .labelsHidden()
                    Text("\(sets)")
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .frame(width: 30, alignment: .center)
                }

                HStack {
                    Text(L10n.routineSetRepReps)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                    Spacer()
                    Stepper("\(reps)", value: $reps, in: 1...30)
                        .labelsHidden()
                    Text("\(reps)")
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .frame(width: 30, alignment: .center)
                }
            }
            .padding(.horizontal, 24)

            Button {
                HapticManager.lightTap()
                dismiss()
            } label: {
                Text(L10n.save)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.mmOnboardingAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - 種目追加シート（設定画面のRoutineEditViewで使用）

struct RoutineExercisePickerSheet: View {
    let day: RoutineDay
    let maxExercises: Int
    let onAdd: (ExerciseDefinition) -> Void
    let currentExerciseIds: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

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

        if day.location == "home" {
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            let filtered = result.filter { homeEquipment.contains($0.equipment) }
            if !filtered.isEmpty { result = filtered }
        } else if day.location == "bodyweight" {
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            let filtered = result.filter { bwEquipment.contains($0.equipment) }
            if !filtered.isEmpty { result = filtered }
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            let isAdded = currentExerciseIds.contains(exercise.id)
                            Button {
                                guard !isAdded else { return }
                                onAdd(exercise)
                            } label: {
                                HStack(spacing: 12) {
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
                                            .foregroundStyle(isAdded ? Color.mmOnboardingTextSub : Color.mmOnboardingTextMain)
                                            .lineLimit(1)

                                        Text(exercise.localizedEquipment)
                                            .font(.caption)
                                            .foregroundStyle(Color.mmOnboardingTextSub)
                                    }

                                    Spacer()

                                    if isAdded {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                            Text(isJapanese ? "追加済み" : "Added")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(Color.mmOnboardingAccent.opacity(0.6))
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
                            .animation(.easeInOut(duration: 0.2), value: isAdded)
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

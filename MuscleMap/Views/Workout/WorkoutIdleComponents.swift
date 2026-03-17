import SwiftUI
import SwiftData

// MARK: - セッション未開始時のコンポーネント

/// ワークアウト未開始時のメインビュー
struct WorkoutIdleView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onStart: () -> Void
    let onSelectExercise: (ExerciseDefinition) -> Void

    @ObservedObject private var favorites = FavoritesManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMuscle: Muscle?
    @State private var suggestedMenu: SuggestedMenu?
    @State private var showingExerciseLibrary = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var favoriteExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        return favorites.favoriteIds.compactMap { store.exercise(for: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 筋肉マップ（タップで種目選択）
                    MuscleMapView(
                        muscleStates: muscleStates,
                        onMuscleTapped: { muscle in
                            selectedMuscle = muscle
                        }
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .padding(.horizontal)

                    // ヒントテキスト
                    Text(L10n.tapMuscleHint)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .multilineTextAlignment(.center)

                    // おすすめメニュー（履歴ありの場合のみ）
                    if let menu = suggestedMenu, !menu.exercises.isEmpty {
                        RecommendedWorkoutBanner(
                            menu: menu,
                            onStart: {
                                // おすすめの全種目をセッションに追加
                                if menu.exercises.isEmpty {
                                    onStart()
                                } else {
                                    for exercise in menu.exercises {
                                        onSelectExercise(exercise.definition)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal)
                    }

                    // お気に入り種目
                    if !favoriteExercises.isEmpty {
                        FavoriteExercisesSection(
                            exercises: favoriteExercises,
                            onSelect: onSelectExercise
                        )
                    }
                }
                .padding(.vertical)
            }

            // 種目を追加して始める（統合CTA）
            Button {
                HapticManager.lightTap()
                showingExerciseLibrary = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.addExerciseAndStart)
                }
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            NavigationStack {
                ExerciseLibraryView()
            }
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleExercisePickerSheet(muscle: muscle) { exercise in
                onSelectExercise(exercise)
                selectedMuscle = nil
            }
        }
        .onAppear {
            loadRecommendation()
        }
    }

    /// おすすめメニューを取得
    private func loadRecommendation() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        let stimulations = repo.fetchLatestStimulations()
        // 履歴がない場合は非表示
        guard !stimulations.isEmpty else {
            suggestedMenu = nil
            return
        }
        suggestedMenu = MenuSuggestionService.suggestTodayMenu(
            stimulations: stimulations,
            exerciseStore: ExerciseStore.shared
        )
    }
}

// MARK: - おすすめワークアウトバナー

struct RecommendedWorkoutBanner: View {
    let menu: SuggestedMenu
    let onStart: () -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        Button {
            HapticManager.lightTap()
            onStart()
        } label: {
            HStack(spacing: 12) {
                Text("💡")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.recommendedWorkout(groupName))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)

                    Text(L10n.startRecommended)
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mmAccentPrimary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mmAccentPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var groupName: String {
        localization.currentLanguage == .japanese
            ? menu.primaryGroup.japaneseName
            : menu.primaryGroup.englishName
    }
}

// MARK: - お気に入り種目セクション

struct FavoriteExercisesSection: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void
    @Environment(\.modelContext) private var modelContext
    private var localization: LocalizationManager { LocalizationManager.shared }

    /// 種目の強さレベルを取得
    private func strengthLevel(for exercise: ExerciseDefinition) -> StrengthLevel? {
        guard let best1RM = PRManager.shared.getBestEstimated1RM(exerciseId: exercise.id, context: modelContext) else {
            return nil
        }
        let bodyweight = AppState.shared.userProfile.weightKg
        return StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: exercise.id,
            estimated1RM: best1RM,
            bodyweightKg: bodyweight
        ).level
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.mmMuscleModerate)
                Text(L10n.favoriteExercises)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        Button {
                            HapticManager.lightTap()
                            onSelect(exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)

                                HStack(spacing: 4) {
                                    Image(systemName: "dumbbell")
                                    Text(exercise.localizedEquipment)
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)

                                HStack(spacing: 4) {
                                    if let primary = exercise.primaryMuscle {
                                        Text(primary.localizedName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.mmAccentPrimary.opacity(0.15))
                                            .foregroundStyle(Color.mmAccentPrimary)
                                            .clipShape(Capsule())
                                    }

                                    // レベルバッジ
                                    if let level = strengthLevel(for: exercise) {
                                        Text(level.emoji + level.localizedName)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(level.color.opacity(0.15))
                                            .foregroundStyle(level.color)
                                            .clipShape(Capsule())
                                    }
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

// MARK: - 筋肉タップ時の種目選択シート

struct MuscleExercisePickerSheet: View {
    let muscle: Muscle
    let onSelect: (ExerciseDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var relatedExercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    private func lastRecord(for exerciseId: String) -> WorkoutSet? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if relatedExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        Text(L10n.noData)
                            .font(.headline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(relatedExercises) { exercise in
                                Button {
                                    HapticManager.lightTap()
                                    onSelect(exercise)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // GIF - カード型で大きく
                                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                            ExerciseGifView(exerciseId: exercise.id, size: .card)
                                        } else {
                                            MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                                                .frame(height: 120)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.mmBgSecondary)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }

                                        // 種目名 + 器具 + 前回記録
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(Color.mmTextPrimary)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                                Text(exercise.localizedEquipment)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.mmTextSecondary)
                                            }
                                            Spacer()
                                            if let record = lastRecord(for: exercise.id) {
                                                Text(L10n.lastRecordLabel(record.weight, record.reps))
                                                    .font(.caption.monospaced().bold())
                                                    .foregroundStyle(Color.mmAccentPrimary)
                                            }
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Color.mmTextSecondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.mmBgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(muscle.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

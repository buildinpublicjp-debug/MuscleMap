import SwiftUI
import SwiftData

// MARK: - 種目選択ビュー（シート表示）

struct ExercisePickerView: View {
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @ObservedObject private var recentManager = RecentExercisesManager.shared
    @State private var searchText = ""
    @State private var muscleStates: [Muscle: MuscleStimulation] = [:]
    @State private var previewExercise: ExerciseDefinition?
    @AppStorage("exercisePickerGridView") private var isGridView = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // フィルターチップ（回復ステータスドット付き）
                    PickerFilterChipsSection(
                        viewModel: viewModel,
                        muscleStates: muscleStates
                    )

                    // お気に入り横スクロール行
                    PickerFavoritesRow(
                        exercises: viewModel.exercises,
                        onSelect: { exercise in
                            HapticManager.lightTap()
                            onSelect(exercise)
                        }
                    )

                    // 最近の検索
                    PickerRecentSearchesRow(
                        searches: viewModel.recentSearches
                    ) { query in
                        searchText = query
                        viewModel.searchText = query
                    }

                    // 種目リスト/グリッド or EmptyState
                    PickerContentSection(
                        viewModel: viewModel,
                        muscleStates: muscleStates,
                        isGridView: isGridView,
                        onSelect: { exercise in
                            HapticManager.lightTap()
                            onSelect(exercise)
                        },
                        onPreview: { exercise in
                            HapticManager.lightTap()
                            previewExercise = exercise
                        }
                    )
                }
            }
            .navigationTitle(L10n.selectExercise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: L10n.searchExercises)
            .onSubmit(of: .search) {
                viewModel.recordSearch(searchText)
            }
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // グリッド/リスト切替
                    Button {
                        isGridView.toggle()
                        HapticManager.lightTap()
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                viewModel.load()
                loadMuscleStates()
            }
            .sheet(item: $previewExercise) { exercise in
                ExercisePreviewSheet(exercise: exercise) {
                    onSelect(exercise)
                }
            }
        }
    }

    private func loadMuscleStates() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        muscleStates = repo.fetchLatestStimulations()
    }
}

// MARK: - 種目行（シンプル版）

struct ExerciseRow: View {
    let exercise: ExerciseDefinition
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)

                HStack(spacing: 8) {
                    Label(exercise.localizedEquipment, systemImage: "dumbbell")
                    Label(exercise.localizedDifficulty, systemImage: "chart.bar")
                }
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()

            // ターゲット筋肉タグ
            if let primary = exercise.primaryMuscle {
                Text(localization.currentLanguage == .japanese ? primary.japaneseName : primary.englishName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .foregroundStyle(Color.mmAccentPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(for: [MuscleStimulation.self], inMemory: true)
}

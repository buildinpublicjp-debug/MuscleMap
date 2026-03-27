import SwiftUI

// MARK: - 種目辞典画面

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @ObservedObject private var recentManager = RecentExercisesManager.shared
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDefinition?
    @AppStorage("exerciseLibraryGridView") private var isGridView = true
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // フィルターチップ（回復ドットなし版 — muscleStates空で渡す）
                PickerFilterChipsSection(
                    viewModel: viewModel,
                    muscleStates: [:]
                )

                // お気に入り横スクロール行
                LibraryFavoritesRow(
                    exercises: viewModel.exercises
                ) { exercise in
                    selectedExercise = exercise
                }

                // 最近の検索
                PickerRecentSearchesRow(
                    searches: viewModel.recentSearches
                ) { query in
                    searchText = query
                    viewModel.searchText = query
                }

                // 種目数
                HStack {
                    Text(L10n.exerciseCountLabel(viewModel.filteredExercises.count))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // 種目リスト/グリッド or EmptyState
                contentSection
            }
        }
        .navigationTitle(L10n.exerciseLibrary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
            ToolbarItem(placement: .principal) {
                Text(L10n.exerciseLibrary)
                    .font(.headline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }
        }
        .searchable(text: $searchText, prompt: L10n.searchExercises)
        .onSubmit(of: .search) {
            viewModel.recordSearch(searchText)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .onAppear {
            viewModel.load()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    // MARK: - コンテンツセクション

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.showRecentOnly && viewModel.filteredExercises.isEmpty {
            PickerEmptyState(
                icon: "clock.arrow.circlepath",
                title: L10n.noRecentExercises,
                subtitle: L10n.recentExercisesHint
            )
        } else if viewModel.showFavoritesOnly && viewModel.filteredExercises.isEmpty {
            PickerEmptyState(
                icon: "star.slash",
                title: L10n.noFavorites,
                subtitle: L10n.addFavoritesHint
            )
        } else if isGridView {
            LibraryGridContent(
                exercises: viewModel.filteredExercises
            ) { exercise in
                selectedExercise = exercise
            }
        } else {
            LibraryListContent(
                exercises: viewModel.filteredExercises
            ) { exercise in
                selectedExercise = exercise
            }
        }
    }
}

#Preview {
    ExerciseLibraryView()
}

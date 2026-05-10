import SwiftUI

// MARK: - 種目辞典 (Biblioteca) — v1.1.5 リデザイン
//
// 構成: 検索バー → Explorar por 4軸 → 主軸チップ → Filtros 折りたたみ
//        → 件数+ソート → 種目グリッド (2列)
// 哲学: 鏡 — データを判断なしに反映、装飾最小

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDefinition?
    @State private var isSearchActive = false
    @FocusState private var searchFieldFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12, pinnedViews: []) {
                    if isSearchActive {
                        searchBar
                    }

                    ExploreBySegment(selectedAxis: $viewModel.selectedAxis)

                    if viewModel.selectedAxis != .favoritos {
                        PrimaryFilterChips(viewModel: viewModel)
                    }

                    FiltrosCollapsibleBar(viewModel: viewModel)

                    LibraryCountSortRow(viewModel: viewModel)

                    if viewModel.filteredExercises.isEmpty {
                        LibraryEmptyState()
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(viewModel.filteredExercises) { exercise in
                                ExerciseGridCardV2(exercise: exercise) {
                                    HapticManager.lightTap()
                                    selectedExercise = exercise
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(L10n.exerciseLibrary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.exerciseLibrary)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.mmTextPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                            viewModel.searchText = ""
                        } else {
                            searchFieldFocused = true
                        }
                    }
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .foregroundStyle(isSearchActive ? Color.mmTextSecondary : Color.mmAccentPrimary)
                }
            }
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

    // MARK: - 検索バー

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.mmTextSecondary)
            TextField(L10n.searchExercises, text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.mmTextPrimary)
                .submitLabel(.search)
                .focused($searchFieldFocused)
                .onSubmit { viewModel.recordSearch(searchText) }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
}

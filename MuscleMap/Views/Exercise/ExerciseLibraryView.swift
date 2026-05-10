import SwiftUI

// MARK: - 種目辞典 (Biblioteca) — v1.1.5 フラット構造
//
// 構成: 検索バー (常時表示) → 部位行 → 器具行 → 件数 → 2列グリッド
// 探す軸セグメント / Filtros collapse / 難易度フィルター / 並び替え は全廃。
// お気に入り toggle は toolbar 右上の ★ で切替。

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDefinition?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12, pinnedViews: []) {
                    searchBar

                    chipRow(label: L10n.axisMusculo) {
                        ForEach(MuscleGroup.allCases) { group in
                            flatChip(
                                title: group.localizedName,
                                isActive: viewModel.selectedMuscleGroup == group
                            ) {
                                viewModel.selectedMuscleGroup = (viewModel.selectedMuscleGroup == group) ? nil : group
                            }
                        }
                    }

                    chipRow(label: L10n.axisEquipo) {
                        ForEach(LibraryEquipmentFilter.allCases) { filter in
                            flatChip(
                                title: filter.localizedName,
                                isActive: viewModel.selectedEquipment == filter.rawValue
                            ) {
                                viewModel.selectedEquipment = (viewModel.selectedEquipment == filter.rawValue) ? nil : filter.rawValue
                            }
                        }
                    }

                    Text(L10n.exerciseCountLong(viewModel.filteredExercises.count))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.mmTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    if viewModel.filteredExercises.isEmpty {
                        LibraryEmptyState()
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(viewModel.filteredExercises) { exercise in
                                LibraryGridCard(exercise: exercise) {
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
                    HapticManager.lightTap()
                    viewModel.showFavoritesOnly.toggle()
                } label: {
                    Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                        .foregroundStyle(viewModel.showFavoritesOnly ? Color.mmAccentPrimary : Color.mmTextSecondary)
                }
                .accessibilityLabel(L10n.axisFavoritos)
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

    // MARK: - 常時表示の検索バー

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.mmTextSecondary)
            TextField(L10n.searchExercises, text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.mmTextPrimary)
                .submitLabel(.search)
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
    }

    // MARK: - ラベル + 横スクロールチップ行

    @ViewBuilder
    private func chipRow<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
                .frame(width: 36, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content()
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, 16)
    }

    private func flatChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.lightTap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? Color.mmAccentPrimary : Color.mmBgCard)
                .foregroundStyle(isActive ? Color.mmBgPrimary : Color.mmTextPrimary)
                .clipShape(Capsule())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
}

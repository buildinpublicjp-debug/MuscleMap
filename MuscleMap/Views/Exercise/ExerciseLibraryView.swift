import SwiftUI

// MARK: - 種目辞典 (Biblioteca) — v1.1.5 フラット構造
//
// 構成: 部位行 → 器具行 → 件数 → 2列グリッド
// 探す軸セグメント / Filtros collapse / 難易度フィルター / 並び替え / 検索バー は全廃。
// お気に入り toggle は toolbar 右上の ★ で切替。
// 部位/器具行は LibraryFilterRows に切り出し、種目選択モーダルと共有。

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var selectedExercise: ExerciseDefinition?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12, pinnedViews: []) {
                    LibraryFilterRows(
                        selectedMuscleGroup: $viewModel.selectedMuscleGroup,
                        selectedEquipment: $viewModel.selectedEquipment
                    )

                    Text(L10n.exerciseCountLong(viewModel.filteredExercises.count))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.mmTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    if viewModel.filteredExercises.isEmpty {
                        LibraryEmptyState()
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
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
        .onAppear {
            viewModel.load()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
}

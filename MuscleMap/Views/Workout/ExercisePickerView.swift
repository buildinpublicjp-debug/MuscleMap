import SwiftUI
import SwiftData

// MARK: - 種目選択ビュー（シート表示）— v1.1.5 Biblioteca 統一版
//
// 構成は Biblioteca タブと完全一致:
// [閉じる] / 種目を選択 / [★] → 部位行 → 器具行 → 件数 → 2列グリッド
// 検索バー / グリッド⇔リスト切替 / FlowLayout 大量チップ / 最近検索 / お気に入り横スクロール は全廃。

struct ExercisePickerView: View {
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var previewExercise: ExerciseDefinition?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
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
                                        onSelect(exercise)
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
            .navigationTitle(L10n.selectExercise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                ToolbarItem(placement: .principal) {
                    Text(L10n.selectExercise)
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
            .sheet(item: $previewExercise) { exercise in
                ExercisePreviewSheet(exercise: exercise) {
                    onSelect(exercise)
                }
            }
        }
    }
}

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(for: [MuscleStimulation.self], inMemory: true)
}

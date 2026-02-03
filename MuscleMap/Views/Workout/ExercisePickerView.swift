import SwiftUI

// MARK: - 種目選択ビュー（シート表示）

struct ExercisePickerView: View {
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // カテゴリフィルター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // お気に入りフィルター
                            CategoryChip(
                                title: "★ お気に入り",
                                isSelected: viewModel.showFavoritesOnly
                            ) {
                                viewModel.showFavoritesOnly.toggle()
                                if viewModel.showFavoritesOnly {
                                    viewModel.selectedCategory = nil
                                }
                            }

                            CategoryChip(
                                title: "すべて",
                                isSelected: viewModel.selectedCategory == nil && !viewModel.showFavoritesOnly
                            ) {
                                viewModel.showFavoritesOnly = false
                                viewModel.selectedCategory = nil
                            }

                            ForEach(viewModel.categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: viewModel.selectedCategory == category && !viewModel.showFavoritesOnly
                                ) {
                                    viewModel.showFavoritesOnly = false
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // 種目リスト
                    List(viewModel.filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                        } label: {
                            ExerciseRow(exercise: exercise)
                        }
                        .listRowBackground(Color.mmBgSecondary)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("種目を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "種目を検索")
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                viewModel.load()
            }
        }
    }
}

// MARK: - カテゴリチップ

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.mmAccentPrimary : Color.mmBgCard)
                .foregroundStyle(isSelected ? Color.mmBgPrimary : Color.mmTextSecondary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - 種目行

struct ExerciseRow: View {
    let exercise: ExerciseDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.nameJA)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)

                HStack(spacing: 8) {
                    Label(exercise.equipment, systemImage: "dumbbell")
                    Label(exercise.difficulty, systemImage: "chart.bar")
                }
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()

            // ターゲット筋肉タグ
            if let primary = exercise.primaryMuscle {
                Text(primary.japaneseName)
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
}

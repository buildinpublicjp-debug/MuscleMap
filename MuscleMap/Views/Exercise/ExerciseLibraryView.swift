import SwiftUI

// MARK: - 種目辞典画面

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDefinition?
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // カテゴリフィルター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                title: L10n.all,
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.selectedCategory = nil
                            }

                            ForEach(viewModel.categories, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
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

                    // 種目リスト
                    List(viewModel.filteredExercises) { exercise in
                        Button {
                            selectedExercise = exercise
                        } label: {
                            ExerciseLibraryRow(exercise: exercise)
                        }
                        .listRowBackground(Color.mmBgSecondary)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(L10n.exerciseLibrary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.exerciseLibrary)
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .searchable(text: $searchText, prompt: L10n.searchExercises)
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
    }
}

// MARK: - カテゴリフィルターチップ

private struct CategoryFilterChip: View {
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

// MARK: - 種目行（リッチUI）

private struct ExerciseLibraryRow: View {
    let exercise: ExerciseDefinition
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 12) {
            // ミニ筋肉マップ（ターゲット筋肉をハイライト）
            MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                .frame(width: 50, height: 70)
                .background(Color.mmBgCard.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 種目情報
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text(localization.currentLanguage == .japanese ? exercise.nameEN : exercise.nameJA)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                // 器具と難易度のタグ（カテゴリは上部フィルターで選択可能なので省略）
                HStack(spacing: 8) {
                    ExerciseTag(text: exercise.equipment, icon: "dumbbell")
                    ExerciseTag(text: exercise.difficulty, icon: "chart.bar")
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 種目タグ

private struct ExerciseTag: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2)
        .foregroundStyle(Color.mmTextSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.mmBgCard)
        .clipShape(Capsule())
    }
}

#Preview {
    ExerciseLibraryView()
}

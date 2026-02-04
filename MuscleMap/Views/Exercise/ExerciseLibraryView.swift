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

// MARK: - 種目行

private struct ExerciseLibraryRow: View {
    let exercise: ExerciseDefinition
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text(localization.currentLanguage == .japanese ? exercise.nameEN : exercise.nameJA)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                HStack(spacing: 12) {
                    Label(exercise.equipment, systemImage: "dumbbell")
                    Label(exercise.difficulty, systemImage: "chart.bar")
                    Label(exercise.category, systemImage: "tag")
                }
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExerciseLibraryView()
}

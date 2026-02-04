import SwiftUI
import SwiftData

// MARK: - 種目選択ビュー（シート表示）

struct ExercisePickerView: View {
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var searchText = ""
    @State private var muscleStates: [Muscle: MuscleStimulation] = [:]

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
                                title: "★ \(L10n.favorites)",
                                isSelected: viewModel.showFavoritesOnly
                            ) {
                                viewModel.showFavoritesOnly.toggle()
                                if viewModel.showFavoritesOnly {
                                    viewModel.selectedCategory = nil
                                }
                            }

                            CategoryChip(
                                title: L10n.all,
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

                    // 種目リスト or EmptyState
                    if viewModel.showFavoritesOnly && viewModel.filteredExercises.isEmpty {
                        FavoritesEmptyState()
                    } else {
                        List(viewModel.filteredExercises) { exercise in
                            Button {
                                onSelect(exercise)
                            } label: {
                                EnhancedExerciseRow(
                                    exercise: exercise,
                                    muscleStates: muscleStates
                                )
                            }
                            .listRowBackground(Color.mmBgSecondary)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(L10n.selectExercise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: L10n.searchExercises)
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                viewModel.load()
                loadMuscleStates()
            }
        }
    }

    private func loadMuscleStates() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        muscleStates = repo.fetchLatestStimulations()
    }
}

// MARK: - お気に入りEmptyState

private struct FavoritesEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            Text(L10n.noFavorites)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
            Text(L10n.addFavoritesHint)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
                    Label(exercise.equipment, systemImage: "dumbbell")
                    Label(exercise.difficulty, systemImage: "chart.bar")
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

// MARK: - 種目行（リッチ版：ミニマップ + 適合性バッジ付き）

struct EnhancedExerciseRow: View {
    let exercise: ExerciseDefinition
    let muscleStates: [Muscle: MuscleStimulation]
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var compatibility: ExerciseCompatibility {
        ExerciseCompatibilityCalculator.calculate(
            exercise: exercise,
            muscleStates: muscleStates
        )
    }

    private var exerciseName: String {
        localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
    }

    private var secondaryName: String {
        localization.currentLanguage == .japanese ? exercise.nameEN : exercise.nameJA
    }

    var body: some View {
        HStack(spacing: 12) {
            // ミニ筋肉マップ
            MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                .frame(width: 44, height: 70)
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 種目情報
            VStack(alignment: .leading, spacing: 4) {
                // 種目名（メイン）
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

                // 種目名（サブ）
                Text(secondaryName)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)

                // メタ情報
                HStack(spacing: 8) {
                    Label(exercise.equipment, systemImage: "dumbbell")
                    Label(exercise.difficulty, systemImage: "chart.bar")
                    if let primary = exercise.primaryMuscle {
                        Text(localization.currentLanguage == .japanese ? primary.japaneseName : primary.englishName)
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)

                // 適合性バッジ
                if let badge = compatibility.badge {
                    HStack(spacing: 4) {
                        if compatibility == .recommended {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                        }
                        Text(badge.text)
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(badge.color.opacity(0.15))
                    .foregroundStyle(badge.color)
                    .clipShape(Capsule())
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

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(for: [MuscleStimulation.self], inMemory: true)
}

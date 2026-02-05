import SwiftUI

// MARK: - 種目辞典画面

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @ObservedObject private var recentManager = RecentExercisesManager.shared
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDefinition?
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // フィルターチップ
                    filterChipsSection

                    // 種目数
                    HStack {
                        Text(L10n.exerciseCountLabel(viewModel.filteredExercises.count))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                    // 種目リスト or EmptyState
                    contentSection
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

    // MARK: - フィルターチップセクション

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 最近使った種目フィルター
                FilterChip(
                    title: "⏱ \(L10n.recent)",
                    isSelected: viewModel.showRecentOnly
                ) {
                    viewModel.showRecentOnly.toggle()
                    if viewModel.showRecentOnly {
                        viewModel.showFavoritesOnly = false
                        viewModel.selectedCategory = nil
                        viewModel.selectedEquipment = nil
                    }
                }

                // お気に入りフィルター
                FilterChip(
                    title: "★ \(L10n.favorites)",
                    isSelected: viewModel.showFavoritesOnly
                ) {
                    viewModel.showFavoritesOnly.toggle()
                    if viewModel.showFavoritesOnly {
                        viewModel.showRecentOnly = false
                        viewModel.selectedCategory = nil
                        viewModel.selectedEquipment = nil
                    }
                }

                // すべて
                FilterChip(
                    title: L10n.all,
                    isSelected: !viewModel.showRecentOnly && !viewModel.showFavoritesOnly && viewModel.selectedCategory == nil && viewModel.selectedEquipment == nil
                ) {
                    viewModel.clearAllFilters()
                }

                // カテゴリフィルター
                ForEach(viewModel.categories, id: \.self) { category in
                    FilterChip(
                        title: L10n.localizedCategory(category),
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.showRecentOnly = false
                        viewModel.showFavoritesOnly = false
                        viewModel.selectedEquipment = nil
                        viewModel.selectedCategory = category
                    }
                }

                // 器具フィルター
                ForEach(viewModel.equipmentList, id: \.self) { equipment in
                    FilterChip(
                        title: L10n.localizedEquipment(equipment),
                        isSelected: viewModel.selectedEquipment == equipment
                    ) {
                        viewModel.showRecentOnly = false
                        viewModel.showFavoritesOnly = false
                        viewModel.selectedCategory = nil
                        viewModel.selectedEquipment = equipment
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - コンテンツセクション

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.showRecentOnly && viewModel.filteredExercises.isEmpty {
            RecentEmptyState()
        } else if viewModel.showFavoritesOnly && viewModel.filteredExercises.isEmpty {
            FavoritesEmptyState()
        } else {
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
}

// MARK: - フィルターチップ

private struct FilterChip: View {
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

// MARK: - 最近使った種目EmptyState

private struct RecentEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            Text(L10n.noRecentExercises)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
            Text(L10n.recentExercisesHint)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
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

                // 日本語モード時のみ英語名サブタイトルを表示
                if localization.currentLanguage == .japanese {
                    Text(exercise.nameEN)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                // 器具と難易度のタグ
                HStack(spacing: 8) {
                    ExerciseTag(text: exercise.localizedEquipment, icon: "dumbbell")
                    ExerciseTag(text: exercise.localizedDifficulty, icon: "chart.bar")
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

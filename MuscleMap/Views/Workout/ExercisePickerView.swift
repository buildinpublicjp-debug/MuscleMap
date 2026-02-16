import SwiftUI
import SwiftData

// MARK: - 種目選択ビュー（シート表示）

struct ExercisePickerView: View {
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @ObservedObject private var recentManager = RecentExercisesManager.shared
    @State private var searchText = ""
    @State private var muscleStates: [Muscle: MuscleStimulation] = [:]
    @State private var previewExercise: ExerciseDefinition?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // フィルターチップ
                    filterChipsSection

                    // 種目リスト or EmptyState
                    contentSection
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
            .sheet(item: $previewExercise) { exercise in
                ExercisePreviewSheet(exercise: exercise) {
                    onSelect(exercise)
                }
            }
        }
    }

    // MARK: - フィルターチップセクション

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 最近使った種目フィルター（最優先）
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
                HStack(spacing: 0) {
                    // メイン行（タップで種目選択）
                    Button {
                        onSelect(exercise)
                    } label: {
                        EnhancedExerciseRow(
                            exercise: exercise,
                            muscleStates: muscleStates,
                            showChevron: false
                        )
                    }

                    // 情報ボタン（タップでプレビュー表示）
                    Button {
                        HapticManager.lightTap()
                        previewExercise = exercise
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(Color.mmAccentSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.mmBgSecondary)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func loadMuscleStates() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        muscleStates = repo.fetchLatestStimulations()
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
                    Label(exercise.localizedEquipment, systemImage: "dumbbell")
                    Label(exercise.localizedDifficulty, systemImage: "chart.bar")
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
    var showChevron: Bool = true
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
            // GIFサムネイル or ミニ筋肉マップ
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
            } else {
                MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                    .frame(width: 56, height: 56)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

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

                // メタ情報（器具 + メインターゲット）
                HStack(spacing: 8) {
                    Label(exercise.localizedEquipment, systemImage: "dumbbell")
                    if let primary = exercise.primaryMuscle {
                        Label(
                            localization.currentLanguage == .japanese ? primary.japaneseName : primary.englishName,
                            systemImage: "figure.strengthtraining.traditional"
                        )
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

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(for: [MuscleStimulation.self], inMemory: true)
}

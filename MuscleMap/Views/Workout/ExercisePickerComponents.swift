import SwiftUI
import SwiftData

// MARK: - フィルターチップセクション（回復ステータスドット付き）

struct PickerFilterChipsSection: View {
    @Bindable var viewModel: ExerciseListViewModel
    let muscleStates: [Muscle: MuscleStimulation]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 最近使った種目フィルター
                PickerFilterChip(
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
                PickerFilterChip(
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
                PickerFilterChip(
                    title: L10n.all,
                    isSelected: !viewModel.showRecentOnly && !viewModel.showFavoritesOnly && viewModel.selectedCategory == nil && viewModel.selectedEquipment == nil
                ) {
                    viewModel.clearAllFilters()
                }

                // カテゴリフィルター（回復ステータスドット付き）
                ForEach(viewModel.categories, id: \.self) { category in
                    PickerFilterChip(
                        title: L10n.localizedCategory(category),
                        isSelected: viewModel.selectedCategory == category,
                        recoveryDot: recoveryDotColor(for: category)
                    ) {
                        viewModel.showRecentOnly = false
                        viewModel.showFavoritesOnly = false
                        viewModel.selectedEquipment = nil
                        viewModel.selectedCategory = category
                    }
                }

                // 器具フィルター
                ForEach(viewModel.equipmentList, id: \.self) { equipment in
                    PickerFilterChip(
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

    // カテゴリに対応する筋肉グループの回復状態ドット色
    private func recoveryDotColor(for category: String) -> Color? {
        // カテゴリ名からMuscleGroupを推定
        guard let group = muscleGroupForCategory(category) else { return nil }
        let muscles = group.muscles

        // グループ内の筋肉の回復状態を集計
        var hasStimulation = false
        var totalProgress: Double = 0
        var count = 0
        var hasNeglected = false

        for muscle in muscles {
            guard let stim = muscleStates[muscle] else { continue }
            hasStimulation = true
            let days = RecoveryCalculator.daysSinceStimulation(stim.stimulationDate)
            if days >= 7 {
                hasNeglected = true
            } else {
                let progress = RecoveryCalculator.recoveryProgress(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets
                )
                totalProgress += progress
                count += 1
            }
        }

        if !hasStimulation { return nil }
        if hasNeglected && count == 0 { return .mmMuscleNeglected }

        let avgProgress = count > 0 ? totalProgress / Double(count) : 1.0
        if avgProgress >= 0.8 { return .mmMuscleRecovered }
        if avgProgress <= 0.3 { return .mmMuscleFatigued }
        return .mmMuscleModerate
    }

    private func muscleGroupForCategory(_ category: String) -> MuscleGroup? {
        // 日本語カテゴリ名 → MuscleGroup マッピング
        switch category {
        case "胸": return .chest
        case "背中": return .back
        case "肩": return .shoulders
        case "腕": return .arms
        case "体幹", "腹筋": return .core
        case "脚", "下半身": return .lowerBody
        default: return nil
        }
    }
}

// MARK: - フィルターチップ（回復ドット付き）

struct PickerFilterChip: View {
    let title: String
    let isSelected: Bool
    var recoveryDot: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let dotColor = recoveryDot {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.mmAccentPrimary : Color.mmBgCard)
            .foregroundStyle(isSelected ? Color.mmBgPrimary : Color.mmTextSecondary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - お気に入り横スクロール行

struct PickerFavoritesRow: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void
    @ObservedObject private var favorites = FavoritesManager.shared

    private var favoriteExercises: [ExerciseDefinition] {
        exercises.filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        if !favoriteExercises.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.favoritesSection)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(favoriteExercises) { exercise in
                            FavoriteExerciseChip(exercise: exercise) {
                                onSelect(exercise)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - お気に入り種目チップ

private struct FavoriteExerciseChip: View {
    let exercise: ExerciseDefinition
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // GIFサムネイル（小）
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Text(exercise.localizedName)
                    .font(.caption2.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)
            }
            .padding(.trailing, 8)
            .background(Color.mmBgSecondary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - 最近の検索行

struct PickerRecentSearchesRow: View {
    let searches: [String]
    let onSelect: (String) -> Void

    var body: some View {
        if !searches.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.recentSearches)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(searches, id: \.self) { query in
                            Button {
                                onSelect(query)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption2)
                                    Text(query)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.mmBgCard)
                                .foregroundStyle(Color.mmTextSecondary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

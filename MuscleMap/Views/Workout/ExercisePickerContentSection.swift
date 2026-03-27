import SwiftUI

// MARK: - コンテンツセクション（グリッド/リスト切替対応）

struct PickerContentSection: View {
    @Bindable var viewModel: ExerciseListViewModel
    let muscleStates: [Muscle: MuscleStimulation]
    let isGridView: Bool
    let onSelect: (ExerciseDefinition) -> Void
    let onPreview: (ExerciseDefinition) -> Void

    var body: some View {
        if viewModel.showRecentOnly && viewModel.filteredExercises.isEmpty {
            PickerEmptyState(
                icon: "clock.arrow.circlepath",
                title: L10n.noRecentExercises,
                subtitle: L10n.recentExercisesHint
            )
        } else if viewModel.showFavoritesOnly && viewModel.filteredExercises.isEmpty {
            PickerEmptyState(
                icon: "star.slash",
                title: L10n.noFavorites,
                subtitle: L10n.addFavoritesHint
            )
        } else if isGridView {
            gridContent
        } else {
            listContent
        }
    }

    // MARK: - グリッド表示

    private var gridContent: some View {
        ScrollView {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    PickerGridCard(
                        exercise: exercise,
                        muscleStates: muscleStates,
                        onSelect: { onSelect(exercise) },
                        onPreview: { onPreview(exercise) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - リスト表示

    private var listContent: some View {
        List(viewModel.filteredExercises) { exercise in
            HStack(spacing: 0) {
                // メイン行（タップで種目選択）
                Button {
                    HapticManager.lightTap()
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
                    onPreview(exercise)
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

// MARK: - グリッドカード

private struct PickerGridCard: View {
    let exercise: ExerciseDefinition
    let muscleStates: [Muscle: MuscleStimulation]
    let onSelect: () -> Void
    let onPreview: () -> Void
    @ObservedObject private var favorites = FavoritesManager.shared
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var compatibility: ExerciseCompatibility {
        ExerciseCompatibilityCalculator.calculate(
            exercise: exercise,
            muscleStates: muscleStates
        )
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // GIF or ミニマップ（上部120px）
                ZStack(alignment: .topTrailing) {
                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                        ExerciseGifView(exerciseId: exercise.id, size: .previewCard)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .clipped()
                    } else {
                        MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.mmBgPrimary.opacity(0.5))
                    }

                    // お気に入りハートアイコン
                    Button {
                        HapticManager.lightTap()
                        favorites.toggle(exercise.id)
                    } label: {
                        Image(systemName: favorites.isFavorite(exercise.id) ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(favorites.isFavorite(exercise.id) ? Color.mmDestructive : Color.mmTextSecondary)
                            .padding(6)
                            .background(Color.mmBgPrimary.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(6)
                }

                // 種目情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell")
                        Text(exercise.localizedEquipment)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)

                    // 適合性バッジ
                    if let badge = compatibility.badge {
                        Text(badge.text)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.15))
                            .foregroundStyle(badge.color)
                            .clipShape(Capsule())
                    }
                }
                .padding(8)
            }
            .background(Color.mmBgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyState（汎用）

struct PickerEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

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

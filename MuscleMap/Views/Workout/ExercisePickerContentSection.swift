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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(Color.mmBgSecondary)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - グリッドカード（Netflixスタイル — GIF + グラデーションオーバーレイ）

private struct PickerGridCard: View {
    let exercise: ExerciseDefinition
    let muscleStates: [Muscle: MuscleStimulation]
    let onSelect: () -> Void
    let onPreview: () -> Void
    @ObservedObject private var favorites = FavoritesManager.shared

    private var compatibility: ExerciseCompatibility {
        ExerciseCompatibilityCalculator.calculate(
            exercise: exercise,
            muscleStates: muscleStates
        )
    }

    /// 主要ターゲットの筋肉
    private var primaryMuscle: Muscle? {
        guard let maxEntry = exercise.muscleMapping.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return Muscle(rawValue: maxEntry.key) ?? Muscle(snakeCase: maxEntry.key)
    }

    var body: some View {
        let name = exercise.localizedName
        let muscleName: String? = primaryMuscle?.localizedName

        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    // GIF or ミニマップ（元の比率のまま）
                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                        ExerciseGifView(exerciseId: exercise.id, size: .card)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background(Color.mmGifBackground)
                            .clipped()
                    } else {
                        MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }

                    // 下部グラデーションオーバーレイ
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    // テキスト（グラデーションの上）
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if let muscleName {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.mmAccentPrimary)
                                    .frame(width: 5, height: 5)
                                Text(muscleName)
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.mmAccentPrimary)
                            }
                        }

                        // 適合性バッジ
                        if let badge = compatibility.badge {
                            Text(badge.text)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badge.color.opacity(0.2))
                                .foregroundStyle(badge.color)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(8)
                }

                // 追加ボタン
                Button {
                    HapticManager.lightTap()
                    onSelect()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.mmAccentPrimary)
                        .background(Color.mmBgPrimary.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding(6)
            }
            .aspectRatio(0.85, contentMode: .fill)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
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

    private var compatibility: ExerciseCompatibility {
        ExerciseCompatibilityCalculator.calculate(
            exercise: exercise,
            muscleStates: muscleStates
        )
    }

    private var exerciseName: String {
        exercise.localizedName
    }

    private var secondaryName: String {
        exercise.secondaryLocalizedName
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
                            primary.localizedName,
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

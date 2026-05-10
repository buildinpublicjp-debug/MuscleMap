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

    // MARK: - グリッド表示（種目辞典と同じ LibraryGridCard を再利用）

    private var gridContent: some View {
        ScrollView {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    LibraryGridCard(exercise: exercise) {
                        onSelect(exercise)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - リスト表示（種目辞典と同じ ExerciseLibraryRow を再利用、行末に詳細プレビュー i ボタン）

    private var listContent: some View {
        List(viewModel.filteredExercises) { exercise in
            HStack(spacing: 0) {
                // メイン行（タップで種目選択）
                Button {
                    HapticManager.lightTap()
                    onSelect(exercise)
                } label: {
                    ExerciseLibraryRow(exercise: exercise)
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


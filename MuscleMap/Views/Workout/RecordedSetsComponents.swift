import SwiftUI
import SwiftData

// MARK: - 記録済みセット一覧コンポーネント

/// 記録済みセット一覧ビュー
struct RecordedSetsView: View {
    let exerciseSets: [(exercise: ExerciseDefinition, sets: [WorkoutSet])]
    let onSelectExercise: (ExerciseDefinition) -> Void
    let onEditSet: (WorkoutSet) -> Void
    let onDeleteSet: (WorkoutSet) -> Void
    var latestSetId: UUID?
    var lastSetWasPR: Bool = false
    private var localization: LocalizationManager { LocalizationManager.shared }

    @State private var setToDelete: WorkoutSet?
    @State private var showingDeleteConfirm = false
    @State private var detailExercise: ExerciseDefinition?

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    /// セッション内で最大重量のセット（最初に出現したもののみ）
    private func isPRSet(_ set: WorkoutSet, in sets: [WorkoutSet]) -> Bool {
        guard set.weight > 0 else { return false }
        let maxWeight = sets.map(\.weight).max() ?? 0
        return set.weight == maxWeight &&
               sets.first(where: { $0.weight == maxWeight })?.id == set.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.recorded)
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .padding(.horizontal)

            ForEach(exerciseSets, id: \.exercise.id) { entry in
                VStack(alignment: .leading, spacing: 0) {
                    // 種目名（タップで遷移）+ info
                    HStack {
                        Button {
                            HapticManager.lightTap()
                            onSelectExercise(entry.exercise)
                        } label: {
                            Text(localization.currentLanguage == .japanese ? entry.exercise.nameJA : entry.exercise.nameEN)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                        }

                        Button {
                            HapticManager.lightTap()
                            detailExercise = entry.exercise
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            HapticManager.lightTap()
                            onSelectExercise(entry.exercise)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    List {
                        ForEach(entry.sets, id: \.id) { set in
                            let isLatest = set.id == latestSetId
                            let isPR = isLatest && lastSetWasPR
                            HStack {
                                Text(L10n.setNumber(set.setNumber))
                                    .font(.caption)
                                    .foregroundStyle(Color.mmTextSecondary)
                                    .frame(width: 50, alignment: .leading)
                                Spacer()
                                if entry.exercise.isBodyweight && set.weight == 0 {
                                    Text(L10n.repsOnly(set.reps))
                                        .font(.subheadline.bold().monospaced())
                                        .foregroundStyle(Color.mmTextPrimary)
                                } else {
                                    Text(L10n.weightReps(set.weight, set.reps))
                                        .font(.subheadline.bold().monospaced())
                                        .foregroundStyle(Color.mmTextPrimary)
                                }
                                // PRバッジ（過去最大重量を超えた場合）
                                if isPR {
                                    Text(L10n.prBadge)
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.mmPRGold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.mmPRGold.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                // PRマーク（セッション内最大重量）
                                if isPRSet(set, in: entry.sets) {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.mmPRGold)
                                }
                                Text(timeFormatter.string(from: set.completedAt))
                                    .font(.caption2)
                                    .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                                    .padding(.leading, 8)
                            }
                            .listRowBackground(
                                isPR
                                    ? Color.mmPRGold.opacity(0.08)
                                    : Color.mmBgCard
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    setToDelete = set
                                    showingDeleteConfirm = true
                                } label: {
                                    Label(L10n.delete, systemImage: "trash")
                                }
                                Button {
                                    HapticManager.lightTap()
                                    onEditSet(set)
                                } label: {
                                    Label(L10n.edit, systemImage: "pencil")
                                }
                                .tint(Color.mmAccentSecondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(height: CGFloat(entry.sets.count) * 48)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: entry.sets.count)
                    .padding(.bottom, 8)
                }
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .confirmationDialog(
            L10n.deleteSetConfirm,
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let set = setToDelete {
                    onDeleteSet(set)
                    setToDelete = nil
                }
            }
            Button(L10n.cancel, role: .cancel) {
                setToDelete = nil
            }
        }
        .sheet(item: $detailExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
            }
        }
    }
}

// MARK: - Preview

//#Preview {
//    // Preview requires full app context with Swift Data
//}

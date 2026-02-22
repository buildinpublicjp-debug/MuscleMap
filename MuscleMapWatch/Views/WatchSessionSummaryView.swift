import SwiftUI

// MARK: - Watch セッションサマリー画面
// 現在のセッションの種目別セット数一覧を表示
// 「ワークアウト終了」ボタンでセッションを終了し、ルートに戻る

struct WatchSessionSummaryView: View {
    @Environment(WatchWorkoutManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    @State private var showEndConfirmation: Bool = false

    var body: some View {
        List {
            // セッション情報
            sessionInfoSection

            // 種目別セット一覧
            exerciseSetsSection

            // 終了ボタン
            endWorkoutSection
        }
        .navigationTitle(WatchL10n.set(number: manager.recordedSets.count))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            WatchL10n.endWorkoutConfirm,
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button(WatchL10n.endWorkout, role: .destructive) {
                manager.endSession()
                dismiss()
            }
            Button(WatchL10n.cancel, role: .cancel) {}
        }
    }

    // MARK: - セッション情報

    private var sessionInfoSection: some View {
        Section {
            if let startDate = manager.sessionStartDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.green)
                    Text(elapsedTime(from: startDate))
                        .font(.footnote)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - 種目別セット一覧

    private var exerciseSetsSection: some View {
        let grouped = groupedSets
        return Section {
            if grouped.isEmpty {
                Text(WatchL10n.noData)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(grouped, id: \.exerciseId) { group in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.exerciseName)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text("\(group.sets.count) \(WatchL10n.reps)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // 最終セットの重量×レップ
                        if let lastSet = group.sets.last {
                            Text("\(String(format: "%.1f", lastSet.weight))\(WatchL10n.currentWeightUnit) × \(lastSet.reps)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 終了ボタン

    private var endWorkoutSection: some View {
        Section {
            Button(role: .destructive) {
                showEndConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text(WatchL10n.endWorkout)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - ヘルパー

    /// 記録済みセットを種目別にグループ化
    private var groupedSets: [ExerciseGroup] {
        var result: [ExerciseGroup] = []
        var seen = Set<String>()
        for set in manager.recordedSets {
            if !seen.contains(set.exerciseId) {
                seen.insert(set.exerciseId)
                let sets = manager.recordedSets.filter { $0.exerciseId == set.exerciseId }
                result.append(ExerciseGroup(
                    exerciseId: set.exerciseId,
                    exerciseName: set.exerciseName,
                    sets: sets
                ))
            }
        }
        return result
    }

    /// 経過時間のフォーマット
    private func elapsedTime(from startDate: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(startDate))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, elapsed % 60)
        }
        return String(format: "%d:%02d", minutes, elapsed % 60)
    }
}

// MARK: - 種目グループ構造体

private struct ExerciseGroup {
    let exerciseId: String
    let exerciseName: String
    let sets: [WatchRecordedSet]
}

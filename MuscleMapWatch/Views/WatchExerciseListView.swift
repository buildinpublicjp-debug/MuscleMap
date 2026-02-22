import SwiftUI

// MARK: - Watch 種目選択画面
// メイン画面。最近の種目・お気に入り・全種目カテゴリへのナビゲーションを提供
// セッション未開始の場合は「ワークアウト開始」ボタンを表示

struct WatchExerciseListView: View {
    @Environment(WatchWorkoutManager.self) private var manager

    var body: some View {
        NavigationStack {
            List {
                if !manager.isSessionActive {
                    // セッション未開始: 開始ボタン
                    Section {
                        Button {
                            manager.startSession()
                        } label: {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                Text(WatchL10n.startWorkout)
                                    .fontWeight(.semibold)
                            }
                        }
                        .tint(.green)
                    }
                } else {
                    // セッション中: サマリーへのリンク
                    Section {
                        NavigationLink {
                            WatchSessionSummaryView()
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.clipboard")
                                Text(WatchL10n.set(number: manager.recordedSets.count))
                                    .fontWeight(.medium)
                            }
                        }
                        .tint(.green)
                    }
                }

                // 最近の種目
                let recentExercises = manager.exerciseStore.recentExercises()
                if !recentExercises.isEmpty {
                    Section {
                        ForEach(recentExercises.prefix(10)) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        Text(WatchL10n.recentExercises)
                    }
                }

                // お気に入り
                let favorites = manager.exerciseStore.favoriteExercises()
                if !favorites.isEmpty {
                    Section {
                        ForEach(favorites.prefix(10)) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        Text(WatchL10n.favorites)
                    }
                }

                // 全種目（カテゴリ別）
                Section {
                    NavigationLink {
                        WatchExerciseCategoryView()
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text(WatchL10n.allExercises)
                        }
                    }
                } header: {
                    Text(WatchL10n.allExercises)
                }
            }
            .navigationTitle("MuscleMap")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 種目行

    @ViewBuilder
    private func exerciseRow(_ exercise: WatchExerciseInfo) -> some View {
        if manager.isSessionActive {
            // セッション中: タップで種目選択→セット入力画面へ
            NavigationLink {
                WatchSetInputView(exercise: exercise)
            } label: {
                exerciseLabel(exercise)
            }
        } else {
            // セッション未開始: タップでセッション開始→種目選択→セット入力
            Button {
                manager.startSession()
                manager.selectExercise(exercise)
            } label: {
                NavigationLink {
                    WatchSetInputView(exercise: exercise)
                } label: {
                    exerciseLabel(exercise)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func exerciseLabel(_ exercise: WatchExerciseInfo) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(WatchL10n.exerciseName(nameJA: exercise.nameJA, nameEN: exercise.nameEN))
                .font(.footnote)
                .fontWeight(.medium)
                .lineLimit(2)
            Text(WatchL10n.localizedCategory(exercise.category))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

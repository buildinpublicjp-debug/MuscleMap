import SwiftUI

// MARK: - Watch カテゴリ別種目一覧
// カテゴリ一覧 → カテゴリ内の種目一覧の2段階ナビゲーション

struct WatchExerciseCategoryView: View {
    @Environment(WatchWorkoutManager.self) private var manager

    var body: some View {
        List {
            ForEach(manager.exerciseStore.categories, id: \.self) { category in
                NavigationLink {
                    categoryExerciseList(category: category)
                } label: {
                    HStack {
                        Image(systemName: categoryIcon(category))
                            .foregroundStyle(.green)
                        Text(WatchL10n.localizedCategory(category))
                            .font(.footnote)
                    }
                }
            }
        }
        .navigationTitle(WatchL10n.allExercises)
    }

    // MARK: - カテゴリ内種目リスト

    @ViewBuilder
    private func categoryExerciseList(category: String) -> some View {
        let exercises = manager.exerciseStore.exercises(forCategory: category)
        List {
            ForEach(exercises) { exercise in
                if manager.isSessionActive {
                    NavigationLink {
                        WatchSetInputView(exercise: exercise)
                    } label: {
                        Text(WatchL10n.exerciseName(nameJA: exercise.nameJA, nameEN: exercise.nameEN))
                            .font(.footnote)
                            .lineLimit(2)
                    }
                } else {
                    Button {
                        manager.startSession()
                        manager.selectExercise(exercise)
                    } label: {
                        NavigationLink {
                            WatchSetInputView(exercise: exercise)
                        } label: {
                            Text(WatchL10n.exerciseName(nameJA: exercise.nameJA, nameEN: exercise.nameEN))
                                .font(.footnote)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(WatchL10n.localizedCategory(category))
    }

    // MARK: - カテゴリアイコン

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "胸": return "heart.fill"
        case "背中": return "figure.walk"
        case "肩": return "figure.arms.open"
        case "腕", "腕（二頭）", "腕（三頭）", "腕（前腕）": return "figure.boxing"
        case "体幹": return "figure.core.training"
        case "下半身", "下半身（四頭筋）", "下半身（ハムストリングス）",
             "下半身（臀部）", "下半身（ふくらはぎ）": return "figure.run"
        case "全身": return "figure.highintensity.intervaltraining"
        default: return "dumbbell.fill"
        }
    }
}

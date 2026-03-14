import Foundation
import SwiftData

// MARK: - 提案ワークアウト

/// メニュー自動提案の出力: 筋肉グループ + 具体的な種目リスト
struct RecommendedWorkout {
    let muscleGroup: String       // "背中・腕" など
    let exercises: [RecommendedExercise]
}

/// 提案種目（重量・レップ・セット数を含む）
struct RecommendedExercise: Identifiable {
    let exerciseId: String
    let exerciseName: String
    let suggestedWeight: Double   // 提案重量（kg）
    let suggestedReps: Int
    let suggestedSets: Int
    let previousWeight: Double?   // 前回重量（nil = 履歴なし）
    let weightIncrease: Double    // +2.5 or +1.25

    var id: String { exerciseId }
}

// MARK: - ワークアウト提案エンジン

/// 回復データ・過去の記録から具体的なメニュー（種目+重量+セット）を提案
struct WorkoutRecommendationEngine {

    /// 回復済みグループから具体的なメニューを生成
    /// - Parameters:
    ///   - suggestedMenu: MenuSuggestionServiceが生成した提案メニュー
    ///   - modelContext: SwiftDataのModelContext（前回記録取得用）
    /// - Returns: 具体的な種目・重量・セット提案（最大3種目）
    @MainActor
    static func generateRecommendation(
        suggestedMenu: SuggestedMenu,
        modelContext: ModelContext
    ) -> RecommendedWorkout {
        let exerciseStore = ExerciseStore.shared
        let favoritesManager = FavoritesManager.shared
        let pairedGroups = MenuSuggestionService.pairedGroups(for: suggestedMenu.primaryGroup)

        // グループ名を結合
        let groupName = pairedGroups.map { $0.localizedName }.joined(separator: "・")

        // 1. 回復済みグループの筋肉に対応する種目を収集
        var candidateExercises: [ExerciseDefinition] = []
        var seenIds: Set<String> = []

        for group in pairedGroups {
            for muscle in group.muscles {
                let exercises = exerciseStore.exercises(targeting: muscle)
                for ex in exercises {
                    if !seenIds.contains(ex.id) {
                        seenIds.insert(ex.id)
                        candidateExercises.append(ex)
                    }
                }
            }
        }

        // 2. お気に入り優先 → デフォルト順（exercises.json順＝人気順）でソート
        let favorites = candidateExercises.filter { favoritesManager.isFavorite($0.id) }
        let nonFavorites = candidateExercises.filter { !favoritesManager.isFavorite($0.id) }
        let sorted = favorites + nonFavorites

        // 3. 上位3種目を選出
        let topExercises = Array(sorted.prefix(3))

        // 4. 各種目の前回記録を取得し、重量提案を計算
        let workoutRepo = WorkoutRepository(modelContext: modelContext)
        var recommended: [RecommendedExercise] = []

        for exercise in topExercises {
            let isCompound = isCompoundExercise(exercise)
            let increment = isCompound ? 2.5 : 1.25

            let lastRecord = workoutRepo.fetchLastRecord(exerciseId: exercise.id)
            let previousWeight = lastRecord?.weight
            let previousReps = lastRecord?.reps ?? 10
            let previousSets: Int

            // 前回セット数を取得
            if let record = lastRecord,
               let session = record.session {
                let setsInSession = session.sets.filter { $0.exerciseId == exercise.id }
                previousSets = max(setsInSession.count, 3)
            } else {
                previousSets = 3
            }

            // 重量提案: 前回重量 + increment（前回記録なしの場合は0）
            let suggestedWeight: Double
            if let prev = previousWeight, prev > 0 {
                suggestedWeight = prev + increment
            } else {
                suggestedWeight = 0
            }

            recommended.append(RecommendedExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.localizedName,
                suggestedWeight: suggestedWeight,
                suggestedReps: previousReps,
                suggestedSets: previousSets,
                previousWeight: previousWeight,
                weightIncrease: increment
            ))
        }

        return RecommendedWorkout(
            muscleGroup: groupName,
            exercises: recommended
        )
    }

    // MARK: - コンパウンド判定

    /// 種目がコンパウンド（多関節）かアイソレーション（単関節）かを判定
    /// muscleMappingに3つ以上の筋肉がある = コンパウンドとみなす
    private static func isCompoundExercise(_ exercise: ExerciseDefinition) -> Bool {
        exercise.muscleMapping.count >= 3
    }
}

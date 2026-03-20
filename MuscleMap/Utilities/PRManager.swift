import Foundation
import SwiftData

// MARK: - 自己ベスト（PR）管理

@MainActor
class PRManager {
    static let shared = PRManager()

    private init() {}

    /// 指定種目の重量PR（最大重量）を取得
    func getWeightPR(exerciseId: String, context: ModelContext) -> Double? {
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let maxSet = try? context.fetch(descriptor).first else {
            return nil
        }
        return maxSet.weight
    }

    /// 指定重量が新しいPRかどうかをチェック
    func checkIsWeightPR(exerciseId: String, weight: Double, context: ModelContext) -> Bool {
        guard let currentPR = getWeightPR(exerciseId: exerciseId, context: context) else {
            // 記録がなければ初PRとなる
            return true
        }
        return weight > currentPR
    }

    /// 指定セッション以外の過去最大重量を取得（前回比用）
    func getPreviousWeightPR(exerciseId: String, excludingSessionId: UUID, context: ModelContext) -> Double? {
        // セッション除外はSwiftDataのPredicateでは困難なため、
        // 上位数件を取得して除外フィルタリング
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        guard let topSets = try? context.fetch(descriptor) else { return nil }
        return topSets.first(where: { $0.session?.id != excludingSessionId })?.weight
    }

    /// 今回セッションでPR更新した種目一覧を取得（前回重量と新重量のペア付き）
    func getSessionPRUpdates(session: WorkoutSession, context: ModelContext) -> [PRUpdate] {
        // 種目ごとにセッション内最大重量を取得
        var exerciseMaxInSession: [String: Double] = [:]
        for set in session.sets {
            let w = set.weight
            if w > (exerciseMaxInSession[set.exerciseId] ?? 0) {
                exerciseMaxInSession[set.exerciseId] = w
            }
        }

        var updates: [PRUpdate] = []
        for (exerciseId, maxWeight) in exerciseMaxInSession {
            guard let previousMax = getPreviousWeightPR(
                exerciseId: exerciseId,
                excludingSessionId: session.id,
                context: context
            ), previousMax > 0, maxWeight > previousMax else { continue }

            updates.append(PRUpdate(
                exerciseId: exerciseId,
                previousWeight: previousMax,
                newWeight: maxWeight
            ))
        }

        // 増加率が高い順にソート
        return updates.sorted { ($0.newWeight / $0.previousWeight) > ($1.newWeight / $1.previousWeight) }
    }

    /// 推定1RM（Epley式）
    func estimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// exerciseType考慮版の推定1RM
    /// - bodyweight: 体重+追加重量でEpley式
    /// - assisted: 体重-補助重量でEpley式（clamp to 0）
    /// - weighted: 通常のEpley式
    func effectiveEstimated1RM(
        weight: Double,
        reps: Int,
        exerciseId: String,
        bodyweightKg: Double
    ) -> Double {
        let exercise = ExerciseStore.shared.exercise(for: exerciseId)
        let type = exercise?.exerciseType ?? exerciseTypeFallback(for: exerciseId)

        switch type {
        case "bodyweight":
            let totalLoad = bodyweightKg + weight
            guard reps > 1 else { return totalLoad }
            return totalLoad * (1 + Double(reps) / 30.0)
        case "assisted":
            let effectiveLoad = max(0, bodyweightKg - weight)
            guard reps > 1 else { return effectiveLoad }
            return effectiveLoad * (1 + Double(reps) / 30.0)
        default: // "weighted"
            return estimated1RM(weight: weight, reps: reps)
        }
    }

    /// exerciseTypeフィールドがない場合のフォールバック
    private func exerciseTypeFallback(for exerciseId: String) -> String {
        let bodyweightIds: Set<String> = [
            "push_up", "chest_dip", "pull_up", "chin_up", "hyperextension",
            "tricep_dip", "crunch", "sit_up", "hanging_leg_raise", "plank",
            "side_plank", "russian_twist", "ab_roller", "mountain_climber",
            "bicycle_crunch", "glute_bridge", "burpee"
        ]
        let assistedIds: Set<String> = ["assisted_pull_up"]
        if assistedIds.contains(exerciseId) { return "assisted" }
        if bodyweightIds.contains(exerciseId) { return "bodyweight" }
        return "weighted"
    }

    /// 指定種目のベスト推定1RM（重量上位セットからEpley式で最大値を取得）
    func getBestEstimated1RM(exerciseId: String, context: ModelContext) -> Double? {
        // 推定1RMは weight*(1+reps/30) のため重量上位セットに絞って計算
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        guard let sets = try? context.fetch(descriptor), !sets.isEmpty else {
            return nil
        }
        return sets.map { estimated1RM(weight: $0.weight, reps: $0.reps) }.max()
    }

    /// 指定種目のベストeffective1RM（exerciseType考慮版）
    func getBestEffective1RM(exerciseId: String, bodyweightKg: Double, context: ModelContext) -> Double? {
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        guard let sets = try? context.fetch(descriptor), !sets.isEmpty else {
            return nil
        }
        return sets.map {
            effectiveEstimated1RM(weight: $0.weight, reps: $0.reps, exerciseId: exerciseId, bodyweightKg: bodyweightKg)
        }.max()
    }
}

// MARK: - PR更新情報

struct PRUpdate {
    let exerciseId: String
    let previousWeight: Double
    let newWeight: Double

    /// 増加率（%）
    var increasePercent: Int {
        guard previousWeight > 0 else { return 0 }
        return Int(((newWeight - previousWeight) / previousWeight) * 100)
    }
}

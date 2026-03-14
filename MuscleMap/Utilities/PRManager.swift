import Foundation
import SwiftData

// MARK: - 自己ベスト（PR）管理

@MainActor
class PRManager {
    static let shared = PRManager()

    private init() {}

    /// 指定種目の重量PR（最大重量）を取得
    func getWeightPR(exerciseId: String, context: ModelContext) -> Double? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
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
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        guard let allSets = try? context.fetch(descriptor) else { return nil }
        return allSets.first(where: { $0.session?.id != excludingSessionId })?.weight
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

    /// 指定種目のベスト推定1RM（全セットからEpley式で最大値を取得）
    func getBestEstimated1RM(exerciseId: String, context: ModelContext) -> Double? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId }
        )
        guard let sets = try? context.fetch(descriptor), !sets.isEmpty else {
            return nil
        }
        return sets.map { estimated1RM(weight: $0.weight, reps: $0.reps) }.max()
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

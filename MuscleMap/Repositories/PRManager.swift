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

    /// 指定セットがPRかどうかをチェック（記録後に判定用）
    func checkIsPR(set: WorkoutSet, context: ModelContext) -> Bool {
        let exerciseId = set.exerciseId
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { ws in
                ws.exerciseId == exerciseId
            },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        guard let allSets = try? context.fetch(descriptor) else {
            return true
        }
        // 自分以外のセットで最大重量を探す
        let otherSets = allSets.filter { $0.id != set.id }
        guard let previousMax = otherSets.first else {
            // 他に記録がなければPR
            return true
        }
        return set.weight > previousMax.weight
    }
}

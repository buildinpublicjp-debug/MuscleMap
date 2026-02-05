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

    /// 推定1RM（Epley式）
    func estimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
}

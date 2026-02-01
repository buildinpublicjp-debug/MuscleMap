import Foundation
import SwiftData

// MARK: - ワークアウトセット（1セット分の記録）

@Model
final class WorkoutSet {
    var id: UUID
    var session: WorkoutSession?
    /// exercises.json の id
    var exerciseId: String
    /// セット番号（1, 2, 3...）
    var setNumber: Int
    /// 重量（kg）
    var weight: Double
    /// レップ数
    var reps: Int
    var completedAt: Date

    init(
        id: UUID = UUID(),
        session: WorkoutSession? = nil,
        exerciseId: String,
        setNumber: Int,
        weight: Double,
        reps: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.session = session
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.completedAt = completedAt
    }
}

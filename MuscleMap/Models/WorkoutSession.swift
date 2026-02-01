import Foundation
import SwiftData

// MARK: - ワークアウトセッション

@Model
final class WorkoutSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]

    /// セッションが進行中かどうか
    var isActive: Bool { endDate == nil }

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        note: String? = nil,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
        self.sets = sets
    }
}

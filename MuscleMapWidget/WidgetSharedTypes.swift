import Foundation

// MARK: - ウィジェット共有データ型（メインアプリと同一定義）

struct WidgetMuscleData: Codable {
    let updatedAt: Date
    let streakDays: Int
    let suggestedGroup: String
    let suggestedReason: String
    let muscleStates: [String: MuscleSnapshot]

    struct MuscleSnapshot: Codable {
        let progress: Double
        let daysSinceStimulation: Int
        let state: StateType

        enum StateType: String, Codable {
            case inactive
            case recovering
            case neglected
            case neglectedSevere
        }
    }
}

import Foundation

// MARK: - ウィジェット共有データ型（簡素化版）

struct WidgetMuscleData: Codable {
    let updatedAt: Date
    let muscleStates: [String: MuscleSnapshot]

    struct MuscleSnapshot: Codable {
        let progress: Double          // 0.0-1.0 回復進捗
        let state: StateType          // 視覚状態

        enum StateType: String, Codable {
            case inactive
            case recovering
            case neglected
            case neglectedSevere
        }
    }
}

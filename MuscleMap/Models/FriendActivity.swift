import Foundation

/// フレンドのアクティビティ（将来サーバーから取得、今はモックデータ）
struct FriendActivity: Identifiable, Codable {
    let id: UUID
    let userName: String
    let avatarEmoji: String  // 将来は画像URL、今は絵文字
    let activityType: ActivityType
    let exerciseName: String?
    let weight: Double?
    let reps: Int?
    let isPR: Bool
    let stimulatedMuscles: [String]  // Muscle.rawValue の配列
    let timestamp: Date

    enum ActivityType: String, Codable {
        case workout    // ワークアウト完了
        case pr         // PR達成
        case streak     // 連続記録達成
    }
}

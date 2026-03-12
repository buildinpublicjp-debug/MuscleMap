import Foundation

// MARK: - モックフレンドデータ生成

/// ソーシャルフィード用のモックデータを提供
enum MockFriendData {

    // MARK: - 公開API

    /// モックフィードを生成（タイムスタンプ降順）
    static func generateMockFeed() -> [FriendActivity] {
        let friends = mockFriends
        var activities: [FriendActivity] = []

        for friend in friends {
            activities.append(contentsOf: generateActivities(for: friend))
        }

        return activities.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - モックフレンド定義

    private struct MockFriend {
        let name: String
        let emoji: String
    }

    private static let mockFriends: [MockFriend] = [
        MockFriend(name: "タクヤ", emoji: "💪"),
        MockFriend(name: "ユウキ", emoji: "🔥"),
        MockFriend(name: "アヤカ", emoji: "🏋️‍♀️"),
        MockFriend(name: "ケンタ", emoji: "🦾"),
        MockFriend(name: "ミホ", emoji: "✨"),
    ]

    // MARK: - アクティビティ生成

    private static func generateActivities(for friend: MockFriend) -> [FriendActivity] {
        let now = Date()

        switch friend.name {
        case "タクヤ":
            return [
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .pr,
                    exerciseName: "ベンチプレス",
                    weight: 100,
                    reps: 3,
                    isPR: true,
                    stimulatedMuscles: ["chest_upper", "chest_lower", "deltoid_anterior", "triceps"],
                    timestamp: now.addingTimeInterval(-1800)  // 30分前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "インクラインダンベルプレス",
                    weight: 32,
                    reps: 10,
                    isPR: false,
                    stimulatedMuscles: ["chest_upper", "deltoid_anterior", "triceps"],
                    timestamp: now.addingTimeInterval(-3600)  // 1時間前
                ),
            ]

        case "ユウキ":
            return [
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "デッドリフト",
                    weight: 180,
                    reps: 5,
                    isPR: false,
                    stimulatedMuscles: ["erector_spinae", "glutes", "hamstrings", "lats", "traps_upper"],
                    timestamp: now.addingTimeInterval(-5400)  // 1.5時間前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .streak,
                    exerciseName: nil,
                    weight: nil,
                    reps: nil,
                    isPR: false,
                    stimulatedMuscles: [],
                    timestamp: now.addingTimeInterval(-7200)  // 2時間前
                ),
            ]

        case "アヤカ":
            return [
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .pr,
                    exerciseName: "スクワット",
                    weight: 80,
                    reps: 5,
                    isPR: true,
                    stimulatedMuscles: ["quadriceps", "glutes", "hamstrings", "erector_spinae"],
                    timestamp: now.addingTimeInterval(-10800)  // 3時間前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "レッグプレス",
                    weight: 120,
                    reps: 12,
                    isPR: false,
                    stimulatedMuscles: ["quadriceps", "glutes"],
                    timestamp: now.addingTimeInterval(-12600)  // 3.5時間前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "レッグカール",
                    weight: 40,
                    reps: 15,
                    isPR: false,
                    stimulatedMuscles: ["hamstrings", "gastrocnemius"],
                    timestamp: now.addingTimeInterval(-14400)  // 4時間前
                ),
            ]

        case "ケンタ":
            return [
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "懸垂",
                    weight: 10,
                    reps: 8,
                    isPR: false,
                    stimulatedMuscles: ["lats", "biceps", "traps_middle_lower", "deltoid_posterior"],
                    timestamp: now.addingTimeInterval(-18000)  // 5時間前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .pr,
                    exerciseName: "バーベルロウ",
                    weight: 90,
                    reps: 6,
                    isPR: true,
                    stimulatedMuscles: ["lats", "traps_middle_lower", "erector_spinae", "biceps"],
                    timestamp: now.addingTimeInterval(-21600)  // 6時間前
                ),
            ]

        case "ミホ":
            return [
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .streak,
                    exerciseName: nil,
                    weight: nil,
                    reps: nil,
                    isPR: false,
                    stimulatedMuscles: [],
                    timestamp: now.addingTimeInterval(-14400)  // 4時間前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "ヒップスラスト",
                    weight: 60,
                    reps: 12,
                    isPR: false,
                    stimulatedMuscles: ["glutes", "hamstrings"],
                    timestamp: now.addingTimeInterval(-16200)  // 4.5時間前
                ),
                FriendActivity(
                    id: UUID(),
                    userName: friend.name,
                    avatarEmoji: friend.emoji,
                    activityType: .workout,
                    exerciseName: "アブダクション",
                    weight: 30,
                    reps: 15,
                    isPR: false,
                    stimulatedMuscles: ["glutes", "adductors"],
                    timestamp: now.addingTimeInterval(-18000)  // 5時間前
                ),
            ]

        default:
            return []
        }
    }
}

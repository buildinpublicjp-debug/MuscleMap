import Foundation

// MARK: - Watch ↔ iPhone 同期メッセージ型

/// 同期メッセージタイプ
enum WatchSyncMessageType: String, Codable {
    case sessionStart
    case setRecorded
    case sessionEnd
}

/// Watch→iPhone: セッション/セットの同期レコード
struct WatchSyncRecord: Codable {
    let type: WatchSyncMessageType
    let sessionId: String       // UUID文字列
    let setId: String?          // セット記録時のみ
    let exerciseId: String?
    let setNumber: Int?
    let weight: Double?
    let reps: Int?
    let timestamp: TimeInterval // Date().timeIntervalSince1970

    /// セッション開始メッセージを生成
    static func sessionStart(sessionId: UUID) -> WatchSyncRecord {
        WatchSyncRecord(
            type: .sessionStart,
            sessionId: sessionId.uuidString,
            setId: nil,
            exerciseId: nil,
            setNumber: nil,
            weight: nil,
            reps: nil,
            timestamp: Date().timeIntervalSince1970
        )
    }

    /// セット記録メッセージを生成
    static func setRecorded(
        sessionId: UUID,
        setId: UUID,
        exerciseId: String,
        setNumber: Int,
        weight: Double,
        reps: Int
    ) -> WatchSyncRecord {
        WatchSyncRecord(
            type: .setRecorded,
            sessionId: sessionId.uuidString,
            setId: setId.uuidString,
            exerciseId: exerciseId,
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            timestamp: Date().timeIntervalSince1970
        )
    }

    /// セッション終了メッセージを生成
    static func sessionEnd(sessionId: UUID) -> WatchSyncRecord {
        WatchSyncRecord(
            type: .sessionEnd,
            sessionId: sessionId.uuidString,
            setId: nil,
            exerciseId: nil,
            setNumber: nil,
            weight: nil,
            reps: nil,
            timestamp: Date().timeIntervalSince1970
        )
    }

    /// Dictionary変換（transferUserInfo用）
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "type": type.rawValue,
            "sessionId": sessionId,
            "timestamp": timestamp
        ]
        if let setId { dict["setId"] = setId }
        if let exerciseId { dict["exerciseId"] = exerciseId }
        if let setNumber { dict["setNumber"] = setNumber }
        if let weight { dict["weight"] = weight }
        if let reps { dict["reps"] = reps }
        return dict
    }

    /// Dictionaryから復元
    static func from(_ dict: [String: Any]) -> WatchSyncRecord? {
        guard let typeRaw = dict["type"] as? String,
              let type = WatchSyncMessageType(rawValue: typeRaw),
              let sessionId = dict["sessionId"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return WatchSyncRecord(
            type: type,
            sessionId: sessionId,
            setId: dict["setId"] as? String,
            exerciseId: dict["exerciseId"] as? String,
            setNumber: dict["setNumber"] as? Int,
            weight: dict["weight"] as? Double,
            reps: dict["reps"] as? Int,
            timestamp: timestamp
        )
    }
}

// MARK: - iPhone→Watch applicationContext キー

enum WatchSyncKeys {
    static let exercises = "syncExercises"
    static let recentIds = "syncRecentIds"
    static let favoriteIds = "syncFavoriteIds"
    static let weightUnit = "syncWeightUnit"
    static let restTimerDuration = "syncRestTimerDuration"
    static let language = "syncLanguage"
}

/// Watch用の軽量エクササイズ情報
struct WatchExerciseInfo: Codable, Identifiable, Hashable {
    let id: String
    let nameEN: String
    let nameJA: String
    let category: String
    let equipment: String
    let muscleMapping: [String: Int]
}

import Foundation

// MARK: - ユーザールーティン

/// オンボーディングで作成する週間ルーティン
struct UserRoutine: Codable {
    var days: [RoutineDay]
    var createdAt: Date

    static let `default` = UserRoutine(days: [], createdAt: Date())
}

/// ルーティンの1日分
struct RoutineDay: Codable, Identifiable {
    var id: UUID
    var name: String
    /// 対象筋肉グループのrawValue配列（例: ["chest", "shoulders"]）
    var muscleGroups: [String]
    var exercises: [RoutineExercise]
    /// トレーニング場所 ("gym" / "home" / "both")
    var location: String

    init(id: UUID = UUID(), name: String, muscleGroups: [String], exercises: [RoutineExercise] = [], location: String = "gym") {
        self.id = id
        self.name = name
        self.muscleGroups = muscleGroups
        self.exercises = exercises
        self.location = location
    }

    /// 後方互換: location が保存されていない旧データでもデコード可能
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        muscleGroups = try container.decode([String].self, forKey: .muscleGroups)
        exercises = try container.decode([RoutineExercise].self, forKey: .exercises)
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? "gym"
    }
}

/// ルーティン内の1種目
struct RoutineExercise: Codable, Identifiable {
    var id: UUID
    var exerciseId: String
    var suggestedSets: Int
    var suggestedReps: Int

    init(id: UUID = UUID(), exerciseId: String, suggestedSets: Int = 3, suggestedReps: Int = 10) {
        self.id = id
        self.exerciseId = exerciseId
        self.suggestedSets = suggestedSets
        self.suggestedReps = suggestedReps
    }
}

// MARK: - UserDefaults永続化

extension UserRoutine {
    private static let storageKey = "userRoutine"

    static func load() -> UserRoutine {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(UserRoutine.self, from: data)
        } catch {
            #if DEBUG
            print("[UserRoutine] Failed to decode: \(error)")
            #endif
            return .default
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            #if DEBUG
            print("[UserRoutine] Failed to encode: \(error)")
            #endif
        }
    }
}

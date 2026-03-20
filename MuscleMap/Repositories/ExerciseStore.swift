import Foundation

// MARK: - エクササイズストア（exercises.jsonの読み込み・検索）

@MainActor
final class ExerciseStore {
    static let shared = ExerciseStore()

    private(set) var exercises: [ExerciseDefinition] = []
    private var exerciseMap: [String: ExerciseDefinition] = [:]

    private init() {}

    // MARK: 読み込み

    /// Bundleからexercises.jsonを読み込む
    func load() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            #if DEBUG
            print("[ExerciseStore] exercises.json not found in bundle")
            print("[ExerciseStore] Bundle path: \(Bundle.main.bundlePath)")
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([ExerciseDefinition].self, from: data)
            exercises = decoded
            exerciseMap = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
            #if DEBUG
            print("[ExerciseStore] Loaded \(decoded.count) exercises")
            #endif
        } catch {
            #if DEBUG
            print("[ExerciseStore] Failed to decode exercises.json: \(error)")
            #endif
        }
    }

    /// まだ読み込まれていなければ再読み込み
    func loadIfNeeded() {
        if exercises.isEmpty {
            load()
        }
    }

    /// テスト用：データを直接設定
    func load(from data: Data) {
        do {
            let decoded = try JSONDecoder().decode([ExerciseDefinition].self, from: data)
            exercises = decoded
            exerciseMap = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        } catch {
            #if DEBUG
            print("[ExerciseStore] Failed to decode test data: \(error)")
            #endif
            exercises = []
            exerciseMap = [:]
        }
    }

    // MARK: 検索

    /// IDでエクササイズを取得
    func exercise(for id: String) -> ExerciseDefinition? {
        exerciseMap[id]
    }

    /// 指定筋肉をターゲットにする種目を取得
    func exercises(targeting muscle: String) -> [ExerciseDefinition] {
        exercises.filter { $0.muscleMapping[muscle] != nil }
    }

    /// 指定筋肉をターゲットにする種目を刺激度%順で取得
    func exercises(targeting muscle: Muscle) -> [ExerciseDefinition] {
        exercises
            .filter { $0.muscleMapping[muscle.rawValue] != nil }
            .sorted { ($0.muscleMapping[muscle.rawValue] ?? 0) > ($1.muscleMapping[muscle.rawValue] ?? 0) }
    }

    /// IDからローカライズ済み種目名を取得
    func exerciseName(for id: String) -> String? {
        exerciseMap[id]?.localizedName
    }

    /// 指定筋肉リストの代表種目を取得（場所フィルター対応、重複除去、最大limit件）
    func sampleExercises(for muscles: [Muscle], location: String, limit: Int = 3) -> [ExerciseDefinition] {
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
        var result: [ExerciseDefinition] = []
        for muscle in muscles {
            let matching = exercises(targeting: muscle)
            if location == "home" {
                let filtered = matching.filter { homeEquipment.contains($0.equipment) }
                if let first = filtered.first, !result.contains(where: { $0.id == first.id }) {
                    result.append(first)
                }
            } else {
                if let first = matching.first, !result.contains(where: { $0.id == first.id }) {
                    result.append(first)
                }
            }
            if result.count >= limit { break }
        }
        return result
    }

}

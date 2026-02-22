import Foundation

// MARK: - Watch用エクササイズストア
// iPhone側からapplicationContextで同期されたデータ、またはバンドルのexercises.jsonから読み込む

final class WatchExerciseStore {
    // MARK: - 定数（UserDefaultsキー）
    private let exercisesKey = "watchExercises"
    private let recentIdsKey = "watchRecentIds"
    private let favoriteIdsKey = "watchFavoriteIds"

    // MARK: - プロパティ
    private(set) var exercises: [WatchExerciseInfo] = []
    private(set) var recentIds: [String] = []
    private(set) var favoriteIds: [String] = []
    private var exerciseMap: [String: WatchExerciseInfo] = [:]

    // MARK: - 初期化

    init() {
        // UserDefaultsから復元を試みる
        if let data = UserDefaults.standard.data(forKey: exercisesKey),
           let decoded = try? JSONDecoder().decode([WatchExerciseInfo].self, from: data),
           !decoded.isEmpty {
            exercises = decoded
            buildMap()
            #if DEBUG
            print("[WatchExerciseStore] UserDefaultsから\(decoded.count)件のエクササイズを復元")
            #endif
        } else {
            // フォールバック: バンドルのexercises.jsonから読み込み
            loadFromBundle()
        }

        // 最近使った種目IDと気に入りIDを復元
        recentIds = UserDefaults.standard.stringArray(forKey: recentIdsKey) ?? []
        favoriteIds = UserDefaults.standard.stringArray(forKey: favoriteIdsKey) ?? []
    }

    // MARK: - iPhone同期データから読み込み

    /// applicationContextで受信したJSONデータから[WatchExerciseInfo]をデコードしてUserDefaultsに保存
    func loadFromSync(data: Data) {
        do {
            let decoded = try JSONDecoder().decode([WatchExerciseInfo].self, from: data)
            exercises = decoded
            buildMap()
            // UserDefaultsに永続化
            UserDefaults.standard.set(data, forKey: exercisesKey)
            #if DEBUG
            print("[WatchExerciseStore] 同期データから\(decoded.count)件のエクササイズを読み込み")
            #endif
        } catch {
            #if DEBUG
            print("[WatchExerciseStore] 同期データのデコードに失敗: \(error)")
            #endif
        }
    }

    /// 最近使った種目IDを同期データから更新
    func updateRecentIds(_ ids: [String]) {
        recentIds = ids
        UserDefaults.standard.set(ids, forKey: recentIdsKey)
    }

    /// お気に入りIDを同期データから更新
    func updateFavoriteIds(_ ids: [String]) {
        favoriteIds = ids
        UserDefaults.standard.set(ids, forKey: favoriteIdsKey)
    }

    // MARK: - バンドルからのフォールバック読み込み

    /// exercises.jsonを読み込み、ExerciseDefinition→WatchExerciseInfoに変換
    func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            #if DEBUG
            print("[WatchExerciseStore] exercises.json がバンドルに見つかりません")
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            // exercises.jsonはExerciseDefinition形式なので、必要なフィールドだけ抽出
            let decoded = try JSONDecoder().decode([BundleExercise].self, from: data)
            exercises = decoded.map { exercise in
                WatchExerciseInfo(
                    id: exercise.id,
                    nameEN: exercise.nameEN,
                    nameJA: exercise.nameJA,
                    category: exercise.category,
                    equipment: exercise.equipment,
                    muscleMapping: exercise.muscleMapping
                )
            }
            buildMap()
            #if DEBUG
            print("[WatchExerciseStore] バンドルから\(exercises.count)件のエクササイズを読み込み")
            #endif
        } catch {
            #if DEBUG
            print("[WatchExerciseStore] exercises.jsonのデコードに失敗: \(error)")
            #endif
        }
    }

    // MARK: - 検索

    /// カテゴリで絞り込み
    func exercises(forCategory category: String) -> [WatchExerciseInfo] {
        exercises.filter { $0.category == category }
    }

    /// IDでエクササイズを取得
    func exercise(forId id: String) -> WatchExerciseInfo? {
        exerciseMap[id]
    }

    /// 最近使った種目を順番通りに返す
    func recentExercises(ids: [String]? = nil) -> [WatchExerciseInfo] {
        let targetIds = ids ?? recentIds
        return targetIds.compactMap { exerciseMap[$0] }
    }

    /// お気に入り種目を返す
    func favoriteExercises() -> [WatchExerciseInfo] {
        favoriteIds.compactMap { exerciseMap[$0] }
    }

    /// ユニークなカテゴリリスト（exercises.jsonの登場順を維持）
    var categories: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for exercise in exercises {
            if !seen.contains(exercise.category) {
                seen.insert(exercise.category)
                result.append(exercise.category)
            }
        }
        return result
    }

    // MARK: - 内部

    /// IDマップを構築
    private func buildMap() {
        exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }
}

// MARK: - バンドルJSON用の中間デコード型

/// exercises.jsonのフル形式（バンドル読み込み用、不要フィールドは無視）
private struct BundleExercise: Decodable {
    let id: String
    let nameEN: String
    let nameJA: String
    let category: String
    let equipment: String
    let muscleMapping: [String: Int]
}

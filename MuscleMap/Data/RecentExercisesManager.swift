import Foundation

// MARK: - 最近使った種目マネージャー

@MainActor
class RecentExercisesManager: ObservableObject {
    static let shared = RecentExercisesManager()

    private let key = "recentExerciseIds"
    private let maxCount = 10

    @Published private(set) var recentIds: [String] = []

    private init() {
        loadFromStorage()
    }

    // MARK: - 種目を使用履歴に追加

    /// 種目を使用履歴に追加（先頭に挿入、重複除去、最大10件）
    func recordUsage(_ exerciseId: String) {
        // 既存のリストから重複を除去
        var ids = recentIds.filter { $0 != exerciseId }

        // 先頭に追加
        ids.insert(exerciseId, at: 0)

        // 最大件数に制限
        if ids.count > maxCount {
            ids = Array(ids.prefix(maxCount))
        }

        recentIds = ids
        saveToStorage()
    }

    // MARK: - 最近使った種目IDリストを取得

    func getRecentIds() -> [String] {
        recentIds
    }

    // MARK: - 永続化

    private func loadFromStorage() {
        if let ids = UserDefaults.standard.stringArray(forKey: key) {
            recentIds = ids
        }
    }

    private func saveToStorage() {
        UserDefaults.standard.set(recentIds, forKey: key)
    }

    // MARK: - クリア（デバッグ用）

    func clear() {
        recentIds = []
        UserDefaults.standard.removeObject(forKey: key)
    }
}

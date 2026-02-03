import Foundation

// MARK: - お気に入り管理

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    private let key = "favoriteExerciseIds"
    
    @Published private(set) var favoriteIds: Set<String> = []
    
    private init() {
        loadFavorites()
    }
    
    // MARK: - Public
    
    /// お気に入りか判定
    func isFavorite(_ exerciseId: String) -> Bool {
        favoriteIds.contains(exerciseId)
    }
    
    /// お気に入りをトグル
    func toggle(_ exerciseId: String) {
        if favoriteIds.contains(exerciseId) {
            favoriteIds.remove(exerciseId)
        } else {
            favoriteIds.insert(exerciseId)
        }
        saveFavorites()
    }
    
    /// お気に入りに追加
    func add(_ exerciseId: String) {
        favoriteIds.insert(exerciseId)
        saveFavorites()
    }
    
    /// お気に入りから削除
    func remove(_ exerciseId: String) {
        favoriteIds.remove(exerciseId)
        saveFavorites()
    }
    
    // MARK: - Private
    
    private func loadFavorites() {
        if let array = UserDefaults.standard.stringArray(forKey: key) {
            favoriteIds = Set(array)
        }
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: key)
    }
}

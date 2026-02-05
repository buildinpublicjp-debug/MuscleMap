import Foundation

// MARK: - 種目辞典ViewModel

@MainActor
@Observable
class ExerciseListViewModel {
    private let exerciseStore: ExerciseStore
    private var isBatchUpdating = false

    var exercises: [ExerciseDefinition] = []
    var filteredExercises: [ExerciseDefinition] = []
    var categories: [String] = []
    var equipmentList: [String] = []

    var selectedCategory: String? {
        didSet { if !isBatchUpdating { applyFilters() } }
    }

    var searchText: String = "" {
        didSet { if !isBatchUpdating { applyFilters() } }
    }

    var showFavoritesOnly: Bool = false {
        didSet { if !isBatchUpdating { applyFilters() } }
    }

    var showRecentOnly: Bool = false {
        didSet { if !isBatchUpdating { applyFilters() } }
    }

    var selectedEquipment: String? {
        didSet { if !isBatchUpdating { applyFilters() } }
    }

    init() {
        self.exerciseStore = ExerciseStore.shared
    }

    /// データ読み込み
    func load() {
        exerciseStore.loadIfNeeded()
        exercises = exerciseStore.exercises

        // カテゴリ一覧を抽出（順序を保持）
        var seenCategories = Set<String>()
        categories = exercises.compactMap { ex in
            if seenCategories.contains(ex.category) { return nil }
            seenCategories.insert(ex.category)
            return ex.category
        }

        // 器具一覧を抽出（順序を保持）
        var seenEquipment = Set<String>()
        equipmentList = exercises.compactMap { ex in
            if seenEquipment.contains(ex.equipment) { return nil }
            seenEquipment.insert(ex.equipment)
            return ex.equipment
        }

        applyFilters()
    }

    /// フィルター適用
    func applyFilters() {
        var result = exercises

        // 最近使った種目フィルター
        if showRecentOnly {
            let recentIds = RecentExercisesManager.shared.getRecentIds()
            if recentIds.isEmpty {
                filteredExercises = []
                return
            }
            // 最近使った順序を維持
            let exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
            result = recentIds.compactMap { exerciseMap[$0] }
        }

        // お気に入りフィルター
        if showFavoritesOnly {
            let favIds = FavoritesManager.shared.favoriteIds
            result = result.filter { favIds.contains($0.id) }
        }

        // カテゴリフィルター
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // 器具フィルター
        if let equipment = selectedEquipment {
            result = result.filter { $0.equipment == equipment }
        }

        // テキスト検索
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.nameJA.lowercased().contains(query) ||
                $0.nameEN.lowercased().contains(query) ||
                $0.equipment.lowercased().contains(query)
            }
        }

        filteredExercises = result
    }

    /// フィルターをすべてクリア（didSetの多重発火を回避）
    func clearAllFilters() {
        isBatchUpdating = true
        showFavoritesOnly = false
        showRecentOnly = false
        selectedCategory = nil
        selectedEquipment = nil
        searchText = ""
        isBatchUpdating = false
        applyFilters()
    }

    /// 指定筋肉をターゲットにする種目を取得
    func exercises(targeting muscle: Muscle) -> [ExerciseDefinition] {
        exerciseStore.exercises(targeting: muscle)
    }
}

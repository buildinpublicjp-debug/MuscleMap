import Foundation

// MARK: - 種目辞典ViewModel

@MainActor
@Observable
class ExerciseListViewModel {
    private let exerciseStore: ExerciseStore
    private var isBatchUpdating = false
    private let recentSearchesKey = "recentExerciseSearches"

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

    /// 最近の検索ワード（最大3件）
    var recentSearches: [String] {
        UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    init() {
        self.exerciseStore = ExerciseStore.shared
    }

    /// 検索履歴を記録（最大3件、重複排除）
    func recordSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var searches = recentSearches
        searches.removeAll { $0 == trimmed }
        searches.insert(trimmed, at: 0)
        if searches.count > 3 {
            searches = Array(searches.prefix(3))
        }
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
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

        // テキスト検索（強化版：筋肉名、ローカライズ器具名、筋肉グループ名も対象）
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { exercise in
                // 種目名（日英）
                if exercise.nameJA.lowercased().contains(query) { return true }
                if exercise.nameEN.lowercased().contains(query) { return true }

                // 器具名（raw + localized）
                if exercise.equipment.lowercased().contains(query) { return true }
                if exercise.localizedEquipment.lowercased().contains(query) { return true }

                // ターゲット筋肉名で検索
                for muscleId in exercise.muscleMapping.keys {
                    if let muscle = Muscle(rawValue: muscleId) {
                        if muscle.japaneseName.lowercased().contains(query) { return true }
                        if muscle.englishName.lowercased().contains(query) { return true }
                    }
                }

                // 筋肉グループ名で検索
                for group in MuscleGroup.allCases {
                    let matchesGroup = group.japaneseName.lowercased().contains(query) ||
                        group.englishName.lowercased().contains(query)
                    if matchesGroup {
                        let groupMuscleIds = Set(group.muscles.map { $0.rawValue })
                        if !exercise.muscleMapping.keys.filter({ groupMuscleIds.contains($0) }).isEmpty {
                            return true
                        }
                    }
                }

                return false
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

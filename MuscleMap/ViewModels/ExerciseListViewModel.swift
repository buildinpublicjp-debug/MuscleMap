import Foundation

// MARK: - 種目辞典ViewModel

@MainActor
@Observable
class ExerciseListViewModel {
    private let exerciseStore: ExerciseStore

    var exercises: [ExerciseDefinition] = []
    var filteredExercises: [ExerciseDefinition] = []
    var categories: [String] = []

    var selectedCategory: String? {
        didSet { applyFilters() }
    }

    var searchText: String = "" {
        didSet { applyFilters() }
    }

    var showFavoritesOnly: Bool = false {
        didSet { applyFilters() }
    }

    init() {
        self.exerciseStore = ExerciseStore.shared
    }

    /// データ読み込み
    func load() {
        exerciseStore.loadIfNeeded()
        exercises = exerciseStore.exercises
        // カテゴリ一覧を抽出（順序を保持）
        var seen = Set<String>()
        categories = exercises.compactMap { ex in
            if seen.contains(ex.category) { return nil }
            seen.insert(ex.category)
            return ex.category
        }
        applyFilters()
    }

    /// フィルター適用
    private func applyFilters() {
        var result = exercises

        // お気に入りフィルター
        if showFavoritesOnly {
            let favIds = FavoritesManager.shared.favoriteIds
            result = result.filter { favIds.contains($0.id) }
        }

        // カテゴリフィルター
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
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

    /// 指定筋肉をターゲットにする種目を取得
    func exercises(targeting muscle: Muscle) -> [ExerciseDefinition] {
        exerciseStore.exercises(targeting: muscle)
    }
}

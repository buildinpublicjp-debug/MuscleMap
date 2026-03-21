import Foundation
import SwiftData

// MARK: - 器具フィルタ定義

@MainActor
struct EquipmentFilter: Identifiable, Equatable {
    let id: String      // JSON key（バーベル, ダンベル etc.）
    let labelJA: String
    let labelEN: String

    var localizedLabel: String {
        LocalizationManager.shared.currentLanguage == .japanese ? labelJA : labelEN
    }

    static let allFilters: [EquipmentFilter] = [
        EquipmentFilter(id: "バーベル", labelJA: "バーベル", labelEN: "Barbell"),
        EquipmentFilter(id: "ダンベル", labelJA: "ダンベル", labelEN: "Dumbbell"),
        EquipmentFilter(id: "マシン", labelJA: "マシン", labelEN: "Machine"),
        EquipmentFilter(id: "ケーブル", labelJA: "ケーブル", labelEN: "Cable"),
        EquipmentFilter(id: "自重", labelJA: "自重", labelEN: "Bodyweight"),
    ]
}

// MARK: - 部位詳細ViewModel

@MainActor
@Observable
class MuscleDetailViewModel {
    private let muscleStateRepo: MuscleStateRepository
    private let workoutRepo: WorkoutRepository
    private let exerciseStore: ExerciseStore

    // 対象筋肉
    let muscle: Muscle

    // 回復状態
    var recoveryStatus: RecoveryStatus = .fullyRecovered
    var recoveryProgress: Double = 1.0
    var lastStimulationDate: Date?
    var lastTotalSets: Int = 0

    // 器具フィルタ（nil = すべて表示）
    var selectedEquipment: String? = nil

    // 関連種目（フィルタ前の全種目、お気に入り優先ソート済み）
    var allRelatedExercises: [ExerciseDefinition] = []

    // フィルタ済み種目（器具フィルタ適用後）
    var filteredExercises: [ExerciseDefinition] {
        guard let equip = selectedEquipment else { return allRelatedExercises }
        return allRelatedExercises.filter { $0.equipment == equip }
    }

    // 直近のワークアウト履歴（この筋肉に関連）
    var recentSets: [(exercise: ExerciseDefinition, set: WorkoutSet)] = []

    init(muscle: Muscle, modelContext: ModelContext) {
        self.muscle = muscle
        self.muscleStateRepo = MuscleStateRepository(modelContext: modelContext)
        self.workoutRepo = WorkoutRepository(modelContext: modelContext)
        self.exerciseStore = ExerciseStore.shared
    }

    /// データ読み込み
    func load() {
        loadRecoveryState()
        loadRelatedExercises()
        loadRecentHistory()
    }

    // MARK: - 内部

    /// 回復状態を読み込む
    private func loadRecoveryState() {
        guard let stim = muscleStateRepo.fetchLatestStimulation(for: muscle) else {
            recoveryStatus = .fullyRecovered
            recoveryProgress = 1.0
            lastStimulationDate = nil
            lastTotalSets = 0
            return
        }

        lastStimulationDate = stim.stimulationDate
        lastTotalSets = stim.totalSets

        recoveryStatus = RecoveryCalculator.recoveryStatus(
            stimulationDate: stim.stimulationDate,
            muscle: muscle,
            totalSets: stim.totalSets
        )

        recoveryProgress = RecoveryCalculator.recoveryProgress(
            stimulationDate: stim.stimulationDate,
            muscle: muscle,
            totalSets: stim.totalSets
        )
    }

    /// 関連種目をお気に入り優先で読み込む
    private func loadRelatedExercises() {
        let all = exerciseStore.exercises(targeting: muscle)
        let favorites = FavoritesManager.shared

        allRelatedExercises = all.sorted { a, b in
            // お気に入り優先
            let aFav = favorites.isFavorite(a.id)
            let bFav = favorites.isFavorite(b.id)
            if aFav != bFav { return aFav }

            // 元の刺激度%順を維持
            return false
        }
    }

    /// 直近の履歴を読み込む
    private func loadRecentHistory() {
        // この筋肉をターゲットにする種目のIDリスト
        let exerciseIds = Set(allRelatedExercises.map(\.id))

        let sessions = workoutRepo.fetchRecentSessions(limit: 10)
        var result: [(exercise: ExerciseDefinition, set: WorkoutSet)] = []

        for session in sessions {
            for workoutSet in session.sets {
                if exerciseIds.contains(workoutSet.exerciseId),
                   let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) {
                    result.append((exercise: exercise, set: workoutSet))
                }
            }
        }

        // 日時降順、最大20件
        recentSets = result
            .sorted { $0.set.completedAt > $1.set.completedAt }
            .prefix(20)
            .map { $0 }
    }

    /// 回復完了までの残り時間（時間）
    var remainingHours: Double? {
        guard let date = lastStimulationDate else { return nil }
        let needed = RecoveryCalculator.adjustedRecoveryHours(muscle: muscle, totalSets: lastTotalSets)
        let elapsed = Date().timeIntervalSince(date) / 3600
        let remaining = needed - elapsed
        return remaining > 0 ? remaining : nil
    }

    /// 回復完了予定時刻
    var estimatedRecoveryDate: Date? {
        guard let remaining = remainingHours else { return nil }
        return Date().addingTimeInterval(remaining * 3600)
    }
}

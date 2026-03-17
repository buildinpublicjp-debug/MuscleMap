import Foundation
import SwiftData

// MARK: - 場所フィルタ

@MainActor
enum LocationFilter: String, CaseIterable {
    case all, gym, home

    var label: String {
        switch self {
        case .all:  return L10n.all
        case .gym:  return L10n.filterGym
        case .home: return L10n.filterHome
        }
    }

    /// UserProfile.trainingLocation からデフォルト値を決定
    static func defaultFilter(from trainingLocation: String) -> LocationFilter {
        switch trainingLocation {
        case "home": return .home
        case "gym":  return .gym
        default:     return .all
        }
    }
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

    // 場所フィルタ（UIバインディング用）
    var locationFilter: LocationFilter = .all

    // 関連種目（フィルタ前の全種目、お気に入り優先ソート済み）
    var allRelatedExercises: [ExerciseDefinition] = []

    // フィルタ済み種目（場所フィルタ適用後）
    var filteredExercises: [ExerciseDefinition] {
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]
        switch locationFilter {
        case .all:  return allRelatedExercises
        case .gym:  return allRelatedExercises
        case .home: return allRelatedExercises.filter { homeEquipment.contains($0.equipment) }
        }
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
        // デフォルトフィルタをUserProfileから設定
        let profile = AppState.shared.userProfile
        locationFilter = LocationFilter.defaultFilter(from: profile.trainingLocation)

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

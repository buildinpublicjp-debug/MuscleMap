import Foundation
import SwiftData

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

    // 関連種目（刺激度%順）
    var relatedExercises: [ExerciseDefinition] = []

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

    /// 関連種目を刺激度%順 + お気に入り・場所優先で読み込む
    private func loadRelatedExercises() {
        let all = exerciseStore.exercises(targeting: muscle)
        let profile = AppState.shared.userProfile
        let location = profile.trainingLocation
        let favorites = FavoritesManager.shared

        // 自宅向け器具セット
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]

        relatedExercises = all.sorted { a, b in
            // 1. お気に入り優先
            let aFav = favorites.isFavorite(a.id)
            let bFav = favorites.isFavorite(b.id)
            if aFav != bFav { return aFav }

            // 2. 場所に合った種目を優先（homeの場合のみ）
            if location == "home" {
                let aHome = homeEquipment.contains(a.equipment)
                let bHome = homeEquipment.contains(b.equipment)
                if aHome != bHome { return aHome }
            }

            // 3. 元の刺激度%順を維持
            return false
        }
    }

    /// 直近の履歴を読み込む
    private func loadRecentHistory() {
        // この筋肉をターゲットにする種目のIDリスト
        let exerciseIds = Set(relatedExercises.map(\.id))

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

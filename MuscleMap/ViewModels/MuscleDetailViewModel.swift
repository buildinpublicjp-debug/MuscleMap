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

// MARK: - 期間フィルタ定義

enum DetailPeriod: String, CaseIterable, Identifiable {
    case oneWeek = "1W"
    case twoWeeks = "2W"
    case oneMonth = "1M"
    case twoMonths = "2M"
    case threeMonths = "3M"
    case all = "ALL"

    var id: String { rawValue }

    @MainActor
    var localizedLabel: String {
        let isJapanese = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .oneWeek: return isJapanese ? "1週" : "1W"
        case .twoWeeks: return isJapanese ? "2週" : "2W"
        case .oneMonth: return isJapanese ? "1月" : "1M"
        case .twoMonths: return isJapanese ? "2月" : "2M"
        case .threeMonths: return isJapanese ? "3月" : "3M"
        case .all: return isJapanese ? "全期間" : "ALL"
        }
    }

    var startDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .oneWeek: return cal.date(byAdding: .day, value: -7, to: now)
        case .twoWeeks: return cal.date(byAdding: .day, value: -14, to: now)
        case .oneMonth: return cal.date(byAdding: .month, value: -1, to: now)
        case .twoMonths: return cal.date(byAdding: .month, value: -2, to: now)
        case .threeMonths: return cal.date(byAdding: .month, value: -3, to: now)
        case .all: return nil
        }
    }
}

// MARK: - チャート用データポイント

struct DetailWeightEntry: Identifiable {
    let date: Date
    let maxWeight: Double
    let isPR: Bool

    var id: Date { date }
}

// MARK: - 種目カードデータ

struct ExerciseCardData: Identifiable {
    let exercise: ExerciseDefinition
    let totalSets: Int
    let lastWeight: Double?
    let lastReps: Int?

    var id: String { exercise.id }
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

    // 期間フィルタ
    var selectedPeriod: DetailPeriod = .oneMonth {
        didSet { reloadPeriodData() }
    }

    // 器具フィルタ（nil = すべて表示）
    var selectedEquipment: String? = nil

    // 関連種目（フィルタ前の全種目、お気に入り優先ソート済み）
    var allRelatedExercises: [ExerciseDefinition] = []

    // フィルタ済み種目（器具フィルタ適用後）
    var filteredExercises: [ExerciseDefinition] {
        guard let equip = selectedEquipment else { return allRelatedExercises }
        return allRelatedExercises.filter { $0.equipment == equip }
    }

    // チャートデータ（期間連動）
    var weightHistory: [DetailWeightEntry] = []

    // 期間サマリー
    var periodLastDate: Date?
    var periodBestWeight: Double?
    var periodBestReps: Int?
    var periodTotalSets: Int = 0

    // 成長率（最古のベストとの比較、%）
    var growthPercent: Double?

    // 期間内の種目カード（セット数・前回記録付き）
    var exerciseCards: [ExerciseCardData] = []

    // 月平均セット数
    var monthlyAverageSets: Int = 0

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
        reloadPeriodData()
    }

    /// 期間変更時のデータリロード
    private func reloadPeriodData() {
        loadWeightHistory()
        loadExerciseCards()
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
            let aFav = favorites.isFavorite(a.id)
            let bFav = favorites.isFavorite(b.id)
            if aFav != bFav { return aFav }
            return false
        }
    }

    /// 重量推移チャート + サマリー + 成長率を算出
    private func loadWeightHistory() {
        let exerciseIds = Set(allRelatedExercises.map(\.id))
        let sessions = workoutRepo.fetchRecentSessions(limit: 200)
        let startDate = selectedPeriod.startDate

        // 期間内セットを抽出
        var allSets: [WorkoutSet] = []
        for session in sessions {
            guard session.endDate != nil else { continue }
            if let start = startDate, session.startDate < start { continue }
            for ws in session.sets where exerciseIds.contains(ws.exerciseId) {
                allSets.append(ws)
            }
        }

        // 日別に最大重量を集計
        let cal = Calendar.current
        var dailyMax: [DateComponents: Double] = [:]
        var runningMax: Double = 0

        let sorted = allSets.sorted { $0.completedAt < $1.completedAt }
        var prDates: Set<DateComponents> = []

        for ws in sorted {
            let dc = cal.dateComponents([.year, .month, .day], from: ws.completedAt)
            let current = dailyMax[dc] ?? 0
            if ws.weight > current { dailyMax[dc] = ws.weight }
            if ws.weight > runningMax {
                runningMax = ws.weight
                prDates.insert(dc)
            }
        }

        // チャートエントリ生成
        weightHistory = dailyMax.compactMap { dc, weight in
            guard let date = cal.date(from: dc) else { return nil }
            return DetailWeightEntry(
                date: date,
                maxWeight: weight,
                isPR: prDates.contains(dc)
            )
        }.sorted { $0.date < $1.date }

        // サマリー計算
        periodTotalSets = allSets.count
        periodLastDate = sorted.last?.completedAt

        if let maxSet = allSets.max(by: { $0.weight < $1.weight }) {
            periodBestWeight = maxSet.weight
            periodBestReps = maxSet.reps
        } else {
            periodBestWeight = nil
            periodBestReps = nil
        }

        // 成長率: 全期間の最古のベストと現在のベストを比較
        let allTimeSessions = workoutRepo.fetchRecentSessions(limit: 500)
        var oldestMax: Double?
        for session in allTimeSessions.reversed() {
            for ws in session.sets where exerciseIds.contains(ws.exerciseId) {
                if oldestMax == nil && ws.weight > 0 {
                    oldestMax = ws.weight
                }
            }
            if oldestMax != nil { break }
        }

        if let oldest = oldestMax, oldest > 0, let best = periodBestWeight, best > oldest {
            growthPercent = ((best - oldest) / oldest) * 100
        } else {
            growthPercent = nil
        }

        // 月平均セット数
        if let first = sorted.first?.completedAt {
            let months = max(1, cal.dateComponents([.month], from: first, to: Date()).month ?? 1)
            monthlyAverageSets = allSets.count / months
        } else {
            monthlyAverageSets = 0
        }
    }

    /// 期間内の種目カード生成
    private func loadExerciseCards() {
        let exerciseIds = Set(allRelatedExercises.map(\.id))
        let sessions = workoutRepo.fetchRecentSessions(limit: 200)
        let startDate = selectedPeriod.startDate

        // 種目別集計
        var setsCount: [String: Int] = [:]
        var lastRecord: [String: (weight: Double, reps: Int)] = [:]

        for session in sessions {
            guard session.endDate != nil else { continue }
            if let start = startDate, session.startDate < start { continue }
            for ws in session.sets where exerciseIds.contains(ws.exerciseId) {
                setsCount[ws.exerciseId, default: 0] += 1
                // 最新記録を保持（日時降順なので最初に見つかったものが最新）
                if lastRecord[ws.exerciseId] == nil {
                    lastRecord[ws.exerciseId] = (weight: ws.weight, reps: ws.reps)
                }
            }
        }

        exerciseCards = setsCount.compactMap { id, count in
            guard let exercise = exerciseStore.exercise(for: id) else { return nil }
            let record = lastRecord[id]
            return ExerciseCardData(
                exercise: exercise,
                totalSets: count,
                lastWeight: record?.weight,
                lastReps: record?.reps
            )
        }.sorted { $0.totalSets > $1.totalSets }
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

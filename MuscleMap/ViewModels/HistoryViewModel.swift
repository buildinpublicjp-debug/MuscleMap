import Foundation
import SwiftData

// MARK: - 履歴・統計ViewModel

@MainActor
@Observable
class HistoryViewModel {
    private let workoutRepo: WorkoutRepository
    private let muscleStateRepo: MuscleStateRepository
    private let exerciseStore: ExerciseStore

    // セッション履歴
    var sessions: [WorkoutSession] = []

    // 週間統計
    var weeklyStats: WeeklyStats = .empty
    // 月間統計
    var monthlyStats: MonthlyStats = .empty

    // 筋肉グループ別の週間ボリューム
    var weeklyGroupVolume: [MuscleGroup: Int] = [:]

    // 最もよく行う種目 Top5
    var topExercises: [(exercise: ExerciseDefinition, count: Int)] = []

    // カレンダー用（stored property: 毎render再計算を防止）
    var workoutDates: Set<DateComponents> = []

    // カレンダー用：日別の筋肉グループデータ
    var dailyMuscleGroups: [DateComponents: Set<MuscleGroup>] = [:]

    // カレンダー用：日別の筋肉マッピング（ミニマッスルマップ表示用）
    var dailyMuscleMappings: [DateComponents: [String: Int]] = [:]

    // チャート用（stored property: 毎render再計算を防止）
    var dailyVolumeData: [DailyVolume] = []

    // マップビュー用：選択された期間
    var selectedPeriod: HistoryPeriod = .week

    // マップビュー用：期間内の筋肉別セット数
    var periodMuscleSets: [Muscle: Int] = [:]

    // マップビュー用：期間内の統計
    var periodStats: PeriodStats = .empty

    // Pro機能：種目別推移グラフ（全期間 Top5）
    var exerciseTrendData: [ExerciseTrendData] = []

    init(modelContext: ModelContext) {
        self.workoutRepo = WorkoutRepository(modelContext: modelContext)
        self.muscleStateRepo = MuscleStateRepository(modelContext: modelContext)
        self.exerciseStore = ExerciseStore.shared
    }

    /// 全データ読み込み
    func load() {
        // 空セッション（sets が空）をフィルタリングして非表示
        sessions = workoutRepo.fetchRecentSessions(limit: 50).filter { !$0.sets.isEmpty }

        calculateWeeklyStats()
        calculateMonthlyStats()
        calculateWeeklyGroupVolume()
        calculateTopExercises()
        calculateWorkoutDates()
        calculateDailyMuscleGroups()
        calculateDailyMuscleMappings()
        calculateDailyVolumeData()
        calculatePeriodMuscleSets()
        calculateExerciseTrendData()
    }

    /// 期間変更時の再計算
    func updatePeriod(_ period: HistoryPeriod) {
        selectedPeriod = period
        calculatePeriodMuscleSets()
    }

    // MARK: - 週間統計

    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let weekSessions = sessions.filter { $0.startDate >= weekAgo }

        let totalSets = weekSessions.reduce(0) { $0 + $1.sets.count }
        let totalVolume = weekSessions.reduce(0.0) { sum, session in
            sum + session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        }

        let trainingDays = Set(weekSessions.map {
            calendar.startOfDay(for: $0.startDate)
        }).count

        let stimulatedGroups = calculateStimulatedGroups(sessions: weekSessions)

        weeklyStats = WeeklyStats(
            sessionCount: weekSessions.count,
            totalSets: totalSets,
            totalVolume: totalVolume,
            trainingDays: trainingDays,
            stimulatedGroupCount: stimulatedGroups.count,
            totalGroupCount: MuscleGroup.allCases.count
        )
    }

    // MARK: - 月間統計

    private func calculateMonthlyStats() {
        let calendar = Calendar.current
        guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) else { return }
        let monthSessions = sessions.filter { $0.startDate >= monthAgo }

        let totalSets = monthSessions.reduce(0) { $0 + $1.sets.count }
        let totalVolume = monthSessions.reduce(0.0) { sum, session in
            sum + session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        }
        let trainingDays = Set(monthSessions.map {
            calendar.startOfDay(for: $0.startDate)
        }).count

        monthlyStats = MonthlyStats(
            sessionCount: monthSessions.count,
            totalSets: totalSets,
            totalVolume: totalVolume,
            trainingDays: trainingDays
        )
    }

    // MARK: - 週間グループボリューム

    private func calculateWeeklyGroupVolume() {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let weekSessions = sessions.filter { $0.startDate >= weekAgo }

        var volume: [MuscleGroup: Int] = [:]
        for group in MuscleGroup.allCases {
            volume[group] = 0
        }

        for session in weekSessions {
            for workoutSet in session.sets {
                guard let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) else { continue }
                for (muscleId, _) in exercise.muscleMapping {
                    guard let muscle = Muscle(rawValue: muscleId) else { continue }
                    volume[muscle.group, default: 0] += 1
                }
            }
        }

        weeklyGroupVolume = volume
    }

    // MARK: - よく行う種目

    private func calculateTopExercises() {
        var counts: [String: Int] = [:]
        for session in sessions {
            for workoutSet in session.sets {
                counts[workoutSet.exerciseId, default: 0] += 1
            }
        }

        topExercises = counts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { (id, count) in
                guard let exercise = exerciseStore.exercise(for: id) else { return nil }
                return (exercise: exercise, count: count)
            }
    }

    // MARK: - 種目別推移（Pro機能）

    private func calculateExerciseTrendData() {
        let calendar = Calendar.current

        // 全セッションから種目別セット数・日別最大重量を集計
        var exerciseTotalSets: [String: Int] = [:]
        var exerciseDailyMax: [String: [Date: Double]] = [:]

        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.startDate)
            for workoutSet in session.sets {
                let exId = workoutSet.exerciseId
                exerciseTotalSets[exId, default: 0] += 1

                if workoutSet.weight > 0 {
                    let current = exerciseDailyMax[exId]?[dayStart] ?? 0
                    if workoutSet.weight > current {
                        if exerciseDailyMax[exId] == nil {
                            exerciseDailyMax[exId] = [:]
                        }
                        exerciseDailyMax[exId]![dayStart] = workoutSet.weight
                    }
                }
            }
        }

        // セット数 Top5 種目を選出
        let top5 = exerciseTotalSets
            .sorted { $0.value > $1.value }
            .prefix(5)

        exerciseTrendData = top5.compactMap { (exerciseId, totalSets) -> ExerciseTrendData? in
            guard let exercise = exerciseStore.exercise(for: exerciseId) else { return nil }

            let dailyWeights = exerciseDailyMax[exerciseId] ?? [:]
            let sortedDates = dailyWeights.keys.sorted()

            // PR判定: 過去の最大を上回った日にフラグ
            var runningMax: Double = 0
            let entries: [ExerciseTrendEntry] = sortedDates.compactMap { date in
                guard let weight = dailyWeights[date] else { return nil }
                let isPR = weight > runningMax
                if isPR { runningMax = weight }
                return ExerciseTrendEntry(date: date, maxWeight: weight, isPR: isPR)
            }

            return ExerciseTrendData(
                exercise: exercise,
                entries: entries,
                totalSets: totalSets
            )
        }
    }

    // MARK: - ヘルパー

    private func calculateStimulatedGroups(sessions: [WorkoutSession]) -> Set<MuscleGroup> {
        var groups = Set<MuscleGroup>()
        for session in sessions {
            for workoutSet in session.sets {
                guard let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) else { continue }
                for muscleId in exercise.muscleMapping.keys {
                    if let muscle = Muscle(rawValue: muscleId) {
                        groups.insert(muscle.group)
                    }
                }
            }
        }
        return groups
    }

    // MARK: - カレンダー用日付

    private func calculateWorkoutDates() {
        let calendar = Calendar.current
        var dates = Set<DateComponents>()
        for session in sessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startDate)
            dates.insert(components)
        }
        workoutDates = dates
    }

    // MARK: - 日別の筋肉グループ計算

    private func calculateDailyMuscleGroups() {
        let calendar = Calendar.current
        var result: [DateComponents: Set<MuscleGroup>] = [:]

        for session in sessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startDate)
            var groups = result[components] ?? Set<MuscleGroup>()

            for workoutSet in session.sets {
                guard let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) else { continue }
                for muscleId in exercise.muscleMapping.keys {
                    if let muscle = Muscle(rawValue: muscleId) {
                        groups.insert(muscle.group)
                    } else {
                        for m in Muscle.allCases {
                            let snakeCase = m.rawValue.replacingOccurrences(
                                of: "([a-z])([A-Z])",
                                with: "$1_$2",
                                options: .regularExpression
                            ).lowercased()
                            if snakeCase == muscleId {
                                groups.insert(m.group)
                                break
                            }
                        }
                    }
                }
            }

            result[components] = groups
        }

        dailyMuscleGroups = result
    }

    // MARK: - 日別の筋肉マッピング（カレンダーミニマップ用）

    private func calculateDailyMuscleMappings() {
        let calendar = Calendar.current
        var result: [DateComponents: [String: Int]] = [:]

        for session in sessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startDate)
            var mapping = result[components] ?? [:]

            for workoutSet in session.sets {
                guard let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) else { continue }
                for (muscleId, intensity) in exercise.muscleMapping {
                    mapping[muscleId] = max(mapping[muscleId] ?? 0, intensity)
                }
            }

            result[components] = mapping
        }

        dailyMuscleMappings = result
    }

    // MARK: - 期間内の筋肉別セット数（マップビュー用）

    private func calculatePeriodMuscleSets() {
        let calendar = Calendar.current
        let now = Date()

        let filteredSessions: [WorkoutSession]
        switch selectedPeriod {
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }
            filteredSessions = sessions.filter { $0.startDate >= weekAgo }
        case .month:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return }
            filteredSessions = sessions.filter { $0.startDate >= monthAgo }
        case .all:
            filteredSessions = sessions
        }

        var muscleSets: [Muscle: Int] = [:]
        for muscle in Muscle.allCases {
            muscleSets[muscle] = 0
        }

        var totalSets = 0
        var totalVolume = 0.0
        let trainingDays = Set(filteredSessions.map {
            calendar.startOfDay(for: $0.startDate)
        }).count

        for session in filteredSessions {
            for workoutSet in session.sets {
                totalSets += 1
                totalVolume += workoutSet.weight * Double(workoutSet.reps)

                guard let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) else { continue }
                for muscleId in exercise.muscleMapping.keys {
                    if let muscle = Muscle(rawValue: muscleId) {
                        muscleSets[muscle, default: 0] += 1
                    }
                }
            }
        }

        periodMuscleSets = muscleSets
        periodStats = PeriodStats(
            sessionCount: filteredSessions.count,
            totalSets: totalSets,
            totalVolume: totalVolume,
            trainingDays: trainingDays
        )
    }

    // MARK: - 筋肉詳細データ取得（ハーフモーダル用）

    func getMuscleHistoryDetail(for muscle: Muscle) -> MuscleHistoryDetail {
        let calendar = Calendar.current
        let now = Date()

        let filteredSessions: [WorkoutSession]
        switch selectedPeriod {
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
                return MuscleHistoryDetail.empty(muscle: muscle)
            }
            filteredSessions = sessions.filter { $0.startDate >= weekAgo }
        case .month:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else {
                return MuscleHistoryDetail.empty(muscle: muscle)
            }
            filteredSessions = sessions.filter { $0.startDate >= monthAgo }
        case .all:
            filteredSessions = sessions
        }

        var exerciseSets: [String: Int] = [:]
        var lastWorkoutDate: Date?
        var bestSet: (weight: Double, reps: Int)?
        var dailyMaxWeights: [Date: Double] = [:]

        for session in filteredSessions {
            let sessionDay = calendar.startOfDay(for: session.startDate)

            for workoutSet in session.sets {
                guard let exercise = exerciseStore.exercise(for: workoutSet.exerciseId) else { continue }

                let stimulatesMuscle = exercise.muscleMapping.keys.contains { muscleId in
                    muscleId == muscle.rawValue
                }

                if stimulatesMuscle {
                    exerciseSets[workoutSet.exerciseId, default: 0] += 1

                    if lastWorkoutDate == nil || session.startDate > lastWorkoutDate! {
                        lastWorkoutDate = session.startDate
                    }

                    if let best = bestSet {
                        if workoutSet.weight > best.weight {
                            bestSet = (workoutSet.weight, workoutSet.reps)
                        }
                    } else {
                        bestSet = (workoutSet.weight, workoutSet.reps)
                    }

                    if workoutSet.weight > 0 {
                        dailyMaxWeights[sessionDay] = max(dailyMaxWeights[sessionDay] ?? 0, workoutSet.weight)
                    }
                }
            }
        }

        let exercises = exerciseSets
            .sorted { $0.value > $1.value }
            .compactMap { (exerciseId, sets) -> MuscleExerciseHistory? in
                guard let exercise = exerciseStore.exercise(for: exerciseId) else { return nil }
                return MuscleExerciseHistory(exercise: exercise, totalSets: sets)
            }

        let sortedDates = dailyMaxWeights.keys.sorted()
        var runningMax: Double = 0
        var weightHistory: [MuscleWeightEntry] = []

        for date in sortedDates {
            let weight = dailyMaxWeights[date]!
            let isPR = weight > runningMax
            if isPR {
                runningMax = weight
            }
            weightHistory.append(MuscleWeightEntry(date: date, maxWeight: weight, isPR: isPR))
        }

        let totalSets = periodMuscleSets[muscle] ?? 0

        return MuscleHistoryDetail(
            muscle: muscle,
            totalSets: totalSets,
            exercises: exercises,
            lastWorkoutDate: lastWorkoutDate,
            bestWeight: bestSet?.weight,
            bestReps: bestSet?.reps,
            weightHistory: weightHistory
        )
    }

    // MARK: - 日ごとのボリュームデータ（直近14日）

    private func calculateDailyVolumeData() {
        let calendar = Calendar.current
        var result: [DailyVolume] = []

        for dayOffset in (0..<14).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let daySessions = sessions.filter {
                $0.startDate >= dayStart && $0.startDate < dayEnd
            }
            let volume = daySessions.reduce(0.0) { sum, session in
                sum + session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            }

            result.append(DailyVolume(date: dayStart, volume: volume))
        }

        dailyVolumeData = result
    }
}

// MARK: - データ構造

struct WeeklyStats {
    let sessionCount: Int
    let totalSets: Int
    let totalVolume: Double
    let trainingDays: Int
    let stimulatedGroupCount: Int
    let totalGroupCount: Int

    static let empty = WeeklyStats(
        sessionCount: 0, totalSets: 0, totalVolume: 0,
        trainingDays: 0, stimulatedGroupCount: 0, totalGroupCount: 6
    )
}

struct MonthlyStats {
    let sessionCount: Int
    let totalSets: Int
    let totalVolume: Double
    let trainingDays: Int

    static let empty = MonthlyStats(
        sessionCount: 0, totalSets: 0, totalVolume: 0, trainingDays: 0
    )
}

struct DailyVolume: Identifiable {
    let date: Date
    let volume: Double
    var id: Date { date }
}

// MARK: - 期間選択

enum HistoryPeriod: String, CaseIterable {
    case week = "7日"
    case month = "30日"
    case all = "全期間"

    var englishName: String {
        switch self {
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .all: return "All Time"
        }
    }
}

// MARK: - 期間内統計

struct PeriodStats {
    let sessionCount: Int
    let totalSets: Int
    let totalVolume: Double
    let trainingDays: Int

    static let empty = PeriodStats(
        sessionCount: 0, totalSets: 0, totalVolume: 0, trainingDays: 0
    )
}

// MARK: - 筋肉履歴詳細（ハーフモーダル用）

struct MuscleHistoryDetail {
    let muscle: Muscle
    let totalSets: Int
    let exercises: [MuscleExerciseHistory]
    let lastWorkoutDate: Date?
    let bestWeight: Double?
    let bestReps: Int?
    let weightHistory: [MuscleWeightEntry]

    static func empty(muscle: Muscle) -> MuscleHistoryDetail {
        MuscleHistoryDetail(
            muscle: muscle,
            totalSets: 0,
            exercises: [],
            lastWorkoutDate: nil,
            bestWeight: nil,
            bestReps: nil,
            weightHistory: []
        )
    }
}

// MARK: - 日別重量エントリ（チャート用）

struct MuscleWeightEntry: Identifiable {
    let date: Date
    let maxWeight: Double
    let isPR: Bool

    var id: Date { date }
}

struct MuscleExerciseHistory: Identifiable {
    let exercise: ExerciseDefinition
    let totalSets: Int

    var id: String { exercise.id }
}

// MARK: - 種目別推移データ（Pro機能）

struct ExerciseTrendData: Identifiable {
    let exercise: ExerciseDefinition
    let entries: [ExerciseTrendEntry]  // 全期間・日別
    let totalSets: Int

    var id: String { exercise.id }

    /// 全期間のベスト重量
    var bestWeight: Double? {
        entries.max(by: { $0.maxWeight < $1.maxWeight })?.maxWeight
    }

    /// 初回トレーニング日
    var startDate: Date? { entries.first?.date }

    /// 成長率（最初→最新の重量変化率）
    var progressPercent: Double? {
        guard let first = entries.first?.maxWeight,
              let last = entries.last?.maxWeight,
              first > 0 else { return nil }
        return ((last - first) / first) * 100
    }
}

struct ExerciseTrendEntry: Identifiable {
    let date: Date
    let maxWeight: Double
    let isPR: Bool

    var id: Date { date }
}

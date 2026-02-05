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

    // チャート用（stored property: 毎render再計算を防止）
    var dailyVolumeData: [DailyVolume] = []

    init(modelContext: ModelContext) {
        self.workoutRepo = WorkoutRepository(modelContext: modelContext)
        self.muscleStateRepo = MuscleStateRepository(modelContext: modelContext)
        self.exerciseStore = ExerciseStore.shared
    }

    /// 全データ読み込み
    func load() {
        sessions = workoutRepo.fetchRecentSessions(limit: 50)
        calculateWeeklyStats()
        calculateMonthlyStats()
        calculateWeeklyGroupVolume()
        calculateTopExercises()
        calculateWorkoutDates()
        calculateDailyVolumeData()
    }

    // MARK: - 週間統計

    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let weekSessions = sessions.filter { $0.startDate >= weekAgo }

        let totalSets = weekSessions.reduce(0) { $0 + $1.sets.count }
        let totalVolume = weekSessions.reduce(0.0) { sum, session in
            sum + session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        }

        // トレーニング日数（ユニーク日）
        let trainingDays = Set(weekSessions.map {
            calendar.startOfDay(for: $0.startDate)
        }).count

        // 刺激された筋肉グループ
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
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
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
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
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

    // MARK: - 日ごとのボリュームデータ（直近14日）

    private func calculateDailyVolumeData() {
        let calendar = Calendar.current
        var result: [DailyVolume] = []

        for dayOffset in (0..<14).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

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

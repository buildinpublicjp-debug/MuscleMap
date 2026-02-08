import SwiftUI
import SwiftData

// MARK: - 週間サマリーViewModel

@MainActor
@Observable
class WeeklySummaryViewModel {
    private var modelContext: ModelContext?

    // 今週の統計
    private(set) var workoutCount: Int = 0
    private(set) var totalSets: Int = 0
    private(set) var totalVolume: Double = 0

    // MVP筋肉（最も刺激した部位）
    private(set) var mvpMuscle: Muscle?
    private(set) var mvpStimulationCount: Int = 0

    // サボり筋肉（7日以上未刺激）
    private(set) var lazyMuscles: [Muscle] = []

    // 今週刺激した筋肉マッピング
    private(set) var weeklyMuscleMapping: [String: Int] = [:]

    // 週の範囲
    private(set) var weekStartDate: Date = Date()
    private(set) var weekEndDate: Date = Date()

    // ストリーク
    private(set) var streakWeeks: Int = 0

    // MARK: - 初期化

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        calculateWeeklySummary()
    }

    // MARK: - 週間サマリー計算

    func calculateWeeklySummary() {
        guard let modelContext = modelContext else { return }

        // 月曜始まりのカレンダー
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 月曜日

        let now = Date()

        // 今週の範囲を取得
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return }
        weekStartDate = weekInterval.start
        weekEndDate = weekInterval.end

        // 今週のワークアウトセッションを取得
        let startDate = weekInterval.start
        let endDate = weekInterval.end

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.endDate != nil &&
                session.startDate >= startDate &&
                session.startDate < endDate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else { return }

        // 統計計算
        workoutCount = sessions.count
        totalSets = sessions.reduce(0) { $0 + $1.sets.count }
        totalVolume = sessions.reduce(0.0) { total, session in
            total + session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        }

        // 筋肉刺激カウント
        var muscleStimulationCount: [Muscle: Int] = [:]
        var muscleMaxIntensity: [String: Int] = [:]

        for session in sessions {
            for set in session.sets {
                guard let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) else { continue }
                for (muscleId, intensity) in exercise.muscleMapping {
                    guard let muscle = Muscle(rawValue: muscleId) else { continue }
                    muscleStimulationCount[muscle, default: 0] += 1
                    muscleMaxIntensity[muscleId] = max(muscleMaxIntensity[muscleId] ?? 0, intensity)
                }
            }
        }

        weeklyMuscleMapping = muscleMaxIntensity

        // MVP筋肉（最も刺激回数が多い）
        if let (muscle, count) = muscleStimulationCount.max(by: { $0.value < $1.value }) {
            mvpMuscle = muscle
            mvpStimulationCount = count
        }

        // サボり筋肉（7日以上未刺激）
        calculateLazyMuscles()

        // ストリーク計算
        calculateStreak(sessions: sessions, calendar: calendar)
    }

    // MARK: - サボり筋肉計算

    private func calculateLazyMuscles() {
        guard let modelContext = modelContext else { return }

        let repo = MuscleStateRepository(modelContext: modelContext)
        let stimulations = repo.fetchLatestStimulations()

        var lazy: [Muscle] = []
        let now = Date()

        for muscle in Muscle.allCases {
            if let stim = stimulations[muscle] {
                let daysSince = Calendar.current.dateComponents([.day], from: stim.stimulationDate, to: now).day ?? 0
                if daysSince >= 7 {
                    lazy.append(muscle)
                }
            } else {
                // 一度も刺激されていない場合もサボり扱い
                lazy.append(muscle)
            }
        }

        lazyMuscles = lazy
    }

    // MARK: - ストリーク計算

    private func calculateStreak(sessions: [WorkoutSession], calendar: Calendar) {
        guard let modelContext = modelContext else { return }

        // 直近53週分のワークアウトセッションを取得
        let now = Date()
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -53, to: now) else { return }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.endDate != nil && session.startDate >= startDate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let allSessions = try? modelContext.fetch(descriptor) else { return }

        // ワークアウトがあった週を Set で管理
        var weeksWithWorkout: Set<DateInterval> = []

        for session in allSessions {
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: session.startDate) {
                weeksWithWorkout.insert(weekInterval)
            }
        }

        // 現在の週を取得
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return }

        // 今週完了しているか
        let isCurrentWeekCompleted = weeksWithWorkout.contains(currentWeekInterval)

        // ストリーク計算
        var streak = 0
        var checkingWeek = currentWeekInterval

        if !isCurrentWeekCompleted {
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkingWeek.start),
                  let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeek) else {
                streakWeeks = 0
                return
            }
            checkingWeek = previousWeekInterval
        }

        while weeksWithWorkout.contains(checkingWeek) {
            streak += 1
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkingWeek.start),
                  let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeek) else {
                break
            }
            checkingWeek = previousWeekInterval
        }

        streakWeeks = streak
    }

    // MARK: - 日付フォーマット

    var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let start = formatter.string(from: weekStartDate)
        let end = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: weekEndDate) ?? weekEndDate)
        return "\(start) - \(end)"
    }

    var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk", totalVolume / 1000)
        }
        return String(format: "%.0f", totalVolume)
    }
}

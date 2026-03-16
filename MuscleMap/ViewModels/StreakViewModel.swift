import SwiftUI
import SwiftData

// MARK: - ストリークマイルストーン

@MainActor
enum StreakMilestone: Int, CaseIterable, Identifiable {
    nonisolated var id: Int { rawValue }
    case oneMonth = 4      // 4週
    case threeMonths = 12  // 12週
    case sixMonths = 26    // 26週
    case oneYear = 52      // 52週

    var localizedTitle: String {
        switch self {
        case .oneMonth: return L10n.milestone1Month
        case .threeMonths: return L10n.milestone3Months
        case .sixMonths: return L10n.milestone6Months
        case .oneYear: return L10n.milestone1Year
        }
    }

    var emoji: String {
        switch self {
        case .oneMonth: return "🎉"
        case .threeMonths: return "🏆"
        case .sixMonths: return "⭐️"
        case .oneYear: return "👑"
        }
    }
}

// MARK: - ストリークViewModel

@MainActor
@Observable
class StreakViewModel {
    private var modelContext: ModelContext?

    /// 現在のストリーク（週数）
    private(set) var currentStreak: Int = 0

    /// 今週ワークアウト完了済みか
    private(set) var isCurrentWeekCompleted: Bool = false

    /// 達成したマイルストーン（表示後にnilにする）
    var achievedMilestone: StreakMilestone?

    /// 前回のストリーク（マイルストーン判定用）
    private var previousStreak: Int = 0

    /// 初回計算かどうか（初回はマイルストーンを表示しない）
    private var isFirstCalculation: Bool = true

    /// ワークアウト履歴が存在するか
    private(set) var hasWorkoutHistory: Bool = false

    // MARK: - 初期化

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        isFirstCalculation = true
        calculateStreak()
    }

    // MARK: - ストリーク計算

    func calculateStreak() {
        guard let modelContext = modelContext else { return }

        // 月曜始まりのカレンダー
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 月曜日

        let now = Date()

        // 直近53週分のワークアウトセッションを取得
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -53, to: now) else { return }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.endDate != nil && session.startDate >= startDate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else { return }

        // ワークアウト履歴の有無を更新
        hasWorkoutHistory = !sessions.isEmpty

        // ワークアウトがあった週を Set で管理
        var weeksWithWorkout: Set<DateInterval> = []

        for session in sessions {
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: session.startDate) {
                weeksWithWorkout.insert(weekInterval)
            }
        }

        // 現在の週を取得
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return }

        // 今週完了しているか
        isCurrentWeekCompleted = weeksWithWorkout.contains(currentWeekInterval)

        // ストリーク計算: 現在の週から過去に遡る
        var streak = 0
        var checkingWeek = currentWeekInterval

        // 今週完了していない場合は、先週から計算開始
        if !isCurrentWeekCompleted {
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkingWeek.start),
                  let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeek) else {
                currentStreak = 0
                return
            }
            checkingWeek = previousWeekInterval
        }

        // 連続週をカウント
        while weeksWithWorkout.contains(checkingWeek) {
            streak += 1
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkingWeek.start),
                  let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeek) else {
                break
            }
            checkingWeek = previousWeekInterval
        }

        // マイルストーン達成チェック（初回計算時はスキップ）
        previousStreak = currentStreak
        currentStreak = streak

        if isFirstCalculation {
            // 初回は既存のストリークを認識するだけで、マイルストーンモーダルは出さない
            isFirstCalculation = false
        } else {
            checkMilestoneAchievement()
        }
    }

    // MARK: - マイルストーン達成チェック

    private func checkMilestoneAchievement() {
        // ワークアウト履歴がない場合はマイルストーンなし
        guard hasWorkoutHistory else { return }

        // 新しくマイルストーンを達成したかチェック
        for milestone in StreakMilestone.allCases.reversed() {
            if currentStreak >= milestone.rawValue && previousStreak < milestone.rawValue {
                achievedMilestone = milestone
                break
            }
        }
    }

    /// マイルストーン表示を消す
    func dismissMilestone() {
        achievedMilestone = nil
    }

    /// 現在達成しているマイルストーン（最高位）
    func currentMilestoneLevel() -> StreakMilestone? {
        for milestone in StreakMilestone.allCases.reversed() {
            if currentStreak >= milestone.rawValue {
                return milestone
            }
        }
        return nil
    }
}

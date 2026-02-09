import SwiftUI
import SwiftData

// MARK: - ヒートマップ期間

@MainActor
enum HeatmapPeriod: String, CaseIterable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var months: Int {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        }
    }

    var weeks: Int {
        months * 4 + (months / 3) // 概算週数
    }

    var localizedLabel: String {
        switch self {
        case .threeMonths: return L10n.threeMonthsAgo
        case .sixMonths: return L10n.sixMonthsAgo
        case .oneYear: return L10n.oneYearAgo
        }
    }
}

// MARK: - ヒートマップセルデータ

struct HeatmapCellData: Identifiable {
    let id: String
    let date: Date
    let muscleCount: Int

    var level: Int {
        switch muscleCount {
        case 0: return 0
        case 1...3: return 1
        case 4...7: return 2
        case 8...12: return 3
        default: return 4
        }
    }
}

// MARK: - ヒートマップ統計

struct HeatmapStats {
    let trainingDays: Int
    let totalDays: Int
    let longestStreak: Int
    let averagePerWeek: Double
}

// MARK: - マッスルヒートマップViewModel

@MainActor
@Observable
class MuscleHeatmapViewModel {
    private var modelContext: ModelContext?

    // 選択中の期間
    var selectedPeriod: HeatmapPeriod = .threeMonths {
        didSet {
            generateHeatmapData()
        }
    }

    // キャッシュ: 日付 → 刺激した筋肉数
    private var muscleCountCache: [Date: Int] = [:]

    // ヒートマップデータ
    private(set) var heatmapData: [[HeatmapCellData]] = [] // [週][曜日]
    private(set) var monthLabels: [(String, Int)] = [] // (ラベル, 開始週インデックス)
    private(set) var stats: HeatmapStats = HeatmapStats(trainingDays: 0, totalDays: 0, longestStreak: 0, averagePerWeek: 0)

    // 計算中フラグ
    private(set) var isLoading = false

    // MARK: - 初期化

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAllData()
        generateHeatmapData()
    }

    // MARK: - 全データをキャッシュに読み込み

    private func loadAllData() {
        guard let modelContext = modelContext else { return }

        isLoading = true

        // 1年分のセッションを取得
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.endDate != nil && session.startDate >= oneYearAgo
            },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else {
            isLoading = false
            return
        }

        let calendar = Calendar.current
        var cache: [Date: Set<String>] = [:]

        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.startDate)

            // この日の筋肉セットを取得
            var muscles = cache[dayStart] ?? Set<String>()

            for set in session.sets {
                if let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) {
                    for (muscleId, _) in exercise.muscleMapping {
                        muscles.insert(muscleId)
                    }
                }
            }

            cache[dayStart] = muscles
        }

        // 筋肉数に変換
        muscleCountCache = cache.mapValues { $0.count }

        isLoading = false
    }

    // MARK: - ヒートマップデータを生成

    private func generateHeatmapData() {
        let calendar = Calendar(identifier: .iso8601) // 週は月曜開始
        let today = Date()

        // 期間の開始日を計算
        guard let periodStart = calendar.date(byAdding: .month, value: -selectedPeriod.months, to: today) else { return }

        // 週の開始日（月曜）を取得
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: periodStart)?.start ?? periodStart
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? today

        // 週ごとにデータを作成
        var weeks: [[HeatmapCellData]] = []
        var currentDate = startOfWeek
        var currentWeek: [HeatmapCellData] = []
        var monthLabelsTemp: [(String, Int)] = []
        var lastMonth = -1

        while currentDate <= endOfWeek {
            let dayStart = calendar.startOfDay(for: currentDate)
            let weekday = calendar.component(.weekday, from: currentDate)
            // weekday: 1=日, 2=月, 3=火, ... 7=土
            // ISO週: 月=1, 火=2, ... 日=7
            let isoWeekday = weekday == 1 ? 7 : weekday - 1

            // 月ラベルの追加
            let month = calendar.component(.month, from: currentDate)
            if month != lastMonth && isoWeekday == 1 {
                let monthName = calendar.shortMonthSymbols[month - 1]
                monthLabelsTemp.append((monthName, weeks.count))
                lastMonth = month
            }

            let muscleCount = muscleCountCache[dayStart] ?? 0
            let cell = HeatmapCellData(
                id: "\(weeks.count)-\(isoWeekday)",
                date: dayStart,
                muscleCount: dayStart <= today ? muscleCount : -1 // 未来は-1
            )

            currentWeek.append(cell)

            if isoWeekday == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // 残りの日を追加
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        heatmapData = weeks
        monthLabels = monthLabelsTemp

        // 統計を計算
        calculateStats(startDate: periodStart, endDate: today)
    }

    // MARK: - 統計を計算

    private func calculateStats(startDate: Date, endDate: Date) {
        let calendar = Calendar.current

        // 期間内のトレーニング日数
        let trainingDays = muscleCountCache.filter { date, count in
            date >= startDate && date <= endDate && count > 0
        }.count

        // 期間内の総日数
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0

        // 最長連続日数
        let longestStreak = calculateLongestStreak(startDate: startDate, endDate: endDate)

        // 週平均
        let weeks = max(1, totalDays / 7)
        let averagePerWeek = Double(trainingDays) / Double(weeks)

        stats = HeatmapStats(
            trainingDays: trainingDays,
            totalDays: totalDays,
            longestStreak: longestStreak,
            averagePerWeek: averagePerWeek
        )
    }

    // MARK: - 最長連続日数を計算

    private func calculateLongestStreak(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current

        // 期間内の日付をソート
        let sortedDates = muscleCountCache
            .filter { $0.key >= startDate && $0.key <= endDate && $0.value > 0 }
            .keys
            .sorted()

        guard !sortedDates.isEmpty else { return 0 }

        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDates.count {
            let prevDate = sortedDates[i - 1]
            let currDate = sortedDates[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: prevDate),
               calendar.isDate(nextDay, inSameDayAs: currDate) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    // MARK: - セルの色を取得

    func cellColor(for level: Int) -> Color {
        switch level {
        case 0: return Color.mmBgSecondary
        case 1: return Color.mmAccentPrimary.opacity(0.25)
        case 2: return Color.mmAccentPrimary.opacity(0.5)
        case 3: return Color.mmAccentPrimary.opacity(0.75)
        case 4: return Color.mmAccentPrimary
        default: return Color.clear // 未来の日付
        }
    }

    // MARK: - 期間テキスト

    var periodRangeText: String {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .month, value: -selectedPeriod.months, to: Date()) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: Date()))"
    }
}

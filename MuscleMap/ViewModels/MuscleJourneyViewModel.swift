import SwiftUI
import SwiftData

// MARK: - 比較期間

@MainActor
enum JourneyPeriod: String, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case custom = "Custom"

    var months: Int? {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        case .custom: return nil
        }
    }

    var localizedLabel: String {
        switch self {
        case .oneMonth: return L10n.oneMonthAgo
        case .threeMonths: return L10n.threeMonthsAgo
        case .sixMonths: return L10n.sixMonthsAgo
        case .oneYear: return L10n.oneYearAgo
        case .custom: return L10n.customDate
        }
    }
}

// MARK: - 筋肉状態スナップショット

struct MuscleStateSnapshot {
    let date: Date
    /// muscle.rawValue → stimulation intensity (0-100)
    let muscleMapping: [String: Int]
    /// 刺激されている筋肉の数
    var stimulatedCount: Int {
        muscleMapping.filter { $0.value > 0 }.count
    }
}

// MARK: - 変化サマリー

struct JourneyChangeSummary {
    /// 新たに刺激した部位（過去は0、現在は刺激あり）
    let newlyStimulated: [Muscle]
    /// 最も改善した部位（刺激度の増加が最大）
    let mostImproved: Muscle?
    let mostImprovedGain: Int
    /// まだ未刺激の部位（両方で0）
    let stillNeglected: [Muscle]
}

// MARK: - マッスル・ジャーニーViewModel

@MainActor
@Observable
class MuscleJourneyViewModel {
    private var modelContext: ModelContext?

    // 選択中の期間
    var selectedPeriod: JourneyPeriod = .threeMonths {
        didSet {
            if selectedPeriod != .custom {
                updateComparisonDate()
                calculateSnapshots()
            }
        }
    }

    // カスタム日付
    var customDate: Date = Date() {
        didSet {
            if selectedPeriod == .custom {
                comparisonDate = customDate
                calculateSnapshots()
            }
        }
    }

    // 比較する過去の日付
    private(set) var comparisonDate: Date = Date()

    // スナップショット
    private(set) var pastSnapshot: MuscleStateSnapshot?
    private(set) var currentSnapshot: MuscleStateSnapshot?

    // 変化サマリー
    private(set) var changeSummary: JourneyChangeSummary?

    // 最初のワークアウト日（DatePickerの制限用）
    private(set) var earliestWorkoutDate: Date?

    // データがあるかどうか
    private(set) var hasPastData = false

    // 計算中フラグ
    private(set) var isCalculating = false

    // MARK: - 初期化

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        findEarliestWorkoutDate()
        updateComparisonDate()
        calculateSnapshots()
    }

    // MARK: - 最初のワークアウト日を取得

    private func findEarliestWorkoutDate() {
        guard let modelContext = modelContext else { return }

        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        descriptor.fetchLimit = 1

        if let session = try? modelContext.fetch(descriptor).first {
            earliestWorkoutDate = session.startDate
        }
    }

    // MARK: - 比較日付を更新

    private func updateComparisonDate() {
        guard let months = selectedPeriod.months else { return }
        comparisonDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
    }

    // MARK: - スナップショット計算

    func calculateSnapshots() {
        guard let modelContext = modelContext else { return }

        isCalculating = true

        // 過去のスナップショット
        pastSnapshot = calculateSnapshot(at: comparisonDate, modelContext: modelContext)

        // 現在のスナップショット
        currentSnapshot = calculateSnapshot(at: Date(), modelContext: modelContext)

        // 過去のデータがあるかチェック
        hasPastData = (pastSnapshot?.stimulatedCount ?? 0) > 0

        // 変化サマリーを計算
        calculateChangeSummary()

        isCalculating = false
    }

    // MARK: - 特定時点でのスナップショットを計算

    private func calculateSnapshot(at targetDate: Date, modelContext: ModelContext) -> MuscleStateSnapshot {
        // targetDate以前の刺激記録を取得
        let descriptor = FetchDescriptor<MuscleStimulation>(
            predicate: #Predicate { $0.stimulationDate <= targetDate },
            sortBy: [SortDescriptor(\.stimulationDate, order: .reverse)]
        )

        guard let stimulations = try? modelContext.fetch(descriptor) else {
            return MuscleStateSnapshot(date: targetDate, muscleMapping: [:])
        }

        // 各筋肉の最新刺激を取得（targetDate時点）
        var latestStimulations: [Muscle: MuscleStimulation] = [:]
        for stim in stimulations {
            guard let muscle = Muscle(rawValue: stim.muscle) else { continue }
            if latestStimulations[muscle] == nil {
                latestStimulations[muscle] = stim
            }
        }

        // 筋肉マッピングを作成（回復進捗に基づく色分け）
        var muscleMapping: [String: Int] = [:]

        for muscle in Muscle.allCases {
            if let stim = latestStimulations[muscle] {
                // 回復進捗を計算
                let progress = RecoveryCalculator.recoveryProgress(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets,
                    now: targetDate
                )
                let daysSince = RecoveryCalculator.daysSinceStimulation(stim.stimulationDate, now: targetDate)

                // 7日以上未刺激は未刺激扱い
                if daysSince >= 7 {
                    muscleMapping[muscle.rawValue] = 0
                } else {
                    // 回復進捗を刺激度に変換（回復中ほど高い値）
                    // progress 0.0 = 直後（高刺激表示）、1.0 = 完全回復（低刺激表示）
                    let intensity = Int((1.0 - progress) * 100)
                    muscleMapping[muscle.rawValue] = max(intensity, 1) // 最低1は刺激あり扱い
                }
            } else {
                muscleMapping[muscle.rawValue] = 0
            }
        }

        return MuscleStateSnapshot(date: targetDate, muscleMapping: muscleMapping)
    }

    // MARK: - 変化サマリーを計算

    private func calculateChangeSummary() {
        guard let past = pastSnapshot, let current = currentSnapshot else {
            changeSummary = nil
            return
        }

        var newlyStimulated: [Muscle] = []
        var stillNeglected: [Muscle] = []
        var improvements: [(Muscle, Int)] = []

        for muscle in Muscle.allCases {
            let pastValue = past.muscleMapping[muscle.rawValue] ?? 0
            let currentValue = current.muscleMapping[muscle.rawValue] ?? 0

            if pastValue == 0 && currentValue > 0 {
                newlyStimulated.append(muscle)
            }

            if pastValue == 0 && currentValue == 0 {
                stillNeglected.append(muscle)
            }

            let gain = currentValue - pastValue
            if gain > 0 {
                improvements.append((muscle, gain))
            }
        }

        // 最も改善した部位
        let mostImproved = improvements.max(by: { $0.1 < $1.1 })

        changeSummary = JourneyChangeSummary(
            newlyStimulated: newlyStimulated,
            mostImproved: mostImproved?.0,
            mostImprovedGain: mostImproved?.1 ?? 0,
            stillNeglected: stillNeglected
        )
    }

    // MARK: - 期間テキスト

    var periodText: String {
        if selectedPeriod == .custom {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: comparisonDate)
        } else {
            return selectedPeriod.localizedLabel
        }
    }

    var progressText: String {
        switch selectedPeriod {
        case .oneMonth:
            return "1 MONTH OF PROGRESS"
        case .threeMonths:
            return "3 MONTHS OF PROGRESS"
        case .sixMonths:
            return "6 MONTHS OF PROGRESS"
        case .oneYear:
            return "1 YEAR OF PROGRESS"
        case .custom:
            let days = Calendar.current.dateComponents([.day], from: comparisonDate, to: Date()).day ?? 0
            if days < 30 {
                return "\(days) DAYS OF PROGRESS"
            } else if days < 365 {
                let months = days / 30
                return "\(months) MONTH\(months > 1 ? "S" : "") OF PROGRESS"
            } else {
                let years = days / 365
                return "\(years) YEAR\(years > 1 ? "S" : "") OF PROGRESS"
            }
        }
    }
}

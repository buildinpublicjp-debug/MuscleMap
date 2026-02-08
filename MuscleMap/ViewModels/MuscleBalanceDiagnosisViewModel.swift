import SwiftUI
import SwiftData

// MARK: - トレーニータイプ

@MainActor
enum TrainerType: String, CaseIterable {
    case mirrorMuscle      // ミラーマッスル型
    case balanceMaster     // バランスマスター型
    case legDayNeverSkip   // レッグデイ・ネバースキップ型
    case backAttack        // バックアタック型
    case coreMaster        // 体幹番長型
    case armDayEveryDay    // アームデイ・エブリデイ型
    case pushCrazy         // プッシュ狂い型
    case fullBodyConqueror // 全身制覇型
    case dataInsufficient  // データ不足

    var emoji: String {
        switch self {
        case .mirrorMuscle: return "🪞"
        case .balanceMaster: return "⚖️"
        case .legDayNeverSkip: return "🦵"
        case .backAttack: return "🔙"
        case .coreMaster: return "🎯"
        case .armDayEveryDay: return "💪"
        case .pushCrazy: return "🏋️"
        case .fullBodyConqueror: return "👑"
        case .dataInsufficient: return "📊"
        }
    }

    var localizedName: String {
        switch self {
        case .mirrorMuscle: return L10n.typeMirrorMuscle
        case .balanceMaster: return L10n.typeBalanceMaster
        case .legDayNeverSkip: return L10n.typeLegDayNeverSkip
        case .backAttack: return L10n.typeBackAttack
        case .coreMaster: return L10n.typeCoreMaster
        case .armDayEveryDay: return L10n.typeArmDayEveryDay
        case .pushCrazy: return L10n.typePushCrazy
        case .fullBodyConqueror: return L10n.typeFullBodyConqueror
        case .dataInsufficient: return L10n.typeDataInsufficient
        }
    }

    var localizedDescription: String {
        switch self {
        case .mirrorMuscle: return L10n.descMirrorMuscle
        case .balanceMaster: return L10n.descBalanceMaster
        case .legDayNeverSkip: return L10n.descLegDayNeverSkip
        case .backAttack: return L10n.descBackAttack
        case .coreMaster: return L10n.descCoreMaster
        case .armDayEveryDay: return L10n.descArmDayEveryDay
        case .pushCrazy: return L10n.descPushCrazy
        case .fullBodyConqueror: return L10n.descFullBodyConqueror
        case .dataInsufficient: return L10n.descDataInsufficient
        }
    }

    var localizedAdvice: String {
        switch self {
        case .mirrorMuscle: return L10n.adviceMirrorMuscle
        case .balanceMaster: return L10n.adviceBalanceMaster
        case .legDayNeverSkip: return L10n.adviceLegDayNeverSkip
        case .backAttack: return L10n.adviceBackAttack
        case .coreMaster: return L10n.adviceCoreMaster
        case .armDayEveryDay: return L10n.adviceArmDayEveryDay
        case .pushCrazy: return L10n.advicePushCrazy
        case .fullBodyConqueror: return L10n.adviceFullBodyConqueror
        case .dataInsufficient: return L10n.adviceDataInsufficient
        }
    }
}

// MARK: - バランス軸

struct BalanceAxis {
    let name: String
    let leftLabel: String
    let rightLabel: String
    let leftRatio: Double  // 0.0 - 1.0
    let rightRatio: Double // 0.0 - 1.0

    var isBalanced: Bool {
        leftRatio >= 0.4 && leftRatio <= 0.6
    }
}

// MARK: - 筋肉バランス診断ViewModel

@MainActor
@Observable
class MuscleBalanceDiagnosisViewModel {
    private var modelContext: ModelContext?

    // 診断結果
    private(set) var trainerType: TrainerType = .dataInsufficient
    private(set) var balanceAxes: [BalanceAxis] = []
    private(set) var muscleStimulationMap: [String: Int] = [:]
    private(set) var totalSessions: Int = 0

    // 状態
    private(set) var isAnalyzing = false
    private(set) var hasResult = false

    // MARK: - 筋肉カテゴリ定義

    // 上半身
    private let upperBodyMuscles: Set<Muscle> = [
        .chestUpper, .chestLower, .lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae,
        .deltoidAnterior, .deltoidLateral, .deltoidPosterior,
        .biceps, .triceps, .forearms
    ]

    // 下半身
    private let lowerBodyMuscles: Set<Muscle> = [
        .glutes, .quadriceps, .hamstrings, .adductors, .hipFlexors,
        .gastrocnemius, .soleus
    ]

    // 前面
    private let frontMuscles: Set<Muscle> = [
        .chestUpper, .chestLower, .deltoidAnterior, .biceps,
        .rectusAbdominis, .obliques, .quadriceps, .hipFlexors
    ]

    // 背面
    private let backMuscles: Set<Muscle> = [
        .lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae, .deltoidPosterior,
        .triceps, .glutes, .hamstrings, .gastrocnemius, .soleus
    ]

    // プッシュ系
    private let pushMuscles: Set<Muscle> = [
        .chestUpper, .chestLower, .deltoidAnterior, .deltoidLateral, .triceps, .quadriceps
    ]

    // プル系
    private let pullMuscles: Set<Muscle> = [
        .lats, .trapsUpper, .trapsMiddleLower, .biceps, .hamstrings, .glutes
    ]

    // コア
    private let coreMuscles: Set<Muscle> = [
        .rectusAbdominis, .obliques, .erectorSpinae
    ]

    // 四肢
    private let limbMuscles: Set<Muscle> = [
        .biceps, .triceps, .forearms, .quadriceps, .hamstrings,
        .gastrocnemius, .soleus
    ]

    // 腕（特別判定用）
    private let armMuscles: Set<Muscle> = [
        .biceps, .triceps, .forearms
    ]

    // ミラーマッスル（上半身前面）
    private let mirrorMuscles: Set<Muscle> = [
        .chestUpper, .chestLower, .deltoidAnterior, .deltoidLateral, .biceps
    ]

    // MARK: - 初期化

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 診断実行

    func runDiagnosis() async {
        guard let modelContext = modelContext else { return }

        isAnalyzing = true
        hasResult = false

        // アニメーション用に少し待つ
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // 全セッションを取得
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else {
            isAnalyzing = false
            return
        }

        totalSessions = sessions.count

        // データ不足チェック
        if totalSessions < 10 {
            trainerType = .dataInsufficient
            balanceAxes = []
            isAnalyzing = false
            hasResult = true
            return
        }

        // 筋肉刺激回数を集計
        var muscleCount: [Muscle: Int] = [:]

        for session in sessions {
            for set in session.sets {
                guard let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) else { continue }
                for (muscleId, _) in exercise.muscleMapping {
                    guard let muscle = Muscle(rawValue: muscleId) else { continue }
                    muscleCount[muscle, default: 0] += 1
                }
            }
        }

        // マッピング用に変換
        muscleStimulationMap = Dictionary(uniqueKeysWithValues: muscleCount.map { ($0.key.rawValue, $0.value) })

        // バランス軸を計算
        let upperLowerAxis = calculateAxis(
            name: "upper_lower",
            leftLabel: L10n.upperBody,
            rightLabel: L10n.lowerBody,
            leftMuscles: upperBodyMuscles,
            rightMuscles: lowerBodyMuscles,
            muscleCount: muscleCount
        )

        let frontBackAxis = calculateAxis(
            name: "front_back",
            leftLabel: L10n.frontSide,
            rightLabel: L10n.backSide,
            leftMuscles: frontMuscles,
            rightMuscles: backMuscles,
            muscleCount: muscleCount
        )

        let pushPullAxis = calculateAxis(
            name: "push_pull",
            leftLabel: L10n.pushType,
            rightLabel: L10n.pullType,
            leftMuscles: pushMuscles,
            rightMuscles: pullMuscles,
            muscleCount: muscleCount
        )

        let coreLimbAxis = calculateAxis(
            name: "core_limb",
            leftLabel: L10n.coreType,
            rightLabel: L10n.limbType,
            leftMuscles: coreMuscles,
            rightMuscles: limbMuscles,
            muscleCount: muscleCount
        )

        balanceAxes = [upperLowerAxis, frontBackAxis, pushPullAxis, coreLimbAxis]

        // タイプ判定
        trainerType = determineType(
            muscleCount: muscleCount,
            axes: balanceAxes
        )

        isAnalyzing = false
        hasResult = true
    }

    // MARK: - 軸計算

    private func calculateAxis(
        name: String,
        leftLabel: String,
        rightLabel: String,
        leftMuscles: Set<Muscle>,
        rightMuscles: Set<Muscle>,
        muscleCount: [Muscle: Int]
    ) -> BalanceAxis {
        let leftTotal = leftMuscles.reduce(0) { $0 + (muscleCount[$1] ?? 0) }
        let rightTotal = rightMuscles.reduce(0) { $0 + (muscleCount[$1] ?? 0) }
        let total = leftTotal + rightTotal

        let leftRatio = total > 0 ? Double(leftTotal) / Double(total) : 0.5
        let rightRatio = total > 0 ? Double(rightTotal) / Double(total) : 0.5

        return BalanceAxis(
            name: name,
            leftLabel: leftLabel,
            rightLabel: rightLabel,
            leftRatio: leftRatio,
            rightRatio: rightRatio
        )
    }

    // MARK: - タイプ判定

    private func determineType(
        muscleCount: [Muscle: Int],
        axes: [BalanceAxis]
    ) -> TrainerType {
        // 全軸バランスチェック
        let allBalanced = axes.allSatisfy { $0.isBalanced }

        // 全部位刺激チェック
        let stimulatedMuscles = muscleCount.filter { $0.value > 0 }.count
        let totalStimulation = muscleCount.values.reduce(0, +)
        let avgStimulation = Muscle.allCases.count > 0 ? Double(totalStimulation) / Double(Muscle.allCases.count) : 0

        // 全身制覇型: 全部位刺激 && 高頻度 && バランス良好
        if stimulatedMuscles >= 18 && avgStimulation >= 5 && allBalanced {
            return .fullBodyConqueror
        }

        // バランスマスター型: 全軸バランス
        if allBalanced {
            return .balanceMaster
        }

        // 各軸の偏りを計算
        var maxBias: (axis: String, value: Double, direction: String) = ("", 0, "")

        for axis in axes {
            let bias = abs(axis.leftRatio - 0.5)
            if bias > maxBias.value {
                let direction = axis.leftRatio > 0.5 ? "left" : "right"
                maxBias = (axis.name, bias, direction)
            }
        }

        // 腕の刺激比率チェック
        let armStim = armMuscles.reduce(0) { $0 + (muscleCount[$1] ?? 0) }
        let totalStim = muscleCount.values.reduce(0, +)
        let armRatio = totalStim > 0 ? Double(armStim) / Double(totalStim) : 0

        if armRatio > 0.3 {
            return .armDayEveryDay
        }

        // ミラーマッスル判定（上半身前面偏重）
        let mirrorStim = mirrorMuscles.reduce(0) { $0 + (muscleCount[$1] ?? 0) }
        let mirrorRatio = totalStim > 0 ? Double(mirrorStim) / Double(totalStim) : 0

        if mirrorRatio > 0.4 {
            return .mirrorMuscle
        }

        // 最大偏りに基づくタイプ判定
        switch maxBias.axis {
        case "upper_lower":
            return maxBias.direction == "right" ? .legDayNeverSkip : .mirrorMuscle
        case "front_back":
            return maxBias.direction == "right" ? .backAttack : .mirrorMuscle
        case "push_pull":
            return maxBias.direction == "left" ? .pushCrazy : .backAttack
        case "core_limb":
            return maxBias.direction == "left" ? .coreMaster : .armDayEveryDay
        default:
            return .balanceMaster
        }
    }

    // MARK: - リセット

    func reset() {
        trainerType = .dataInsufficient
        balanceAxes = []
        muscleStimulationMap = [:]
        hasResult = false
    }
}

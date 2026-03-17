import Foundation
import SwiftData
import SwiftUI

// MARK: - Strength Map 表示パラメータ

struct StrengthDisplayParams {
    let strokeWidth: CGFloat
    let opacity: Double
    let color: Color
}

// MARK: - 強さレベル（ユーザー向け表示）

/// 体重比ベースの強さレベル（S/A+等のグレードを人間がわかる言葉に変換）
enum StrengthLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case elite = "elite"
    case freak = "freak"

    /// 日本語名
    var japaneseName: String {
        switch self {
        case .beginner:     return "初心者"
        case .intermediate: return "中級者"
        case .advanced:     return "上級者"
        case .elite:        return "エリート"
        case .freak:        return "怪物"
        }
    }

    /// 英語名
    var englishName: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .elite:        return "Elite"
        case .freak:        return "Freak"
        }
    }

    /// ローカライズ名
    @MainActor
    var localizedName: String {
        LocalizationManager.shared.currentLanguage == .japanese ? japaneseName : englishName
    }

    /// レベルカラー
    var color: Color {
        switch self {
        case .beginner:     return .mmTextSecondary
        case .intermediate: return .mmMuscleModerate
        case .advanced:     return .mmAccentSecondary
        case .elite:        return .mmAccentPrimary
        case .freak:        return .mmPRGold
        }
    }

    /// レベル絵文字
    var emoji: String {
        switch self {
        case .beginner:     return "🌱"
        case .intermediate: return "💪"
        case .advanced:     return "🔥"
        case .elite:        return "⚡"
        case .freak:        return "👑"
        }
    }

    /// スコア閾値（この値以上で該当レベル）
    var minimumScore: Double {
        switch self {
        case .beginner:     return 0.0
        case .intermediate: return 0.20
        case .advanced:     return 0.40
        case .elite:        return 0.65
        case .freak:        return 0.85
        }
    }

    /// 次のレベル（freakの場合はnil）
    var nextLevel: StrengthLevel? {
        switch self {
        case .beginner:     return .intermediate
        case .intermediate: return .advanced
        case .advanced:     return .elite
        case .elite:        return .freak
        case .freak:        return nil
        }
    }
}

// MARK: - 種目カテゴリ別閾値

/// 体重比スコアの閾値テーブル
private enum StrengthCategory {
    /// カテゴリA: コンパウンド大筋群（胸・背中・脚）
    case compoundLarge
    /// カテゴリB: コンパウンド中筋群（肩・上腕）
    case compoundMedium
    /// カテゴリC: アイソレーション小筋群
    case isolation

    /// 体重比 → 0.0〜1.0 スコアに変換
    func score(for ratio: Double) -> Double {
        switch self {
        case .compoundLarge:
            if ratio <= 0     { return 0.0 }
            if ratio <= 0.5   { return lerp(ratio, from: 0, to: 0.5, scoreFrom: 0.0, scoreTo: 0.15) }
            if ratio <= 0.75  { return lerp(ratio, from: 0.5, to: 0.75, scoreFrom: 0.15, scoreTo: 0.30) }
            if ratio <= 1.0   { return lerp(ratio, from: 0.75, to: 1.0, scoreFrom: 0.30, scoreTo: 0.50) }
            if ratio <= 1.25  { return lerp(ratio, from: 1.0, to: 1.25, scoreFrom: 0.50, scoreTo: 0.70) }
            if ratio <= 1.5   { return lerp(ratio, from: 1.25, to: 1.5, scoreFrom: 0.70, scoreTo: 0.85) }
            return 1.0

        case .compoundMedium:
            if ratio <= 0     { return 0.0 }
            if ratio <= 0.3   { return lerp(ratio, from: 0, to: 0.3, scoreFrom: 0.0, scoreTo: 0.15) }
            if ratio <= 0.5   { return lerp(ratio, from: 0.3, to: 0.5, scoreFrom: 0.15, scoreTo: 0.35) }
            if ratio <= 0.7   { return lerp(ratio, from: 0.5, to: 0.7, scoreFrom: 0.35, scoreTo: 0.55) }
            if ratio <= 0.9   { return lerp(ratio, from: 0.7, to: 0.9, scoreFrom: 0.55, scoreTo: 0.75) }
            if ratio <= 1.1   { return lerp(ratio, from: 0.9, to: 1.1, scoreFrom: 0.75, scoreTo: 0.90) }
            return 1.0

        case .isolation:
            if ratio <= 0     { return 0.0 }
            if ratio <= 0.2   { return lerp(ratio, from: 0, to: 0.2, scoreFrom: 0.0, scoreTo: 0.15) }
            if ratio <= 0.35  { return lerp(ratio, from: 0.2, to: 0.35, scoreFrom: 0.15, scoreTo: 0.35) }
            if ratio <= 0.5   { return lerp(ratio, from: 0.35, to: 0.5, scoreFrom: 0.35, scoreTo: 0.55) }
            if ratio <= 0.65  { return lerp(ratio, from: 0.5, to: 0.65, scoreFrom: 0.55, scoreTo: 0.75) }
            if ratio <= 0.8   { return lerp(ratio, from: 0.65, to: 0.8, scoreFrom: 0.75, scoreTo: 0.90) }
            return 1.0
        }
    }

    /// スコアから体重比を逆算（次のレベルに必要な体重比を求めるため）
    func ratioForScore(_ targetScore: Double) -> Double {
        switch self {
        case .compoundLarge:
            if targetScore <= 0.15 { return inverseLerp(targetScore, scoreFrom: 0.0, scoreTo: 0.15, from: 0, to: 0.5) }
            if targetScore <= 0.30 { return inverseLerp(targetScore, scoreFrom: 0.15, scoreTo: 0.30, from: 0.5, to: 0.75) }
            if targetScore <= 0.50 { return inverseLerp(targetScore, scoreFrom: 0.30, scoreTo: 0.50, from: 0.75, to: 1.0) }
            if targetScore <= 0.70 { return inverseLerp(targetScore, scoreFrom: 0.50, scoreTo: 0.70, from: 1.0, to: 1.25) }
            if targetScore <= 0.85 { return inverseLerp(targetScore, scoreFrom: 0.70, scoreTo: 0.85, from: 1.25, to: 1.5) }
            return 1.5

        case .compoundMedium:
            if targetScore <= 0.15 { return inverseLerp(targetScore, scoreFrom: 0.0, scoreTo: 0.15, from: 0, to: 0.3) }
            if targetScore <= 0.35 { return inverseLerp(targetScore, scoreFrom: 0.15, scoreTo: 0.35, from: 0.3, to: 0.5) }
            if targetScore <= 0.55 { return inverseLerp(targetScore, scoreFrom: 0.35, scoreTo: 0.55, from: 0.5, to: 0.7) }
            if targetScore <= 0.75 { return inverseLerp(targetScore, scoreFrom: 0.55, scoreTo: 0.75, from: 0.7, to: 0.9) }
            if targetScore <= 0.90 { return inverseLerp(targetScore, scoreFrom: 0.75, scoreTo: 0.90, from: 0.9, to: 1.1) }
            return 1.1

        case .isolation:
            if targetScore <= 0.15 { return inverseLerp(targetScore, scoreFrom: 0.0, scoreTo: 0.15, from: 0, to: 0.2) }
            if targetScore <= 0.35 { return inverseLerp(targetScore, scoreFrom: 0.15, scoreTo: 0.35, from: 0.2, to: 0.35) }
            if targetScore <= 0.55 { return inverseLerp(targetScore, scoreFrom: 0.35, scoreTo: 0.55, from: 0.35, to: 0.5) }
            if targetScore <= 0.75 { return inverseLerp(targetScore, scoreFrom: 0.55, scoreTo: 0.75, from: 0.5, to: 0.65) }
            if targetScore <= 0.90 { return inverseLerp(targetScore, scoreFrom: 0.75, scoreTo: 0.90, from: 0.65, to: 0.8) }
            return 0.8
        }
    }

    /// 線形補間ヘルパー
    private func lerp(_ value: Double, from: Double, to: Double, scoreFrom: Double, scoreTo: Double) -> Double {
        let t = (value - from) / (to - from)
        return scoreFrom + t * (scoreTo - scoreFrom)
    }

    /// 逆線形補間（スコア→体重比）
    private func inverseLerp(_ score: Double, scoreFrom: Double, scoreTo: Double, from: Double, to: Double) -> Double {
        guard scoreTo != scoreFrom else { return from }
        let t = (score - scoreFrom) / (scoreTo - scoreFrom)
        return from + t * (to - from)
    }
}

// MARK: - 筋肉→カテゴリ マッピング

private let muscleCategory: [Muscle: StrengthCategory] = [
    // カテゴリA: コンパウンド大筋群
    .chestUpper:       .compoundLarge,
    .chestLower:       .compoundLarge,
    .lats:             .compoundLarge,
    .trapsMiddleLower: .compoundLarge,
    .quadriceps:       .compoundLarge,
    .hamstrings:       .compoundLarge,
    .glutes:           .compoundLarge,
    .erectorSpinae:    .compoundLarge,
    // カテゴリB: コンパウンド中筋群
    .deltoidAnterior:  .compoundMedium,
    .deltoidLateral:   .compoundMedium,
    .deltoidPosterior: .compoundMedium,
    .trapsUpper:       .compoundMedium,
    .biceps:           .compoundMedium,
    .triceps:          .compoundMedium,
    // カテゴリC: アイソレーション小筋群
    .forearms:         .isolation,
    .gastrocnemius:    .isolation,
    .soleus:           .isolation,
    .obliques:         .isolation,
    .rectusAbdominis:  .isolation,
    .adductors:        .isolation,
    .hipFlexors:       .compoundLarge,
]

// MARK: - StrengthScoreCalculator

@MainActor
final class StrengthScoreCalculator {
    static let shared = StrengthScoreCalculator()

    private init() {}

    /// 全WorkoutSetから筋肉ごとのStrengthスコア（0.0〜1.0）を算出
    func muscleStrengthScores(allSets: [WorkoutSet], bodyweightKg: Double) -> [String: Double] {
        let bodyweight = bodyweightKg > 0 ? bodyweightKg : 70.0

        // Step 1: 種目ごとの最大推定1RMを算出
        var exerciseBest1RM: [String: Double] = [:]
        for set in allSets {
            let estimated = PRManager.shared.estimated1RM(weight: set.weight, reps: set.reps)
            if estimated > (exerciseBest1RM[set.exerciseId] ?? 0) {
                exerciseBest1RM[set.exerciseId] = estimated
            }
        }

        // Step 1.5: オンボーディングPR入力値をマージ（ワークアウト記録がない種目のみ補完）
        let initialPRs = AppState.shared.userProfile.initialPRs
        for (exerciseId, pr1RM) in initialPRs where pr1RM > 0 {
            if pr1RM > (exerciseBest1RM[exerciseId] ?? 0) {
                exerciseBest1RM[exerciseId] = pr1RM
            }
        }

        // Step 2: 種目→筋肉の逆引きで、筋肉ごとの最高スコアを算出
        var muscleScores: [String: Double] = [:]
        let exerciseStore = ExerciseStore.shared

        for (exerciseId, best1RM) in exerciseBest1RM {
            guard let definition = exerciseStore.exercise(for: exerciseId) else { continue }
            let strengthRatio = best1RM / bodyweight

            for (muscleId, _) in definition.muscleMapping {
                guard let muscle = Muscle(rawValue: muscleId) else { continue }
                let category = muscleCategory[muscle] ?? .isolation
                let score = category.score(for: strengthRatio)

                if score > (muscleScores[muscleId] ?? 0) {
                    muscleScores[muscleId] = score
                }
            }
        }

        return muscleScores
    }

    // MARK: - グレード判定

    /// スコア（0.0〜1.0）からグレード文字列を返す
    static func grade(score: Double) -> String {
        switch score {
        case 0.85...: return "S"
        case 0.70...: return "A+"
        case 0.55...: return "A"
        case 0.40...: return "B+"
        case 0.30...: return "B"
        case 0.20...: return "C"
        default:      return "D"
        }
    }

    /// グレード文字列から対応するカラーを返す
    static func gradeColor(grade: String) -> Color {
        switch grade {
        case "S":  return .mmAccentPrimary
        case "A+": return Color(hex: "#00CC8F")
        case "A":  return .mmAccentSecondary
        case "B+": return .mmMuscleRecovered
        case "B":  return .mmMuscleModerate
        case "C":  return .mmTextSecondary
        default:   return Color(hex: "#808080")
        }
    }

    // MARK: - 強さレベル判定

    /// スコア（0.0〜1.0）からStrengthLevelを返す
    static func level(score: Double) -> StrengthLevel {
        if score >= StrengthLevel.freak.minimumScore { return .freak }
        if score >= StrengthLevel.elite.minimumScore { return .elite }
        if score >= StrengthLevel.advanced.minimumScore { return .advanced }
        if score >= StrengthLevel.intermediate.minimumScore { return .intermediate }
        return .beginner
    }

    /// 種目の推定1RMと体重から直接レベルを判定
    /// - Returns: (現在のレベル, 次のレベルまでに必要な追加kg, 次のレベル名)
    static func exerciseStrengthLevel(
        exerciseId: String,
        estimated1RM: Double,
        bodyweightKg: Double
    ) -> (level: StrengthLevel, kgToNext: Double?, nextLevel: StrengthLevel?) {
        let bodyweight = bodyweightKg > 0 ? bodyweightKg : 70.0
        let ratio = estimated1RM / bodyweight

        // 種目のプライマリ筋肉からカテゴリを推定
        let category: StrengthCategory
        if let definition = ExerciseStore.shared.exercise(for: exerciseId),
           let primaryMuscleId = definition.muscleMapping.max(by: { $0.value < $1.value })?.key,
           let muscle = Muscle(rawValue: primaryMuscleId) {
            category = muscleCategory[muscle] ?? .compoundLarge
        } else {
            category = .compoundLarge
        }

        let score = category.score(for: ratio)
        let currentLevel = level(score: score)

        // 次のレベルまでに必要なkg
        guard let nextLvl = currentLevel.nextLevel else {
            return (currentLevel, nil, nil) // 既に最高レベル
        }

        let nextScore = nextLvl.minimumScore
        let nextRatio = category.ratioForScore(nextScore)
        let next1RM = nextRatio * bodyweight
        let kgNeeded = max(0, next1RM - estimated1RM)

        return (currentLevel, kgNeeded, nextLvl)
    }

    /// 総合レベル（全種目の中央値ベース）
    func overallLevel(allSets: [WorkoutSet], bodyweightKg: Double) -> StrengthLevel {
        let scores = muscleStrengthScores(allSets: allSets, bodyweightKg: bodyweightKg)
        guard !scores.isEmpty else { return .beginner }
        let avgScore = scores.values.reduce(0, +) / Double(scores.count)
        return Self.level(score: avgScore)
    }

    // MARK: - 表示パラメータ

    /// スコアから表示パラメータへ変換
    func displayParams(score: Double) -> StrengthDisplayParams {
        if score <= 0 {
            return StrengthDisplayParams(
                strokeWidth: 1.0,
                opacity: 0.25,
                color: Color.mmMuscleInactive
            )
        } else if score < 0.2 {
            return StrengthDisplayParams(
                strokeWidth: 1.5,
                opacity: 0.4,
                color: Color.mmAccentSecondary
            )
        } else if score < 0.4 {
            return StrengthDisplayParams(
                strokeWidth: 2.5,
                opacity: 0.55,
                color: Color.mmAccentSecondary
            )
        } else if score < 0.6 {
            return StrengthDisplayParams(
                strokeWidth: 3.5,
                opacity: 0.70,
                color: Color.mmAccentSecondary
            )
        } else if score < 0.8 {
            return StrengthDisplayParams(
                strokeWidth: 5.0,
                opacity: 0.85,
                color: Color.mmAccentSecondary
            )
        } else {
            return StrengthDisplayParams(
                strokeWidth: 7.0,
                opacity: 1.0,
                color: Color.mmAccentPrimary
            )
        }
    }
}

import Foundation
import SwiftData
import SwiftUI

// MARK: - Strength Map 表示パラメータ

struct StrengthDisplayParams {
    let strokeWidth: CGFloat
    let opacity: Double
    let color: Color
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

    /// 線形補間ヘルパー
    private func lerp(_ value: Double, from: Double, to: Double, scoreFrom: Double, scoreTo: Double) -> Double {
        let t = (value - from) / (to - from)
        return scoreFrom + t * (scoreTo - scoreFrom)
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
]

// MARK: - StrengthScoreCalculator

@MainActor
final class StrengthScoreCalculator {
    static let shared = StrengthScoreCalculator()

    private init() {}

    /// 全WorkoutSetから筋肉ごとのStrengthスコア（0.0〜1.0）を算出
    /// - Parameters:
    ///   - allSets: 全WorkoutSet配列
    ///   - bodyweightKg: ユーザー体重（kg）
    /// - Returns: [筋肉ID文字列: スコア(0.0〜1.0)]
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

        // Step 2: 種目→筋肉の逆引きで、筋肉ごとの最高スコアを算出
        var muscleScores: [String: Double] = [:]
        let exerciseStore = ExerciseStore.shared

        for (exerciseId, best1RM) in exerciseBest1RM {
            guard let definition = exerciseStore.exercise(for: exerciseId) else { continue }

            // 体重比を算出
            let strengthRatio = best1RM / bodyweight

            // この種目が関連する全筋肉についてスコアを計算
            for (muscleId, _) in definition.muscleMapping {
                guard let muscle = Muscle(rawValue: muscleId) else { continue }
                let category = muscleCategory[muscle] ?? .isolation
                let score = category.score(for: strengthRatio)

                // その筋肉の最高スコアを採用
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

    /// スコアから表示パラメータへ変換
    func displayParams(score: Double) -> StrengthDisplayParams {
        if score <= 0 {
            // 未記録
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
            // 0.8〜1.0: 最強レベル
            return StrengthDisplayParams(
                strokeWidth: 7.0,
                opacity: 1.0,
                color: Color.mmAccentPrimary
            )
        }
    }
}

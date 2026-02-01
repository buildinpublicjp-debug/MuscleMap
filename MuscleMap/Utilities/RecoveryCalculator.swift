import Foundation

// MARK: - 回復計算（ボリューム係数付き）

struct RecoveryCalculator {

    // MARK: ボリューム係数

    /// セット数からボリューム係数を算出
    static func volumeCoefficient(sets: Int) -> Double {
        switch sets {
        case ...0:  return 0.7    // 安全策（0以下は最小値）
        case 1:     return 0.7    // 軽く触っただけ
        case 2:     return 0.85
        case 3:     return 1.0    // 標準
        case 4:     return 1.1
        default:    return 1.15   // 5セット以上（上限）
        }
    }

    // MARK: 回復時間

    /// 調整済み回復時間（時間）
    static func adjustedRecoveryHours(muscle: Muscle, totalSets: Int) -> Double {
        Double(muscle.baseRecoveryHours) * volumeCoefficient(sets: totalSets)
    }

    // MARK: 回復進捗

    /// 回復進捗（0.0=直後 〜 1.0=完全回復）
    static func recoveryProgress(
        stimulationDate: Date,
        muscle: Muscle,
        totalSets: Int,
        now: Date = Date()
    ) -> Double {
        let elapsed = now.timeIntervalSince(stimulationDate) / 3600 // 時間に変換
        let needed = adjustedRecoveryHours(muscle: muscle, totalSets: totalSets)
        guard needed > 0 else { return 1.0 }
        return min(1.0, max(0.0, elapsed / needed))
    }

    // MARK: 未刺激日数

    /// 未刺激日数を計算
    static func daysSinceStimulation(_ date: Date, now: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
    }

    // MARK: 回復ステータス

    /// 回復ステータスを判定
    static func recoveryStatus(
        stimulationDate: Date,
        muscle: Muscle,
        totalSets: Int,
        now: Date = Date()
    ) -> RecoveryStatus {
        let progress = recoveryProgress(
            stimulationDate: stimulationDate,
            muscle: muscle,
            totalSets: totalSets,
            now: now
        )
        let days = daysSinceStimulation(stimulationDate, now: now)

        if days >= 14 {
            return .neglectedSevere
        } else if days >= 7 {
            return .neglected
        } else if progress >= 1.0 {
            return .fullyRecovered
        } else {
            return .recovering(progress: progress)
        }
    }
}

// MARK: - 回復ステータス

enum RecoveryStatus: Equatable {
    /// 回復中（progress: 0.0〜1.0）
    case recovering(progress: Double)
    /// 完全回復
    case fullyRecovered
    /// 未刺激（7日以上）
    case neglected
    /// 未刺激（14日以上、深刻）
    case neglectedSevere
}

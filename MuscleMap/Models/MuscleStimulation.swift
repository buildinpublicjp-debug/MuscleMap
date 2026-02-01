import Foundation
import SwiftData

// MARK: - 筋肉刺激記録（回復計算の元データ）

@Model
final class MuscleStimulation {
    /// Muscle.rawValue
    var muscle: String
    /// 刺激を受けた日時
    var stimulationDate: Date
    /// 刺激度%の最大値 / 100（0.0-1.0）
    var maxIntensity: Double
    /// その日の合計セット数（ボリューム係数用）
    var totalSets: Int
    /// 関連するセッションID
    var sessionId: UUID

    /// Muscle enumに変換
    var muscleEnum: Muscle? {
        Muscle(rawValue: muscle)
    }

    init(
        muscle: String,
        stimulationDate: Date = Date(),
        maxIntensity: Double,
        totalSets: Int,
        sessionId: UUID
    ) {
        self.muscle = muscle
        self.stimulationDate = stimulationDate
        self.maxIntensity = maxIntensity
        self.totalSets = totalSets
        self.sessionId = sessionId
    }
}

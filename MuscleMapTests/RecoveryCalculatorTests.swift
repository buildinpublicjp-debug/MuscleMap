import Testing
import Foundation
@testable import MuscleMap

// MARK: - RecoveryCalculator テスト

struct RecoveryCalculatorTests {

    // MARK: ボリューム係数

    @Test("ボリューム係数: 1セット = 0.7")
    func volumeCoefficient1Set() {
        #expect(RecoveryCalculator.volumeCoefficient(sets: 1) == 0.7)
    }

    @Test("ボリューム係数: 3セット = 1.0（標準）")
    func volumeCoefficient3Sets() {
        #expect(RecoveryCalculator.volumeCoefficient(sets: 3) == 1.0)
    }

    @Test("ボリューム係数: 5セット以上 = 1.15（上限）")
    func volumeCoefficient5PlusSets() {
        #expect(RecoveryCalculator.volumeCoefficient(sets: 5) == 1.15)
        #expect(RecoveryCalculator.volumeCoefficient(sets: 10) == 1.15)
    }

    @Test("ボリューム係数: 0以下 = 0.7（安全策）")
    func volumeCoefficientZero() {
        #expect(RecoveryCalculator.volumeCoefficient(sets: 0) == 0.7)
        #expect(RecoveryCalculator.volumeCoefficient(sets: -1) == 0.7)
    }

    // MARK: 回復時間

    @Test("調整済み回復時間: 大筋群3セット = 72h")
    func adjustedRecoveryHoursLargeMuscle() {
        let hours = RecoveryCalculator.adjustedRecoveryHours(muscle: .quadriceps, totalSets: 3)
        #expect(hours == 72.0)
    }

    @Test("調整済み回復時間: 中筋群3セット = 48h")
    func adjustedRecoveryHoursMediumMuscle() {
        let hours = RecoveryCalculator.adjustedRecoveryHours(muscle: .chestUpper, totalSets: 3)
        #expect(hours == 48.0)
    }

    @Test("調整済み回復時間: 小筋群3セット = 24h")
    func adjustedRecoveryHoursSmallMuscle() {
        let hours = RecoveryCalculator.adjustedRecoveryHours(muscle: .forearms, totalSets: 3)
        #expect(hours == 24.0)
    }

    @Test("調整済み回復時間: 大筋群1セット = 72 * 0.7 = 50.4h")
    func adjustedRecoveryHoursLowVolume() {
        let hours = RecoveryCalculator.adjustedRecoveryHours(muscle: .lats, totalSets: 1)
        #expect(abs(hours - 50.4) < 0.01)
    }

    // MARK: 回復進捗

    @Test("回復進捗: 直後 = 0.0")
    func recoveryProgressJustWorked() {
        let now = Date()
        let progress = RecoveryCalculator.recoveryProgress(
            stimulationDate: now,
            muscle: .chestUpper,
            totalSets: 3,
            now: now
        )
        #expect(progress == 0.0)
    }

    @Test("回復進捗: 24h後の中筋群 = 0.5")
    func recoveryProgressHalfway() {
        let now = Date()
        let stimDate = now.addingTimeInterval(-24 * 3600) // 24時間前
        let progress = RecoveryCalculator.recoveryProgress(
            stimulationDate: stimDate,
            muscle: .chestUpper, // 48h回復
            totalSets: 3,        // 係数1.0
            now: now
        )
        #expect(abs(progress - 0.5) < 0.01)
    }

    @Test("回復進捗: 完全回復後は1.0に制限")
    func recoveryProgressCapped() {
        let now = Date()
        let stimDate = now.addingTimeInterval(-200 * 3600) // 200時間前
        let progress = RecoveryCalculator.recoveryProgress(
            stimulationDate: stimDate,
            muscle: .chestUpper,
            totalSets: 3,
            now: now
        )
        #expect(progress == 1.0)
    }

    // MARK: 未刺激日数

    @Test("未刺激日数: 同日 = 0")
    func daysSinceStimulationToday() {
        let days = RecoveryCalculator.daysSinceStimulation(Date())
        #expect(days == 0)
    }

    @Test("未刺激日数: 7日前")
    func daysSinceStimulation7Days() {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let days = RecoveryCalculator.daysSinceStimulation(sevenDaysAgo, now: now)
        #expect(days == 7)
    }

    // MARK: 回復ステータス

    @Test("回復ステータス: 回復中")
    func recoveryStatusRecovering() {
        let now = Date()
        let status = RecoveryCalculator.recoveryStatus(
            stimulationDate: now,
            muscle: .quadriceps,
            totalSets: 3,
            now: now
        )
        #expect(status == .recovering(progress: 0.0))
    }

    @Test("回復ステータス: 完全回復")
    func recoveryStatusFullyRecovered() {
        let now = Date()
        let stimDate = now.addingTimeInterval(-100 * 3600)
        let status = RecoveryCalculator.recoveryStatus(
            stimulationDate: stimDate,
            muscle: .chestUpper, // 48h
            totalSets: 3,
            now: now
        )
        #expect(status == .fullyRecovered)
    }

    @Test("回復ステータス: 7日以上未刺激 = neglected")
    func recoveryStatusNeglected() {
        let now = Date()
        let stimDate = Calendar.current.date(byAdding: .day, value: -8, to: now)!
        let status = RecoveryCalculator.recoveryStatus(
            stimulationDate: stimDate,
            muscle: .forearms,
            totalSets: 3,
            now: now
        )
        #expect(status == .neglected)
    }

    @Test("回復ステータス: 14日以上未刺激 = neglectedSevere")
    func recoveryStatusNeglectedSevere() {
        let now = Date()
        let stimDate = Calendar.current.date(byAdding: .day, value: -15, to: now)!
        let status = RecoveryCalculator.recoveryStatus(
            stimulationDate: stimDate,
            muscle: .biceps,
            totalSets: 3,
            now: now
        )
        #expect(status == .neglectedSevere)
    }
}

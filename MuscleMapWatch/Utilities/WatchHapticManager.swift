import WatchKit

// MARK: - Watch用ハプティックフィードバックマネージャー
// WKInterfaceDeviceを使用してwatchOS向けの触覚フィードバックを提供

struct WatchHapticManager {

    /// セット記録完了 → 成功ハプティック
    static func setRecorded() {
        WKInterfaceDevice.current().play(.success)
    }

    /// レストタイマー完了 → 通知ハプティック
    static func restTimerCompleted() {
        WKInterfaceDevice.current().play(.notification)
    }

    /// ステッパー操作（重量・レップ調整） → クリックハプティック
    static func stepperChanged() {
        WKInterfaceDevice.current().play(.click)
    }

    /// ワークアウト終了 → 成功ハプティック
    static func workoutEnded() {
        WKInterfaceDevice.current().play(.success)
    }
}

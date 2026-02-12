import UIKit

// MARK: - Haptic Feedback マネージャー

@MainActor
struct HapticManager {
    /// セット記録完了
    static func setRecorded() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// ワークアウト終了
    static func workoutEnded() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        // 少し遅延して重めのインパクトを追加
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }

    /// 重量・レップ調整
    static func stepperChanged() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// 軽いタップ（ボタン押下など）
    static func lightTap() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// エラー時
    static func error() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// 成功時（シェア完了など）
    static func success() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// PR達成時（強い連続バイブレーション）
    static func prAchieved() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        // 連続的な強いインパクトで祝福感を演出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
        }
    }

    /// セット完了時（軽〜中程度のフィードバック）
    static func setCompleted() {
        guard AppState.shared.isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

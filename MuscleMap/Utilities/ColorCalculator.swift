import SwiftUI

// MARK: - 筋肉の視覚状態

enum MuscleVisualState: Equatable {
    /// 背景に溶け込む（刺激なし or 完全回復）
    case inactive
    /// 回復中（色とパルスアニメーション有無）
    case recovering(progress: Double)
    /// 未刺激（7日以上。fast = 14日以上で高速点滅）
    case neglected(fast: Bool)

    /// 表示色を返す
    var color: Color {
        switch self {
        case .inactive:
            return .mmMuscleInactive
        case .recovering(let progress):
            return Self.recoveryColor(progress: progress)
        case .neglected:
            return .mmMuscleNeglected
        }
    }

    /// パルスアニメーションが必要か
    var shouldPulse: Bool {
        switch self {
        case .recovering(let progress):
            return progress < 0.2
        case .neglected:
            return true
        default:
            return false
        }
    }

    /// パルスの速度（秒）
    var pulseInterval: Double {
        switch self {
        case .neglected(fast: true): return 0.5
        case .neglected(fast: false): return 1.5
        case .recovering(let progress) where progress < 0.2: return 1.0
        default: return 0
        }
    }

    // 回復進捗に応じた色を5段階×20%バンドで補間
    private static func recoveryColor(progress: Double) -> Color {
        switch progress {
        case ..<0.2:
            return .mmMuscleCoral
        case 0.2..<0.4:
            return Color.interpolate(
                from: .mmMuscleCoral, to: .mmMuscleAmber,
                t: (progress - 0.2) / 0.2
            )
        case 0.4..<0.6:
            return Color.interpolate(
                from: .mmMuscleAmber, to: .mmMuscleYellow,
                t: (progress - 0.4) / 0.2
            )
        case 0.6..<0.8:
            return Color.interpolate(
                from: .mmMuscleYellow, to: .mmMuscleLime,
                t: (progress - 0.6) / 0.2
            )
        case 0.8...:
            return Color.interpolate(
                from: .mmMuscleLime, to: .mmMuscleBioGreen,
                t: min(1.0, (progress - 0.8) / 0.2)
            )
        default:
            return .mmMuscleBioGreen
        }
    }
}

// MARK: - RecoveryStatus → MuscleVisualState 変換

extension RecoveryStatus {
    var visualState: MuscleVisualState {
        switch self {
        case .recovering(let progress):
            return .recovering(progress: progress)
        case .fullyRecovered:
            return .inactive
        case .neglected:
            return .neglected(fast: false)
        case .neglectedSevere:
            return .neglected(fast: true)
        }
    }
}

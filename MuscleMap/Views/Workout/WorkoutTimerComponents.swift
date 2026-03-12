import SwiftUI

// MARK: - ワークアウトタイマー関連コンポーネント

/// レストタイマー（フルサイズ）
struct RestTimerView: View {
    let seconds: Int
    let isOvertime: Bool
    let onStop: () -> Void

    private var formattedTime: String {
        let mins = seconds / 60
        let secs = seconds % 60
        if isOvertime {
            return "+\(String(format: "%d:%02d", mins, secs))"
        }
        return String(format: "%d:%02d", mins, secs)
    }

    private var timerColor: Color {
        if isOvertime {
            return Color.mmTimerOvertime
        } else if seconds <= 10 {
            return Color.mmTimerWarning
        } else {
            return Color.mmAccentPrimary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // タイマー表示
            HStack(spacing: 6) {
                Image(systemName: isOvertime ? "exclamationmark.timer" : "timer")
                    .font(.subheadline)
                Text(formattedTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(timerColor)

            // 停止ボタン
            Button {
                onStop()
                HapticManager.lightTap()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(8)
                    .background(Color.mmBgSecondary)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(timerColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - コンパクトタイマーバッジ（GIFオーバーレイ用）

/// コンパクトタイマーバッジ
struct CompactTimerBadge: View {
    let seconds: Int
    let isOvertime: Bool
    let onStop: () -> Void

    private var formattedTime: String {
        let mins = seconds / 60
        let secs = seconds % 60
        if isOvertime {
            return "+\(String(format: "%d:%02d", mins, secs))"
        }
        return String(format: "%d:%02d", mins, secs)
    }

    private var badgeColor: Color {
        if isOvertime {
            return Color.mmTimerOvertime
        } else if seconds <= 10 {
            return Color.mmTimerWarning
        } else {
            return Color.mmAccentPrimary
        }
    }

    var body: some View {
        Button {
            onStop()
            HapticManager.lightTap()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOvertime ? "exclamationmark.timer" : "timer")
                    .font(.caption2)
                Text(formattedTime)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isOvertime ? badgeColor : Color.mmTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.mmBgPrimary.opacity(0.7))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Rest Timer") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 20) {
            RestTimerView(seconds: 90, isOvertime: false) {
                print("Timer stopped")
            }
            RestTimerView(seconds: 5, isOvertime: false) {
                print("Timer stopped")
            }
            RestTimerView(seconds: 15, isOvertime: true) {
                print("Timer stopped")
            }
        }
    }
}

#Preview("Compact Timer Badge") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 20) {
            CompactTimerBadge(seconds: 90, isOvertime: false) {
                print("Timer stopped")
            }
            CompactTimerBadge(seconds: 5, isOvertime: false) {
                print("Timer stopped")
            }
            CompactTimerBadge(seconds: 15, isOvertime: true) {
                print("Timer stopped")
            }
        }
    }
}

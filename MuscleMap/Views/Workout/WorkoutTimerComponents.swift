import SwiftUI

// MARK: - ワークアウトタイマー関連コンポーネント

/// レストタイマー（フルスクリーン）
struct RestTimerView: View {
    let seconds: Int
    let onStop: () -> Void

    private var formattedTime: String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        HStack(spacing: 12) {
            // タイマー表示
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.subheadline)
                Text(formattedTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(Color.mmAccentPrimary)

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
        .background(Color.mmAccentPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - コンパクトタイマーバッジ（GIFオーバーレイ用）

/// コンパクトタイマーバッジ
struct CompactTimerBadge: View {
    let seconds: Int
    let onStop: () -> Void

    private var formattedTime: String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        Button {
            onStop()
            HapticManager.lightTap()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.caption2)
                Text(formattedTime)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(Color.mmTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Rest Timer") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 20) {
            RestTimerView(seconds: 90) {
                print("Timer stopped")
            }
            RestTimerView(seconds: 5) {
                print("Timer stopped")
            }
        }
    }
}

#Preview("Compact Timer Badge") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 20) {
            CompactTimerBadge(seconds: 90) {
                print("Timer stopped")
            }
            CompactTimerBadge(seconds: 5) {
                print("Timer stopped")
            }
        }
    }
}

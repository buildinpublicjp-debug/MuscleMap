import SwiftUI

// MARK: - Watch レストタイマー画面
// セット記録後に自動表示。カウントダウン → 0到達でハプティック → オーバータイム表示
// 「次のセット」で入力画面に戻り、「種目を変更」で種目選択に戻る

struct WatchRestTimerView: View {
    @Environment(WatchWorkoutManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            // タイマー表示
            timerDisplay

            Spacer()

            // アクションボタン
            actionButtons
        }
        .padding(.horizontal, 8)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - タイマー表示

    private var timerDisplay: some View {
        VStack(spacing: 4) {
            // オーバータイムラベル
            if manager.isRestTimerOvertime {
                Text(WatchL10n.overtime)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            } else {
                Text(WatchL10n.rest)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // 時間表示
            Text(timerText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(timerColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: manager.restTimerSeconds)
        }
    }

    // MARK: - タイマーテキスト

    private var timerText: String {
        let seconds = manager.restTimerSeconds
        let minutes = seconds / 60
        let secs = seconds % 60
        let formatted = String(format: "%d:%02d", minutes, secs)
        return manager.isRestTimerOvertime ? "+\(formatted)" : formatted
    }

    // MARK: - タイマーカラー

    private var timerColor: Color {
        if manager.isRestTimerOvertime {
            return .red
        }
        if manager.restTimerSeconds <= 10 {
            return .yellow
        }
        return .green
    }

    // MARK: - アクションボタン

    private var actionButtons: some View {
        VStack(spacing: 8) {
            // 次のセット（同じ種目で続行）
            Button {
                manager.stopRestTimer()
                dismiss()
            } label: {
                Text(WatchL10n.nextSet)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .tint(.green)

            // 種目を変更（種目選択画面に戻る）
            Button {
                manager.stopRestTimer()
                manager.selectedExercise = nil
                // ルートまで戻る
                dismiss()
            } label: {
                Text(WatchL10n.changeExercise)
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}

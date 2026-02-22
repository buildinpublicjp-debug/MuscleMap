import SwiftUI

// MARK: - Watch セット入力画面
// Digital Crown で重量/レップ数を調整し、「記録」ボタンでセットを保存
// 記録後はレストタイマー画面に自動遷移

struct WatchSetInputView: View {
    @Environment(WatchWorkoutManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    let exercise: WatchExerciseInfo

    /// Digital Crownのフォーカス対象（true=重量, false=レップ）
    @State private var isWeightFocused: Bool = true

    /// Digital Crown用のバインディング値
    @State private var crownWeight: Double = 0
    @State private var crownReps: Double = 10

    /// レストタイマー画面への遷移
    @State private var showRestTimer: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // 種目名 + セット番号
                headerSection

                // 重量入力
                weightSection

                // レップ数入力
                repsSection

                // 前回の記録
                previousRecordSection

                // 記録ボタン
                recordButton

                // 種目変更・終了ボタン
                actionButtons
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(WatchL10n.set(number: manager.currentSetNumber))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !manager.isSessionActive {
                manager.startSession()
            }
            manager.selectExercise(exercise)
            crownWeight = manager.currentWeight
            crownReps = Double(manager.currentReps)
        }
        .navigationDestination(isPresented: $showRestTimer) {
            WatchRestTimerView()
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        Text(WatchL10n.exerciseName(nameJA: exercise.nameJA, nameEN: exercise.nameEN))
            .font(.footnote)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }

    // MARK: - 重量入力

    private var weightSection: some View {
        VStack(spacing: 2) {
            HStack {
                Button {
                    manager.adjustWeight(by: -2.5)
                    crownWeight = manager.currentWeight
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                VStack(spacing: 0) {
                    Text(String(format: "%.1f", manager.currentWeight))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(isWeightFocused ? .green : .primary)
                    Text(WatchL10n.currentWeightUnit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .focusable(isWeightFocused)
                .digitalCrownRotation(
                    $crownWeight,
                    from: 0,
                    through: 500,
                    by: 0.5,
                    sensitivity: .medium
                )
                .onChange(of: crownWeight) { _, newValue in
                    manager.currentWeight = max(0, newValue)
                }
                .onTapGesture {
                    isWeightFocused = true
                }

                Button {
                    manager.adjustWeight(by: 2.5)
                    crownWeight = manager.currentWeight
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - レップ数入力

    private var repsSection: some View {
        VStack(spacing: 2) {
            HStack {
                Button {
                    manager.adjustReps(by: -1)
                    crownReps = Double(manager.currentReps)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                VStack(spacing: 0) {
                    Text("\(manager.currentReps)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(!isWeightFocused ? .green : .primary)
                    Text(WatchL10n.reps)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .focusable(!isWeightFocused)
                .digitalCrownRotation(
                    $crownReps,
                    from: 1,
                    through: 100,
                    by: 1,
                    sensitivity: .low
                )
                .onChange(of: crownReps) { _, newValue in
                    manager.currentReps = max(1, Int(newValue))
                }
                .onTapGesture {
                    isWeightFocused = false
                }

                Button {
                    manager.adjustReps(by: 1)
                    crownReps = Double(manager.currentReps)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 前回の記録

    private var previousRecordSection: some View {
        Group {
            if let lastWeight = manager.lastWeight, let lastReps = manager.lastReps {
                Text(WatchL10n.previousRecord(weight: lastWeight, reps: lastReps))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 記録ボタン

    private var recordButton: some View {
        Button {
            manager.recordSet()
            crownWeight = manager.currentWeight
            crownReps = Double(manager.currentReps)
            showRestTimer = true
        } label: {
            Text(WatchL10n.record)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
        }
        .tint(.green)
        .padding(.top, 4)
    }

    // MARK: - アクションボタン

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                Text(WatchL10n.changeExercise)
                    .font(.caption2)
            }
            .font(.caption2)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}

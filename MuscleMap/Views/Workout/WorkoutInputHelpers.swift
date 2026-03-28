import SwiftUI

// MARK: - ワークアウト入力ヘルパーコンポーネント

/// 標準ステッパーボタン（レップ数用）
struct StepperButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
            HapticManager.stepperChanged()
        } label: {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .foregroundStyle(Color.mmAccentPrimary)
                .frame(width: 60, height: 60)
                .background(Color.mmBgSecondary)
                .clipShape(Circle())
        }
    }
}

// MARK: - 重量入力ビュー（タップで直接入力可能）

/// 重量入力ビュー
struct WeightInputView: View {
    @Binding var weight: Double
    let label: String
    var isGhost: Bool = false

    @State private var isEditing = false
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 2) {
            if isEditing {
                TextField("", text: $inputText)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.mmTextPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onSubmit { finishEditing() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { finishEditing() }
                    }
            } else {
                Text("\(weight, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(isGhost ? Color.mmTextSecondary.opacity(0.5) : Color.mmTextPrimary)
                    .onTapGesture {
                        inputText = ""  // 空にしてから編集開始（追記バグ修正）
                        isEditing = true
                        isFocused = true
                        HapticManager.lightTap()
                    }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    private func finishEditing() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty,
           let newWeight = Double(trimmed.replacingOccurrences(of: ",", with: ".")) {
            weight = max(0, newWeight)
        }
        // 空入力の場合は weight をそのまま維持
        isEditing = false
    }
}

// MARK: - 重量用+/-ボタン（長押し加速対応）

/// 重量ステッパーボタン（長押し加速対応）
/// 長押し開始: 2.5kg刻み → 1秒後: 5kg刻みに加速
struct WeightStepperButton: View {
    let systemImage: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    var onAcceleratedPress: (() -> Void)?

    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?
    @State private var longPressStartDate: Date?

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2.bold())
            .foregroundStyle(Color.mmAccentPrimary)
            .frame(width: 60, height: 60)
            .background(Color.mmBgSecondary)
            .clipShape(Circle())
            .scaleEffect(isLongPressing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isLongPressing)
            .onTapGesture {
                onTap()
                HapticManager.stepperChanged()
            }
            .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                isLongPressing = pressing
                if pressing {
                    startLongPressTimer()
                } else {
                    stopLongPressTimer()
                }
            }, perform: {})
            .onDisappear {
                longPressTimer?.invalidate()
                longPressTimer = nil
            }
    }

    private func startLongPressTimer() {
        longPressStartDate = Date()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [onLongPress, onAcceleratedPress] _ in
            Task { @MainActor in
                let elapsed = Date().timeIntervalSince(longPressStartDate ?? Date())
                if elapsed > 1.0, let accelerated = onAcceleratedPress {
                    accelerated()
                } else {
                    onLongPress()
                }
                HapticManager.lightTap()
            }
        }
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressStartDate = nil
    }
}

// MARK: - Preview

#Preview("Stepper Button") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        HStack(spacing: 20) {
            StepperButton(systemImage: "minus") {
                print("Minus tapped")
            }
            StepperButton(systemImage: "plus") {
                print("Plus tapped")
            }
        }
    }
}

#Preview("Weight Input") {
    @Previewable @State var weight = 100.0

    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        WeightInputView(weight: $weight, label: "kg")
    }
}

#Preview("Weight Stepper Button") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        HStack(spacing: 20) {
            WeightStepperButton(systemImage: "minus", onTap: {
                print("Minus tap")
            }, onLongPress: {
                print("Minus long press")
            }, onAcceleratedPress: {
                print("Minus accelerated")
            })
            WeightStepperButton(systemImage: "plus", onTap: {
                print("Plus tap")
            }, onLongPress: {
                print("Plus long press")
            }, onAcceleratedPress: {
                print("Plus accelerated")
            })
        }
    }
}

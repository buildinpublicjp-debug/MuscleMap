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
                    .foregroundStyle(Color.mmTextPrimary)
                    .onTapGesture {
                        inputText = String(format: "%.2f", weight)
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
        if let newWeight = Double(inputText.replacingOccurrences(of: ",", with: ".")) {
            weight = max(0, newWeight)
        }
        isEditing = false
    }
}

// MARK: - 重量用+/-ボタン（長押しで0.25kg刻み）

/// 重量ステッパーボタン（長押し対応）
struct WeightStepperButton: View {
    let systemImage: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?

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
    }

    private func startLongPressTimer() {
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [onLongPress] _ in
            Task { @MainActor in
                onLongPress()
                HapticManager.lightTap()
            }
        }
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
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
            })
            WeightStepperButton(systemImage: "plus", onTap: {
                print("Plus tap")
            }, onLongPress: {
                print("Plus long press")
            })
        }
    }
}

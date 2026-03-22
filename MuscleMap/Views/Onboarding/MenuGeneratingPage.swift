import SwiftUI

// MARK: - メニュー生成中ローディング演出ページ

/// 3〜4秒のフェイクローディング後に自動で次ページへ遷移
struct MenuGeneratingPage: View {
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var currentStep = 0
    @State private var allDone = false

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// ステップ定義（アイコン + テキスト）
    private var steps: [(icon: String, textJA: String, textEN: String)] {
        [
            ("figure.strengthtraining.traditional", "目標と経験を分析中…", "Analyzing goals & experience…"),
            ("dumbbell.fill", "最適な種目を選定中…", "Selecting optimal exercises…"),
            ("calendar", "分割スケジュールを構築中…", "Building your split schedule…"),
            ("checkmark.seal.fill", "あなた専用メニュー完成！", "Your custom menu is ready!"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ヘッダー
            VStack(spacing: 8) {
                // パルスアニメーション付きアイコン
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Text(isJapanese ? "あなた専用メニューを作成中" : "Creating Your Custom Menu")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 40)

            // ステップリスト
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepRow(
                        index: index,
                        icon: step.icon,
                        text: isJapanese ? step.textJA : step.textEN
                    )
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmOnboardingCard)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressFraction, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
        .onAppear {
            startAnimation()
        }
    }

    /// 進捗率（0.0〜1.0）
    private var progressFraction: CGFloat {
        guard !steps.isEmpty else { return 0 }
        if allDone { return 1.0 }
        return CGFloat(currentStep) / CGFloat(steps.count)
    }

    // MARK: - ステップ行

    private func stepRow(index: Int, icon: String, text: String) -> some View {
        let isCompleted = index < currentStep
        let isActive = index == currentStep && !allDone
        let isFuture = index > currentStep && !allDone

        return HStack(spacing: 12) {
            // ステータスアイコン
            ZStack {
                if isCompleted || (allDone && index == steps.count - 1) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .transition(.scale.combined(with: .opacity))
                } else if isActive {
                    // スピナー風パルス
                    Circle()
                        .fill(Color.mmOnboardingAccent.opacity(0.2))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.mmOnboardingAccent, lineWidth: 2)
                                .frame(width: 22, height: 22)
                        )
                        .scaleEffect(isActive ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isActive)
                } else {
                    Circle()
                        .fill(Color.mmOnboardingCard)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 22, height: 22)

            // テキスト
            Text(text)
                .font(.system(size: 15, weight: isActive ? .bold : .medium))
                .foregroundStyle(
                    isFuture
                        ? Color.mmOnboardingTextSub.opacity(0.4)
                        : (isCompleted || allDone)
                            ? Color.mmOnboardingAccent
                            : Color.mmOnboardingTextMain
                )

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: appeared)
    }

    // MARK: - アニメーションシーケンス

    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            appeared = true
        }

        // ステップ0 → 1 → 2 → 3 を順番に進行（各0.8秒間隔）
        for i in 1...steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStep = i
                }
                if i < steps.count {
                    HapticManager.lightTap()
                }
            }
        }

        // 全ステップ完了後、少し待って自動遷移
        let totalDelay = Double(steps.count) * 0.8 + 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            withAnimation(.easeInOut(duration: 0.3)) {
                allDone = true
            }
            HapticManager.mediumTap()
        }

        // 自動遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay + 0.5) {
            onComplete()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        MenuGeneratingPage(onComplete: {})
    }
}

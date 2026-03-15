import SwiftUI

// MARK: - 週間トレーニング頻度

enum WeeklyFrequency: Int, CaseIterable, Codable {
    case twice = 2
    case thrice = 3
    case four = 4
    case fivePlus = 5

    var title: String {
        switch self {
        case .twice: return "週2回"
        case .thrice: return "週3回"
        case .four: return "週4回"
        case .fivePlus: return "週5回以上"
        }
    }

    var subtitle: String {
        switch self {
        case .twice: return "上半身/下半身で効率よく"
        case .thrice: return "プッシュ/プル/脚の王道分割"
        case .four: return "部位別でしっかり追い込む"
        case .fivePlus: return "各部位を個別にフルで"
        }
    }
}

// MARK: - 頻度選択画面

struct FrequencySelectionPage: View {
    let onNext: (WeeklyFrequency) -> Void

    @State private var selected: WeeklyFrequency?
    @State private var appeared = false
    @State private var isProceeding = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text("週にどれくらいやれる？")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text("あなたに合った分割法を提案します")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 32)

            // 選択カード
            VStack(spacing: 12) {
                ForEach(Array(WeeklyFrequency.allCases.enumerated()), id: \.element) { index, frequency in
                    FrequencyCard(
                        frequency: frequency,
                        isSelected: selected == frequency,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selected = frequency
                            }
                            HapticManager.lightTap()
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.3), value: appeared)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding, let freq = selected else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext(freq)
            } label: {
                Text("次へ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selected != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if selected != nil {
                                LinearGradient(
                                    colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.mmOnboardingCard
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selected == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

// MARK: - 頻度カード

private struct FrequencyCard: View {
    let frequency: WeeklyFrequency
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text(frequency.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }

                Spacer()

                // チェックマーク
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.mmOnboardingAccent)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingBg)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Color.mmOnboardingTextSub.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        FrequencySelectionPage(onNext: { _ in })
    }
}

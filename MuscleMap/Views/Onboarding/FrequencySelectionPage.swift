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

    /// スケジュールプレビュー用の曜日割り当て
    var schedulePreview: [(day: String, content: String)] {
        switch self {
        case .twice:
            return [
                ("月", "上半身"), ("火", "OFF"), ("水", "下半身"),
                ("木", "OFF"), ("金", "OFF"), ("土", "OFF"), ("日", "OFF"),
            ]
        case .thrice:
            return [
                ("月", "プッシュ"), ("火", "OFF"), ("水", "プル"),
                ("木", "OFF"), ("金", "脚"), ("土", "OFF"), ("日", "OFF"),
            ]
        case .four:
            return [
                ("月", "胸"), ("火", "背中"), ("水", "OFF"),
                ("木", "肩・腕"), ("金", "脚"), ("土", "OFF"), ("日", "OFF"),
            ]
        case .fivePlus:
            return [
                ("月", "胸"), ("火", "背中"), ("水", "肩"),
                ("木", "腕"), ("金", "脚"), ("土", "OFF"), ("日", "OFF"),
            ]
        }
    }
}

// MARK: - 頻度選択画面（スケジュールプレビュー付き）

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

            // 選択カード（左バー方式）
            VStack(spacing: 10) {
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

            // スケジュールプレビュー（選択時にフェードイン）
            if let freq = selected {
                WeekSchedulePreview(schedule: freq.schedulePreview)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.4), value: selected)
            }

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding, let freq = selected else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext(freq)
            } label: {
                Text(L10n.next)
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

// MARK: - 頻度カード（左バー方式）

private struct FrequencyCard: View {
    let frequency: WeeklyFrequency
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 12)

                HStack(spacing: 12) {
                    // 回数バッジ
                    Text("\(frequency.rawValue)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 36, height: 36)

                    // テキスト
                    VStack(alignment: .leading, spacing: 2) {
                        Text(frequency.title)
                            .font(.system(size: 18, weight: .bold))
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
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 60)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 週間スケジュールプレビュー

private struct WeekSchedulePreview: View {
    let schedule: [(day: String, content: String)]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(schedule.enumerated()), id: \.offset) { _, item in
                let isTraining = item.content != "OFF"
                VStack(spacing: 4) {
                    Text(item.day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextSub)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(isTraining ? Color.mmOnboardingAccent.opacity(0.15) : Color.mmOnboardingCard)
                        .frame(height: 36)
                        .overlay {
                            if isTraining {
                                Text(item.content)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.mmOnboardingAccent)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        FrequencySelectionPage(onNext: { _ in })
    }
}

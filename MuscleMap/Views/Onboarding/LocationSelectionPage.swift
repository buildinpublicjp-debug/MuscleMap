import SwiftUI

// MARK: - トレーニング場所

enum TrainingLocation: String, CaseIterable, Codable {
    case gym
    case home
    case both

    var title: String {
        switch self {
        case .gym: return "ジム"
        case .home: return "自宅"
        case .both: return "両方"
        }
    }

    var emoji: String {
        switch self {
        case .gym: return "🏋️"
        case .home: return "🏠"
        case .both: return "🔄"
        }
    }

    var subtitle: String {
        switch self {
        case .gym: return "マシン・バーベル・ダンベル全部使える"
        case .home: return "自重とダンベルでしっかり鍛える"
        case .both: return "ジムと自宅を組み合わせる"
        }
    }
}

// MARK: - 場所選択画面

struct LocationSelectionPage: View {
    let onNext: (TrainingLocation) -> Void

    @State private var selected: TrainingLocation?
    @State private var appeared = false
    @State private var isProceeding = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text("どこで鍛える？")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text("使える器具に合わせて種目を提案します")
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
                ForEach(Array(TrainingLocation.allCases.enumerated()), id: \.element) { index, location in
                    LocationCard(
                        location: location,
                        isSelected: selected == location,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selected = location
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
                guard !isProceeding, let loc = selected else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext(loc)
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

// MARK: - 場所カード

private struct LocationCard: View {
    let location: TrainingLocation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 絵文字アイコン
                Text(location.emoji)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(Color.mmOnboardingAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Text(location.subtitle)
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
            .frame(height: 80)
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
        LocationSelectionPage(onNext: { _ in })
    }
}

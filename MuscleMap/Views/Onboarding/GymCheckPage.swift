import SwiftUI

// MARK: - 「今ジムにいる？」画面

struct GymCheckPage: View {
    let onNext: () -> Void

    @State private var selectedOption: GymOption?
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    private enum GymOption {
        case atGym
        case atHome
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            // ヘッダー
            VStack(spacing: 12) {
                Text(L10n.gymCheckTitle)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.gymCheckSub)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 48)

            // 2つの大きなカード
            VStack(spacing: 16) {
                // ジムにいる
                GymOptionCard(
                    emoji: "🏋️",
                    title: L10n.gymCheckAtGym,
                    subtitle: L10n.gymCheckAtGymSub,
                    isSelected: selectedOption == .atGym,
                    accentColor: Color.mmOnboardingAccent,
                    onTap: {
                        guard selectedOption == nil else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedOption = .atGym
                        }
                        HapticManager.lightTap()
                        AppState.shared.isAtGym = true

                        // 少し待ってから次ページへ遷移
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onNext()
                        }
                    }
                )

                // 家にいる
                GymOptionCard(
                    emoji: "📱",
                    title: L10n.gymCheckAtHome,
                    subtitle: L10n.gymCheckAtHomeSub,
                    isSelected: selectedOption == .atHome,
                    accentColor: Color(red: 0.4, green: 0.8, blue: 1.0),
                    onTap: {
                        guard selectedOption == nil else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedOption = .atHome
                        }
                        HapticManager.lightTap()
                        AppState.shared.isAtGym = false

                        // 少し待ってから次ページへ遷移
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onNext()
                        }
                    }
                )
            }
            .padding(.horizontal, 24)
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 30)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                cardsAppeared = true
            }
        }
    }
}

// MARK: - ジム選択カード（高さ160pt）

private struct GymOptionCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 48))

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GymCheckPage(onNext: {})
    }
}

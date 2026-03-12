import SwiftUI

// MARK: - 機能紹介画面（CTA）

struct CallToActionPage: View {
    let onComplete: () -> Void

    @State private var buttonGlow = false
    @State private var cardAppearances: [Bool] = [false, false, false]
    @State private var strengthHintVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトル
            Text(L10n.ctaPageTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer().frame(height: 32)

            // 3つの機能カード
            VStack(spacing: 16) {
                FeatureCard(
                    icon: "figure.stand",
                    iconColor: Color.mmOnboardingAccent,
                    title: L10n.ctaFeature1Title,
                    description: L10n.ctaFeature1Desc
                )
                .opacity(cardAppearances[0] ? 1 : 0)
                .offset(y: cardAppearances[0] ? 0 : 20)

                FeatureCard(
                    icon: "list.bullet.clipboard.fill",
                    iconColor: Color(red: 0.4, green: 0.8, blue: 1.0),
                    title: L10n.ctaFeature2Title,
                    description: L10n.ctaFeature2Desc
                )
                .opacity(cardAppearances[1] ? 1 : 0)
                .offset(y: cardAppearances[1] ? 0 : 20)

                FeatureCard(
                    icon: "waveform.path.ecg",
                    iconColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                    title: L10n.ctaFeature3Title,
                    description: L10n.ctaFeature3Desc
                )
                .opacity(cardAppearances[2] ? 1 : 0)
                .offset(y: cardAppearances[2] ? 0 : 20)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            // Strength Map予告ヒント
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingAccent)

                Text(L10n.ctaStrengthMapHint)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mmOnboardingAccent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mmOnboardingAccent.opacity(0.15), lineWidth: 1)
                    )
            )
            .opacity(strengthHintVisible ? 1 : 0)
            .offset(y: strengthHintVisible ? 0 : 10)

            Spacer()

            // CTAボタン（「無料ではじめる」）
            Button {
                HapticManager.lightTap()
                onComplete()
            } label: {
                Text(L10n.ctaGetStartedFree)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: Color.mmOnboardingAccent.opacity(buttonGlow ? 0.35 : 0.15),
                        radius: buttonGlow ? 6 : 2
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            // Pro版ヒントテキスト
            Text(L10n.ctaProHint)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))
                .padding(.top, 10)

            // 利用規約・プライバシーポリシー
            HStack(spacing: 4) {
                if let termsURL = URL(string: LegalURL.termsOfUse) {
                    Link(destination: termsURL) {
                        Text(L10n.termsOfUse)
                            .underline()
                    }
                }
                Text("|")
                if let privacyURL = URL(string: LegalURL.privacyPolicy) {
                    Link(destination: privacyURL) {
                        Text(L10n.privacyPolicy)
                            .underline()
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(Color.mmOnboardingTextSub)
            .padding(.top, 12)
            .padding(.bottom, 48)
        }
        .onAppear {
            // Staggered card animation
            for index in 0..<3 {
                withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.15 + 0.2)) {
                    cardAppearances[index] = true
                }
            }
            // Strength Mapヒント表示
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                strengthHintVisible = true
            }
            // Button glow animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
        }
    }
}

// MARK: - 機能カード

private struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(iconColor)
            }

            // テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        CallToActionPage(onComplete: {})
    }
}

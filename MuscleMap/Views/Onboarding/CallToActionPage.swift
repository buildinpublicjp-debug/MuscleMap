import SwiftUI

// MARK: - Page 4: CTA（はじめる）

struct CallToActionPage: View {
    let onComplete: () -> Void

    @State private var buttonGlow = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 特典リスト（カード形式）
            VStack(spacing: 16) {
                FeatureCard(
                    icon: "figure.stand",
                    title: L10n.onboardingFeature1,
                    subtitle: L10n.onboardingFeature1Sub,
                    delay: 0.1
                )
                FeatureCard(
                    icon: "list.bullet.clipboard",
                    title: L10n.onboardingFeature2,
                    subtitle: L10n.onboardingFeature2Sub,
                    delay: 0.3
                )
                FeatureCard(
                    icon: "waveform.path.ecg",
                    title: L10n.onboardingFeature3,
                    subtitle: L10n.onboardingFeature3Sub,
                    delay: 0.5
                )
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer()

            // CTAボタン
            Button {
                HapticManager.lightTap()
                onComplete()
            } label: {
                Text(L10n.getStarted)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
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
                        color: Color.mmOnboardingAccent.opacity(0.4),
                        radius: buttonGlow ? 15 : 5
                    )
            }
            .padding(.horizontal, 24)

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
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
        }
    }
}

// MARK: - 特典カード

private struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let delay: Double

    @State private var visible = false

    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(Color.mmOnboardingAccent.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color.mmOnboardingAccent)
            }

            // テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -15)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                visible = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        CallToActionPage(onComplete: {})
    }
}

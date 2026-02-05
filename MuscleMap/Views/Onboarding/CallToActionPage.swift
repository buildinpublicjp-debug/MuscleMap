import SwiftUI

// MARK: - Page 4: CTA（はじめる）

struct CallToActionPage: View {
    let onComplete: () -> Void

    @State private var buttonGlow = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 特典リスト
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(text: L10n.onboardingFeature1, delay: 0.1)
                FeatureRow(text: L10n.onboardingFeature2, delay: 0.3)
                FeatureRow(text: L10n.onboardingFeature3, delay: 0.5)
            }
            .padding(.horizontal, 32)
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
                Link(destination: URL(string: LegalURL.termsOfUse)!) {
                    Text(L10n.termsOfUse)
                        .underline()
                }
                Text("|")
                Link(destination: URL(string: LegalURL.privacyPolicy)!) {
                    Text(L10n.privacyPolicy)
                        .underline()
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

// MARK: - 特典行

private struct FeatureRow: View {
    let text: String
    let delay: Double

    @State private var visible = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.mmOnboardingAccent)

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.mmOnboardingTextMain)
        }
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
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

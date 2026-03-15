import SwiftUI

// MARK: - 機能紹介画面（CTA）

struct CallToActionPage: View {
    let onComplete: () -> Void

    @State private var buttonGlow = false
    @State private var valuesAppeared = false
    @State private var headlineAppeared = false

    /// 選んだ目標に合わせたキャッチコピー
    private var goalBasedHeadline: String {
        guard let raw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: raw) else {
            return "あなたの体の変化を記録しよう。"
        }
        switch goal {
        case .getBig:
            return "90日後、鏡の前で笑える。"
        case .martialArts:
            return "パンチ力も、全部フィジカルが土台。"
        case .getAttractive:
            return "変わる旅を始めよう。"
        case .dontGetDisrespected:
            return "存在感は、体が作る。"
        case .sports:
            return "パフォーマンスの土台を作ろう。"
        case .moveWell:
            return "動ける体は、日々の積み重ね。"
        case .health:
            return "健康な体が、全ての基盤。"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            // 目標に合わせたキャッチコピー
            Text(goalBasedHeadline)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(headlineAppeared ? 1 : 0)
                .offset(y: headlineAppeared ? 0 : 20)

            Spacer().frame(height: 12)

            // サブタイトル
            Text(L10n.ctaPageTitle)
                .font(.subheadline)
                .foregroundStyle(Color.mmOnboardingTextSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(headlineAppeared ? 1 : 0)

            Spacer().frame(height: 48)

            // 3つのシンプルな価値（パーソナライズ済み）
            VStack(spacing: 20) {
                ValueRow(emoji: "🗺️", text: "あなたの目標に合った筋肉を優先提案")
                ValueRow(emoji: "📊", text: "種目・重量・セット数まで自動で出る")
                ValueRow(emoji: "🏋️", text: "週\(AppState.shared.userProfile.weeklyFrequency)回に最適化された分割法")
            }
            .padding(.horizontal, 24)
            .opacity(valuesAppeared ? 1 : 0)
            .offset(y: valuesAppeared ? 0 : 20)

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
            withAnimation(.easeOut(duration: 0.5)) {
                headlineAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                valuesAppeared = true
            }
            // Button glow animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
        }
    }
}

// MARK: - 価値行（絵文字 + テキスト）

private struct ValueRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 48)

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.mmOnboardingTextMain)

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

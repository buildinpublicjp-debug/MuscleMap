import SwiftUI
import RevenueCat

// MARK: - ペイウォール画面（プレミアムデザイン）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var heroProgress: CGFloat = 0

    private let purchaseManager = PurchaseManager.shared

    /// デモ用の筋肉状態（ヒーロー領域）
    private var demoStates: [Muscle: MuscleVisualState] {
        [
            .chestUpper: .recovering(progress: 0.2),
            .chestLower: .recovering(progress: 0.15),
            .deltoidAnterior: .recovering(progress: 0.35),
            .deltoidLateral: .recovering(progress: 0.4),
            .biceps: .recovering(progress: 0.5),
            .triceps: .recovering(progress: 0.55),
            .lats: .recovering(progress: 0.65),
            .quadriceps: .recovering(progress: 0.3),
            .rectusAbdominis: .recovering(progress: 0.45),
        ]
    }

    var body: some View {
        ZStack {
            Color.mmOnboardingBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // ヒーロー領域
                    heroSection

                    // ヘッドライン
                    Text(L10n.paywallHeadline)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // 特典リスト
                    featureListSection

                    // プランカード
                    planCardsSection

                    // CTAボタン
                    ctaButton

                    // フッター
                    footerSection
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            // ×ボタン（右上）
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .alert(L10n.purchaseError, isPresented: $showError) {
            Button(L10n.ok) {}
        } message: {
            Text(L10n.purchaseErrorMessage)
        }
        .task {
            await purchaseManager.fetchOfferings()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                heroProgress = 1.0
            }
        }
    }

    // MARK: - ヒーロー領域

    private var heroSection: some View {
        MuscleMapView(muscleStates: demoStates, demoMode: true)
            .frame(height: 200)
            .scaleEffect(1.0 + heroProgress * 0.05)
            .opacity(0.6)
            .blur(radius: 4)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .padding(.horizontal, 16)
    }

    // MARK: - 特典リスト

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PaywallFeatureRow(
                icon: "heart.text.clipboard",
                text: L10n.paywallFeatureRecovery
            )
            PaywallFeatureRow(
                icon: "rectangle.on.rectangle",
                text: L10n.paywallFeatureWidget
            )
            PaywallFeatureRow(
                icon: "clock.arrow.circlepath",
                text: L10n.paywallFeatureHistory
            )
            PaywallFeatureRow(
                icon: "square.and.arrow.up",
                text: L10n.paywallFeatureExport
            )
        }
        .padding(.horizontal, 32)
    }

    // MARK: - プランカード

    private var planCardsSection: some View {
        HStack(spacing: 10) {
            PlanCardView(
                title: L10n.planMonthly,
                price: purchaseManager.monthlyPrice,
                subtitle: nil,
                badge: nil,
                isSelected: selectedPlan == .monthly
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .monthly
                }
            }

            PlanCardView(
                title: L10n.planAnnual,
                price: purchaseManager.annualPrice,
                subtitle: L10n.annualPerMonth,
                badge: L10n.mostPopular,
                isSelected: selectedPlan == .annual
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .annual
                }
            }

            PlanCardView(
                title: L10n.planLifetime,
                price: purchaseManager.lifetimePrice,
                subtitle: L10n.lifetimeLabel,
                badge: nil,
                isSelected: selectedPlan == .lifetime
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .lifetime
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - CTAボタン

    private var ctaButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(L10n.startFreeTrial)
                        .font(.system(size: 18, weight: .bold))
                }
            }
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
        }
        .disabled(isPurchasing)
        .padding(.horizontal, 24)
    }

    // MARK: - フッター

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text(L10n.cancelAnytime)
                .font(.caption)
                .foregroundStyle(Color.mmOnboardingTextSub)

            // App Store必須: 自動更新説明文
            Text(L10n.subscriptionDisclosure)
                .font(.caption2)
                .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await restore() }
            } label: {
                Text(L10n.restorePurchases)
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .underline()
            }

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
            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.6))
        }
    }

    // MARK: - 購入処理

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = await purchaseManager.purchase(plan: selectedPlan)
        switch result {
        case .success:
            HapticManager.setRecorded()
            dismiss()
        case .cancelled:
            // ユーザーがキャンセルした場合はエラーを表示しない
            break
        case .failed:
            showError = true
        }
    }

    private func restore() async {
        isPurchasing = true
        let success = await purchaseManager.restorePurchases()
        isPurchasing = false
        if success {
            dismiss()
        }
    }
}

// MARK: - プランタイプ

enum PlanType {
    case monthly
    case annual
    case lifetime
}

// MARK: - Preview

#Preview {
    PaywallView()
}

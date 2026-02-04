import SwiftUI
import RevenueCat

// MARK: - ペイウォール画面

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanType = .annual
    @State private var isPurchasing = false
    @State private var showError = false

    private let purchaseManager = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        headerSection

                        // 機能比較テーブル
                        featureComparisonSection

                        // プラン選択
                        planSelectionSection

                        // 購入ボタン
                        purchaseButton

                        // リストア + 利用規約
                        footerSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
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
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.mmAccentPrimary)

            Text(L10n.muscleMaplPremium)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)

            Text(L10n.unlockAndOptimize)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    // MARK: - 機能比較テーブル

    private var featureComparisonSection: some View {
        VStack(spacing: 0) {
            // ヘッダー行
            HStack {
                Text(L10n.features)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.free)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(width: 52)
                Text(L10n.premiumLabel)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 72)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.mmBgSecondary)

            // 機能行
            ForEach(FeatureComparison.allFeatures) { feature in
                FeatureComparisonRow(feature: feature)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mmBgSecondary, lineWidth: 1)
        )
    }

    // MARK: - プラン選択

    private var planSelectionSection: some View {
        VStack(spacing: 8) {
            PlanCard(
                plan: .monthly,
                isSelected: selectedPlan == .monthly,
                price: purchaseManager.monthlyPrice,
                period: L10n.monthlyPlan,
                badge: nil,
                subtext: nil
            ) {
                selectedPlan = .monthly
            }

            PlanCard(
                plan: .annual,
                isSelected: selectedPlan == .annual,
                price: purchaseManager.annualPrice,
                period: L10n.annualPlan,
                badge: L10n.recommendedBadge,
                subtext: L10n.perMonthPrice
            ) {
                selectedPlan = .annual
            }

            PlanCard(
                plan: .lifetime,
                isSelected: selectedPlan == .lifetime,
                price: purchaseManager.lifetimePrice,
                period: L10n.lifetimePlan,
                badge: nil,
                subtext: nil
            ) {
                selectedPlan = .lifetime
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedPlan)
    }

    // MARK: - 購入ボタン

    private var purchaseButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(Color.mmBgPrimary)
                } else {
                    Text(purchaseButtonLabel)
                        .font(.headline)
                }
            }
            .foregroundStyle(Color.mmBgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mmAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
    }

    // MARK: - フッター

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await restore()
                }
            } label: {
                Text(L10n.restorePurchases)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            HStack(spacing: 16) {
                Button {
                    // 利用規約（外部リンク）
                } label: {
                    Text(L10n.termsOfService)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
                Button {
                    // プライバシーポリシー（外部リンク）
                } label: {
                    Text(L10n.privacyPolicy)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
            }

            if selectedPlan == .monthly {
                Text(L10n.monthlyTrialNote)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            } else if selectedPlan == .annual {
                Text(L10n.annualTrialNote)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            }
        }
    }

    // MARK: - ボタンラベル

    private var purchaseButtonLabel: String {
        switch selectedPlan {
        case .monthly: return L10n.startMonthlyPlan
        case .annual: return L10n.startAnnualPlan
        case .lifetime: return L10n.purchaseLifetime
        }
    }

    // MARK: - 購入処理

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let success = await purchaseManager.purchase(plan: selectedPlan)
        if success {
            HapticManager.setRecorded()
            dismiss()
        } else {
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

// MARK: - 機能比較データ

private struct FeatureComparison: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let freeAccess: Bool
    let premiumAccess: Bool

    @MainActor static var allFeatures: [FeatureComparison] {
        [
            FeatureComparison(name: L10n.featureMuscleMap2D, icon: "figure.stand", freeAccess: true, premiumAccess: true),
            FeatureComparison(name: L10n.featureWorkoutRecord, icon: "dumbbell", freeAccess: true, premiumAccess: true),
            FeatureComparison(name: L10n.featureRecoveryTracking, icon: "heart.text.clipboard", freeAccess: true, premiumAccess: true),
            FeatureComparison(name: L10n.featureMenuSuggestion, icon: "sparkles", freeAccess: true, premiumAccess: true),
            FeatureComparison(name: L10n.featureDetailedStats, icon: "chart.bar.fill", freeAccess: false, premiumAccess: true),
            FeatureComparison(name: L10n.feature3DView, icon: "cube.fill", freeAccess: false, premiumAccess: true),
            FeatureComparison(name: L10n.featureMenuSuggestionPlus, icon: "wand.and.stars", freeAccess: false, premiumAccess: true),
            FeatureComparison(name: L10n.featureDataExport, icon: "square.and.arrow.up", freeAccess: false, premiumAccess: true),
        ]
    }
}

// MARK: - 機能比較行

private struct FeatureComparisonRow: View {
    let feature: FeatureComparison

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: feature.icon)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(width: 20)
                Text(feature.name)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Free
            Image(systemName: feature.freeAccess ? "checkmark" : "minus")
                .font(.caption.bold())
                .foregroundStyle(feature.freeAccess ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                .frame(width: 52)

            // Premium
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(Color.mmAccentPrimary)
                .frame(width: 72)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.mmBgCard)
    }
}

// MARK: - プランカード

private struct PlanCard: View {
    let plan: PlanType
    let isSelected: Bool
    let price: String
    let period: String
    let badge: String?
    let subtext: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(period)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(Color.mmBgPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.mmAccentPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    if let subtext {
                        Text(subtext)
                            .font(.caption2)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }

                Spacer()

                Text(price)
                    .font(.title3.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.mmAccentPrimary.opacity(0.08) : Color.mmBgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.mmAccentPrimary : Color.mmBgSecondary,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}

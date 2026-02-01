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
                    VStack(spacing: 32) {
                        // ヘッダー
                        headerSection

                        // 機能リスト
                        featuresSection

                        // プラン選択
                        planSelectionSection

                        // 購入ボタン
                        purchaseButton

                        // リストア + 利用規約
                        footerSection
                    }
                    .padding()
                    .padding(.bottom, 32)
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
            .alert("購入エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text("購入を完了できませんでした。しばらく後にお試しください。")
            }
            .task {
                await purchaseManager.fetchOfferings()
            }
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("MuscleMap Premium")
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)

            Text("全機能をアンロックして\nトレーニングを最適化")
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    // MARK: - 機能リスト

    private var featuresSection: some View {
        VStack(spacing: 12) {
            PremiumFeatureRow(icon: "chart.bar.fill", title: "詳細統計", description: "月間トレンド、グループ別分析")
            PremiumFeatureRow(icon: "cube.fill", title: "3D筋肉ビュー", description: "RealityKitで部位を立体表示")
            PremiumFeatureRow(icon: "sparkles", title: "メニュー提案+", description: "高度なメニュー最適化")
            PremiumFeatureRow(icon: "square.and.arrow.up", title: "データエクスポート", description: "CSV形式でバックアップ")
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - プラン選択

    private var planSelectionSection: some View {
        VStack(spacing: 12) {
            PlanCard(
                plan: .monthly,
                isSelected: selectedPlan == .monthly,
                price: monthlyPrice,
                period: "月額",
                badge: nil
            ) {
                selectedPlan = .monthly
            }

            PlanCard(
                plan: .annual,
                isSelected: selectedPlan == .annual,
                price: annualPrice,
                period: "年額",
                badge: "おすすめ"
            ) {
                selectedPlan = .annual
            }

            PlanCard(
                plan: .lifetime,
                isSelected: selectedPlan == .lifetime,
                price: lifetimePrice,
                period: "買い切り",
                badge: nil
            ) {
                selectedPlan = .lifetime
            }
        }
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
        VStack(spacing: 12) {
            Button {
                Task {
                    await restore()
                }
            } label: {
                Text("購入を復元")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            HStack(spacing: 16) {
                Button {
                    // 利用規約（外部リンク）
                } label: {
                    Text("利用規約")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                }
                Button {
                    // プライバシーポリシー（外部リンク）
                } label: {
                    Text("プライバシーポリシー")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                }
            }

            if selectedPlan == .monthly {
                Text("7日間の無料トライアル後、¥980/月で自動更新")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            } else if selectedPlan == .annual {
                Text("14日間の無料トライアル後、¥7,800/年で自動更新")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            }
        }
    }

    // MARK: - 価格表示

    private var monthlyPrice: String {
        if let pkg = purchaseManager.monthlyPackage {
            return pkg.localizedPriceString
        }
        return "¥980"
    }

    private var annualPrice: String {
        if let pkg = purchaseManager.annualPackage {
            return pkg.localizedPriceString
        }
        return "¥7,800"
    }

    private var lifetimePrice: String {
        if let pkg = purchaseManager.lifetimePackage {
            return pkg.localizedPriceString
        }
        return "¥12,000"
    }

    private var purchaseButtonLabel: String {
        switch selectedPlan {
        case .monthly: return "月額プランで始める"
        case .annual: return "年額プランで始める（おすすめ）"
        case .lifetime: return "買い切りプランで購入"
        }
    }

    // MARK: - 購入処理

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let package: Package?
        switch selectedPlan {
        case .monthly: package = purchaseManager.monthlyPackage
        case .annual: package = purchaseManager.annualPackage
        case .lifetime: package = purchaseManager.lifetimePackage
        }

        guard let package else {
            showError = true
            return
        }

        let success = await purchaseManager.purchase(package)
        if success {
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

// MARK: - 機能行

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.mmAccentPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.mmAccentPrimary)
        }
    }
}

// MARK: - プランカード

private struct PlanCard: View {
    let plan: PlanType
    let isSelected: Bool
    let price: String
    let period: String
    let badge: String?
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

                    if plan == .annual {
                        Text("月あたり ¥650")
                            .font(.caption2)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }

                Spacer()

                Text(price)
                    .font(.title3.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mmBgCard)
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

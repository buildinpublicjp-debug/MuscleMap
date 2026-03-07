import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // ヒーローセクション
                        heroSection

                        // 機能説明
                        featureSection

                        // プラン選択
                        planSection

                        // 復元ボタン
                        restoreButton
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("MuscleMap Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MuscleMap Pro")
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - ヒーローセクション

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.mmAccentPrimary)

            Text("Strength Mapで\n筋力を可視化")
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text("PRデータから各筋肉の発達レベルを算出し、\nリアルタイムにマップ上に表示します")
                .font(.body)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - 機能リスト

    private var featureSection: some View {
        VStack(spacing: 16) {
            featureRow(
                icon: "figure.strengthtraining.traditional",
                title: "筋力マップ",
                description: "体重比スコアで筋肉の発達度を可視化"
            )
            featureRow(
                icon: "chart.bar.fill",
                title: "発達レベル分析",
                description: "21筋肉それぞれの強さをスコア化"
            )
            featureRow(
                icon: "arrow.up.right",
                title: "成長の記録",
                description: "トレーニングの成果がマップに反映される"
            )
        }
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.mmAccentPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - プラン選択

    private var planSection: some View {
        VStack(spacing: 16) {
            // 年額プラン（推奨）
            planButton(
                title: "年額プラン",
                price: "¥4,900 / 年",
                note: "月あたり約¥408",
                isRecommended: true,
                productId: "yearly"
            )

            // 月額プラン
            planButton(
                title: "月額プラン",
                price: "¥590 / 月",
                note: nil,
                isRecommended: false,
                productId: "monthly"
            )
        }
        .padding(.horizontal, 24)
    }

    private func planButton(title: String, price: String, note: String?, isRecommended: Bool, productId: String) -> some View {
        Button {
            // TODO: RevenueCat購入処理
            // Task { await PurchaseManager.shared.purchase(productId: productId) }
            HapticManager.lightTap()
        } label: {
            VStack(spacing: 8) {
                if isRecommended {
                    Text("おすすめ")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.mmBgPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.mmAccentPrimary)
                        .clipShape(Capsule())
                }

                Text(title)
                    .font(.body.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text(price)
                    .font(.title3.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isRecommended ? Color.mmAccentPrimary : Color.mmBorder,
                        lineWidth: isRecommended ? 2 : 1
                    )
            )
        }
    }

    // MARK: - 復元ボタン

    private var restoreButton: some View {
        Button {
            // TODO: RevenueCat復元処理
            // Task { await PurchaseManager.shared.restore() }
            HapticManager.lightTap()
        } label: {
            Text("購入を復元")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.bottom, 16)
    }
}

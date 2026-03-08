import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

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

            Text("90日後、\nあなたの変化が証明される")
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text("筋力の成長を記録し続け、\n90日後に数字とマップで変化を証明しよう")
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
                icon: "bolt.shield.fill",
                title: "Strength Map",
                description: "体が変わっていくのが目で見える"
            )
            featureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "全期間グラフ",
                description: "どこが強くなったか数値で証明できる"
            )
            featureRow(
                icon: "video.fill",
                title: "90日 Recap（近日公開）",
                description: "変化の記録を動画で残してシェアできる"
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
            HapticManager.lightTap()
            Task {
                isPurchasing = true
                try? await PurchaseManager.shared.purchase(productId: productId)
                isPurchasing = false
            }
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

                if PurchaseManager.shared.isLoading {
                    ProgressView()
                } else {
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
        .disabled(isPurchasing)
    }

    // MARK: - 復元ボタン

    private var restoreButton: some View {
        Button {
            HapticManager.lightTap()
            Task { try? await PurchaseManager.shared.restore() }
        } label: {
            Text("購入を復元")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.bottom, 16)
    }
}

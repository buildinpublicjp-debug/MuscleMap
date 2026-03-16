import SwiftUI

// MARK: - Paywall View（Pro版購入モーダル）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        heroSection
                        featureSection
                        planSection
                        restoreButton
                        legalText
                    }
                    .padding(.vertical)
                }

                // 購入中オーバーレイ
                if PurchaseManager.shared.isLoading {
                    ZStack {
                        Color.mmBgPrimary.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(Color.mmAccentPrimary)
                            Text("処理中...")
                                .font(.subheadline)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .padding(32)
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
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
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .disabled(PurchaseManager.shared.isLoading)
                }
            }
            .alert("購入エラー", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました。")
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
        VStack(spacing: 12) {
            featureRow(
                icon: "figure.strengthtraining.traditional",
                color: Color.mmAccentPrimary,
                title: "筋力マップ",
                description: "体が変わっていくのが目で見える"
            )
            featureRow(
                icon: "chart.xyaxis.line",
                color: Color(red: 0.2, green: 0.8, blue: 0.5),
                title: "種目別推移グラフ（全期間）",
                description: "どこが強くなったか数値で証明できる"
            )
            // 90日チャレンジ — 開発中（グレーアウト + 時計アイコン）
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("90日チャレンジ — 開発中")
                        .font(.body.bold())
                        .foregroundStyle(Color.mmTextSecondary)
                    Text("変化を記録してRecapを生成")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                }

                Spacer()

                Image(systemName: "clock")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            }
            .padding(16)
            .background(Color.mmBgCard.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
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

            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(Color.mmAccentPrimary)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - プラン選択

    private var planSection: some View {
        VStack(spacing: 12) {
            planButton(
                title: "年額プラン",
                price: "¥4,900 / 年",
                note: "月あたり約¥408（年額一括払い）",
                isRecommended: true,
                productId: "yearly"
            )
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

    private func planButton(
        title: String,
        price: String,
        note: String?,
        isRecommended: Bool,
        productId: String
    ) -> some View {
        Button {
            HapticManager.lightTap()
            Task {
                do {
                    let purchased = try await PurchaseManager.shared.purchase(productId: productId)
                    if purchased {
                        dismiss()
                    }
                    // purchased == false はユーザーが自分でキャンセル → 何もしない
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                    HapticManager.error()
                }
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
        .disabled(PurchaseManager.shared.isLoading)
    }

    // MARK: - 購入復元

    private var restoreButton: some View {
        Button {
            HapticManager.lightTap()
            Task {
                do {
                    let restored = try await PurchaseManager.shared.restore()
                    if restored {
                        dismiss()
                    } else {
                        errorMessage = "復元できる購入履歴が見つかりませんでした。"
                        showingError = true
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        } label: {
            Text("購入を復元")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .disabled(PurchaseManager.shared.isLoading)
    }

    // MARK: - 法的表記

    private var legalText: some View {
        Text("購入によりApple IDに請求されます。定期購読は期限切れの24時間以内に自動更新されます。iTunesアカウント設定から自動更新をオフにすることができます。")
            .font(.caption2)
            .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
    }
}

#Preview {
    PaywallView()
}

import SwiftUI

// MARK: - 90日チャレンジバナー

/// 3つの状態を自動切替:
/// A: 未開始 → チャレンジ訴求（非ProはPaywall、ProはchallengeStartDate設定）
/// B: 進行中 → Day数 + プログレスバー
/// C: 完了 → 達成メッセージ
struct ChallengeProgressBanner: View {
    @State private var appState = AppState.shared
    @Binding var showingPaywall: Bool

    /// チャレンジ進捗率（0.0〜1.0）
    private var progress: Double {
        guard appState.challengeActive else { return appState.challengeCompleted ? 1.0 : 0.0 }
        return Double(appState.challengeDay) / 90.0
    }

    var body: some View {
        Group {
            if appState.challengeCompleted {
                // 状態C: 完了
                completedBanner
            } else if appState.challengeActive {
                // 状態B: 進行中
                activeBanner
            } else {
                // 状態A: 未開始
                notStartedBanner
            }
        }
    }

    // MARK: - 状態A: 未開始

    private var notStartedBanner: some View {
        Button {
            HapticManager.lightTap()
            if PurchaseManager.shared.isPremium {
                // Pro: チャレンジ開始
                appState.challengeStartDate = Date()
            } else {
                // 非Pro: Paywall表示
                showingPaywall = true
            }
        } label: {
            HStack(spacing: 12) {
                Text("🔥")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.challenge90Title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.challenge90Subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(L10n.start)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmBgPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mmAccentPrimary)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 状態B: 進行中

    private var activeBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🔥")
                    .font(.subheadline)

                Text(L10n.challengeDayN(appState.challengeDay))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text("/ 90")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.mmBgSecondary)
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.mmAccentPrimary)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 状態C: 完了

    private var completedBanner: some View {
        HStack(spacing: 12) {
            Text("🎉")
                .font(.title3)

            Text(L10n.challengeComplete)
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmAccentPrimary)

            Spacer()

            // Recap機能は別フェーズ — タップ無効
            Text(L10n.challengeViewRecap)
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.mmBgSecondary)
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ワークアウト完了画面用 Day完了バナー

/// チャレンジ進行中の場合のみ表示
struct ChallengeDayCompleteBanner: View {
    @State private var appState = AppState.shared

    private var progress: Double {
        Double(appState.challengeDay) / 90.0
    }

    private var daysLeft: Int {
        max(90 - appState.challengeDay, 0)
    }

    var body: some View {
        if appState.challengeActive {
            VStack(spacing: 8) {
                HStack {
                    Text("✅")
                        .font(.subheadline)

                    Text(L10n.challengeDayN(appState.challengeDay))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)

                    Text(L10n.challengeDayComplete)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmAccentPrimary)

                    Spacer()

                    Text(L10n.challengeDaysLeft(daysLeft))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                // プログレスバー
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mmBgSecondary)
                            .frame(height: 8)

                        Capsule()
                            .fill(Color.mmAccentPrimary)
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 8)

                // パーセント表示
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

import SwiftUI

// MARK: - オンボーディング画面

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.stand",
            iconColors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
            title: "筋肉の状態が見える",
            subtitle: "21の筋肉の回復状態を\nリアルタイムで可視化",
            detail: "トレーニング後の筋肉は色で回復度を表示。\n赤→緑へのグラデーションで一目瞭然。"
        ),
        OnboardingPage(
            icon: "sparkles",
            iconColors: [Color.mmMuscleAmber, Color.mmMuscleCoral],
            title: "迷わないメニュー提案",
            subtitle: "回復データから\n今日のベストメニューを自動提案",
            detail: "ジムで開いた瞬間にスタートできる。\n未刺激の部位も見逃しません。"
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColors: [Color.mmAccentSecondary, Color.mmAccentPrimary],
            title: "成長を記録・分析",
            subtitle: "80種目のEMGベース刺激マッピングで\n科学的なトレーニング管理",
            detail: "セット数・ボリューム・部位カバー率を\nチャートで確認。"
        ),
    ]

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // ページインジケーター
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // ボタン
                Button {
                    HapticManager.lightTap()
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "次へ" : "始める")
                        .font(.headline)
                        .foregroundStyle(Color.mmBgPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mmAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)

                // スキップ
                if currentPage < pages.count - 1 {
                    Button {
                        onComplete()
                    } label: {
                        Text("スキップ")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.top, 12)
                }

                Spacer().frame(height: 32)
            }
        }
    }
}

// MARK: - ページデータ

private struct OnboardingPage {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let detail: String
}

// MARK: - ページビュー

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.15)
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // タイトル
            Text(page.title)
                .font(.title.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            // サブタイトル
            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(Color.mmAccentPrimary)
                .multilineTextAlignment(.center)

            // 詳細
            Text(page.detail)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

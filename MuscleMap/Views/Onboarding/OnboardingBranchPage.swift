import SwiftUI

// MARK: - オンボーディング分岐ページ（ジム/家で内容が変わる）

struct OnboardingBranchPage: View {
    let onNext: () -> Void

    @State private var appeared = false

    /// ジムにいるかどうかで表示を分岐
    private var isAtGym: Bool {
        AppState.shared.isAtGym
    }

    var body: some View {
        if isAtGym {
            // ジム: ガイド付きワークアウト案内
            gymBody
        } else {
            // 家: 直近トレーニング入力（筋肉マップ）
            RecentTrainingInputPage(onNext: onNext)
        }
    }

    private var gymBody: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            gymContent

            Spacer()

            // 次へボタン
            Button {
                HapticManager.lightTap()
                // ジムルート: 実画面チュートリアルフラグをセット
                AppState.shared.showWorkoutTutorial = true
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.mmOnboardingAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - ジムにいる場合: ガイド付きワークアウト案内

    private var gymContent: some View {
        VStack(spacing: 24) {
            // アイコン
            ZStack {
                Circle()
                    .fill(Color.mmOnboardingAccent.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.mmOnboardingAccent)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)

            VStack(spacing: 12) {
                Text(L10n.branchGymTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.branchGymSub)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            // ガイドステップ
            VStack(spacing: 12) {
                GuidedStepRow(number: 1, text: L10n.branchGymStep1)
                GuidedStepRow(number: 2, text: L10n.branchGymStep2)
                GuidedStepRow(number: 3, text: L10n.branchGymStep3)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
    }
}

// MARK: - ガイドステップ行

private struct GuidedStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.mmOnboardingAccent)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
            }

            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(Color.mmOnboardingTextMain)

            Spacer()
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("At Gym") {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        OnboardingBranchPage(onNext: {})
            .onAppear { AppState.shared.isAtGym = true }
    }
}

#Preview("At Home") {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        OnboardingBranchPage(onNext: {})
            .onAppear { AppState.shared.isAtGym = false }
    }
}

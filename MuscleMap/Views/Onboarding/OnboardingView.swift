import SwiftUI

// MARK: - オンボーディング画面（超シンプル2画面）

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            if currentPage == 0 {
                // 画面1: 言語選択
                LanguageSelectionPage {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage = 1
                    }
                }
            } else {
                // 画面2: 一言紹介
                IntroPage(onComplete: onComplete)
            }

            // ページインジケーター
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentPage == 0 ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(currentPage == 1 ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - 画面1: 言語選択

private struct LanguageSelectionPage: View {
    let onLanguageSelected: () -> Void
    @State private var localization = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // アプリアイコン
            ZStack {
                Circle()
                    .fill(Color.mmAccentPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "figure.stand")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            // タイトル
            Text("MuscleMap")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.mmTextPrimary)

            Spacer()

            // 言語選択ボタン
            VStack(spacing: 12) {
                Button {
                    localization.currentLanguage = .japanese
                    HapticManager.lightTap()
                    onLanguageSelected()
                } label: {
                    Text(L10n.languageJapanese)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 1)
                        )
                }

                Button {
                    localization.currentLanguage = .english
                    HapticManager.lightTap()
                    onLanguageSelected()
                } label: {
                    Text(L10n.languageEnglish)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - 画面2: 一言紹介

private struct IntroPage: View {
    let onComplete: () -> Void

    /// デモ用の筋肉状態（胸と肩が光っている）
    private var demoMuscleStates: [Muscle: MuscleVisualState] {
        [
            .chestUpper: .recovering(progress: 0.3),
            .chestLower: .recovering(progress: 0.2),
            .deltoidAnterior: .recovering(progress: 0.4),
            .deltoidLateral: .recovering(progress: 0.5),
            .triceps: .recovering(progress: 0.6)
        ]
    }

    var body: some View {
        VStack(spacing: 24) {
            // スキップボタン
            HStack {
                Spacer()
                Button {
                    onComplete()
                } label: {
                    Text(L10n.skip)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()

            // 筋肉マップ（デモアニメーション付き）
            MuscleMapView(muscleStates: demoMuscleStates, demoMode: true)
                .frame(height: UIScreen.main.bounds.height * 0.45)
                .padding(.horizontal, 24)

            // キャッチコピー
            VStack(spacing: 12) {
                Text(L10n.onboardingTagline1)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Text(L10n.onboardingTagline2)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Spacer()

            // はじめるボタン
            Button {
                HapticManager.lightTap()
                onComplete()
            } label: {
                Text(L10n.getStarted)
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

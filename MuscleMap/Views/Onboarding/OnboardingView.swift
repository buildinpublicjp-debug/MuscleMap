import SwiftUI

// MARK: - オンボーディング画面（言語選択 → V2フロー）

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var languageSelected = false

    var body: some View {
        ZStack {
            if !languageSelected {
                // 画面1: 言語選択
                ZStack {
                    Color.mmBgPrimary.ignoresSafeArea()
                    LanguageSelectionPage {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            languageSelected = true
                        }
                    }
                }
                .transition(.opacity)
            } else {
                // V2オンボーディングフロー（4ページ）
                OnboardingV2View(onComplete: onComplete)
                    .transition(.opacity)
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

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

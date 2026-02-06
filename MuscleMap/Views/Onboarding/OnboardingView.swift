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
    private var localization: LocalizationManager { LocalizationManager.shared }
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // アプリアイコン
            ZStack {
                Circle()
                    .fill(Color.mmAccentPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                if isLoading {
                    ProgressView()
                        .tint(Color.mmAccentPrimary)
                        .scaleEffect(1.5)
                } else {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }

            // タイトル
            Text("MuscleMap")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.mmTextPrimary)

            Spacer()

            // 言語選択ボタン
            VStack(spacing: 12) {
                Button {
                    selectLanguage(.japanese)
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
                .disabled(isLoading)

                Button {
                    selectLanguage(.english)
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
                .disabled(isLoading)
            }
            .padding(.horizontal, 32)
            .opacity(isLoading ? 0.5 : 1.0)

            Spacer()
        }
    }

    private func selectLanguage(_ language: AppLanguage) {
        guard !isLoading else { return }
        isLoading = true
        HapticManager.lightTap()

        // 言語設定を非同期で実行し、UIをブロックしない
        Task { @MainActor in
            #if DEBUG
            let start = Date()
            #endif

            localization.currentLanguage = language

            #if DEBUG
            let elapsed = Date().timeIntervalSince(start)
            print("[LanguageSelection] Language set in \(String(format: "%.3f", elapsed))s")
            #endif

            // 次のランループでコールバックを実行（UIの更新を完了させる）
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            onLanguageSelected()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

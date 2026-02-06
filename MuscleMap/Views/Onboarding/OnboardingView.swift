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
    @State private var glowAnimation = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // プレミアムアイコン（グラデーション＋グロー）
            ZStack {
                // 外側のグロー
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.mmAccentPrimary.opacity(0.3),
                                Color.mmAccentPrimary.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(glowAnimation ? 1.1 : 1.0)
                    .opacity(glowAnimation ? 0.8 : 0.5)

                // 内側の円
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.mmAccentPrimary.opacity(0.2),
                                Color.mmAccentSecondary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)

                // アイコン
                if isLoading {
                    ProgressView()
                        .tint(Color.mmAccentPrimary)
                        .scaleEffect(1.5)
                } else {
                    // 筋肉アイコン群
                    ZStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 45, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }

            // タイトル
            VStack(spacing: 8) {
                Text("MuscleMap")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Text(L10n.onboardingTagline1)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()

            // 言語選択ボタン
            VStack(spacing: 12) {
                LanguageButton(
                    title: L10n.languageJapanese,
                    flag: "🇯🇵",
                    isLoading: isLoading
                ) {
                    selectLanguage(.japanese)
                }

                LanguageButton(
                    title: L10n.languageEnglish,
                    flag: "🇺🇸",
                    isLoading: isLoading
                ) {
                    selectLanguage(.english)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
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

// MARK: - 言語選択ボタン

private struct LanguageButton: View {
    let title: String
    let flag: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(flag)
                    .font(.title2)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mmAccentPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}

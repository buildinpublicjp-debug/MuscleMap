import SwiftUI

// MARK: - 設定画面

struct SettingsView: View {
    @State private var appState = AppState.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var localization = LocalizationManager.shared
    @State private var showingPaywall = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showingSafari = false
    @State private var safariURL: URL?
    @AppStorage("youtubeSearchLanguage") private var youtubeSearchLanguage: String = "auto"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                List {
                    // 1. MuscleMap Pro
                    premiumSection

                    // 2. 一般
                    generalSection

                    // 3. 法的事項
                    legalSection

                    // 4. アプリについて
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .alert(L10n.restoreResult, isPresented: $showingRestoreAlert) {
                Button(L10n.ok) {}
            } message: {
                Text(restoreMessage)
            }
        }
    }

    // MARK: - 1. MuscleMap Pro

    private var premiumSection: some View {
        Section {
            if purchaseManager.isProUser {
                // Pro加入済み
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.proActive)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(L10n.premiumUnlocked)
                            .font(.caption)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)

                // サブスク管理リンク
                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gear")
                            .foregroundStyle(Color.mmTextSecondary)
                        Text(L10n.manageSubscription)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            } else {
                // Pro未加入
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown")
                            .foregroundStyle(Color.mmAccentPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.proUpgrade)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                            Text(L10n.unlockAllFeatures)
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .listRowBackground(Color.mmBgCard)

                Button {
                    Task {
                        let success = await purchaseManager.restorePurchases()
                        restoreMessage = success ? L10n.purchaseRestored : L10n.noPurchaseFound
                        showingRestoreAlert = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.mmTextSecondary)
                        Text(L10n.restorePurchases)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text("MuscleMap Pro")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 2. 一般

    private var generalSection: some View {
        Section {
            // 言語設定
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .foregroundStyle(Color.mmAccentPrimary)
                Text(L10n.language)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Picker("", selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)

            // 重量単位設定
            HStack(spacing: 12) {
                Image(systemName: "scalemass")
                    .foregroundStyle(Color.mmAccentSecondary)
                Text(L10n.weightUnit)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Picker("", selection: $appState.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)

            // YouTube検索言語設定
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.red)
                Text(L10n.searchLanguage)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Picker("", selection: $youtubeSearchLanguage) {
                    ForEach(YouTubeSearchLanguage.allCases, id: \.rawValue) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text(L10n.appSettings)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 3. 法的事項

    private var legalSection: some View {
        Section {
            Button {
                safariURL = URL(string: LegalURL.privacyPolicy)
                showingSafari = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(L10n.privacyPolicy)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .listRowBackground(Color.mmBgCard)

            Button {
                safariURL = URL(string: LegalURL.termsOfUse)
                showingSafari = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(L10n.termsOfUse)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text(L10n.termsOfService)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 4. アプリについて

    private var aboutSection: some View {
        Section {
            // バージョン
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.mmTextSecondary)
                Text(L10n.version)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(appState.appVersion) (\(appState.buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)

            // フィードバック
            Button {
                if let url = URL(string: "https://github.com/buildinpublicjp-debug/MuscleMap/issues") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(L10n.feedback)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text(L10n.appInfo)
                .foregroundStyle(Color.mmTextSecondary)
        } footer: {
            Text(L10n.tagline)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }
}

// MARK: - Bindable for AppState (non-@Observable stored properties)

@MainActor
private struct Bindable {
    let appState: AppState

    init(_ appState: AppState) {
        self.appState = appState
    }

    var isHapticEnabled: Binding<Bool> {
        Binding(
            get: { appState.isHapticEnabled },
            set: { appState.isHapticEnabled = $0 }
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

import SwiftUI

// MARK: - 設定画面

struct SettingsView: View {
    @State private var appState = AppState.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var localization = LocalizationManager.shared
    @State private var showingPaywall = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    @AppStorage("youtubeSearchLanguage") private var youtubeSearchLanguage: String = "auto"
    @State private var claudeAPIKey: String = ""
    @State private var showingAPIKey = false

    /// Claude APIキーのKeychain連携Binding
    private var claudeAPIKeyBinding: Binding<String> {
        Binding(
            get: { claudeAPIKey },
            set: { newValue in
                claudeAPIKey = newValue
                if newValue.isEmpty {
                    KeyManager.deleteKey(.claudeAPI)
                } else {
                    KeyManager.saveKey(newValue, for: .claudeAPI)
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                List {
                    // プレミアムセクション
                    premiumSection

                    // アプリ設定
                    appSettingsSection

                    // データ管理
                    dataSection

                    // アプリ情報
                    appInfoSection
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
            .alert(L10n.restoreResult, isPresented: $showingRestoreAlert) {
                Button(L10n.ok) {}
            } message: {
                Text(restoreMessage)
            }
            .onAppear {
                // KeychainからClaude APIキーを読み込み
                claudeAPIKey = KeyManager.getKey(.claudeAPI) ?? ""
            }
        }
    }

    // MARK: - プレミアム

    private var premiumSection: some View {
        Section {
            if purchaseManager.canAccessPremiumFeatures {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.premium)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(L10n.premiumUnlocked)
                            .font(.caption)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown")
                            .foregroundStyle(Color.mmAccentPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.upgradeToPremium)
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
            Text(L10n.premium)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - アプリ設定

    private var appSettingsSection: some View {
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

            Toggle(isOn: Bindable(appState).isHapticEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(L10n.hapticFeedback)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .tint(Color.mmAccentPrimary)
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

            // Claude API Key
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "brain")
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text(L10n.claudeAPIKey)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Button {
                        showingAPIKey.toggle()
                    } label: {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                HStack {
                    if showingAPIKey {
                        TextField(L10n.enterAPIKey, text: claudeAPIKeyBinding)
                            .font(.caption)
                            .foregroundStyle(Color.mmTextPrimary)
                            .autocapitalization(.none)
                            .textContentType(.password)
                    } else {
                        SecureField(L10n.enterAPIKey, text: claudeAPIKeyBinding)
                            .font(.caption)
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                }
                .padding(8)
                .background(Color.mmBgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if claudeAPIKey.isEmpty {
                    Text(L10n.apiKeyHint)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(L10n.aiRecognition)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                    .font(.caption2)
                }
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text(L10n.appSettings)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - データ管理

    private var dataSection: some View {
        Section {
            // Obsidian連携
            NavigationLink {
                ObsidianSettingsView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "link")
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.obsidianSync)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                        if ObsidianSyncManager.shared.isConnected {
                            Text(L10n.connected)
                                .font(.caption)
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                }
            }
            .listRowBackground(Color.mmBgCard)

            // CSVインポート
            NavigationLink {
                CSVImportView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(L10n.csvImport)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .listRowBackground(Color.mmBgCard)

            // 画像から取り込み
            NavigationLink {
                ImageImportView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(L10n.imageImport)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .listRowBackground(Color.mmBgCard)

            // データエクスポート（将来実装）
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                Text(L10n.dataExport)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                Spacer()
                Text(L10n.comingSoon)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            }
            .listRowBackground(Color.mmBgCard)

            // エクササイズ情報
            HStack(spacing: 12) {
                Image(systemName: "dumbbell")
                    .foregroundStyle(Color.mmTextSecondary)
                Text(L10n.registeredExercises)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text(L10n.exerciseCount(ExerciseStore.shared.exercises.count))
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)

            // 筋肉数
            HStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .foregroundStyle(Color.mmTextSecondary)
                Text(L10n.trackedMuscles)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text(L10n.muscleCount(Muscle.allCases.count))
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text(L10n.data)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - アプリ情報

    private var appInfoSection: some View {
        Section {
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

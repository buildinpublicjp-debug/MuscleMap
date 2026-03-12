import SwiftUI

// MARK: - 設定画面

struct SettingsView: View {
    @State private var appState = AppState.shared
    @State private var localization = LocalizationManager.shared
    @State private var themeManager = ThemeManager.shared
    @State private var showingSafari = false
    @State private var safariURL: URL?
    @State private var showingPaywall = false
    @State private var showingProfileEdit = false
    #if DEBUG
    @State private var showingResetAlert = false
    #endif
    @AppStorage("youtubeSearchLanguage") private var youtubeSearchLanguage: String = "auto"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                List {
                    // 0. アカウント・Pro
                    accountProSection

                    // 1. 一般
                    generalSection

                    // 2. 法的事項
                    legalSection

                    // 3. アプリについて
                    aboutSection

                    #if DEBUG
                    // 4. 開発者メニュー
                    developerSection
                    #endif
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditSheet()
            }
            #if DEBUG
            .alert("オンボーディングをリセットしました", isPresented: $showingResetAlert) {
                Button("OK") {}
            } message: {
                Text("アプリを再起動すると、オンボーディングが再表示されます。")
            }
            #endif
        }
    }

    // MARK: - 0. アカウント・Pro

    private var accountProSection: some View {
        Section {
            // プロフィール編集
            Button {
                showingProfileEdit = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle")
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text("プロフィール編集")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(String(format: "%.1fkg", appState.userProfile.weightKg))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .listRowBackground(Color.mmBgCard)

            // Pro導線
            if PurchaseManager.shared.isPremium {
                // Proメンバー表示 → サブスク管理
                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text("MuscleMap Pro")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Spacer()
                        Text("Pro ✓")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            } else {
                // 非Pro: アップグレード誘導
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundStyle(Color.mmAccentPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MuscleMap Pro — アップグレード")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text("90日後、あなたの変化が証明される")
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text("アカウント")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 1. 一般

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

            // テーマ設定
            HStack(spacing: 12) {
                Image(systemName: "paintbrush")
                    .foregroundStyle(Color.mmBrandPurple)
                Text(L10n.theme)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Picker("", selection: $themeManager.currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)

            // レストタイマー設定
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .foregroundStyle(Color.mmAccentSecondary)
                Text(L10n.restTimerDuration)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Picker("", selection: $appState.defaultRestTimerDuration) {
                    Text("30\(L10n.seconds)").tag(30)
                    Text("60\(L10n.seconds)").tag(60)
                    Text("90\(L10n.seconds)").tag(90)
                    Text("120\(L10n.seconds)").tag(120)
                    Text("180\(L10n.seconds)").tag(180)
                    Text("300\(L10n.seconds)").tag(300)
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

    // MARK: - 2. 法的事項

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

    // MARK: - 3. アプリについて

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
    // MARK: - 4. 開発者メニュー（DEBUG）

    #if DEBUG
    private var developerSection: some View {
        Section {
            Button(role: .destructive) {
                appState.hasCompletedOnboarding = false
                appState.hasSeenDemoAnimation = false
                appState.hasSeenHomeCoachMark = false
                appState.hasCompletedFirstWorkout = false
                showingResetAlert = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.red)
                    Text("オンボーディングをリセット")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("開発者メニュー")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }
    #endif
}

// MARK: - プロフィール編集シート

struct ProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String = ""
    @State private var weightText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                Form {
                    Section {
                        // ニックネーム
                        HStack {
                            Text("ニックネーム")
                                .foregroundStyle(Color.mmTextPrimary)
                            Spacer()
                            TextField("名前", text: $nickname)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.mmTextPrimary)
                        }
                        .listRowBackground(Color.mmBgCard)

                        // 体重
                        HStack {
                            Text("体重")
                                .foregroundStyle(Color.mmTextPrimary)
                            Spacer()
                            TextField("70", text: $weightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.mmTextPrimary)
                                .frame(width: 64)
                            Text("kg")
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .listRowBackground(Color.mmBgCard)
                    } header: {
                        Text("基本情報")
                            .foregroundStyle(Color.mmTextSecondary)
                    } footer: {
                        Text("体重はStrength Mapのスコア計算に使用されます")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.mmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        var profile = AppState.shared.userProfile
                        if !nickname.isEmpty {
                            profile.nickname = nickname
                        }
                        if let weight = Double(weightText), weight > 0 {
                            profile.weightKg = weight
                        }
                        AppState.shared.userProfile = profile
                        HapticManager.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                nickname = AppState.shared.userProfile.nickname
                weightText = String(format: "%.1f", AppState.shared.userProfile.weightKg)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

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
    @State private var showingActivityFeed = false
    @State private var showingExerciseLibrary = false
    #if DEBUG
    @State private var showingResetAlert = false
    #endif
    @AppStorage("youtubeSearchLanguage") private var youtubeSearchLanguage: String = "auto"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                List {
                    // 0. Pro版アップグレード（非Pro時のみ目立つバナー）
                    if !PurchaseManager.shared.isPremium {
                        proUpgradeBanner
                    }

                    // 1. アカウント・Pro
                    accountProSection

                    // 2. 一般
                    generalSection

                    // 3. 法的事項
                    legalSection

                    // 4. アプリについて
                    aboutSection

                    #if DEBUG
                    // 5. 開発者メニュー
                    developerSection
                    #endif

                    // バージョン番号（最下部）
                    versionFooter
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
            .sheet(isPresented: $showingExerciseLibrary) {
                NavigationStack {
                    ExerciseLibraryView()
                }
            }
            .sheet(isPresented: $showingActivityFeed) {
                NavigationStack {
                    ActivityFeedView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingActivityFeed = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.mmTextSecondary)
                                }
                            }
                        }
                }
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
                    Text(L10n.profileEdit)
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
                            Text(L10n.proUpgradeCellTitle)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text(L10n.proUpgradeCellSubtitle)
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
            Text(L10n.account)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 1. 一般

    private var generalSection: some View {
        Section {
            // マイルーティン（ルーティン設定済みの場合のみ表示）
            if RoutineManager.shared.hasRoutine {
                NavigationLink {
                    RoutineEditView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(L10n.myRoutine)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            }

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
                    .foregroundStyle(Color.mmDestructive)
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
            // 種目辞典
            Button {
                showingExerciseLibrary = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "book")
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(L10n.exerciseLibrary)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .listRowBackground(Color.mmBgCard)

            // ソーシャルフィード（Preview）
            Button {
                showingActivityFeed = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text(L10n.socialFeed)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.mmBgPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.mmAccentSecondary)
                        .clipShape(Capsule())
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
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
        }
    }
    // MARK: - Pro版アップグレードバナー（非Pro時のみ）

    private var proUpgradeBanner: some View {
        Section {
            Button {
                showingPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title2)
                        .foregroundStyle(Color.mmAccentPrimary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.proUpgradeTitle)
                            .font(.headline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(L10n.proUpgradeSubtitle)
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mmBgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - バージョンフッター（最下部）

    private var versionFooter: some View {
        Section {
        } footer: {
            VStack(spacing: 4) {
                Text(L10n.tagline)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                Text("v\(appState.appVersion) (\(appState.buildNumber))")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
            }
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
                        .foregroundStyle(Color.mmDestructive)
                    Text("オンボーディングをリセット")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmDestructive)
                }
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text(L10n.developerMenu)
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
    @State private var selectedExperience: TrainingExperience = .beginner
    @State private var showingSavedToast = false

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                Form {
                    Section {
                        // ニックネーム
                        HStack {
                            Text(L10n.profileNickname)
                                .foregroundStyle(Color.mmTextPrimary)
                            Spacer()
                            TextField(L10n.profileNickname, text: $nickname)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.mmTextPrimary)
                        }
                        .listRowBackground(Color.mmBgCard)

                        // 体重
                        HStack {
                            Text(L10n.profileWeight)
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
                        Text(L10n.profileBasicInfo)
                            .foregroundStyle(Color.mmTextSecondary)
                    } footer: {
                        Text(L10n.profileWeightFooter)
                            .foregroundStyle(Color.mmTextSecondary)
                    }

                    // トレーニング経験セクション
                    Section {
                        Picker(L10n.settingsTrainingExp,
                               selection: $selectedExperience) {
                            Text(L10n.settingsExpBeginner)
                                .tag(TrainingExperience.beginner)
                            Text(L10n.settingsExpSixMonths)
                                .tag(TrainingExperience.halfYear)
                            Text(L10n.settingsExpOneYear)
                                .tag(TrainingExperience.oneYearPlus)
                            Text(L10n.settingsExpVeteran)
                                .tag(TrainingExperience.veteran)
                        }
                        .foregroundStyle(Color.mmTextPrimary)
                        .tint(Color.mmAccentPrimary)
                        .listRowBackground(Color.mmBgCard)
                    } header: {
                        Text(L10n.settingsExpLabel)
                            .foregroundStyle(Color.mmTextSecondary)
                    } footer: {
                        Text(L10n.settingsExpMenuHint)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .scrollContentBackground(.hidden)

                // 保存トースト
                if showingSavedToast {
                    VStack {
                        Spacer()
                        Text(L10n.settingsExpChanged)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmBgPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.mmAccentPrimary)
                            .clipShape(Capsule())
                            .padding(.bottom, 48)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(L10n.profileEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) { dismiss() }
                        .foregroundStyle(Color.mmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.save) {
                        var profile = AppState.shared.userProfile
                        if !nickname.isEmpty {
                            profile.nickname = nickname
                        }
                        if let weight = Double(weightText), weight > 0 {
                            profile.weightKg = weight
                        }
                        profile.trainingExperience = selectedExperience
                        AppState.shared.userProfile = profile
                        HapticManager.lightTap()

                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSavedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSavedToast = false
                            }
                            dismiss()
                        }
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                nickname = AppState.shared.userProfile.nickname
                weightText = String(format: "%.1f", AppState.shared.userProfile.weightKg)
                selectedExperience = AppState.shared.userProfile.trainingExperience
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

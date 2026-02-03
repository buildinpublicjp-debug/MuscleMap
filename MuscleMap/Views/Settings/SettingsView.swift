import SwiftUI

// MARK: - 設定画面

struct SettingsView: View {
    @State private var appState = AppState.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var showingPaywall = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""

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
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("復元結果", isPresented: $showingRestoreAlert) {
                Button("OK") {}
            } message: {
                Text(restoreMessage)
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
                        Text("Premium")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text("全機能がアンロックされています")
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
                            Text("Premiumにアップグレード")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                            Text("全機能をアンロック")
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
                        restoreMessage = success
                            ? String(localized: "購入が復元されました。")
                            : String(localized: "復元できる購入が見つかりませんでした。")
                        showingRestoreAlert = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.mmTextSecondary)
                        Text("購入を復元")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text("プレミアム")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - アプリ設定

    private var appSettingsSection: some View {
        Section {
            Toggle(isOn: Bindable(appState).isHapticEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .foregroundStyle(Color.mmTextSecondary)
                    Text("触覚フィードバック")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .tint(Color.mmAccentPrimary)
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("アプリ設定")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - データ管理

    private var dataSection: some View {
        Section {
            // エクササイズ情報
            HStack(spacing: 12) {
                Image(systemName: "dumbbell")
                    .foregroundStyle(Color.mmTextSecondary)
                Text("登録種目数")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(ExerciseStore.shared.exercises.count)種目")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)

            // 筋肉数
            HStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .foregroundStyle(Color.mmTextSecondary)
                Text("追跡筋肉数")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(Muscle.allCases.count)部位")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("データ")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - アプリ情報

    private var appInfoSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.mmTextSecondary)
                Text("バージョン")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(appState.appVersion) (\(appState.buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("アプリ情報")
                .foregroundStyle(Color.mmTextSecondary)
        } footer: {
            Text("MuscleMap — 筋肉の状態が見える。だから、迷わない。")
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }
}

// MARK: - Bindable for AppState (non-@Observable stored properties)

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

import SwiftUI
import SwiftData

// MARK: - Obsidian連携設定画面

struct ObsidianSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var syncManager = ObsidianSyncManager.shared
    @State private var showingFolderPicker = false
    @State private var showingDisconnectAlert = false

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            List {
                // 接続状態
                connectionSection

                // 同期
                if syncManager.isConnected {
                    syncSection
                }

                // ヘルプ
                helpSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Obsidian連携")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFolderPicker) {
            FolderPickerView { url in
                syncManager.setVaultFolder(url)
            }
        }
        .alert("接続を解除", isPresented: $showingDisconnectAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("解除", role: .destructive) {
                syncManager.disconnect()
            }
        } message: {
            Text("Obsidian Vaultとの接続を解除しますか？")
        }
    }

    // MARK: - 接続状態セクション

    private var connectionSection: some View {
        Section {
            if syncManager.isConnected {
                // 接続済み
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("接続済み")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        if let vaultPath = syncManager.vaultPath {
                            Text(vaultPath)
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.mmBgCard)

                Button(role: .destructive) {
                    showingDisconnectAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(Color.red)
                        Text("接続を解除")
                            .font(.subheadline)
                            .foregroundStyle(Color.red)
                    }
                }
                .listRowBackground(Color.mmBgCard)
            } else {
                // 未接続
                Button {
                    showingFolderPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(Color.mmAccentPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vaultフォルダを選択")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                            Text("Obsidianのワークアウトデータを読み込みます")
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
            }
        } header: {
            Text("接続状態")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 同期セクション

    private var syncSection: some View {
        Section {
            // 同期ボタン
            Button {
                Task {
                    await syncManager.syncFromObsidian(modelContext: modelContext)
                }
            } label: {
                HStack(spacing: 12) {
                    if case .syncing = syncManager.syncStatus {
                        ProgressView()
                            .tint(Color.mmAccentPrimary)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                    Text("今すぐ同期")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .disabled(syncManager.syncStatus == .syncing)
            .listRowBackground(Color.mmBgCard)

            // 最終同期日時
            if let lastSync = syncManager.lastSyncDate {
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .foregroundStyle(Color.mmTextSecondary)
                    Text("最終同期")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .listRowBackground(Color.mmBgCard)
            }

            // 同期結果
            if case .success(let message) = syncManager.syncStatus {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .listRowBackground(Color.mmBgCard)
            } else if case .error(let message) = syncManager.syncStatus {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(Color.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text("同期")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - ヘルプセクション

    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("対応フォーマット")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text("""
                    ### 2026/1/18（背中）
                    - ラットプルダウン: 68kg×21回, 75kg×8回
                    - シーテッドロー: 73kg×8回
                    """)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(8)
                    .background(Color.mmBgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("ヘルプ")
                .foregroundStyle(Color.mmTextSecondary)
        } footer: {
            Text("Obsidianへの書き込みは行いません（読み取り専用）")
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
        }
    }
}

// MARK: - フォルダ選択（UIDocumentPicker）

struct FolderPickerView: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelect: (URL) -> Void

        init(onSelect: @escaping (URL) -> Void) {
            self.onSelect = onSelect
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onSelect(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ObsidianSettingsView()
    }
}

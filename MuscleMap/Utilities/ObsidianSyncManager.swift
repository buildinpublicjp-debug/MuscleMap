import Foundation
import SwiftData
import WidgetKit

// MARK: - Obsidian同期マネージャー

@MainActor
@Observable
class ObsidianSyncManager {
    static let shared = ObsidianSyncManager()

    // MARK: - Published State

    var isConnected: Bool = false
    var vaultPath: String?
    var lastSyncDate: Date?
    var syncStatus: SyncStatus = .idle
    var lastSyncResult: ImportResult?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success(String)
        case error(String)
    }

    // MARK: - Private

    private let bookmarkKey = "obsidian_vault_bookmark"
    private let lastSyncKey = "obsidian_last_sync"
    private let vaultPathKey = "obsidian_vault_path"

    private init() {
        loadSavedState()
    }

    // MARK: - Public API

    /// Vaultフォルダを設定（UIDocumentPickerから呼ばれる）
    func setVaultFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            syncStatus = .error("フォルダへのアクセス権限がありません")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            UserDefaults.standard.set(url.path, forKey: vaultPathKey)

            isConnected = true
            vaultPath = url.lastPathComponent
            syncStatus = .success("Vaultを設定しました")
        } catch {
            syncStatus = .error("ブックマークの保存に失敗: \(error.localizedDescription)")
        }
    }

    /// Vault接続を解除
    func disconnect() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: vaultPathKey)
        UserDefaults.standard.removeObject(forKey: lastSyncKey)

        isConnected = false
        vaultPath = nil
        lastSyncDate = nil
        syncStatus = .idle
        lastSyncResult = nil
    }

    /// Obsidianから同期
    func syncFromObsidian(modelContext: ModelContext) async {
        guard let url = resolveBookmark() else {
            syncStatus = .error("Vaultにアクセスできません。再設定してください。")
            return
        }

        syncStatus = .syncing

        guard url.startAccessingSecurityScopedResource() else {
            syncStatus = .error("フォルダへのアクセス権限がありません")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            // Markdownファイルを検索
            let markdownFiles = try findMarkdownFiles(in: url)

            if markdownFiles.isEmpty {
                syncStatus = .error("Markdown ファイルが見つかりませんでした")
                return
            }

            // 全ファイルを読み込んでパース
            var allWorkouts: [ParsedWorkout] = []

            for fileURL in markdownFiles {
                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    let workouts = MarkdownParser.parse(content)
                    allWorkouts.append(contentsOf: workouts)
                }
            }

            if allWorkouts.isEmpty {
                syncStatus = .success("ワークアウトデータが見つかりませんでした")
                return
            }

            // インポート
            let converter = ImportDataConverter(modelContext: modelContext)
            let result = converter.importWorkouts(allWorkouts, skipDuplicates: true)

            lastSyncResult = result
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

            if result.isSuccess {
                syncStatus = .success(result.summary)
                // ウィジェット更新
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                syncStatus = .error(result.errors.joined(separator: "\n"))
            }

        } catch {
            syncStatus = .error("同期エラー: \(error.localizedDescription)")
        }
    }

    /// プレビュー用：同期せずにパース結果を返す
    func previewSync() async -> ImportPreview? {
        guard let url = resolveBookmark() else {
            return nil
        }

        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let markdownFiles = try findMarkdownFiles(in: url)
            var allWorkouts: [ParsedWorkout] = []

            for fileURL in markdownFiles {
                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    let workouts = MarkdownParser.parse(content)
                    allWorkouts.append(contentsOf: workouts)
                }
            }

            // プレビュー用にダミーのModelContextは使えないので、
            // 重複チェックなしでプレビュー生成
            return ImportPreview(
                workouts: allWorkouts,
                matchedExercises: [:],
                unmatchedExercises: [],
                potentialDuplicates: 0
            )

        } catch {
            return nil
        }
    }

    // MARK: - Private

    private func loadSavedState() {
        if let path = UserDefaults.standard.string(forKey: vaultPathKey) {
            vaultPath = URL(fileURLWithPath: path).lastPathComponent
            isConnected = UserDefaults.standard.data(forKey: bookmarkKey) != nil
        }
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    private func resolveBookmark() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        // ブックマークが古い場合は再保存
        if isStale {
            if let newBookmark = try? url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                UserDefaults.standard.set(newBookmark, forKey: bookmarkKey)
            }
        }

        return url
    }

    private func findMarkdownFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default

        var markdownFiles: [URL] = []

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])

            if resourceValues.isDirectory == true {
                // サブディレクトリを再帰的に検索
                let subFiles = try findMarkdownFiles(in: url)
                markdownFiles.append(contentsOf: subFiles)
            } else if resourceValues.isRegularFile == true && url.pathExtension == "md" {
                markdownFiles.append(url)
            }
        }

        return markdownFiles
    }
}

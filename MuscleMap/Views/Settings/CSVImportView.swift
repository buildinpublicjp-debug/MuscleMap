import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

// MARK: - CSVインポート画面

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingFilePicker = false
    @State private var importState: ImportState = .idle
    @State private var preview: ImportPreview?
    @State private var csvContent: String?

    enum ImportState: Equatable {
        case idle
        case previewing
        case importing
        case success(ImportResult)
        case error(String)
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            List {
                // ファイル選択
                fileSelectionSection

                // プレビュー
                if let preview = preview {
                    previewSection(preview)
                }

                // インポートボタン
                if preview != nil {
                    importSection
                }

                // 結果
                resultSection

                // ヘルプ
                helpSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("CSVインポート")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    // MARK: - ファイル選択セクション

    private var fileSelectionSection: some View {
        Section {
            Button {
                showingFilePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CSVファイルを選択")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text("Strong/Hevy形式に対応")
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
        } header: {
            Text("ファイル選択")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - プレビューセクション

    private func previewSection(_ preview: ImportPreview) -> some View {
        Section {
            // ワークアウト数
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.mmTextSecondary)
                Text("ワークアウト数")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(preview.workouts.count)件")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)

            // セット数
            let totalSets = preview.workouts.flatMap { $0.exercises }.flatMap { $0.sets }.count
            HStack(spacing: 12) {
                Image(systemName: "list.number")
                    .foregroundStyle(Color.mmTextSecondary)
                Text("セット数")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(totalSets)セット")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)

            // 未登録種目
            if !preview.unmatchedExercises.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.orange)
                        Text("未登録の種目")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                    Text(preview.unmatchedExercises.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .listRowBackground(Color.mmBgCard)
            }

            // 重複
            if preview.potentialDuplicates > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color.orange)
                    Text("重複の可能性")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text("\(preview.potentialDuplicates)件")
                        .font(.subheadline)
                        .foregroundStyle(Color.orange)
                }
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text("プレビュー")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - インポートセクション

    private var importSection: some View {
        Section {
            Button {
                performImport()
            } label: {
                HStack {
                    Spacer()
                    if importState == .importing {
                        ProgressView()
                            .tint(Color.mmBgPrimary)
                    } else {
                        Text("インポート実行")
                            .font(.headline)
                    }
                    Spacer()
                }
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.mmAccentPrimary)
            .disabled(importState == .importing)
        }
    }

    // MARK: - 結果セクション

    @ViewBuilder
    private var resultSection: some View {
        if case .success(let result) = importState {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text("インポート完了")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                    Text(result.summary)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .listRowBackground(Color.mmBgCard)

                Button {
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("閉じる")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                }
                .listRowBackground(Color.mmBgCard)
            } header: {
                Text("結果")
                    .foregroundStyle(Color.mmTextSecondary)
            }
        } else if case .error(let message) = importState {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
                .listRowBackground(Color.mmBgCard)
            } header: {
                Text("エラー")
                    .foregroundStyle(Color.mmTextSecondary)
            }
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
                    Date,Exercise,Weight (kg),Reps,Sets
                    2026-01-18,Bench Press,60,10,3
                    2026-01-18,Squat,80,8,3
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
            Text("Strong、HevyなどのアプリからエクスポートしたCSVに対応")
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
        }
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                importState = .error("ファイルへのアクセス権限がありません")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                csvContent = content

                // パース & プレビュー生成
                let workouts = CSVParser.parse(content)
                if workouts.isEmpty {
                    importState = .error("ワークアウトデータが見つかりませんでした。フォーマットを確認してください。")
                    preview = nil
                } else {
                    let converter = ImportDataConverter(modelContext: modelContext)
                    preview = converter.preview(workouts)
                    importState = .previewing
                }
            } catch {
                importState = .error("ファイルの読み込みに失敗: \(error.localizedDescription)")
            }

        case .failure(let error):
            importState = .error("ファイル選択エラー: \(error.localizedDescription)")
        }
    }

    private func performImport() {
        guard let content = csvContent else { return }

        importState = .importing

        let workouts = CSVParser.parse(content)
        let converter = ImportDataConverter(modelContext: modelContext)
        let result = converter.importWorkouts(workouts, skipDuplicates: true)

        if result.isSuccess {
            importState = .success(result)
            // ウィジェット更新
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            importState = .error(result.errors.joined(separator: "\n"))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CSVImportView()
    }
}

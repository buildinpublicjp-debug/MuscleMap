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
    @State private var showingPaywall = false

    private let purchaseManager = PurchaseManager.shared

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

            if !purchaseManager.isProUser {
                // Pro未加入: ロック表示
                VStack(spacing: 24) {
                    Spacer()
                    ProFeatureBanner(feature: .export) {
                        showingPaywall = true
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .sheet(isPresented: $showingPaywall) {
                    PaywallView()
                }
            }

            if purchaseManager.isProUser {
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
            } // if isProUser
        }
        .navigationTitle(L10n.csvImport)
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
                        Text(L10n.selectCSVFile)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(L10n.strongHevyFormat)
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
            Text(L10n.fileSelection)
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
                Text(L10n.workoutCount)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text(L10n.itemCount(preview.workouts.count))
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .listRowBackground(Color.mmBgCard)

            // セット数
            let totalSets = preview.workouts.flatMap { $0.exercises }.flatMap { $0.sets }.count
            HStack(spacing: 12) {
                Image(systemName: "list.number")
                    .foregroundStyle(Color.mmTextSecondary)
                Text(L10n.totalSets)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text(L10n.setsLabel(totalSets))
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
                        Text(L10n.unregisteredExercises)
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
                    Text(L10n.potentialDuplicates)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(L10n.itemCount(preview.potentialDuplicates))
                        .font(.subheadline)
                        .foregroundStyle(Color.orange)
                }
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text(L10n.preview)
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
                        Text(L10n.executeImport)
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
                        Text(L10n.importComplete)
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
                        Text(L10n.close)
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundStyle(Color.mmAccentPrimary)
                }
                .listRowBackground(Color.mmBgCard)
            } header: {
                Text(L10n.result)
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
                Text(L10n.error)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
    }

    // MARK: - ヘルプセクション

    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.supportedFormat)
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
            Text(L10n.help)
                .foregroundStyle(Color.mmTextSecondary)
        } footer: {
            Text(L10n.csvImportFooter)
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
                importState = .error(L10n.noAccessPermission)
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                csvContent = content

                // パース & プレビュー生成
                let workouts = CSVParser.parse(content)
                if workouts.isEmpty {
                    importState = .error(L10n.noWorkoutDataFound)
                    preview = nil
                } else {
                    let converter = ImportDataConverter(modelContext: modelContext)
                    preview = converter.preview(workouts)
                    importState = .previewing
                }
            } catch {
                importState = .error(L10n.fileReadError(error.localizedDescription))
            }

        case .failure(let error):
            importState = .error(L10n.fileSelectionError(error.localizedDescription))
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

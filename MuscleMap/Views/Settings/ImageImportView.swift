import SwiftUI
import SwiftData
import PhotosUI
import WidgetKit

// MARK: - 画像インポート画面

struct ImageImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var importState: ImageImportState = .idle
    @State private var recognizedData: RecognizedWorkoutData?
    @State private var preview: ImportPreview?
    @State private var useAIRecognition: Bool = true

    private var claudeAPIKey: String {
        KeyManager.getKey(.claudeAPI) ?? ""
    }

    enum ImageImportState: Equatable {
        case idle
        case loading
        case recognizing
        case recognizingAI
        case previewing
        case importing
        case success(ImportResult)
        case error(String)
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            List {
                // 画像選択
                imageSelectionSection

                // 認識されたテキスト表示
                if let data = recognizedData, !data.rawText.isEmpty {
                    recognizedTextSection(data)
                }

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
        .navigationTitle("画像から取り込み")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { _, newValue in
            Task {
                await loadImage(from: newValue)
            }
        }
    }

    // MARK: - 画像選択セクション

    private var imageSelectionSection: some View {
        Section {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("写真を選択")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text("スクリーンショットや手書きメモ")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Spacer()
                    if importState == .loading || importState == .recognizing || importState == .recognizingAI {
                        ProgressView()
                            .tint(Color.mmAccentPrimary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .listRowBackground(Color.mmBgCard)

            // 選択された画像のプレビュー
            if let image = selectedImage {
                VStack(alignment: .center, spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // 認識中のステータス表示
                    if importState == .recognizingAI {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(L10n.aiRecognizing)
                                .font(.caption)
                                .foregroundStyle(Color.mmAccentSecondary)
                        }
                    } else if importState == .recognizing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(L10n.ocrRecognizing)
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.mmBgCard)
            }

            // AI認識トグル（APIキーがある場合のみ）
            if !claudeAPIKey.isEmpty {
                Toggle(isOn: $useAIRecognition) {
                    HStack(spacing: 12) {
                        Image(systemName: "brain")
                            .foregroundStyle(Color.mmAccentSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.aiRecognition)
                                .font(.subheadline)
                                .foregroundStyle(Color.mmTextPrimary)
                            Text("Claude API")
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }
                .tint(Color.mmAccentPrimary)
                .listRowBackground(Color.mmBgCard)
            }
        } header: {
            Text("画像選択")
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 認識テキストセクション

    private func recognizedTextSection(_ data: RecognizedWorkoutData) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "text.viewfinder")
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text("認識されたテキスト")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                ScrollView {
                    Text(data.rawText)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
                .padding(8)
                .background(Color.mmBgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("OCR結果")
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

            // 種目数
            let exerciseCount = preview.workouts.flatMap { $0.exercises }.count
            HStack(spacing: 12) {
                Image(systemName: "dumbbell")
                    .foregroundStyle(Color.mmTextSecondary)
                Text("種目数")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(exerciseCount)種目")
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

            // 検出された種目
            if !preview.workouts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Color.mmTextSecondary)
                        Text("検出された種目")
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                    }
                    let exerciseNames = preview.workouts
                        .flatMap { $0.exercises }
                        .map { $0.name }
                    Text(exerciseNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .listRowBackground(Color.mmBgCard)
            }

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
                    • トレーニングアプリのスクリーンショット
                    • 手書きのトレーニングメモ
                    • ジムのマシン画面の写真

                    認識される情報:
                    • 重量: 60kg, 135lb など
                    • 回数: 10回, 10reps, ×10 など
                    • セット数: 3セット, 3sets など
                    """)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .listRowBackground(Color.mmBgCard)
        } header: {
            Text("ヘルプ")
                .foregroundStyle(Color.mmTextSecondary)
        } footer: {
            if !claudeAPIKey.isEmpty && useAIRecognition {
                Text("Claude AI (Haiku) を使用して高精度認識")
                    .font(.caption2)
                    .foregroundStyle(Color.mmAccentSecondary.opacity(0.7))
            } else {
                Text("iOS Vision Frameworkを使用してテキストを認識します")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            }
        }
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        importState = .loading
        recognizedData = nil
        preview = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                importState = .error("画像を読み込めませんでした")
                return
            }

            selectedImage = image

            var workouts: [ParsedWorkout] = []
            var rawText = ""

            // AI認識を使用するかどうか
            if useAIRecognition && !claudeAPIKey.isEmpty {
                importState = .recognizingAI

                do {
                    // JPEG形式で圧縮してAPI呼び出し
                    guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                        throw ClaudeAPIError.invalidResponse
                    }

                    workouts = try await ClaudeAPIService.parseWorkoutImage(
                        imageData: jpegData,
                        apiKey: claudeAPIKey
                    )
                    rawText = "AI認識結果: \(workouts.count)件のワークアウトを検出"

                } catch {
                    // AI認識が失敗した場合はOCRにフォールバック
                    importState = .recognizing
                    rawText = try await ImageRecognitionParser.extractText(from: image)
                    workouts = ImageRecognitionParser.parseText(rawText)
                    rawText = "[OCRフォールバック]\n" + rawText
                }
            } else {
                importState = .recognizing

                // 従来のOCR認識
                rawText = try await ImageRecognitionParser.extractText(from: image)
                workouts = ImageRecognitionParser.parseText(rawText)
            }

            recognizedData = RecognizedWorkoutData(
                rawText: rawText,
                workouts: workouts,
                confidence: workouts.isEmpty ? 0 : 0.8
            )

            if workouts.isEmpty {
                importState = .error("ワークアウトデータを検出できませんでした")
                preview = nil
            } else {
                // プレビュー生成
                let converter = ImportDataConverter(modelContext: modelContext)
                preview = converter.preview(workouts)
                importState = .previewing
            }
        } catch {
            importState = .error("認識エラー: \(error.localizedDescription)")
        }
    }

    private func performImport() {
        guard let data = recognizedData, !data.workouts.isEmpty else { return }

        importState = .importing

        let converter = ImportDataConverter(modelContext: modelContext)
        let result = converter.importWorkouts(data.workouts, skipDuplicates: true)

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
        ImageImportView()
    }
}

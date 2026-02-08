import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - ワークアウト完了画面

struct WorkoutCompletionView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var showingShareOptions = false
    @State private var renderedImage: UIImage?

    private var localization: LocalizationManager { LocalizationManager.shared }

    /// Instagramがインストールされているか
    private var isInstagramAvailable: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - 統計計算

    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private var totalSets: Int {
        session.sets.count
    }

    private var uniqueExercises: Int {
        Set(session.sets.map(\.exerciseId)).count
    }

    private var duration: String {
        guard let end = session.endDate else { return "--" }
        let interval = end.timeIntervalSince(session.startDate)
        let minutes = Int(interval / 60)
        return L10n.minutes(minutes)
    }

    /// 実施した種目リスト（重複除去、順番保持）
    private var exercisesDone: [ExerciseDefinition] {
        var seen = Set<String>()
        var result: [ExerciseDefinition] = []
        for set in session.sets {
            if !seen.contains(set.exerciseId),
               let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) {
                seen.insert(set.exerciseId)
                result.append(exercise)
            }
        }
        return result
    }

    /// 刺激した筋肉のマッピング（筋肉ID → 最大刺激度%）
    private var stimulatedMuscleMapping: [String: Int] {
        var muscleIntensity: [String: Int] = [:]

        for set in session.sets {
            guard let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) else { continue }
            for (muscleId, percentage) in exercise.muscleMapping {
                muscleIntensity[muscleId] = max(muscleIntensity[muscleId] ?? 0, percentage)
            }
        }

        return muscleIntensity
    }

    private func setsCount(for exerciseId: String) -> Int {
        session.sets.filter { $0.exerciseId == exerciseId }.count
    }

    /// 種目名リスト（シェア用）
    private var exerciseNames: [String] {
        exercisesDone.map { localization.currentLanguage == .japanese ? $0.nameJA : $0.nameEN }
    }

    /// シェア用テキスト
    private var shareText: String {
        let volumeStr = formatVolume(totalVolume)
        return """
        今日のワークアウト完了 💪
        \(uniqueExercises)種目 | \(totalSets)セット | \(volumeStr)kg
        \(AppConstants.shareHashtag)
        \(AppConstants.appStoreURL)
        """
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // スクロール可能なコンテンツ
                ScrollView {
                    VStack(spacing: 24) {
                        // 完了アイコン
                        completionIcon
                            .padding(.top, 24)

                        // タイトル
                        Text(L10n.workoutComplete)
                            .font(.title.bold())
                            .foregroundStyle(Color.mmTextPrimary)

                        // 統計カード
                        statsCard

                        // 刺激した筋肉
                        stimulatedMusclesSection

                        // 種目リスト（セット数付き）
                        exerciseList
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }

                // ボタン（下部固定）
                buttonSection
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [shareText, image]) {
                    // シェア完了時のフィードバック
                    HapticManager.success()
                }
            }
        }
        .confirmationDialog(L10n.shareTo, isPresented: $showingShareOptions, titleVisibility: .visible) {
            if isInstagramAvailable {
                Button(L10n.shareToInstagramStories) {
                    shareToInstagramStories()
                }
            }
            Button(L10n.shareToOtherApps) {
                showingShareSheet = true
            }
            Button(L10n.cancel, role: .cancel) {}
        }
    }

    // MARK: - 完了アイコン

    private var completionIcon: some View {
        ZStack {
            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.2))
                .frame(width: 100, height: 100)

            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.4))
                .frame(width: 80, height: 80)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.mmAccentPrimary)
        }
    }

    // MARK: - 統計カード

    private var statsCard: some View {
        HStack(spacing: 0) {
            StatBox(value: formatVolume(totalVolume), label: L10n.totalVolume, icon: "scalemass")
            StatBox(value: "\(uniqueExercises)", label: L10n.exercises, icon: "figure.strengthtraining.traditional")
            StatBox(value: "\(totalSets)", label: L10n.sets, icon: "number")
            StatBox(value: duration, label: L10n.time, icon: "clock")
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 刺激した筋肉セクション

    private var stimulatedMusclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.stimulatedMuscles)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            HStack(spacing: 12) {
                // 前面
                MiniMuscleMapView(
                    muscleMapping: stimulatedMuscleMapping,
                    showFront: true
                )
                .aspectRatio(0.5, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 220)

                // 背面
                MiniMuscleMapView(
                    muscleMapping: stimulatedMuscleMapping,
                    showFront: false
                )
                .aspectRatio(0.5, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 種目リスト

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.exercisesDone)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            ForEach(exercisesDone) { exercise in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                    Text(L10n.setsLabel(setsCount(for: exercise.id)))
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ボタンセクション

    private var buttonSection: some View {
        VStack(spacing: 12) {
            // シェアボタン
            Button {
                prepareShareImage()
                showingShareOptions = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.share)
                }
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 閉じるボタン
            Button {
                onDismiss()
            } label: {
                Text(L10n.close)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }

    // MARK: - シェア用画像生成

    @MainActor
    private func prepareShareImage() {
        let shareView = WorkoutShareCard(
            totalVolume: totalVolume,
            totalSets: totalSets,
            exerciseCount: uniqueExercises,
            duration: duration,
            exerciseNames: exerciseNames,
            date: session.startDate,
            muscleMapping: stimulatedMuscleMapping
        )

        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }

    // MARK: - Instagram Storiesにシェア

    @MainActor
    private func shareToInstagramStories() {
        guard let image = renderedImage,
              let imageData = image.pngData(),
              let url = URL(string: "instagram-stories://share") else {
            return
        }

        // ペーストボードに画像をセット
        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]]

        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5) // 5分で期限切れ
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

        // Instagram Storiesを開く
        UIApplication.shared.open(url) { success in
            if success {
                HapticManager.success()
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - 統計ボックス

private struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - シェア用カード（画像レンダリング用）
// Instagram Stories最適サイズ: 9:16比率 (390 x 693)

private struct WorkoutShareCard: View {
    let totalVolume: Double
    let totalSets: Int
    let exerciseCount: Int
    let duration: String
    let exerciseNames: [String]
    let date: Date
    let muscleMapping: [String: Int]

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーションアクセント
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MuscleMap")
                            .font(.title2.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title)
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // 筋肉マップ（FRONT/BACKラベル付き）
                VStack(spacing: 8) {
                    HStack(spacing: 40) {
                        Text("FRONT")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                            .frame(width: 140)
                        Text("BACK")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                            .frame(width: 140)
                    }
                    ShareMuscleMapView(muscleMapping: muscleMapping)
                }
                .padding(.vertical, 4)

                // 統計（より目立つスタイル）
                HStack(spacing: 8) {
                    ShareStatItemBold(value: formatVolume(totalVolume), unit: "kg", label: L10n.volume)
                    ShareStatItemBold(value: "\(exerciseCount)", unit: nil, label: L10n.exercises)
                    ShareStatItemBold(value: "\(totalSets)", unit: nil, label: L10n.sets)
                    ShareStatItemBold(value: duration, unit: nil, label: L10n.time)
                }
                .padding(.horizontal, 20)

                // 種目リスト
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(exerciseNames.prefix(4), id: \.self) { name in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(Color.mmTextPrimary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    if exerciseNames.count > 4 {
                        Text(L10n.andMoreCount(exerciseNames.count - 4))
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // フッター（ブランディング + QRコード）
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        // QRコード
                        if let qrImage = generateQRCode(from: AppConstants.appStoreURL) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        // ブランディングテキスト
                        VStack(alignment: .leading, spacing: 2) {
                            Text(AppConstants.appName)
                                .font(.headline.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text(L10n.shareTagline)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                            Text(L10n.downloadApp)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.7))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: 390, height: 693)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    /// QRコード生成
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction

        guard let outputImage = filter.outputImage else { return nil }

        // 高解像度にスケールアップ
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private struct ShareStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.mmTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// シェアカード用の目立つ統計アイテム
private struct ShareStatItemBold: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)
                if let unit = unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - シェアシート

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete?()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let session = WorkoutSession()
    session.endDate = Date()

    return WorkoutCompletionView(session: session) {
        #if DEBUG
        print("Dismissed")
        #endif
    }
}

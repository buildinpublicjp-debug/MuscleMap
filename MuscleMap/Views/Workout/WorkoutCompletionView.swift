import SwiftUI
import SwiftData
import UIKit

// MARK: - ワークアウト完了画面

struct WorkoutCompletionView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var showingShareOptions = false
    @State private var renderedImage: UIImage?
    @State private var showingFullBodyConquest = false
    @State private var currentMuscleStates: [Muscle: MuscleVisualState] = [:]
    @State private var isFirstConquest = false
    @State private var showingFirstWorkoutPaywall = false
    @State private var appState = AppState.shared

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
        .onAppear {
            checkFullBodyConquest()
            markFirstWorkoutCompleted()
        }
        .fullScreenCover(isPresented: $showingFullBodyConquest) {
            FullBodyConquestView(
                muscleStates: currentMuscleStates,
                onShare: {},
                onDismiss: {
                    showingFullBodyConquest = false
                }
            )
        }
        .sheet(isPresented: $showingFirstWorkoutPaywall) {
            PaywallView()
        }
    }

    // MARK: - 初回ワークアウト完了処理

    private func markFirstWorkoutCompleted() {
        // 初回ワークアウト完了をマーク
        if !appState.hasCompletedFirstWorkout {
            appState.hasCompletedFirstWorkout = true

            // 初回のみペイウォールを表示（少し遅延させてUXを改善）
            if !appState.hasSeenFirstWorkoutPaywall && !PurchaseManager.shared.isProUser {
                appState.hasSeenFirstWorkoutPaywall = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingFirstWorkoutPaywall = true
                }
            }
        }
    }

    // MARK: - 全身制覇チェック

    private func checkFullBodyConquest() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        let stimulations = repo.fetchLatestStimulations()

        // 全筋肉の状態を取得
        var states: [Muscle: MuscleVisualState] = [:]
        var stimulatedCount = 0

        for muscle in Muscle.allCases {
            if let stim = stimulations[muscle] {
                let status = RecoveryCalculator.recoveryStatus(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets
                )

                switch status {
                case .recovering(let progress):
                    states[muscle] = .recovering(progress: progress)
                    stimulatedCount += 1
                case .fullyRecovered:
                    // 完全回復は刺激済み扱い（過去に刺激された）
                    states[muscle] = .inactive
                    stimulatedCount += 1
                case .neglected, .neglectedSevere:
                    // 7日以上未刺激も過去に刺激されたことがある
                    states[muscle] = .neglected(fast: status == .neglectedSevere)
                    stimulatedCount += 1
                }
            } else {
                // 一度も刺激されていない
                states[muscle] = .inactive
            }
        }

        currentMuscleStates = states

        // 全21部位が刺激済み（stimulationsに記録がある）= 全身制覇
        let allMusclesStimulated = stimulations.count == Muscle.allCases.count

        if allMusclesStimulated {
            isFirstConquest = !AppState.shared.hasAchievedFullBodyConquest

            // 達成記録を更新
            if isFirstConquest {
                AppState.shared.hasAchievedFullBodyConquest = true
                AppState.shared.fullBodyConquestDate = Date()
            }
            AppState.shared.fullBodyConquestCount += 1

            // 初回は祝福モーダル、2回目以降は表示しない（バナーは別途実装可能）
            if isFirstConquest {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingFullBodyConquest = true
                }
            }
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

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

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
                // ヘッダー（統一デザイン）
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // タイトル
                Text("WORKOUT COMPLETE")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                // 筋肉マップ（大きく表示）
                ShareMuscleMapView(muscleMapping: muscleMapping)
                    .padding(.vertical, 8)

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

                // フッター（シンプル）
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    Text("MuscleMap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                        .padding(.bottom, 16)
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

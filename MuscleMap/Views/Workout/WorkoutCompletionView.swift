import SwiftUI
import SwiftData
import UIKit

// MARK: - ワークアウト完了画面（種目フォーカス版）

struct WorkoutCompletionView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var showingShareOptions = false
    @State private var renderedImage: UIImage?
    @State private var showingFullBodyConquest = false
    @State private var currentMuscleStates: [Muscle: MuscleVisualState] = [:]
    @State private var conquestLastStimulations: [Muscle: Date] = [:]
    @State private var conquestAchievedAt: Date = Date()
    @State private var isFirstConquest = false
    @State private var appState = AppState.shared
    @State private var hasPRUpdate = false
    @State private var showingPaywall = false
    @State private var showingCamera = false
    @State private var photoSaved = false
    @State private var daysSinceLastPhoto: Int?
    @State private var prUpdatesMap: [String: PRUpdate] = [:]
    // 過去写真比較カード用
    @State private var pastComparisonPhoto: ProgressPhoto?
    @State private var todayComparisonPhoto: ProgressPhoto?
    @State private var photoCardDismissed = false
    // exerciseCard 用 e1RM 進捗バー: exerciseId → 歴代最高 e1RM (現セッション除外)
    @State private var historicalMaxE1RM: [String: Double] = [:]

    // TODO(v1.2): 数値の前回比較 — exerciseCard内に diff 表示を再有効化
    // TODO(v1.2): 過去写真比較の拡張 — 月次プログレス、複数枚並べ、ハイライト
    // TODO(v1.2): セット数が多い場合 (5+) のコンパクトモード対応


    /// Instagramがインストールされているか
    private var isInstagramAvailable: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - 統計計算

    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private var totalSets: Int { session.sets.count }

    private var uniqueExercises: Int {
        Set(session.sets.map(\.exerciseId)).count
    }

    private var durationMinutes: Int {
        guard let end = session.endDate else { return 0 }
        return Int(end.timeIntervalSince(session.startDate) / 60)
    }

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

    /// 刺激された筋肉名リスト
    private var stimulatedMuscleNames: [String] {
        stimulatedMuscleMapping.compactMap { key, value -> String? in
            guard value > 0, let muscle = Muscle(rawValue: key) else { return nil }
            return muscle.localizedName
        }
    }

    private var stimulatedMusclesWithSets: [(muscle: Muscle, totalSets: Int)] {
        var muscleSets: [Muscle: Int] = [:]
        for set in session.sets {
            guard let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) else { continue }
            for (muscleId, _) in exercise.muscleMapping {
                guard let muscle = Muscle(rawValue: muscleId) else { continue }
                muscleSets[muscle, default: 0] += 1
            }
        }
        return muscleSets.map { ($0.key, $0.value) }
    }

    /// 種目ごとのセッション内最大重量セット
    private func bestSet(for exerciseId: String) -> WorkoutSet? {
        session.sets
            .filter { $0.exerciseId == exerciseId }
            .max(by: { $0.weight < $1.weight })
    }

    /// 種目ごとのセット数
    private func setsCount(for exerciseId: String) -> Int {
        session.sets.filter { $0.exerciseId == exerciseId }.count
    }

    private var exerciseNames: [String] {
        exercisesDone.map { $0.localizedName }
    }

    private func formatVolume(_ volume: Double) -> String {
        volume >= 1000 ? String(format: "%.1fk", volume / 1000) : String(format: "%.0f", volume)
    }

    private var shareText: String {
        return """
        \(L10n.workoutCompleteShareTitle)
        \(L10n.workoutCompleteSummary(uniqueExercises, totalSets, durationMinutes))
        \(L10n.trackedWithMuscleMap)
        \(AppConstants.shareHashtag)
        \(AppConstants.appStoreURL)
        """
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.mmBgPrimary, Color.mmBgSecondary.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // 1+2. WORKOUT COMPLETE label + ヒーロー (3 / 9 / 33)
                        heroSummary
                            .padding(.top, 8)

                        // 3. 鍛えた部位 (mini map) — ヒーロー直下、横長コンパクト
                        miniMuscleMap

                        // 4. 種目カードリスト (全セット展開 + e1RM 進捗バー + 王冠)
                        exerciseCardList

                        // 5. 過去写真比較 (写真ある場合のみ)
                        if showPhotoComparison {
                            sectionDivider
                            photoComparisonCard
                        }

                        sectionDivider

                        // 6. 体の記録を撮る
                        progressPhotoButton

                        if let days = daysSinceLastPhoto, days >= 7, !photoSaved {
                            photoReminderBanner(days: days)
                        }

                        // 7. 次回推奨日
                        if !stimulatedMusclesWithSets.isEmpty {
                            NextRecommendedDaySection(
                                stimulatedMuscles: stimulatedMusclesWithSets
                            )
                        }

                        // 8. シェアボタン
                        shareButton
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }

                // 閉じるボタン（下部固定）
                Button {
                    HapticManager.lightTap()
                    onDismiss()
                } label: {
                    Text(L10n.close)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [shareText, image]) {
                    HapticManager.success()
                }
            }
        }
        .confirmationDialog(L10n.shareTo, isPresented: $showingShareOptions, titleVisibility: .visible) {
            if isInstagramAvailable {
                Button(L10n.shareToInstagramStories) { shareToInstagramStories() }
            }
            Button(L10n.shareToOtherApps) { showingShareSheet = true }
            Button(L10n.cancel, role: .cancel) {}
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingCamera) {
            CameraPickerView { image in
                saveProgressPhoto(image)
            }
        }
        .onAppear {
            markFirstWorkoutCompleted()
            daysSinceLastPhoto = ProgressPhoto.daysSinceLastPhoto(context: modelContext)
            loadComparisonPhotos()
            loadHistoricalE1RM()
            // レビュー要求（2回目の完了で発火）
            // ReviewManager.recordWorkoutCompletion() // TODO: ReviewManager未実装
            Task {
                checkFullBodyConquest()
                loadPRUpdates()
                checkPRUpdates()
                scheduleRecoveryNotification()
            }
        }
        .fullScreenCover(isPresented: $showingFullBodyConquest) {
            FullBodyConquestView(
                lastStimulations: conquestLastStimulations,
                achievementDate: conquestAchievedAt,
                onShare: {},
                onDismiss: { showingFullBodyConquest = false }
            )
        }
    }

    // MARK: - 1+2. ヒーロー: WORKOUT COMPLETE + 3つの大きな数値

    private var heroSummary: some View {
        VStack(spacing: 16) {
            // 「WORKOUT COMPLETE」ラベル
            Text(L10n.workoutCompleteLabel)
                .font(.system(size: 12, weight: .heavy))
                .tracking(3)
                .foregroundStyle(Color.mmAccentPrimary)

            // 大きな数値 3つ横並び
            HStack(spacing: 0) {
                heroStatColumn(
                    value: "\(uniqueExercises)",
                    label: isJapanese ? "種目" : "Exercises"
                )
                heroDivider
                heroStatColumn(
                    value: "\(totalSets)",
                    label: isJapanese ? "セット" : "Sets"
                )
                heroDivider
                heroStatColumn(
                    value: "\(durationMinutes)",
                    label: isJapanese ? "分" : "Min"
                )
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private func heroStatColumn(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(Color.mmTextSecondary.opacity(0.15))
            .frame(width: 1, height: 56)
    }

    // MARK: - 3. 鍛えた部位 (mini muscle map) — ヒーロー直下、横長コンパクト

    private var miniMuscleMap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isJapanese ? "鍛えた部位" : "Trained Muscles")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
                .tracking(0.5)

            ShareMuscleMapView(
                muscleMapping: stimulatedMuscleMapping,
                mapHeight: 110,
                glowEnabled: false
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 5. 過去写真比較カード

    private var showPhotoComparison: Bool {
        !photoCardDismissed && pastComparisonPhoto != nil && todayComparisonPhoto != nil
    }

    private var photoComparisonCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text(isJapanese ? "あなたの変化" : "Your Progress")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                HStack(spacing: 12) {
                    if let past = pastComparisonPhoto {
                        photoTile(photo: past, label: daysAgoLabel(past.captureDate))
                    }
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmAccentPrimary)
                    if let today = todayComparisonPhoto {
                        photoTile(photo: today, label: L10n.today)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(Color.mmBgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // 消去ボタン
            Button {
                HapticManager.lightTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    photoCardDismissed = true
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                    .background(Circle().fill(Color.mmBgSecondary))
            }
            .buttonStyle(.plain)
            .padding(8)
        }
    }

    private func photoTile(photo: ProgressPhoto, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.mmBgPrimary)
                if let url = photo.fullImageURL,
                   let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(width: 100, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 8. シェアボタン

    private var shareButton: some View {
        Button {
            HapticManager.lightTap()
            prepareShareImage()
            showingShareOptions = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text(L10n.shareWorkout)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.mmBgPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.mmAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - セクション境界 (薄い divider)

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.mmBorder.opacity(0.15))
            .frame(height: 0.5)
    }

    // MARK: - L10n ヘルパー

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private func daysAgoLabel(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return L10n.today }
        return isJapanese ? "\(days)日前" : "\(days) days ago"
    }

    // MARK: - 2. 種目カードリスト

    private var exerciseCardList: some View {
        VStack(spacing: 8) {
            ForEach(exercisesDone) { exercise in
                exerciseCard(exercise)
            }
        }
    }

    /// 種目カード — 全セット展開版（種目名 + divider + 各セット行: weight×reps + 進捗バー + 王冠）
    /// TODO(v1.2): セット数が5以上の場合のコンパクトモード（折り畳み or サマリー化）
    private func exerciseCard(_ exercise: ExerciseDefinition) -> some View {
        let name = exercise.localizedName
        let exerciseSets = session.sets
            .filter { $0.exerciseId == exercise.id }
            .sorted(by: { $0.setNumber < $1.setNumber })
        let histMax = historicalMaxE1RM[exercise.id] ?? 0
        // 進捗バーの分母: 歴代最高 と 今セッション最高 の大きい方（過去なし種目でも比例表示できる）
        let sessionMaxE1RM = exerciseSets.map { estimatedE1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        let denominator = max(histMax, sessionMaxE1RM)
        // 種目PR (e1RM ベース): 今セッション内のいずれかが歴代を超えたか
        let exerciseHasNewPR = histMax > 0 && sessionMaxE1RM > histMax

        return VStack(alignment: .leading, spacing: 0) {
            // 種目名 + (PR時) 王冠 PR
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)
                if exerciseHasNewPR {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                        Text("PR")
                            .font(.system(size: 11, weight: .heavy))
                    }
                    .foregroundStyle(Color.mmPRGold)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // 区切り
            Rectangle()
                .fill(Color.mmBorder.opacity(0.18))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // セット行リスト（全展開、各行に進捗バー）
            VStack(spacing: 8) {
                ForEach(exerciseSets, id: \.id) { set in
                    setRow(
                        set: set,
                        isPR: isPRSet(set, in: exerciseSets, histMax: histMax),
                        ratio: ratioForSet(set, denominator: denominator)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// セット詳細1行: weight × reps テキスト + 進捗バー + (PR時) 王冠
    private func setRow(set: WorkoutSet, isPR: Bool, ratio: Double) -> some View {
        HStack(spacing: 12) {
            Text(formatSetDisplay(weight: set.weight, reps: set.reps))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.mmTextPrimary)
                .frame(width: 100, alignment: .leading)

            progressBar(ratio: ratio)
                .frame(maxWidth: .infinity)

            // PR セットなら王冠表示、それ以外は同サイズ余白で揃える
            Image(systemName: "crown.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.mmPRGold)
                .opacity(isPR ? 1 : 0)
                .frame(width: 16, alignment: .trailing)
        }
    }

    /// セット行右側の進捗バー (黄→緑グラデ、ratio で塗り長)
    private func progressBar(ratio: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.mmBgPrimary)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.mmMuscleModerate, Color.mmMuscleRecovered],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(0, min(1.0, ratio)) * geo.size.width)
            }
        }
        .frame(height: 6)
    }

    /// セット表示文字列 — "30 kg × 10" / "自重 × 10"
    private func formatSetDisplay(weight: Double, reps: Int) -> String {
        if weight > 0 {
            let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", weight)
                : String(format: "%.1f", weight)
            return "\(weightStr) kg × \(reps)"
        } else {
            return isJapanese ? "自重 × \(reps)" : "BW × \(reps)"
        }
    }

    // MARK: - e1RM 計算と PR 判定

    /// Epley 公式による推定 1RM
    private func estimatedE1RM(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// 進捗バーの ratio = セット e1RM ÷ 分母 (歴代最高 or 今日最高の大きい方)
    private func ratioForSet(_ set: WorkoutSet, denominator: Double) -> Double {
        guard denominator > 0 else { return 0 }
        let e1rm = estimatedE1RM(weight: set.weight, reps: set.reps)
        return e1rm / denominator
    }

    /// セットが新 e1RM PR かどうか (歴代最高超え、かつ今セッション最高タイ以上)
    private func isPRSet(_ set: WorkoutSet, in sessionSets: [WorkoutSet], histMax: Double) -> Bool {
        guard histMax > 0 else { return false }   // 過去記録ゼロの種目は王冠スパムを避ける
        let setE1RM = estimatedE1RM(weight: set.weight, reps: set.reps)
        guard setE1RM > histMax else { return false }
        let sessionMax = sessionSets.map { estimatedE1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
        return setE1RM >= sessionMax
    }

    /// 歴代最高 e1RM (現セッション除外) を全 ExerciseDefinition × 過去 WorkoutSet から集計
    private func loadHistoricalE1RM() {
        let descriptor = FetchDescriptor<WorkoutSet>()
        guard let allSets = try? modelContext.fetch(descriptor) else { return }
        var maxByExercise: [String: Double] = [:]
        for set in allSets {
            // 現セッションのセットは除外
            if set.session?.id == session.id { continue }
            let e1rm = estimatedE1RM(weight: set.weight, reps: set.reps)
            if e1rm > (maxByExercise[set.exerciseId] ?? 0) {
                maxByExercise[set.exerciseId] = e1rm
            }
        }
        historicalMaxE1RM = maxByExercise
    }

    // MARK: - プログレスフォトボタン

    private var progressPhotoButton: some View {
        return Button {
            HapticManager.lightTap()
            showingCamera = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: photoSaved ? "checkmark.circle.fill" : "camera.fill")
                Text(photoSaved ? L10n.photoSaved : L10n.takeProgressPhoto)
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(photoSaved ? Color.mmAccentPrimary : Color.mmTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(photoSaved ? Color.mmAccentPrimary.opacity(0.15) : Color.mmBgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(photoSaved)
    }

    private func photoReminderBanner(days: Int) -> some View {
        return HStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.subheadline)
                .foregroundStyle(Color.mmWarning)
            Text(L10n.photoReminderDays(days))
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmWarning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - ヘルパーメソッド

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fkg", weight)
        }
        return String(format: "%.1fkg", weight)
    }

    private func markFirstWorkoutCompleted() {
        if !appState.hasCompletedFirstWorkout {
            appState.hasCompletedFirstWorkout = true
        }
    }

    /// PR更新情報を種目IDでマップに変換
    private func loadPRUpdates() {
        let updates = PRManager.shared.getSessionPRUpdates(session: session, context: modelContext)
        for update in updates {
            prUpdatesMap[update.exerciseId] = update
        }
    }

    private func checkFullBodyConquest() {
        let repo = MuscleStateRepository(modelContext: modelContext)
        let stimulations = repo.fetchLatestStimulations()

        var states: [Muscle: MuscleVisualState] = [:]
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
                case .fullyRecovered:
                    states[muscle] = .inactive
                case .neglected, .neglectedSevere:
                    states[muscle] = .neglected(fast: status == .neglectedSevere)
                }
            } else {
                states[muscle] = .untrained
            }
        }

        currentMuscleStates = states

        let allMusclesStimulated = stimulations.count == Muscle.allCases.count
        if allMusclesStimulated {
            // リデザイン版 FullBodyConquestView 用: 各部位の最終刺激日と達成日
            var dates: [Muscle: Date] = [:]
            for (muscle, stim) in stimulations {
                dates[muscle] = stim.stimulationDate
            }
            conquestLastStimulations = dates
            conquestAchievedAt = session.endDate ?? Date()

            isFirstConquest = !AppState.shared.hasAchievedFullBodyConquest
            if isFirstConquest {
                AppState.shared.hasAchievedFullBodyConquest = true
            }
            AppState.shared.fullBodyConquestCount += 1

            if isFirstConquest {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingFullBodyConquest = true
                }
            }
        }
    }

    @MainActor
    private func prepareShareImage() {
        let prItems: [SharePRItem] = prUpdatesMap.values.prefix(3).compactMap { update in
            guard let exercise = ExerciseStore.shared.exercise(for: update.exerciseId) else { return nil }
            let name = exercise.localizedName
            return SharePRItem(
                exerciseName: name,
                previousWeight: update.previousWeight,
                newWeight: update.newWeight,
                increasePercent: update.increasePercent
            )
        }

        // 種目ごとの最大重量×レップ（シェアカード用）
        let exerciseEntries: [ShareExerciseEntry] = exercisesDone.prefix(3).compactMap { exercise in
            guard let best = bestSet(for: exercise.id), best.weight > 0 else { return nil }
            let name = exercise.localizedName
            return ShareExerciseEntry(exerciseName: name, weight: best.weight, reps: best.reps)
        }

        let shareView = WorkoutShareCard(
            exerciseEntries: exerciseEntries,
            totalSets: totalSets,
            exerciseCount: uniqueExercises,
            date: session.startDate,
            muscleMapping: stimulatedMuscleMapping,
            prItems: prItems,
            durationMinutes: durationMinutes
        )
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            renderedImage = image
        }
    }

    private func checkPRUpdates() {
        hasPRUpdate = !prUpdatesMap.isEmpty
    }

    private func scheduleRecoveryNotification() {
        guard !stimulatedMusclesWithSets.isEmpty else { return }

        var maxHours: Double = 0
        for entry in stimulatedMusclesWithSets {
            let hours = RecoveryCalculator.adjustedRecoveryHours(
                muscle: entry.muscle,
                totalSets: entry.totalSets
            )
            maxHours = max(maxHours, hours)
        }
        let recoveryDate = Date().addingTimeInterval(maxHours * 3600)

        let nextPart = WorkoutRecommendationEngine.todaysPart(modelContext: modelContext)
        let partName = nextPart?.localizedName ?? L10n.trainingFallback

        NotificationManager.shared.scheduleRecoveryReminder(
            nextPartName: partName,
            recoveryDate: recoveryDate
        )
    }

    private func saveProgressPhoto(_ image: UIImage) {
        guard let path = ProgressPhoto.savePhoto(image, sessionId: session.id) else { return }
        let photo = ProgressPhoto(imagePath: path, sessionId: session.id)
        modelContext.insert(photo)
        try? modelContext.save()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            photoSaved = true
        }
        // 今日の写真が増えたので比較カード再ロード
        loadComparisonPhotos()
        HapticManager.success()
    }

    /// 過去写真比較カード用に過去・今日の ProgressPhoto を読み込む
    /// - 過去: 直近30日以内 (今日除く) の最古の1枚 — 一番ビフォーアフター差が大きいもの
    /// - 今日: 今日撮影された最新の1枚
    private func loadComparisonPhotos() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let cutoff30 = calendar.date(byAdding: .day, value: -30, to: startOfToday) ?? startOfToday

        // 今日の写真 (今日0時以降)
        var todayDescriptor = FetchDescriptor<ProgressPhoto>(
            predicate: #Predicate { $0.captureDate >= startOfToday },
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        todayDescriptor.fetchLimit = 1
        todayComparisonPhoto = (try? modelContext.fetch(todayDescriptor))?.first

        // 過去の写真 (30日以内、今日0時より前) — 最古を取得
        var pastDescriptor = FetchDescriptor<ProgressPhoto>(
            predicate: #Predicate { $0.captureDate >= cutoff30 && $0.captureDate < startOfToday },
            sortBy: [SortDescriptor(\.captureDate, order: .forward)]
        )
        pastDescriptor.fetchLimit = 1
        pastComparisonPhoto = (try? modelContext.fetch(pastDescriptor))?.first
    }

    @MainActor
    private func shareToInstagramStories() {
        guard let image = renderedImage,
              let imageData = image.jpegData(compressionQuality: 0.9),
              let appID = Bundle.main.bundleIdentifier,
              let url = URL(string: "instagram-stories://share?source_application=\(appID)") else { return }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData,
            "com.instagram.sharedSticker.sourceApplication": appID
        ]]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]
        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

        UIApplication.shared.open(url) { success in
            if success { HapticManager.success() }
        }
    }
}

// MARK: - Preview

#Preview {
    let session = WorkoutSession()
    session.endDate = Date()
    return WorkoutCompletionView(session: session) {}
}

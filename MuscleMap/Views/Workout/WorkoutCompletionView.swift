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
    @State private var isFirstConquest = false
    @State private var appState = AppState.shared
    @State private var hasPRUpdate = false
    @State private var levelUpExercises: [LevelUpInfo] = []
    @State private var showingStrengthShareSheet = false
    @State private var strengthShareImage: UIImage?
    @State private var showingPaywall = false
    @State private var showingCamera = false
    @State private var photoSaved = false
    @State private var daysSinceLastPhoto: Int?
    @State private var prUpdatesMap: [String: PRUpdate] = [:]

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
        exercisesDone.map { localization.currentLanguage == .japanese ? $0.nameJA : $0.nameEN }
    }

    private func formatVolume(_ volume: Double) -> String {
        volume >= 1000 ? String(format: "%.1fk", volume / 1000) : String(format: "%.0f", volume)
    }

    private var shareText: String {
        if localization.currentLanguage == .japanese {
            return """
            今日のワークアウト完了
            \(uniqueExercises)種目 · \(totalSets)セット · \(durationMinutes)分
            MuscleMap で記録
            \(AppConstants.shareHashtag)
            \(AppConstants.appStoreURL)
            """
        } else {
            return """
            Workout Complete
            \(uniqueExercises) exercises · \(totalSets) sets · \(durationMinutes)min
            Tracked with MuscleMap
            \(AppConstants.shareHashtag)
            \(AppConstants.appStoreURL)
            """
        }
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
                    VStack(spacing: 16) {
                        // 1. 筋肉マップ（ヒーロー）
                        muscleMapHero
                            .padding(.top, 16)

                        // 2. 種目カードリスト（メインコンテンツ）
                        exerciseCardList

                        // 3. サマリー（1行）
                        compactSummary

                        // レベルアップ（PR更新でレベルが上がった場合）
                        if !levelUpExercises.isEmpty {
                            LevelUpCelebrationSection(levelUps: levelUpExercises)
                        }

                        // 4. プログレスフォト
                        progressPhotoButton

                        if let days = daysSinceLastPhoto, days >= 7, !photoSaved {
                            photoReminderBanner(days: days)
                        }

                        // 5. 次回推奨
                        if !stimulatedMusclesWithSets.isEmpty {
                            NextRecommendedDaySection(
                                stimulatedMuscles: stimulatedMusclesWithSets
                            )
                        }

                        // 6. シェアボタン
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
                        }
                        .buttonStyle(.plain)
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
        .sheet(isPresented: $showingStrengthShareSheet) {
            if let image = strengthShareImage {
                ShareSheet(items: [image]) {
                    HapticManager.success()
                }
            }
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
            Task {
                checkFullBodyConquest()
                loadPRUpdates()
                checkPRUpdates()
                detectLevelUps()
                scheduleRecoveryNotification()
            }
        }
        .fullScreenCover(isPresented: $showingFullBodyConquest) {
            FullBodyConquestView(
                muscleStates: currentMuscleStates,
                onShare: {},
                onDismiss: { showingFullBodyConquest = false }
            )
        }
    }

    // MARK: - 1. 筋肉マップヒーロー

    private var muscleMapHero: some View {
        VStack(spacing: 8) {
            // 「WORKOUT COMPLETE」ラベル
            Text("WORKOUT COMPLETE")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(Color.mmAccentPrimary)

            // 筋肉マップ（グロー付き）
            ZStack {
                Circle()
                    .fill(Color.mmAccentPrimary.opacity(0.03))
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)

                ShareMuscleMapView(
                    muscleMapping: stimulatedMuscleMapping,
                    mapHeight: 240,
                    glowEnabled: true
                )
            }

            // 刺激部位チップ
            if !stimulatedMuscleNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(stimulatedMuscleNames, id: \.self) { name in
                            Text(name)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.mmAccentPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.mmAccentPrimary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - 2. 種目カードリスト

    private var exerciseCardList: some View {
        VStack(spacing: 8) {
            ForEach(exercisesDone) { exercise in
                exerciseCard(exercise)
            }
        }
    }

    private func exerciseCard(_ exercise: ExerciseDefinition) -> some View {
        let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
        let sets = setsCount(for: exercise.id)
        let best = bestSet(for: exercise.id)
        let prUpdate = prUpdatesMap[exercise.id]

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                // GIFサムネイル
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .gridCard)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.mmBgPrimary)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "dumbbell.fill")
                                .font(.title3)
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    // 種目名
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    // 重量推移（前回 → 今回）
                    if let best, best.weight > 0 {
                        if let pr = prUpdate {
                            HStack(spacing: 4) {
                                Text(formatWeight(pr.previousWeight))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(Color.mmTextSecondary)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.mmTextSecondary)
                                Text("\(formatWeight(best.weight))×\(best.reps)")
                                    .font(.caption.bold().monospaced())
                                    .foregroundStyle(Color.mmTextPrimary)
                            }
                        } else {
                            Text("\(formatWeight(best.weight))×\(best.reps)")
                                .font(.caption.bold().monospaced())
                                .foregroundStyle(Color.mmTextPrimary)
                        }
                    }

                    // セット数
                    Text(L10n.setsLabel(sets))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()
            }
            .padding(12)

            // PRライン（PRの場合のみ）
            if let pr = prUpdate {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.mmPRGold.opacity(0.3))
                        .frame(height: 0.5)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmPRGold)
                    Text("PR ↑\(pr.increasePercent)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.mmPRGold)
                    Rectangle()
                        .fill(Color.mmPRGold.opacity(0.3))
                        .frame(height: 0.5)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 3. サマリー（1行）

    private var compactSummary: some View {
        let isJapanese = localization.currentLanguage == .japanese
        let text = isJapanese
            ? "\(uniqueExercises)種目 · \(totalSets)セット · \(durationMinutes)分"
            : "\(uniqueExercises) exercises · \(totalSets) sets · \(durationMinutes)min"

        return Text(text)
            .font(.caption)
            .foregroundStyle(Color.mmTextSecondary)
            .frame(maxWidth: .infinity)
    }

    // MARK: - プログレスフォトボタン

    private var progressPhotoButton: some View {
        let isJapanese = localization.currentLanguage == .japanese
        return Button {
            HapticManager.lightTap()
            showingCamera = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: photoSaved ? "checkmark.circle.fill" : "camera.fill")
                Text(photoSaved
                     ? (isJapanese ? "記録済み" : "Photo Saved")
                     : (isJapanese ? "体の記録を撮る" : "Take Progress Photo"))
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(photoSaved ? Color.mmAccentPrimary : Color.mmTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(photoSaved ? Color.mmAccentPrimary.opacity(0.15) : Color.mmBgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(photoSaved)
    }

    private func photoReminderBanner(days: Int) -> some View {
        let isJapanese = localization.currentLanguage == .japanese
        return HStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.subheadline)
                .foregroundStyle(Color.mmWarning)
            Text(isJapanese
                 ? "最後の体の記録から\(days)日経過"
                 : "It's been \(days) days since your last progress photo")
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
                states[muscle] = .inactive
            }
        }

        currentMuscleStates = states

        let allMusclesStimulated = stimulations.count == Muscle.allCases.count
        if allMusclesStimulated {
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
            let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
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
            let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
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

    private func detectLevelUps() {
        let prUpdates = Array(prUpdatesMap.values)
        guard !prUpdates.isEmpty else { return }

        let bodyweight = AppState.shared.userProfile.weightKg

        var results: [LevelUpInfo] = []
        for update in prUpdates {
            let previous1RM = PRManager.shared.effectiveEstimated1RM(
                weight: update.previousWeight, reps: 1,
                exerciseId: update.exerciseId, bodyweightKg: bodyweight
            )
            let sessionSets = session.sets.filter { $0.exerciseId == update.exerciseId }
            let best1RMInSession = sessionSets.map {
                PRManager.shared.effectiveEstimated1RM(
                    weight: $0.weight, reps: $0.reps,
                    exerciseId: update.exerciseId, bodyweightKg: bodyweight
                )
            }.max() ?? PRManager.shared.effectiveEstimated1RM(
                weight: update.newWeight, reps: 1,
                exerciseId: update.exerciseId, bodyweightKg: bodyweight
            )

            let previousResult = StrengthScoreCalculator.exerciseStrengthLevel(
                exerciseId: update.exerciseId,
                estimated1RM: previous1RM,
                bodyweightKg: bodyweight
            )
            let newResult = StrengthScoreCalculator.exerciseStrengthLevel(
                exerciseId: update.exerciseId,
                estimated1RM: best1RMInSession,
                bodyweightKg: bodyweight
            )

            if newResult.level != previousResult.level {
                let exerciseName: String
                if let def = ExerciseStore.shared.exercise(for: update.exerciseId) {
                    exerciseName = localization.currentLanguage == .japanese ? def.nameJA : def.nameEN
                } else {
                    exerciseName = update.exerciseId
                }

                results.append(LevelUpInfo(
                    exerciseName: exerciseName,
                    previousLevel: previousResult.level,
                    newLevel: newResult.level,
                    kgToNext: newResult.kgToNext,
                    nextLevel: newResult.nextLevel
                ))
            }
        }

        levelUpExercises = results
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
        let isJa = LocalizationManager.shared.currentLanguage == .japanese
        let partName = nextPart?.localizedName ?? (isJa ? "トレーニング" : "Training")

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
        HapticManager.success()
    }

    @MainActor
    private func shareToInstagramStories() {
        guard let image = renderedImage,
              let imageData = image.pngData(),
              let url = URL(string: "instagram-stories://share") else { return }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
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

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
    @State private var appState = AppState.shared
    @State private var hasPRUpdate = false
    @State private var showingStrengthShareSheet = false
    @State private var strengthShareImage: UIImage?

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

    private var duration: String {
        guard let end = session.endDate else { return "--" }
        let minutes = Int(end.timeIntervalSince(session.startDate) / 60)
        return L10n.minutes(minutes)
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

    /// 今回刺激した筋肉とセッション内の推定セット数（回復予測用）
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
            今日のワークアウト完了 💪
            \(uniqueExercises)種目 | \(totalSets)セット | \(formatVolume(totalVolume))kg
            \(AppConstants.shareHashtag)
            \(AppConstants.appStoreURL)
            """
        } else {
            return """
            Workout Complete 💪
            \(uniqueExercises) exercises | \(totalSets) sets | \(formatVolume(totalVolume))kg
            \(AppConstants.shareHashtag)
            \(AppConstants.appStoreURL)
            """
        }
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        CompletionIcon()
                            .padding(.top, 24)

                        Text(L10n.workoutComplete)
                            .font(.title.bold())
                            .foregroundStyle(Color.mmTextPrimary)

                        CompletionStatsCard(
                            totalVolume: totalVolume,
                            uniqueExercises: uniqueExercises,
                            totalSets: totalSets,
                            duration: duration
                        )

                        StimulatedMusclesSection(muscleMapping: stimulatedMuscleMapping)

                        // 次回おすすめ日
                        if !stimulatedMusclesWithSets.isEmpty {
                            NextRecommendedDaySection(
                                stimulatedMuscles: stimulatedMusclesWithSets
                            )
                        }

                        // PR更新時のみStrength Mapシェア導線
                        if hasPRUpdate {
                            StrengthMapShareSection(
                                onShareStrengthMap: {
                                    prepareStrengthShareImage()
                                    showingStrengthShareSheet = true
                                }
                            )
                        }

                        CompletionExerciseList(
                            exercises: exercisesDone,
                            setsCountProvider: setsCount
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }

                CompletionButtonSection(
                    onShare: {
                        prepareShareImage()
                        showingShareOptions = true
                    },
                    onDismiss: onDismiss
                )
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
        .onAppear {
            checkFullBodyConquest()
            markFirstWorkoutCompleted()
            checkPRUpdates()
        }
        .fullScreenCover(isPresented: $showingFullBodyConquest) {
            FullBodyConquestView(
                muscleStates: currentMuscleStates,
                onShare: {},
                onDismiss: { showingFullBodyConquest = false }
            )
        }
    }

    // MARK: - ヘルパーメソッド

    private func markFirstWorkoutCompleted() {
        if !appState.hasCompletedFirstWorkout {
            appState.hasCompletedFirstWorkout = true
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
                AppState.shared.fullBodyConquestDate = Date()
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
        // PR更新情報を取得
        let prUpdates = PRManager.shared.getSessionPRUpdates(session: session, context: modelContext)
        let prItems: [SharePRItem] = prUpdates.prefix(2).compactMap { update in
            guard let exercise = ExerciseStore.shared.exercise(for: update.exerciseId) else { return nil }
            let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
            return SharePRItem(
                exerciseName: name,
                previousWeight: update.previousWeight,
                newWeight: update.newWeight,
                increasePercent: update.increasePercent
            )
        }

        let shareView = WorkoutShareCard(
            totalVolume: totalVolume,
            totalSets: totalSets,
            exerciseCount: uniqueExercises,
            date: session.startDate,
            muscleMapping: stimulatedMuscleMapping,
            prItems: prItems
        )
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            renderedImage = image
        }
    }

    /// 今回のセッションにPR更新が含まれるかチェック
    private func checkPRUpdates() {
        // 種目ごとにこのセッション内の最大重量を取得し、
        // セッション以前の記録と比較
        var exerciseMaxInSession: [String: Double] = [:]
        for set in session.sets {
            let w = set.weight
            if w > (exerciseMaxInSession[set.exerciseId] ?? 0) {
                exerciseMaxInSession[set.exerciseId] = w
            }
        }

        for (exerciseId, maxWeight) in exerciseMaxInSession {
            // セッション以前のPR（このセッションのセットを除外して比較）
            let descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate {
                    $0.exerciseId == exerciseId
                },
                sortBy: [SortDescriptor(\.weight, order: .reverse)]
            )
            guard let allSets = try? modelContext.fetch(descriptor) else { continue }

            // このセッション以外のセットの最大重量を取得
            let previousMax = allSets
                .filter { $0.session?.id != session.id }
                .first?.weight ?? 0

            if maxWeight > previousMax && previousMax > 0 {
                hasPRUpdate = true
                return
            }
        }
    }

    /// Strength Mapシェア画像を生成
    @MainActor
    private func prepareStrengthShareImage() {
        let allSetsDescriptor = FetchDescriptor<WorkoutSet>()
        guard let allSets = try? modelContext.fetch(allSetsDescriptor) else { return }

        let profile = UserProfile.load()
        let scores = StrengthScoreCalculator.shared.muscleStrengthScores(
            allSets: allSets,
            bodyweightKg: profile.weightKg
        )

        strengthShareImage = generateStrengthShareImage(
            scores: scores,
            userName: profile.nickname,
            date: Date()
        )
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

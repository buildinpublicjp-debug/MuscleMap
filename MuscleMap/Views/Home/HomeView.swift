import SwiftUI
import SwiftData

// MARK: - ホーム画面

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var streakViewModel = StreakViewModel()
    @State private var selectedMuscle: Muscle?
    @State private var showDemo = false
    @State private var showingMilestone = false
    @State private var showingAnalyticsMenu = false
    @State private var showingTodayRecommendation = false

    /// ワークアウト履歴があるかどうか
    private var hasWorkoutHistory: Bool {
        AppState.shared.hasCompletedFirstWorkout
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 週間ストリークバッジ（コンパクト表示）
                            WeeklyStreakBadge(
                                weeks: streakViewModel.currentStreak,
                                isCurrentWeekCompleted: streakViewModel.isCurrentWeekCompleted
                            )

                            // 筋肉マップ（メイン）- ホームの主役
                            MuscleMapView(
                                muscleStates: vm.muscleStates,
                                onMuscleTapped: { muscle in
                                    selectedMuscle = muscle
                                },
                                demoMode: showDemo
                            )
                            .frame(maxHeight: 500)
                            .padding(.horizontal)

                            // 未刺激警告（該当する場合のみ）
                            if !vm.neglectedMuscleInfos.isEmpty {
                                NeglectedWarningView(muscleInfos: vm.neglectedMuscleInfos)
                                    .padding(.horizontal)
                            }

                            // 統計・分析セクション（ワークアウト履歴がある場合のみ）
                            if hasWorkoutHistory {
                                ViewStatsButton {
                                    showingAnalyticsMenu = true
                                }
                                .padding(.horizontal)

                                // 今日のおすすめボタン（統計の下に配置）
                                TodayRecommendationButton {
                                    showingTodayRecommendation = true
                                }
                                .padding(.horizontal)
                            } else {
                                // 初回ユーザー向けCTA（タップでワークアウトタブへ遷移）
                                FirstWorkoutCTA {
                                    AppState.shared.selectedTab = 1
                                }
                                .padding(.horizontal)
                            }

                            // 凡例
                            MuscleMapLegend()
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("MuscleMap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MuscleMap")
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                viewModel?.loadMuscleStates()
                viewModel?.checkActiveSession()

                // ストリーク計算
                streakViewModel.configure(with: modelContext)

                // マイルストーン達成チェック
                if streakViewModel.achievedMilestone != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingMilestone = true
                    }
                }

                // 初回デモアニメーション
                if !AppState.shared.hasSeenDemoAnimation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDemo = true
                        AppState.shared.hasSeenDemoAnimation = true
                    }
                }
            }
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailView(muscle: muscle)
            }
            .sheet(isPresented: $showingMilestone) {
                if let milestone = streakViewModel.achievedMilestone {
                    MilestoneView(
                        milestone: milestone,
                        streakWeeks: streakViewModel.currentStreak
                    ) {
                        streakViewModel.dismissMilestone()
                        showingMilestone = false
                    }
                }
            }
            .sheet(isPresented: $showingAnalyticsMenu) {
                AnalyticsMenuView()
            }
            .sheet(isPresented: $showingTodayRecommendation) {
                if let vm = viewModel {
                    TodayRecommendationView(menu: vm.getSuggestedMenu())
                }
            }
        }
    }
}

// MARK: - 今日のおすすめボタン

private struct TodayRecommendationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.todayRecommendation)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.basedOnRecovery)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 今日のおすすめメニュービュー

private struct TodayRecommendationView: View {
    let menu: SuggestedMenu
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: ExerciseDefinition?

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 提案理由
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Color.mmAccentPrimary)
                                Text(L10n.suggestionReason)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                            }
                            Text(menu.reason)
                                .font(.body)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // 種目リスト
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.suggestedExercises)
                                .font(.headline)
                                .foregroundStyle(Color.mmTextPrimary)

                            ForEach(menu.exercises) { exercise in
                                SuggestedExerciseRow(
                                    exercise: exercise,
                                    onTap: {
                                        selectedExercise = exercise.definition
                                    }
                                )
                            }

                            if menu.exercises.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 40))
                                        .foregroundStyle(Color.mmTextSecondary)
                                    Text(L10n.letsStartTraining)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.mmTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            }
                        }

                        // 開始ボタン
                        Button {
                            HapticManager.lightTap()
                            AppState.shared.selectedTab = 1
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(L10n.startWorkout)
                            }
                            .font(.headline)
                            .foregroundStyle(Color.mmBgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.mmAccentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.todayRecommendation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 提案種目行

private struct SuggestedExerciseRow: View {
    let exercise: SuggestedExercise
    let onTap: () -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 筋肉マップ（どこに効くかを視覚的に表示）
                ZStack(alignment: .topTrailing) {
                    MiniMuscleMapView(muscleMapping: exercise.definition.muscleMapping)
                        .frame(width: 40, height: 52)

                    // 未刺激警告バッジ
                    if exercise.isNeglectedFix {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mmMuscleNeglected)
                            .offset(x: 4, y: -4)
                    }
                }

                // 種目情報
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(localization.currentLanguage == .japanese ? exercise.definition.nameJA : exercise.definition.nameEN)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)

                        if exercise.isNeglectedFix {
                            Text(L10n.neglected)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mmMuscleNeglected.opacity(0.2))
                                .foregroundStyle(Color.mmMuscleNeglected)
                                .clipShape(Capsule())
                        }
                    }
                    Text(L10n.setsReps(exercise.suggestedSets, exercise.suggestedReps))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 統計を見るボタン

private struct ViewStatsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title3)
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(L10n.viewStats)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 初回ユーザー向けCTA

private struct FirstWorkoutCTA: View {
    let onStartWorkout: () -> Void

    var body: some View {
        Button(action: onStartWorkout) {
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(L10n.startFirstWorkout)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)

                Text(L10n.firstWorkoutHint)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)

                // 開始ボタン
                HStack {
                    Image(systemName: "play.fill")
                    Text(L10n.startWorkout)
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.mmAccentPrimary)
                .clipShape(Capsule())
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - マッスル・ジャーニーカード

private struct MuscleJourneyCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.muscleJourney)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.journeyCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - トレーニングヒートマップカード

private struct TrainingHeatmapCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.trainingHeatmap)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.heatmapCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 筋肉バランス診断カード

private struct BalanceDiagnosisCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.muscleBalanceDiagnosis)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.diagnosisCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 週間ストリークバッジ

private struct WeeklyStreakBadge: View {
    let weeks: Int
    let isCurrentWeekCompleted: Bool

    @State private var glowAnimation = false

    private var showBadge: Bool {
        weeks > 0 || !isCurrentWeekCompleted
    }

    var body: some View {
        if showBadge {
            HStack(spacing: 8) {
                // 炎アイコン
                Image(systemName: "flame.fill")
                    .foregroundStyle(isCurrentWeekCompleted ? .orange : Color.mmTextSecondary)
                    .shadow(color: isCurrentWeekCompleted ? .orange.opacity(glowAnimation ? 0.6 : 0.2) : .clear, radius: glowAnimation ? 8 : 4)

                // テキスト
                if weeks > 0 {
                    Text(L10n.weekStreak(weeks))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                } else {
                    Text(L10n.noWorkoutThisWeek)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.mmBgCard)
            .clipShape(Capsule())
            .onAppear {
                if isCurrentWeekCompleted {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowAnimation = true
                    }
                }
            }
        }
    }
}

// MARK: - マイルストーン祝福画面

private struct MilestoneView: View {
    let milestone: StreakMilestone
    let streakWeeks: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 絵文字
                Text(milestone.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                // タイトル
                Text(milestone.localizedTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // サブタイトル
                Text(L10n.streakCongrats(streakWeeks))
                    .font(.title3)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer()

                // シェアボタン
                Button {
                    generateShareImage()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.shareAchievement)
                    }
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

                // 閉じるボタン
                Button {
                    onDismiss()
                } label: {
                    Text(L10n.close)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            HapticManager.workoutEnded()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [L10n.milestoneShareText(streakWeeks, AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
            }
        }
    }

    @MainActor
    private func generateShareImage() {
        let shareCard = MilestoneShareCard(milestone: milestone, streakWeeks: streakWeeks)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - マイルストーンシェアカード

private struct MilestoneShareCard: View {
    let milestone: StreakMilestone
    let streakWeeks: Int

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // ヘッダー
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

                Spacer()

                // 絵文字
                Text(milestone.emoji)
                    .font(.system(size: 80))

                // タイトル
                Text(milestone.localizedTitle)
                    .font(.title.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                // ストリーク数
                Text(L10n.weekStreak(streakWeeks))
                    .font(.title2)
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                // フッター
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
}

// MARK: - 未刺激警告

private struct NeglectedWarningView: View {
    let muscleInfos: [NeglectedMuscleInfo]
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.mmMuscleNeglected)
                Text(L10n.neglectedMuscles)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(muscleInfos) { info in
                    Text(info.muscle.localizedName)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.mmMuscleNeglected.opacity(0.2))
                        .foregroundStyle(Color.mmMuscleNeglected)
                        .clipShape(Capsule())
                }
            }

            // シェアボタン
            Button {
                prepareShareImage()
                showingShareSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.shareShame)
                }
                .font(.caption.bold())
                .foregroundStyle(Color.mmMuscleNeglected)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.mmMuscleNeglected.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                let worstMuscle = muscleInfos.first
                let shareText = L10n.neglectedShareText(
                    worstMuscle?.muscle.localizedName ?? "",
                    worstMuscle?.daysSinceStimulation ?? 0,
                    AppConstants.shareHashtag,
                    AppConstants.appStoreURL
                )
                ShareSheet(items: [shareText, image], onComplete: nil)
            }
        }
    }

    @MainActor
    private func prepareShareImage() {
        let shareCard = NeglectedShareCard(muscleInfos: muscleInfos)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 未刺激シェアカード

private struct NeglectedShareCard: View {
    let muscleInfos: [NeglectedMuscleInfo]

    private var neglectedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        // 未刺激の筋肉を紫表示用に設定（-1は特別な値として紫を示す）
        for info in muscleInfos {
            mapping[info.muscle.rawValue] = -1
        }
        return mapping
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション（紫系）
            LinearGradient(
                colors: [Color.mmMuscleNeglected, Color.mmMuscleNeglected.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // ヘッダー
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
                VStack(spacing: 4) {
                    Text("NEGLECTED ALERT ⚠️")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmMuscleNeglected)
                    Text(L10n.neglectedShareSubtitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                // 筋肉マップ（紫ハイライト）
                NeglectedMuscleMapView(neglectedMuscles: Set(muscleInfos.map { $0.muscle }))
                    .frame(height: 200)

                // 未刺激部位リスト
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(muscleInfos.prefix(5)) { info in
                        HStack {
                            Circle()
                                .fill(Color.mmMuscleNeglected)
                                .frame(width: 8, height: 8)
                            Text(info.muscle.localizedName)
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                            Spacer()
                            Text(L10n.daysNeglected(info.daysSinceStimulation))
                                .font(.caption)
                                .foregroundStyle(Color.mmMuscleNeglected)
                        }
                    }
                    if muscleInfos.count > 5 {
                        Text(L10n.andMoreCount(muscleInfos.count - 5))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // フッター
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmMuscleNeglected.opacity(0.3))
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
        .background(
            LinearGradient(
                colors: [Color.mmBgCard, Color.mmBgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmMuscleNeglected.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }

}

// MARK: - 未刺激筋肉マップビュー（紫ハイライト）

private struct NeglectedMuscleMapView: View {
    let neglectedMuscles: Set<Muscle>

    var body: some View {
        HStack(spacing: 20) {
            // 前面
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in MusclePathData.frontMuscles {
                    let path = entry.path(rect)
                    let isNeglected = neglectedMuscles.contains(entry.muscle)
                    let color = isNeglected ? Color.mmMuscleNeglected : Color.mmBgSecondary

                    context.fill(path, with: .color(color))
                    context.stroke(
                        path,
                        with: .color(Color.mmMuscleBorder.opacity(0.4)),
                        lineWidth: 0.5
                    )
                }
            }
            .frame(width: 100, height: 180)

            // 背面
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in MusclePathData.backMuscles {
                    let path = entry.path(rect)
                    let isNeglected = neglectedMuscles.contains(entry.muscle)
                    let color = isNeglected ? Color.mmMuscleNeglected : Color.mmBgSecondary

                    context.fill(path, with: .color(color))
                    context.stroke(
                        path,
                        with: .color(Color.mmMuscleBorder.opacity(0.4)),
                        lineWidth: 0.5
                    )
                }
            }
            .frame(width: 100, height: 180)
        }
    }
}

// MARK: - 凡例（3×2グリッド）

private struct MuscleMapLegend: View {
    private var items: [(Color, String)] {
        [
            (.mmMuscleCoral, L10n.highLoad),
            (.mmMuscleAmber, L10n.earlyRecovery),
            (.mmMuscleYellow, L10n.midRecovery),
            (.mmMuscleLime, L10n.lateRecovery),
            (.mmMuscleBioGreen, L10n.almostRecovered),
            (.mmMuscleNeglected, L10n.notStimulated),
        ]
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.0)
                        .frame(width: 10, height: 10)
                    Text(item.1)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }
}

// MARK: - FlowLayout（タグ表示用）

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

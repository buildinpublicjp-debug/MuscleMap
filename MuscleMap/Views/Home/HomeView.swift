import SwiftUI
import SwiftData

// MARK: - ホーム画面

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var streakViewModel = StreakViewModel()
    @State private var selectedMuscle: Muscle?
    @State private var showDemo = false
    @State private var showingAnalyticsMenu = false
    @State private var showingStrengthMap = false
    @State private var showingPaywall = false
    @State private var strengthScores: [String: Double] = [:]
    @State private var showCoachMark = false
    @State private var showMapExplanation = false
    @State private var showingExerciseLibrary = false
    @State private var recommendedWorkout: RecommendedWorkout?
    @State private var showingMenuPreview = false
    @State private var menuPreviewData: (RecommendedWorkout, SuggestedMenu)?

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
                            // 1. 週間ストリークバッジ（ワークアウト履歴がない場合は非表示）
                            WeeklyStreakBadge(
                                weeks: streakViewModel.currentStreak,
                                isCurrentWeekCompleted: streakViewModel.isCurrentWeekCompleted,
                                hasWorkoutHistory: hasWorkoutHistory
                            )

                            // 2. 90日チャレンジバナー（チャレンジ開始済み or 完了済みの場合のみ表示）
                            if AppState.shared.challengeActive || AppState.shared.challengeCompleted {
                                ChallengeProgressBanner(showingPaywall: $showingPaywall)
                                    .padding(.horizontal)
                            }

                            // 3. 筋肉マップ（メイン）- ホームの主役
                            ZStack(alignment: .top) {
                                MuscleMapView(
                                    muscleStates: vm.muscleStates,
                                    onMuscleTapped: { muscle in
                                        selectedMuscle = muscle
                                    },
                                    demoMode: showDemo
                                )
                                .frame(maxHeight: 500)

                                // 初回コーチマーク
                                if showCoachMark {
                                    HomeCoachMarkView {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            showCoachMark = false
                                        }
                                        AppState.shared.hasSeenHomeCoachMark = true
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                    .zIndex(10)
                                }

                                // 初回筋肉マップ説明オーバーレイ
                                if showMapExplanation {
                                    MapExplanationOverlay {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            showMapExplanation = false
                                        }
                                        AppState.shared.hasSeenMapExplanation = true
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    .zIndex(11)
                                }
                            }
                            .padding(.horizontal)

                            // 3. 今日のおすすめインライン（マップ直下）
                            TodayRecommendationInline(
                                suggestedMenu: vm.getSuggestedMenu(),
                                recommendation: recommendedWorkout,
                                hasWorkoutHistory: hasWorkoutHistory,
                                isPremium: PurchaseManager.shared.isPremium,
                                onStart: {
                                    HapticManager.lightTap()
                                    AppState.shared.selectedTab = 1
                                },
                                onStartWithMenu: { exercises in
                                    // 提案種目をAppStateに保存してワークアウトタブへ遷移
                                    AppState.shared.pendingRecommendedExercises = exercises
                                    AppState.shared.pendingRecommendationTrigger = UUID()
                                    AppState.shared.selectedTab = 1
                                },
                                onShowPaywall: {
                                    showingPaywall = true
                                },
                                onReviewMenu: { rec, menu in
                                    menuPreviewData = (rec, menu)
                                    showingMenuPreview = true
                                },
                                todayRoutine: vm.todayRoutine,
                                previousWeightProvider: { exerciseId in
                                    vm.previousWeight(for: exerciseId)
                                }
                            )
                            .padding(.horizontal)

                            // 4. Strength Mapエリア
                            if showingStrengthMap {
                                VStack(spacing: 8) {
                                    HStack {
                                        Label("Strength Map", systemImage: "bolt.shield.fill")
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.mmAccentPrimary)
                                        Spacer()
                                        Button {
                                            withAnimation { showingStrengthMap = false }
                                        } label: {
                                            Text(L10n.viewRecovery)
                                                .font(.caption2)
                                                .foregroundStyle(Color.mmAccentSecondary)
                                        }
                                    }
                                    .padding(.horizontal)

                                    StrengthMapView(muscleScores: strengthScores)
                                        .frame(maxHeight: 500)
                                        .padding(.horizontal)
                                }
                            } else if !PurchaseManager.shared.isPremium {
                                StrengthMapPreviewBanner {
                                    HapticManager.lightTap()
                                    showingPaywall = true
                                }
                                .padding(.horizontal)
                            } else {
                                Button {
                                    loadStrengthScores()
                                    withAnimation { showingStrengthMap = true }
                                    HapticManager.lightTap()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bolt.shield.fill")
                                            .foregroundStyle(Color.mmAccentPrimary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Strength Map")
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.mmTextPrimary)
                                            Text("筋力レベルを見る")
                                                .font(.caption2)
                                                .foregroundStyle(Color.mmTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(Color.mmTextSecondary)
                                    }
                                    .padding(16)
                                    .background(Color.mmBgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal)
                            }

                            // 5. 未刺激警告（該当する場合のみ）
                            if !vm.neglectedMuscleInfos.isEmpty {
                                NeglectedWarningView(muscleInfos: vm.neglectedMuscleInfos)
                                    .padding(.horizontal)
                            }

                            // 6. 凡例
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingExerciseLibrary = true
                    } label: {
                        Image(systemName: "book")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAnalyticsMenu = true
                    } label: {
                        Image(systemName: "chart.bar")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .onAppear {
                #if DEBUG
                let profile = AppState.shared.userProfile
                print("[DataFlow] primaryGoal: \(AppState.shared.primaryOnboardingGoal ?? \"nil\")")
                print("[DataFlow] frequency: \(profile.weeklyFrequency)")
                print("[DataFlow] location: \(profile.trainingLocation)")
                print("[DataFlow] priorityMuscles: \(profile.goalPriorityMuscles)")
                print("[DataFlow] experience: \(profile.trainingExperience.rawValue)")
                print("[DataFlow] initialPRs: \(profile.initialPRs)")
                print("[DataFlow] weightKg: \(profile.weightKg)")
                #endif

                Task {
                    if viewModel == nil {
                        viewModel = HomeViewModel(modelContext: modelContext)
                    }
                    viewModel?.loadMuscleStates()
                    viewModel?.checkActiveSession()
                    viewModel?.loadTodayRoutine()

                    // loadMuscleStates完了後にメニュー提案（ルーティン未設定時のみ）
                    if let vm = viewModel, vm.todayRoutine == nil {
                        if hasWorkoutHistory && PurchaseManager.shared.isPremium {
                            // 通常フロー: 回復データベースの提案
                            let menu = vm.getSuggestedMenu()
                            recommendedWorkout = WorkoutRecommendationEngine.generateRecommendation(
                                suggestedMenu: menu,
                                modelContext: modelContext
                            )
                        } else if !hasWorkoutHistory {
                            // 初回ユーザー: 目標ベースのフォールバック提案
                            recommendedWorkout = WorkoutRecommendationEngine.generateFirstTimeRecommendation(
                                modelContext: modelContext
                            )
                        }
                    }
                }

                // ストリーク計算
                streakViewModel.configure(with: modelContext)

                // マイルストーン達成チェック（achievedMilestoneがnon-nilなら自動でsheetが表示される）

                // 初回デモアニメーション
                if !AppState.shared.hasSeenDemoAnimation {
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        showDemo = true
                        AppState.shared.hasSeenDemoAnimation = true
                    }
                }

                // 初回コーチマーク表示判定（WorkoutSet 0件 & 未表示）
                if !AppState.shared.hasSeenHomeCoachMark {
                    let descriptor = FetchDescriptor<WorkoutSet>()
                    let count = (try? modelContext.fetchCount(descriptor)) ?? 0
                    if count == 0 {
                        Task {
                            try? await Task.sleep(for: .seconds(1.0))
                            withAnimation(.easeIn(duration: 0.3)) {
                                showCoachMark = true
                            }
                        }
                    }
                }

                // 初回筋肉マップ説明（オンボーディング完了直後、コーチマーク非該当時）
                if !AppState.shared.hasSeenMapExplanation && AppState.shared.hasSeenHomeCoachMark {
                    Task {
                        try? await Task.sleep(for: .seconds(0.8))
                        withAnimation(.easeIn(duration: 0.3)) {
                            showMapExplanation = true
                        }
                    }
                }
            }
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailView(muscle: muscle)
            }
            .sheet(item: $streakViewModel.achievedMilestone) { milestone in
                MilestoneView(
                    milestone: milestone,
                    streakWeeks: streakViewModel.currentStreak
                ) {
                    streakViewModel.dismissMilestone()
                }
            }
            .sheet(isPresented: $showingExerciseLibrary) {
                NavigationStack {
                    ExerciseLibraryView()
                }
            }
            .sheet(isPresented: $showingAnalyticsMenu) {
                AnalyticsMenuView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingMenuPreview) {
                if let (rec, menu) = menuPreviewData {
                    MenuPreviewSheet(
                        recommendation: rec,
                        suggestedMenu: menu,
                        onStart: { exercises in
                            showingMenuPreview = false
                            AppState.shared.pendingRecommendedExercises = exercises
                            AppState.shared.pendingRecommendationTrigger = UUID()
                            AppState.shared.selectedTab = 1
                        }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.mmBgSecondary)
                }
            }
        }
    }

    /// Strength Map用のスコアを計算
    private func loadStrengthScores() {
        let descriptor = FetchDescriptor<WorkoutSet>()
        guard let allSets = try? modelContext.fetch(descriptor) else { return }
        let bodyweight = AppState.shared.userProfile.weightKg
        strengthScores = StrengthScoreCalculator.shared.muscleStrengthScores(
            allSets: allSets,
            bodyweightKg: bodyweight
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

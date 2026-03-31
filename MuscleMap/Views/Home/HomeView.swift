import SwiftUI
import SwiftData

// MARK: - ホーム画面（Action-First レイアウト v2）

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var streakViewModel = StreakViewModel()
    @State private var selectedMuscle: Muscle?
    @State private var showDemo = false
    @State private var showingPaywall = false
    @State private var showCoachMark = false
    @State private var showMapExplanation = false
    @State private var showingExerciseLibrary = false
    @State private var showingRecoveryDetail = false
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
                        VStack(spacing: 16) {
                            // 1. TodayActionCard（今日のプラン + CTA）— 最上部
                            TodayActionCard(
                                viewModel: vm,
                                streakWeeks: streakViewModel.currentStreak,
                                isCurrentWeekCompleted: streakViewModel.isCurrentWeekCompleted,
                                hasWorkoutHistory: hasWorkoutHistory,
                                recommendedWorkout: recommendedWorkout,
                                onShowPaywall: { showingPaywall = true },
                                onStartWithMenu: { exercises in
                                    AppState.shared.pendingRecommendedExercises = exercises
                                    AppState.shared.pendingRecommendationTrigger = UUID()
                                    AppState.shared.selectedTab = 1
                                },
                                onReviewMenu: { rec, menu in
                                    menuPreviewData = (rec, menu)
                                    showingMenuPreview = true
                                },
                                onStart: {
                                    HapticManager.lightTap()
                                    AppState.shared.selectedTab = 1
                                }
                            )

                            // 2. RecoveryStatusSection（コンパクトマップ + ステータスチップ）
                            ZStack(alignment: .top) {
                                RecoveryStatusSection(
                                    muscleStates: vm.muscleStates,
                                    latestStimulations: vm.latestStimulations,
                                    onMuscleTapped: { muscle in
                                        selectedMuscle = muscle
                                        // レビュー要求（5回タップで発火）
                                        ReviewManager.recordMuscleTap()
                                    },
                                    onDetailsTapped: {
                                        showingRecoveryDetail = true
                                    }
                                )

                                // 初回コーチマーク（マップセクション上に表示）
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

                            // 3. Weekly Volume Chart
                            WeeklyVolumeChart()

                            // 4. 履歴ショートカット
                            HistoryShortcutButton()
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
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
            }
            .onAppear {
                #if DEBUG
                let profile = AppState.shared.userProfile
                print("[DataFlow] primaryGoal: \(AppState.shared.primaryOnboardingGoal ?? "nil")")
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
                            let menu = vm.getSuggestedMenu()
                            recommendedWorkout = WorkoutRecommendationEngine.generateRecommendation(
                                suggestedMenu: menu,
                                modelContext: modelContext
                            )
                        } else if !hasWorkoutHistory {
                            recommendedWorkout = WorkoutRecommendationEngine.generateFirstTimeRecommendation(
                                modelContext: modelContext
                            )
                        }
                    }
                }

                // ストリーク計算
                streakViewModel.configure(with: modelContext)

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
            .sheet(isPresented: $showingRecoveryDetail) {
                if let vm = viewModel {
                    RecoveryDetailView(
                        muscleStates: vm.muscleStates,
                        latestStimulations: vm.latestStimulations
                    )
                }
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

}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

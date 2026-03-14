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
    @State private var showingStrengthMap = false
    @State private var showingPaywall = false
    @State private var strengthScores: [String: Double] = [:]
    @State private var showCoachMark = false
    @State private var showingExerciseLibrary = false

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

                            // 2. 90日チャレンジバナー（初回ワークアウト完了後に表示）
                            if hasWorkoutHistory {
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
                            }
                            .padding(.horizontal)

                            // 3. 今日のおすすめインライン（マップ直下）
                            TodayRecommendationInline(
                                suggestedMenu: vm.getSuggestedMenu(),
                                hasWorkoutHistory: hasWorkoutHistory,
                                onStart: {
                                    HapticManager.lightTap()
                                    AppState.shared.selectedTab = 1
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
                                        Text("Strength Map")
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.mmTextPrimary)
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

                // 初回コーチマーク表示判定（WorkoutSet 0件 & 未表示）
                if !AppState.shared.hasSeenHomeCoachMark {
                    let descriptor = FetchDescriptor<WorkoutSet>()
                    let count = (try? modelContext.fetchCount(descriptor)) ?? 0
                    if count == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeIn(duration: 0.3)) {
                                showCoachMark = true
                            }
                        }
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

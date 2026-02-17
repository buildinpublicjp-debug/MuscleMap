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

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

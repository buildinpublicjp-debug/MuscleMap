import SwiftUI

// MARK: - ルートビュー（オンボーディング → メインタブ）

struct ContentView: View {
    @State private var appState = AppState.shared

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                withAnimation {
                    appState.hasCompletedOnboarding = true
                }
                // ペイウォールは初回ワークアウト完了後に表示（WorkoutCompletionViewで処理）
            }
        }
    }
}

// MARK: - メインTabView

private struct MainTabView: View {
    @State private var appState = AppState.shared
    @State private var previousTab: Int = 0
    @State private var showingPaywall = false
    @State private var showWorkoutLimitAlert = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(L10n.home, systemImage: "figure.stand")
                }
                .tag(0)

            WorkoutStartView()
                .tabItem {
                    Label(L10n.workout, systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)

            ExerciseDictionaryView()
                .tabItem {
                    Label(
                        LocalizationManager.shared.currentLanguage == .japanese ? "種目辞典" : "Exercises",
                        systemImage: "book.fill"
                    )
                }
                .tag(2)

            HistoryView()
                .tabItem {
                    Label(L10n.history, systemImage: "chart.bar")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(L10n.settings, systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(Color.mmAccentPrimary)
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            if newValue == 1 && !PurchaseManager.shared.canRecordWorkout {
                // 週間制限に達した場合はアラートで説明してからペイウォールへ
                appState.selectedTab = oldValue
                showWorkoutLimitAlert = true
            } else {
                previousTab = newValue
            }
        }
        .alert("今週の無料ワークアウト", isPresented: $showWorkoutLimitAlert) {
            Button("Proにアップグレード") {
                showingPaywall = true
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("無料プランでは週1回までワークアウトを記録できます。Proにアップグレードすると無制限に記録できます。")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isHardPaywall: false)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

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

            HistoryView()
                .tabItem {
                    Label(L10n.history, systemImage: "chart.bar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(L10n.settings, systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(Color.mmAccentPrimary)
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            if newValue == 1 && !PurchaseManager.shared.canRecordWorkout {
                // 週間制限に達した場合はペイウォールを表示
                appState.selectedTab = oldValue
                showingPaywall = true
            } else {
                previousTab = newValue
            }
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

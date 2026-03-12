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

            ActivityFeedView()
                .tabItem {
                    Label(L10n.feed, systemImage: "person.2.fill")
                }
                .tag(2)

            ExerciseLibraryView()
                .tabItem {
                    Label(L10n.exerciseLibrary, systemImage: "book")
                }
                .tag(3)

            HistoryView()
                .tabItem {
                    Label(L10n.history, systemImage: "chart.bar")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label(L10n.settings, systemImage: "gearshape")
                }
                .tag(5)
        }
        .tint(Color.mmAccentPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

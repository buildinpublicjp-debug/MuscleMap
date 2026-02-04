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
            }
        }
    }
}

// MARK: - メインTabView

private struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
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

            ExerciseLibraryView()
                .tabItem {
                    Label(L10n.exerciseLibrary, systemImage: "book")
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

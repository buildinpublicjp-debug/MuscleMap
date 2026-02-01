import SwiftUI

// MARK: - メインTabView

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "figure.stand")
                }
                .tag(0)

            WorkoutStartView()
                .tabItem {
                    Label("ワークアウト", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)

            ExerciseLibraryView()
                .tabItem {
                    Label("種目辞典", systemImage: "book")
                }
                .tag(2)

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "chart.bar")
                }
                .tag(3)
        }
        .tint(Color.mmAccentPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

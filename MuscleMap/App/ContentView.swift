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

            // Phase 4で実装
            HistoryPlaceholderView()
                .tabItem {
                    Label("履歴", systemImage: "chart.bar")
                }
                .tag(3)
        }
        .tint(Color.mmAccentPrimary)
    }
}

// MARK: - 履歴プレースホルダー（Phase 4で実装）

private struct HistoryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.mmTextSecondary)
                    Text("履歴・統計")
                        .font(.headline)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text("Phase 4で実装予定")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

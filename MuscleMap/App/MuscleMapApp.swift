import SwiftUI
import SwiftData

@main
struct MuscleMapApp: App {
    init() {
        // エクササイズデータを起動時に読み込み
        ExerciseStore.shared.load()

        // TabBar外観をダークに設定
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.mmBgSecondary)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // NavigationBar外観
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.mmBgPrimary)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            WorkoutSession.self,
            WorkoutSet.self,
            MuscleStimulation.self
        ])
    }
}

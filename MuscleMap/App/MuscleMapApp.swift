import SwiftUI
import SwiftData

@main
struct MuscleMapApp: App {
    init() {
        // エクササイズデータを起動時に読み込み
        ExerciseStore.shared.load()

        // 3Dモデルの可用性を判定
        ModelLoader.shared.evaluateModelAvailability()

        // 初回起動時の外観設定
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            WorkoutSession.self,
            WorkoutSet.self,
            MuscleStimulation.self
        ])
    }

    /// UIKit外観を設定
    private func configureAppearance() {
        // TabBar外観
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.mmBgSecondary)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // NavigationBar外観
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.mmBgPrimary)
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}

// MARK: - ルートビュー（テーマ監視）

struct RootView: View {
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        ContentView()
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

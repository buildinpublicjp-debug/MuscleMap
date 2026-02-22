import SwiftUI

// MARK: - MuscleMap Watch アプリエントリーポイント

@main
struct MuscleMapWatchApp: App {
    @State private var workoutManager = WatchWorkoutManager()

    var body: some Scene {
        WindowGroup {
            WatchExerciseListView()
                .environment(workoutManager)
                .onAppear {
                    WatchSessionDelegate.shared.workoutManager = workoutManager
                }
        }
    }
}

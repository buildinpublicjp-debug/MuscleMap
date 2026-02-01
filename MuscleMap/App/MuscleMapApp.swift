import SwiftUI
import SwiftData

@main
struct MuscleMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WorkoutSession.self,
            WorkoutSet.self,
            MuscleStimulation.self
        ])
    }
}

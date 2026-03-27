import SwiftUI

// MARK: - 種目辞典タブ（NavigationStack ラッパー）

struct ExerciseDictionaryView: View {
    var body: some View {
        NavigationStack {
            ExerciseLibraryView()
        }
    }
}

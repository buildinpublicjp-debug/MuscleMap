import SwiftUI

// MARK: - 旧目標設定画面（GoalSelectionPageに移行済み）
// PersonalizationPage は GoalSelectionPage のラッパー。後方互換のため残す。

struct PersonalizationPage: View {
    let onGoalSelected: () -> Void

    var body: some View {
        GoalSelectionPage(onNext: onGoalSelected)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        PersonalizationPage(onGoalSelected: {})
    }
}

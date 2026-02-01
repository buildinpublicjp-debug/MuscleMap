import SwiftUI

struct ContentView: View {
    var body: some View {
        // Phase 2でTabViewに置き換え
        ZStack {
            Color.mmBgPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.mmAccentPrimary)

                Text("MuscleMap")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Text("筋肉の状態が見える。だから、迷わない。")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
    }
}

#Preview {
    ContentView()
}

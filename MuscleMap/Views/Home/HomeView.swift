import SwiftUI
import SwiftData

// MARK: - ホーム画面

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showingWorkout = false
    @State private var selectedMuscle: Muscle?
    @State private var showDemo = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 継続日数バッジ
                            if vm.streakDays > 0 {
                                StreakBadge(days: vm.streakDays)
                            }

                            // 筋肉マップ
                            MuscleMapView(
                                muscleStates: vm.muscleStates,
                                onMuscleTapped: { muscle in
                                    selectedMuscle = muscle
                                },
                                demoMode: showDemo
                            )
                            .frame(maxHeight: 500)
                            .padding(.horizontal)

                            // 未刺激警告
                            if !vm.neglectedMuscles.isEmpty {
                                NeglectedWarningView(muscles: vm.neglectedMuscles)
                                    .padding(.horizontal)
                            }

                            // 凡例
                            MuscleMapLegend()
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("MuscleMap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MuscleMap")
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                viewModel?.loadMuscleStates()
                viewModel?.checkActiveSession()
                viewModel?.calculateStreak()

                // 初回デモアニメーション
                if !AppState.shared.hasSeenDemoAnimation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDemo = true
                        AppState.shared.hasSeenDemoAnimation = true
                    }
                }
            }
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailView(muscle: muscle)
            }
        }
    }
}

// MARK: - 継続日数バッジ

private struct StreakBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text(L10n.dayStreak(days))
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.mmBgCard)
        .clipShape(Capsule())
    }
}

// MARK: - 未刺激警告

private struct NeglectedWarningView: View {
    let muscles: [Muscle]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.mmMuscleNeglected)
                Text(L10n.neglectedMuscles)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(muscles) { muscle in
                    Text(muscle.localizedName)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.mmMuscleNeglected.opacity(0.2))
                        .foregroundStyle(Color.mmMuscleNeglected)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 凡例（3×2グリッド）

private struct MuscleMapLegend: View {
    private var items: [(Color, String)] {
        [
            (.mmMuscleCoral, L10n.highLoad),
            (.mmMuscleAmber, L10n.earlyRecovery),
            (.mmMuscleYellow, L10n.midRecovery),
            (.mmMuscleLime, L10n.lateRecovery),
            (.mmMuscleBioGreen, L10n.almostRecovered),
            (.mmMuscleNeglected, L10n.notStimulated),
        ]
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.0)
                        .frame(width: 10, height: 10)
                    Text(item.1)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }
}

// MARK: - FlowLayout（タグ表示用）

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

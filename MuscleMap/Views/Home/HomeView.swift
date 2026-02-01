import SwiftUI
import SwiftData

// MARK: - ホーム画面

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showingWorkout = false
    @State private var selectedMuscle: Muscle?

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
                                }
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
            }
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailSheet(muscle: muscle)
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
            Text("\(days)日連続")
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
                Text("未刺激の部位")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(muscles) { muscle in
                    Text(muscle.japaneseName)
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

// MARK: - 凡例

private struct MuscleMapLegend: View {
    private let items: [(Color, String)] = [
        (.mmMuscleJustWorked, "高負荷"),
        (.mmMuscleCoral, "回復中"),
        (.mmMuscleAmber, "回復中"),
        (.mmMuscleMint, "回復中"),
        (.mmMuscleBioGreen, "ほぼ回復"),
        (.mmMuscleNeglected, "未刺激"),
    ]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items, id: \.1) { item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.0)
                        .frame(width: 8, height: 8)
                    Text(item.1)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }
}

// MARK: - 筋肉詳細シート

private struct MuscleDetailSheet: View {
    let muscle: Muscle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(muscle.japaneseName)
                        .font(.title2.bold())
                        .foregroundStyle(Color.mmTextPrimary)

                    Text("グループ: \(muscle.group.japaneseName)")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)

                    Text("基準回復時間: \(muscle.baseRecoveryHours)時間")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(muscle.japaneseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium])
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

import SwiftUI
import SwiftData

// MARK: - 部位詳細画面

struct MuscleDetailView: View {
    let muscle: Muscle

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MuscleDetailViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 3D/2Dビジュアル
                            Muscle3DView(
                                muscle: muscle,
                                visualState: vm.recoveryStatus.visualState
                            )
                            .padding(.horizontal)

                            // 回復ステータスカード
                            RecoveryStatusCard(viewModel: vm)
                                .padding(.horizontal)

                            // 基本情報
                            MuscleInfoCard(muscle: muscle)
                                .padding(.horizontal)

                            // 関連種目
                            if !vm.relatedExercises.isEmpty {
                                RelatedExercisesSection(
                                    muscle: muscle,
                                    exercises: vm.relatedExercises
                                )
                            }

                            // 直近の履歴
                            if !vm.recentSets.isEmpty {
                                RecentHistorySection(
                                    recentSets: vm.recentSets
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(muscle.japaneseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = MuscleDetailViewModel(muscle: muscle, modelContext: modelContext)
                }
                viewModel?.load()
            }
        }
    }
}

// MARK: - 回復ステータスカード

private struct RecoveryStatusCard: View {
    let viewModel: MuscleDetailViewModel

    var body: some View {
        VStack(spacing: 16) {
            // ステータスヘッダー
            HStack {
                statusIcon
                Text(statusText)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
            }

            // プログレスバー
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.mmBgPrimary)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressColor)
                            .frame(width: geo.size.width * viewModel.recoveryProgress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(Int(viewModel.recoveryProgress * 100))%")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(progressColor)

                    Spacer()

                    if let remaining = viewModel.remainingHours {
                        Text("残り\(formatHours(remaining))")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    } else {
                        Text("回復完了")
                            .font(.caption)
                            .foregroundStyle(Color.mmMuscleBioGreen)
                    }
                }
            }

            // 詳細情報
            HStack(spacing: 24) {
                if let date = viewModel.lastStimulationDate {
                    DetailItem(
                        label: "最終刺激",
                        value: formatDate(date)
                    )
                }

                if viewModel.lastTotalSets > 0 {
                    DetailItem(
                        label: "セット数",
                        value: "\(viewModel.lastTotalSets)セット"
                    )
                }

                if let recoveryDate = viewModel.estimatedRecoveryDate {
                    DetailItem(
                        label: "回復予定",
                        value: formatDate(recoveryDate)
                    )
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusIcon: some View {
        Group {
            switch viewModel.recoveryStatus {
            case .recovering:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(progressColor)
            case .fullyRecovered:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.mmMuscleBioGreen)
            case .neglected:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.mmMuscleNeglected)
            case .neglectedSevere:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.mmMuscleNeglected)
            }
        }
        .font(.title3)
    }

    private var statusText: String {
        switch viewModel.recoveryStatus {
        case .recovering(let progress):
            if progress < 0.3 { return "高負荷 — 休息が必要" }
            if progress < 0.7 { return "回復中" }
            return "ほぼ回復"
        case .fullyRecovered:
            return "完全回復 — トレーニング可能"
        case .neglected:
            return "未刺激 — 7日以上"
        case .neglectedSevere:
            return "未刺激 — 14日以上"
        }
    }

    private var progressColor: Color {
        viewModel.recoveryStatus.visualState.color == .clear
            ? Color.mmMuscleBioGreen
            : viewModel.recoveryStatus.visualState.color
    }

    private func formatHours(_ hours: Double) -> String {
        if hours >= 24 {
            return "\(Int(hours / 24))日\(Int(hours.truncatingRemainder(dividingBy: 24)))時間"
        }
        return "\(Int(hours))時間"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 詳細項目

private struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextPrimary)
        }
    }
}

// MARK: - 筋肉基本情報カード

private struct MuscleInfoCard: View {
    let muscle: Muscle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本情報")
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            HStack(spacing: 16) {
                InfoBlock(
                    icon: "figure.stand",
                    label: "グループ",
                    value: muscle.group.japaneseName
                )

                InfoBlock(
                    icon: "clock",
                    label: "基準回復",
                    value: "\(muscle.baseRecoveryHours)時間"
                )

                InfoBlock(
                    icon: "scalemass",
                    label: "サイズ",
                    value: muscleSizeLabel
                )
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var muscleSizeLabel: String {
        switch muscle.baseRecoveryHours {
        case 72: return "大筋群"
        case 48: return "中筋群"
        default: return "小筋群"
        }
    }
}

private struct InfoBlock: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.mmAccentSecondary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)

            Text(value)
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 関連種目セクション

private struct RelatedExercisesSection: View {
    let muscle: Muscle
    let exercises: [ExerciseDefinition]
    @State private var selectedExercise: ExerciseDefinition?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("関連種目（刺激度%順）")
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
                .padding(.horizontal)

            ForEach(exercises.prefix(10)) { exercise in
                Button {
                    selectedExercise = exercise
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.nameJA)
                                .font(.subheadline)
                                .foregroundStyle(Color.mmTextPrimary)
                            Text(exercise.equipment)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                        }

                        Spacer()

                        // 刺激度%
                        let percentage = exercise.stimulationPercentage(for: muscle)
                        Text("\(percentage)%")
                            .font(.subheadline.monospaced().bold())
                            .foregroundStyle(stimulationColor(percentage))

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding()
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    private func stimulationColor(_ percentage: Int) -> Color {
        switch percentage {
        case 80...: return .mmMuscleJustWorked
        case 50..<80: return .mmMuscleAmber
        default: return .mmMuscleMint
        }
    }
}

// MARK: - 直近の履歴セクション

private struct RecentHistorySection: View {
    let recentSets: [(exercise: ExerciseDefinition, set: WorkoutSet)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近の記録")
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
                .padding(.horizontal)

            ForEach(recentSets.prefix(10), id: \.set.id) { entry in
                HStack {
                    Text(entry.exercise.nameJA)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(entry.set.weight, specifier: "%.1f")kg × \(entry.set.reps)回")
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.mmAccentPrimary)

                    Text(formatDate(entry.set.completedAt))
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    MuscleDetailView(muscle: .chestUpper)
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

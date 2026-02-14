import SwiftUI
import SwiftData

// MARK: - 部位詳細画面

struct MuscleDetailView: View {
    let muscle: Muscle

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MuscleDetailViewModel?
    private var localization: LocalizationManager { LocalizationManager.shared }

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
            .navigationTitle(localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
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
    private var localization: LocalizationManager { LocalizationManager.shared }

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
                        Text(formatRemainingTime(remaining))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    } else {
                        Text(L10n.recoveryComplete)
                            .font(.caption)
                            .foregroundStyle(Color.mmMuscleBioGreen)
                    }
                }
            }

            // 詳細情報
            HStack(spacing: 24) {
                if let date = viewModel.lastStimulationDate {
                    DetailItem(
                        label: L10n.lastStimulation,
                        value: formatDate(date)
                    )
                }

                if viewModel.lastTotalSets > 0 {
                    DetailItem(
                        label: L10n.setCount,
                        value: L10n.setsLabel(viewModel.lastTotalSets)
                    )
                }

                if let recoveryDate = viewModel.estimatedRecoveryDate {
                    DetailItem(
                        label: L10n.estimatedRecovery,
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
            if progress < 0.3 { return L10n.highLoadRestNeeded }
            if progress < 0.7 { return L10n.recovering }
            return L10n.almostRecovered
        case .fullyRecovered:
            return L10n.fullyRecoveredTrainable
        case .neglected:
            return L10n.neglected7Days
        case .neglectedSevere:
            return L10n.neglected14Days
        }
    }

    private var progressColor: Color {
        viewModel.recoveryStatus.visualState.color == .clear
            ? Color.mmMuscleBioGreen
            : viewModel.recoveryStatus.visualState.color
    }

    private func formatRemainingTime(_ hours: Double) -> String {
        let h = Int(hours)
        if h >= 24 {
            let days = h / 24
            let remainingHours = h % 24
            return localization.currentLanguage == .japanese
                ? "残り\(days)日\(remainingHours)時間"
                : "\(days)d \(remainingHours)h remaining"
        }
        return localization.currentLanguage == .japanese
            ? "残り\(h)時間"
            : "\(h)h remaining"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = localization.currentLanguage == .japanese
            ? Locale(identifier: "ja_JP")
            : Locale(identifier: "en_US")
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
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.basicInfo)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            HStack(spacing: 16) {
                InfoBlock(
                    icon: "figure.stand",
                    label: L10n.muscleGroup,
                    value: muscle.group.localizedName
                )

                InfoBlock(
                    icon: "clock",
                    label: L10n.baseRecovery,
                    value: L10n.hoursUnit(muscle.baseRecoveryHours)
                )

                InfoBlock(
                    icon: "scalemass",
                    label: L10n.size,
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
        case 72: return L10n.largeMuscle
        case 48: return L10n.mediumMuscle
        default: return L10n.smallMuscle
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
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.relatedExercises)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
                .padding(.horizontal)

            ForEach(exercises.prefix(10)) { exercise in
                Button {
                    selectedExercise = exercise
                } label: {
                    HStack(spacing: 12) {
                        // サムネイル（小さめ）
                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                            ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                                .frame(width: 40, height: 40)
                                .background(Color.mmBgPrimary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        // 種目情報
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(exercise.localizedEquipment)
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }

                        Spacer()

                        // 刺激度%
                        let percentage = exercise.stimulationPercentage(for: muscle)
                        Text("\(percentage)%")
                            .font(.subheadline.monospaced().bold())
                            .foregroundStyle(stimulationColor(percentage))

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
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
        default: return .mmMuscleLime
        }
    }
}

// MARK: - 直近の履歴セクション

private struct RecentHistorySection: View {
    let recentSets: [(exercise: ExerciseDefinition, set: WorkoutSet)]
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.recentRecords)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
                .padding(.horizontal)

            ForEach(recentSets.prefix(10), id: \.set.id) { entry in
                HStack {
                    Text(localization.currentLanguage == .japanese ? entry.exercise.nameJA : entry.exercise.nameEN)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(L10n.weightReps(entry.set.weight, entry.set.reps))
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
        formatter.locale = localization.currentLanguage == .japanese
            ? Locale(identifier: "ja_JP")
            : Locale(identifier: "en_US")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    MuscleDetailView(muscle: .chestUpper)
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

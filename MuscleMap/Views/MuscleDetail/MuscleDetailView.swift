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
                        VStack(spacing: 8) {
                            // 1. 回復ゲージ（最上部）
                            RecoveryGaugeCard(viewModel: vm)
                                .padding(.horizontal)

                            // 2. 2Dマップハイライト
                            Muscle3DView(
                                muscle: muscle,
                                visualState: vm.recoveryStatus.visualState
                            )
                            .padding(.horizontal)

                            // 筋肉名テキスト（日本語 22pt bold + 英語 14pt）
                            VStack(spacing: 4) {
                                Text(muscle.japaneseName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color.mmTextPrimary)
                                Text(muscle.englishName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                            .padding(.horizontal)

                            // 3. 関連種目（GIF拡大）
                            if !vm.allRelatedExercises.isEmpty {
                                RelatedExercisesSection(
                                    muscle: muscle,
                                    viewModel: vm
                                )
                            }

                            // 4. 直近の履歴
                            if !vm.recentSets.isEmpty {
                                RecentHistorySection(
                                    recentSets: vm.recentSets
                                )
                            }
                        }
                        .padding(.vertical, 8)
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

// MARK: - 回復ゲージカード（最上部に配置）

private struct RecoveryGaugeCard: View {
    let viewModel: MuscleDetailViewModel
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        if viewModel.lastStimulationDate != nil {
            // 刺激記録あり → 回復ゲージ表示
            VStack(spacing: 8) {
                HStack {
                    // 回復ステータスアイコン
                    statusIcon
                    Text(statusText)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)

                    Spacer()

                    Text(recoveryDetailText)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                // プログレスバー
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.mmBgCard)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geo.size.width * viewModel.recoveryProgress, height: 8)
                    }
                }
                .frame(height: 8)

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
            .padding(16)
            .background(Color.mmBgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            // 未刺激 → フォールバック表示
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.mmTextSecondary)
                Text(L10n.noRecord)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
            }
            .padding(16)
            .background(Color.mmBgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var statusIcon: some View {
        Group {
            switch viewModel.recoveryStatus {
            case .recovering:
                Image(systemName: "clock.fill")
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
        .font(.subheadline)
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

    private var recoveryDetailText: String {
        if let remaining = viewModel.remainingHours {
            return formatRemainingTime(remaining)
        }
        return L10n.recoveryComplete
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
    @Bindable var viewModel: MuscleDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedExercise: ExerciseDefinition?
    private var localization: LocalizationManager { LocalizationManager.shared }

    private func lastRecord(for exerciseId: String) -> WorkoutSet? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // セクションヘッダー
            HStack {
                Text(L10n.relatedExercises)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(viewModel.filteredExercises.count)\(L10n.exerciseUnit)")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal)

            // 場所フィルタ（セグメントコントロール）
            Picker("", selection: $viewModel.locationFilter) {
                ForEach(LocationFilter.allCases, id: \.self) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 種目カード（GIF 80x80 + テキスト横並び）
            if viewModel.filteredExercises.isEmpty {
                Text(L10n.noExercisesForLocation)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.filteredExercises.prefix(10)) { exercise in
                    Button {
                        HapticManager.lightTap()
                        selectedExercise = exercise
                    } label: {
                        exerciseCard(exercise)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    // MARK: - 種目カード（横レイアウト — GIF 80x80）

    @ViewBuilder
    private func exerciseCard(_ exercise: ExerciseDefinition) -> some View {
        HStack(spacing: 12) {
            // 左: GIF 80x80 / 筋肉マップフォールバック
            Group {
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                        .frame(width: 80, height: 80)
                } else {
                    MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                        .padding(4)
                        .frame(width: 80, height: 80)
                        .background(Color.mmBgPrimary.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 中央: 種目情報
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // 器具
                Text(exercise.localizedEquipment)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                // 刺激度バッジ
                if let primary = exercise.primaryMuscle {
                    Text(primary.localizedName)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.mmAccentPrimary.opacity(0.2))
                        .foregroundStyle(Color.mmAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // 前回記録
                if let record = lastRecord(for: exercise.id) {
                    Text(L10n.lastRecordLabel(record.weight, record.reps))
                        .font(.caption2.monospaced().bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(12)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        .minimumScaleFactor(0.7)

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

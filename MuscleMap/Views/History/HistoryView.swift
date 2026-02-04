import SwiftUI
import SwiftData
import Charts

// MARK: - 履歴・統計画面

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @State private var selectedPeriod: StatPeriod = .weekly
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 期間セレクター
                            periodPicker

                            // サマリーカード
                            if selectedPeriod == .weekly {
                                WeeklySummaryCard(stats: vm.weeklyStats)
                            } else {
                                MonthlySummaryCard(stats: vm.monthlyStats)
                            }

                            // ボリュームチャート
                            VolumeChartCard(data: vm.dailyVolumeData)

                            // グループ別ボリューム
                            GroupVolumeCard(volume: vm.weeklyGroupVolume)

                            // よく行う種目
                            if !vm.topExercises.isEmpty {
                                TopExercisesCard(exercises: vm.topExercises)
                            }

                            // セッション履歴
                            SessionHistorySection(sessions: vm.sessions)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.history)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !PurchaseManager.shared.canAccessPremiumFeatures {
                        Button {
                            showingPaywall = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HistoryViewModel(modelContext: modelContext)
                }
                viewModel?.load()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - 期間ピッカー

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatPeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(selectedPeriod == period ? Color.mmBgPrimary : Color.mmTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color.mmAccentPrimary : Color.clear)
                }
            }
        }
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 期間

enum StatPeriod: String, CaseIterable, Identifiable {
    case weekly
    case monthly

    var id: String { rawValue }

    @MainActor var label: String {
        switch self {
        case .weekly: return L10n.weekly
        case .monthly: return L10n.monthly
        }
    }
}

// MARK: - 週間サマリーカード

private struct WeeklySummaryCard: View {
    let stats: WeeklyStats

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.thisWeekSummary)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                StatItem(value: "\(stats.sessionCount)", label: L10n.sessions, icon: "figure.strengthtraining.traditional")
                StatItem(value: "\(stats.totalSets)", label: L10n.totalSets, icon: "number")
                StatItem(value: formatVolume(stats.totalVolume), label: L10n.totalVolume, icon: "scalemass")
                StatItem(value: "\(stats.trainingDays)", label: L10n.trainingDays, icon: "calendar")
            }

            // グループカバー率
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .foregroundStyle(Color.mmAccentPrimary)
                    .font(.caption)
                Text(L10n.groupCoverage)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text("\(stats.stimulatedGroupCount)/\(stats.totalGroupCount)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            // カバー率バー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmBgSecondary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmAccentPrimary)
                        .frame(width: geo.size.width * coverageRatio, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var coverageRatio: CGFloat {
        guard stats.totalGroupCount > 0 else { return 0 }
        return CGFloat(stats.stimulatedGroupCount) / CGFloat(stats.totalGroupCount)
    }
}

// MARK: - 月間サマリーカード

private struct MonthlySummaryCard: View {
    let stats: MonthlyStats

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.thisMonthSummary)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                StatItem(value: "\(stats.sessionCount)", label: L10n.sessions, icon: "figure.strengthtraining.traditional")
                StatItem(value: "\(stats.totalSets)", label: L10n.totalSets, icon: "number")
                StatItem(value: formatVolume(stats.totalVolume), label: L10n.totalVolume, icon: "scalemass")
                StatItem(value: "\(stats.trainingDays)", label: L10n.trainingDays, icon: "calendar")
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 統計アイテム

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ボリュームチャート（14日間）

private struct VolumeChartCard: View {
    let data: [DailyVolume]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.dailyVolume14Days)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            if data.allSatisfy({ $0.volume == 0 }) {
                emptyChartView
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(
                        item.volume > 0
                            ? Color.mmAccentPrimary.gradient
                            : Color.mmBgSecondary.gradient
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.mmTextSecondary)
                        AxisGridLine()
                            .foregroundStyle(Color.mmBgSecondary)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyChartView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title2)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            Text(L10n.noData)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}

// MARK: - グループ別ボリュームカード

private struct GroupVolumeCard: View {
    let volume: [MuscleGroup: Int]
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var sortedGroups: [(group: MuscleGroup, sets: Int)] {
        MuscleGroup.allCases.map { group in
            (group: group, sets: volume[group] ?? 0)
        }
    }

    private var maxSets: Int {
        sortedGroups.map(\.sets).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.groupSetsThisWeek)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            VStack(spacing: 8) {
                ForEach(sortedGroups, id: \.group) { item in
                    HStack(spacing: 8) {
                        Text(localization.currentLanguage == .japanese ? item.group.japaneseName : item.group.englishName)
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                            .frame(width: 48, alignment: .trailing)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.mmBgSecondary)
                                    .frame(height: 12)
                                if item.sets > 0 {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colorForGroup(item.group))
                                        .frame(width: max(4, geo.size.width * barRatio(item.sets)), height: 12)
                                }
                            }
                        }
                        .frame(height: 12)

                        Text("\(item.sets)")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func barRatio(_ sets: Int) -> CGFloat {
        guard maxSets > 0 else { return 0 }
        return CGFloat(sets) / CGFloat(maxSets)
    }

    private func colorForGroup(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: return .mmMuscleJustWorked
        case .back: return .mmAccentSecondary
        case .shoulders: return .mmMuscleAmber
        case .arms: return .mmMuscleCoral
        case .core: return .mmMuscleLime
        case .lowerBody: return .mmAccentPrimary
        }
    }
}

// MARK: - よく行う種目カード

private struct TopExercisesCard: View {
    let exercises: [(exercise: ExerciseDefinition, count: Int)]
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.topExercises)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            ForEach(Array(exercises.enumerated()), id: \.element.exercise.id) { index, item in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.currentLanguage == .japanese ? item.exercise.nameJA : item.exercise.nameEN)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(item.exercise.category)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }

                    Spacer()

                    Text(L10n.setsLabel(item.count))
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.vertical, 4)

                if index < exercises.count - 1 {
                    Divider()
                        .background(Color.mmBgSecondary)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - セッション履歴

private struct SessionHistorySection: View {
    let sessions: [WorkoutSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.sessionHistory)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                    Text(L10n.noSessionsYet)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(sessions) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - セッション行

private struct SessionRowView: View {
    let session: WorkoutSession
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var exerciseNames: String {
        let ids = Set(session.sets.map(\.exerciseId))
        let names = ids.compactMap { id -> String? in
            guard let exercise = ExerciseStore.shared.exercise(for: id) else { return nil }
            return localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
        }
        let displayNames = names.prefix(3).joined(separator: ", ")
        return names.count > 3 ? "\(displayNames) \(L10n.andMore)" : displayNames
    }

    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private var duration: String {
        guard let end = session.endDate else { return L10n.inProgress }
        let interval = end.timeIntervalSince(session.startDate)
        let minutes = Int(interval / 60)
        return L10n.minutes(minutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(duration)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            Text(exerciseNames)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)

            HStack(spacing: 16) {
                Label(L10n.setsLabel(session.sets.count), systemImage: "number")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Label(formatVolume(totalVolume), systemImage: "scalemass")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.vertical, 8)

        Divider()
            .background(Color.mmBgSecondary)
    }
}

// MARK: - ヘルパー

private func formatVolume(_ volume: Double) -> String {
    if volume >= 1000 {
        return String(format: "%.1fk", volume / 1000)
    }
    return String(format: "%.0f", volume)
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

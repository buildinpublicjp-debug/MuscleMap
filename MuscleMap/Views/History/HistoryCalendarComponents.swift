import SwiftUI
import Charts

// MARK: - カレンダー表示

struct HistoryCalendarView: View {
    let viewModel: HistoryViewModel
    let onDateSelected: (Date) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 月間カレンダー（カラーバー付き）
                MonthlyCalendarView(
                    workoutDates: viewModel.workoutDates,
                    dailyMuscleGroups: viewModel.dailyMuscleGroups
                ) { date in
                    onDateSelected(date)
                }

                // 月間サマリーカード
                MonthlySummaryCard(stats: viewModel.monthlyStats)

                // ボリュームチャート
                VolumeChartCard(data: viewModel.dailyVolumeData)

                // グループ別ボリューム
                GroupVolumeCard(volume: viewModel.weeklyGroupVolume)

                // よく行う種目
                if !viewModel.topExercises.isEmpty {
                    TopExercisesCard(exercises: viewModel.topExercises)
                }

                // セッション履歴
                SessionHistorySection(sessions: viewModel.sessions)
            }
            .padding()
        }
    }
}

// MARK: - ボリュームチャート（14日間）

struct VolumeChartCard: View {
    let data: [DailyVolume]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

struct GroupVolumeCard: View {
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
        VStack(alignment: .leading, spacing: 16) {
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
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.mmBgSecondary)
                                    .frame(height: 12)
                                if item.sets > 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorForGroup(item.group))
                                        .frame(width: max(4, geo.size.width * barRatio(item.sets)), height: 12)
                                }
                            }
                        }
                        .frame(height: 12)

                        Text("\(item.sets)")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(Color.mmAccentPrimary)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

struct TopExercisesCard: View {
    let exercises: [(exercise: ExerciseDefinition, count: Int)]
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.topExercises)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            ForEach(Array(exercises.enumerated()), id: \.element.exercise.id) { index, item in
                HStack(spacing: 12) {
                    // ランク番号
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                        .frame(width: 20)

                    // ミニ筋肉マップ（ビジュアル要素）
                    MiniMuscleMapView(muscleMapping: item.exercise.muscleMapping)
                        .frame(width: 32, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.currentLanguage == .japanese ? item.exercise.nameJA : item.exercise.nameEN)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(item.exercise.localizedEquipment)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }

                    Spacer()

                    Text("\(item.count)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color.mmAccentPrimary)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

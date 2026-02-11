import SwiftUI
import SwiftData
import Charts

// MARK: - 履歴・統計画面

/// 履歴画面の表示モード
enum HistoryViewMode: String, CaseIterable {
    case map = "マップ"
    case calendar = "カレンダー"

    var englishName: String {
        switch self {
        case .map: return "Map"
        case .calendar: return "Calendar"
        }
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @State private var showingPaywall = false
    @State private var selectedCalendarDate: SelectedDate?
    @State private var selectedMuscle: SelectedMuscle?
    @State private var viewMode: HistoryViewMode = .map
    private var localization: LocalizationManager { LocalizationManager.shared }

    /// シート表示用のラッパー（Identifiable対応）
    struct SelectedDate: Identifiable {
        let id = UUID()
        let date: Date
    }

    struct SelectedMuscle: Identifiable {
        let id = UUID()
        let muscle: Muscle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    VStack(spacing: 0) {
                        // セグメントコントロール
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(HistoryViewMode.allCases, id: \.self) { mode in
                                Text(localization.currentLanguage == .japanese ? mode.rawValue : mode.englishName)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                        // コンテンツ切り替え
                        switch viewMode {
                        case .map:
                            HistoryMapView(
                                viewModel: vm,
                                onMuscleTap: { muscle in
                                    selectedMuscle = SelectedMuscle(muscle: muscle)
                                }
                            )
                        case .calendar:
                            HistoryCalendarView(
                                viewModel: vm,
                                onDateSelected: { date in
                                    selectedCalendarDate = SelectedDate(date: date)
                                }
                            )
                        }
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
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Pro")
                                    .font(.caption.bold())
                            }
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
            .sheet(item: $selectedCalendarDate) { selected in
                DayWorkoutDetailView(date: selected.date)
            }
            .sheet(item: $selectedMuscle) { selected in
                if let vm = viewModel {
                    MuscleHistoryDetailSheet(
                        detail: vm.getMuscleHistoryDetail(for: selected.muscle),
                        period: vm.selectedPeriod
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

// MARK: - 月間サマリーカード（改善版）

private struct MonthlySummaryCard: View {
    let stats: MonthlyStats
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(L10n.thisMonthSummary)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                BigStatItem(
                    value: "\(stats.sessionCount)",
                    label: localization.currentLanguage == .japanese ? "セッション" : "Sessions",
                    icon: "figure.strengthtraining.traditional"
                )
                BigStatItem(
                    value: "\(stats.totalSets)",
                    label: localization.currentLanguage == .japanese ? "セット数" : "Sets",
                    icon: "number"
                )
                BigStatItem(
                    value: formatVolume(stats.totalVolume),
                    label: localization.currentLanguage == .japanese ? "総ボリューム" : "Volume",
                    icon: "scalemass"
                )
                BigStatItem(
                    value: "\(stats.trainingDays)",
                    label: localization.currentLanguage == .japanese ? "トレ日数" : "Days",
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                            .frame(width: 24, alignment: .trailing)
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

private struct TopExercisesCard: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - セッション履歴

private struct SessionHistorySection: View {
    let sessions: [WorkoutSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

    /// セッション内の種目から筋肉マッピングを集約
    private var aggregatedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        let ids = Set(session.sets.map(\.exerciseId))
        for id in ids {
            guard let exercise = ExerciseStore.shared.exercise(for: id) else { continue }
            for (muscle, intensity) in exercise.muscleMapping {
                mapping[muscle] = max(mapping[muscle] ?? 0, intensity)
            }
        }
        return mapping
    }

    var body: some View {
        HStack(spacing: 12) {
            // ミニ筋肉マップ（ビジュアル要素）
            MiniMuscleMapView(muscleMapping: aggregatedMuscleMapping)
                .frame(width: 36, height: 48)

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

// MARK: - マップ表示（新規）

private struct HistoryMapView: View {
    let viewModel: HistoryViewModel
    let onMuscleTap: (Muscle) -> Void
    @State private var showFront = true
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 16) {
            // 期間セレクター
            PeriodSelector(
                selectedPeriod: viewModel.selectedPeriod,
                onPeriodChanged: { period in
                    viewModel.updatePeriod(period)
                }
            )

            // 筋肉マップカード
            VStack(spacing: 16) {
                // 前面/背面トグル（改善版）
                HStack {
                    // 現在の表示面
                    HStack(spacing: 6) {
                        Image(systemName: showFront ? "person.fill" : "person.fill")
                            .font(.caption)
                        Text(showFront
                            ? (localization.currentLanguage == .japanese ? "前面" : "Front")
                            : (localization.currentLanguage == .japanese ? "背面" : "Back")
                        )
                        .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color.mmTextPrimary)

                    Spacer()

                    // トグルボタン
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showFront.toggle()
                        }
                        HapticManager.lightTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption.weight(.medium))
                            Text(showFront
                                ? (localization.currentLanguage == .japanese ? "背面を見る" : "View Back")
                                : (localization.currentLanguage == .japanese ? "前面を見る" : "View Front")
                            )
                            .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.mmAccentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mmAccentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                // 筋肉マップ（ホーム画面と同じ表示品質を維持）
                HistoryMuscleMapCanvas(
                    muscleSets: viewModel.periodMuscleSets,
                    showFront: showFront,
                    onMuscleTap: { muscle in
                        HapticManager.lightTap()
                        onMuscleTap(muscle)
                    }
                )
                .aspectRatio(0.6, contentMode: .fit)
                .frame(maxHeight: 380)

                // 凡例
                HistoryMapLegend()
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer(minLength: 0)
        }
        .padding()
    }
}

// MARK: - 期間セレクター（改善版）

private struct PeriodSelector: View {
    let selectedPeriod: HistoryPeriod
    let onPeriodChanged: (HistoryPeriod) -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(HistoryPeriod.allCases, id: \.self) { period in
                Button {
                    onPeriodChanged(period)
                    HapticManager.lightTap()
                } label: {
                    Text(localization.currentLanguage == .japanese ? period.rawValue : period.englishName)
                        .font(.subheadline.weight(selectedPeriod == period ? .bold : .medium))
                        .foregroundStyle(selectedPeriod == period ? Color.mmBgPrimary : Color.mmTextPrimary.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedPeriod == period {
                                    LinearGradient(
                                        colors: [Color.mmAccentPrimary, Color.mmAccentPrimary.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                } else {
                                    Color.mmBgSecondary.opacity(0.6)
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedPeriod == period ? Color.clear : Color.mmTextSecondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                }
            }
            Spacer()
        }
    }
}

// MARK: - 履歴筋肉マップキャンバス

private struct HistoryMuscleMapCanvas: View {
    let muscleSets: [Muscle: Int]
    let showFront: Bool
    let onMuscleTap: (Muscle) -> Void

    private var maxSets: Int {
        max(1, muscleSets.values.max() ?? 1)
    }

    var body: some View {
        let muscles = showFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            // Draw all muscle paths
            for entry in muscles {
                let sets = muscleSets[entry.muscle] ?? 0
                let path = entry.path(rect)

                // Fill
                context.fill(path, with: .color(colorForSets(sets)))

                // Stroke
                context.stroke(path, with: .color(Color.mmMuscleBorder.opacity(0.3)), lineWidth: 0.5)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Find the first muscle with workout data
            for entry in muscles {
                if let sets = muscleSets[entry.muscle], sets > 0 {
                    onMuscleTap(entry.muscle)
                    return
                }
            }
            // Fallback: tap first muscle
            if let first = muscles.first {
                onMuscleTap(first.muscle)
            }
        }
    }

    private func colorForSets(_ sets: Int) -> Color {
        guard sets > 0 else {
            return Color.mmTextSecondary.opacity(0.1)
        }

        let ratio = Double(sets) / Double(maxSets)

        // セット数に応じたグラデーション
        if ratio < 0.25 {
            return Color.mmMuscleLime.opacity(0.4)
        } else if ratio < 0.5 {
            return Color.mmMuscleLime.opacity(0.6)
        } else if ratio < 0.75 {
            return Color.mmAccentPrimary.opacity(0.7)
        } else {
            return Color.mmAccentPrimary
        }
    }
}

// MARK: - 履歴マップ凡例（改善版）

private struct HistoryMapLegend: View {
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 8) {
            // グラデーションバー
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.mmTextSecondary.opacity(0.15))
                    .frame(width: 40)
                LinearGradient(
                    colors: [
                        Color.mmMuscleLime.opacity(0.4),
                        Color.mmMuscleLime.opacity(0.6),
                        Color.mmAccentPrimary.opacity(0.7),
                        Color.mmAccentPrimary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // ラベル
            HStack {
                Text(localization.currentLanguage == .japanese ? "未トレ" : "None")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(localization.currentLanguage == .japanese ? "少" : "Low")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(localization.currentLanguage == .japanese ? "中" : "Mid")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(localization.currentLanguage == .japanese ? "多" : "High")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - 期間内サマリーカード（改善版）

private struct PeriodSummaryCard: View {
    let stats: PeriodStats
    let period: HistoryPeriod
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(localization.currentLanguage == .japanese
                    ? "\(period.rawValue)のサマリー"
                    : "\(period.englishName) Summary"
                )
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                BigStatItem(
                    value: "\(stats.sessionCount)",
                    label: localization.currentLanguage == .japanese ? "セッション" : "Sessions",
                    icon: "figure.strengthtraining.traditional"
                )
                BigStatItem(
                    value: "\(stats.totalSets)",
                    label: localization.currentLanguage == .japanese ? "セット数" : "Sets",
                    icon: "number"
                )
                BigStatItem(
                    value: formatVolume(stats.totalVolume),
                    label: localization.currentLanguage == .japanese ? "総ボリューム" : "Volume",
                    icon: "scalemass"
                )
                BigStatItem(
                    value: "\(stats.trainingDays)",
                    label: localization.currentLanguage == .japanese ? "トレ日数" : "Days",
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 大きい統計アイテム

private struct BigStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - カレンダー表示（既存を移動）

private struct HistoryCalendarView: View {
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

// MARK: - 筋肉履歴詳細シート（リデザイン版 v2）

private struct MuscleHistoryDetailSheet: View {
    let detail: MuscleHistoryDetail
    let period: HistoryPeriod
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // 上部 18%: 部位名 + 3Dビジュアル（コンパクト化して.mediumでも統計が見える）
                        muscleVisualSection(height: geometry.size.height * 0.18)

                        // 中部: 統計情報カード
                        statsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // 下部: 種目リスト（スクロール可能）
                        exerciseListSection
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                    }
                }
            }
            .background(Color.mmBgSecondary) // モーダル背景を差別化
            .navigationTitle(localization.currentLanguage == .japanese
                ? detail.muscle.japaneseName
                : detail.muscle.englishName
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - 筋肉ビジュアルセクション（30%）

    private func muscleVisualSection(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Muscle3DViewを使用（部位にズーム＆ハイライト）
            Muscle3DView(
                muscle: detail.muscle,
                visualState: .inactive // アクセントカラーでハイライト
            )
            .frame(height: max(height - 50, 120)) // 最小120pt

            // 筋肉名とグループ
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.currentLanguage == .japanese
                        ? detail.muscle.japaneseName
                        : detail.muscle.englishName
                    )
                    .font(.title3.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                    Text(localization.currentLanguage == .japanese
                        ? detail.muscle.group.japaneseName
                        : detail.muscle.group.englishName
                    )
                    .font(.caption)
                    .foregroundStyle(Color.mmAccentPrimary)
                }

                Spacer()

                // 期間バッジ
                Text(localization.currentLanguage == .japanese
                    ? period.rawValue
                    : period.englishName
                )
                .font(.caption.bold())
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.mmAccentPrimary)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mmBgCard)
        }
    }

    // MARK: - 統計セクション（30%）- 棒グラフ

    private var statsSection: some View {
        VStack(spacing: 12) {
            // 重量推移グラフ
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.currentLanguage == .japanese ? "重量推移" : "Weight Progress")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                if detail.weightHistory.isEmpty {
                    // 空状態
                    weightChartEmptyState
                } else {
                    // 棒グラフ
                    weightChart
                }
            }

            Divider()
                .background(Color.mmTextSecondary.opacity(0.2))

            // 補足テキスト（3列）
            HStack(spacing: 0) {
                // 最終トレーニング日
                VStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text(localization.currentLanguage == .japanese ? "最終" : "Last")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(detail.lastWorkoutDate.map { formatDate($0) } ?? "-")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
                .frame(maxWidth: .infinity)

                // ベスト記録
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(Color.yellow)
                    Text(localization.currentLanguage == .japanese ? "ベスト" : "Best")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                    if let weight = detail.bestWeight, let reps = detail.bestReps {
                        Text("\(Int(weight))kg×\(reps)")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                    } else {
                        Text("-")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // 合計セット数
                VStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(localization.currentLanguage == .japanese ? "セット" : "Sets")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text("\(detail.totalSets)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 重量推移グラフ

    private var weightChart: some View {
        Chart(detail.weightHistory) { entry in
            // 折れ線グラフ（推移を直感的に表現）
            LineMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Weight", entry.maxWeight)
            )
            .foregroundStyle(Color.mmAccentPrimary)
            .interpolationMethod(.catmullRom)

            // データポイント（PR時は大きく黄色で表示）
            PointMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Weight", entry.maxWeight)
            )
            .foregroundStyle(entry.isPR ? Color.yellow : Color.mmAccentPrimary)
            .symbolSize(entry.isPR ? 100 : 40)
            .annotation(position: .top, alignment: .center) {
                if entry.isPR {
                    Text("PR")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.yellow)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day(), centered: true)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .frame(height: 80)
    }

    // MARK: - グラフ空状態

    private var weightChartEmptyState: some View {
        VStack(spacing: 8) {
            // 空のグラフ枠
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mmTextSecondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 80)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                        Text(localization.currentLanguage == .japanese
                            ? "まだ記録がありません"
                            : "No records yet"
                        )
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    }
                }
        }
    }

    // MARK: - 種目リストセクション（40%）

    private var exerciseListSection: some View {
        VStack(spacing: 12) {
            // ヘッダー
            HStack {
                Text(localization.currentLanguage == .japanese ? "この期間の種目" : "Exercises")
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(detail.exercises.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            if detail.exercises.isEmpty {
                // 空状態
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.title)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                    Text(localization.currentLanguage == .japanese
                        ? "記録なし"
                        : "No Records"
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // 種目リスト
                ForEach(detail.exercises) { item in
                    HStack(spacing: 12) {
                        // ミニ筋肉マップ
                        MiniMuscleMapView(muscleMapping: item.exercise.muscleMapping)
                            .frame(width: 36, height: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.currentLanguage == .japanese
                                ? item.exercise.nameJA
                                : item.exercise.nameEN
                            )
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.mmTextPrimary)
                            .lineLimit(1)

                            Text(item.exercise.localizedEquipment)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                        }

                        Spacer()

                        // セット数
                        Text("\(item.totalSets)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                    .padding(.vertical, 8)

                    if item.id != detail.exercises.last?.id {
                        Divider()
                            .background(Color.mmTextSecondary.opacity(0.2))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ヘルパー

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = localization.currentLanguage == .japanese ? "M/d" : "MMM d"
        return formatter.string(from: date)
    }
}


// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

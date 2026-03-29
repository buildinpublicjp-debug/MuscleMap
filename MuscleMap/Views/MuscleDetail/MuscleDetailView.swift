import SwiftUI
import SwiftData
import Charts

// MARK: - 部位詳細画面（リデザイン版）

struct MuscleDetailView: View {
    let muscle: Muscle

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MuscleDetailViewModel?
    @State private var selectedExercise: ExerciseDefinition?
    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 1. 2Dマップハイライト + 筋肉名
                            muscleHeaderSection(vm: vm)

                            // 2. 回復状態バナー
                            RecoveryBannerView(viewModel: vm)
                                .padding(.horizontal)

                            // 3. 期間チップ
                            DetailPeriodPicker(selected: Bindable(vm).selectedPeriod)
                                .padding(.horizontal)

                            // 4. 期間サマリーカード
                            PeriodSummaryCards(viewModel: vm)
                                .padding(.horizontal)

                            // 5. エリアチャート
                            DetailAreaChart(
                                entries: vm.weightHistory,
                                period: vm.selectedPeriod
                            )
                            .padding(.horizontal)

                            // 6. 種目Netflixグリッド
                            if !vm.exerciseCards.isEmpty {
                                DetailExerciseGrid(
                                    cards: vm.exerciseCards,
                                    selectedExercise: $selectedExercise
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(isJapanese ? muscle.japaneseName : muscle.englishName)
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
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    // MARK: - マップ + 筋肉名ヘッダー

    private func muscleHeaderSection(vm: MuscleDetailViewModel) -> some View {
        VStack(spacing: 4) {
            Muscle3DView(
                muscle: muscle,
                visualState: vm.recoveryStatus.visualState
            )
            .padding(.horizontal)

            VStack(spacing: 2) {
                Text(muscle.japaneseName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)
                Text(muscle.englishName)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
    }
}

// MARK: - 回復状態バナー

private struct RecoveryBannerView: View {
    let viewModel: MuscleDetailViewModel
    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    var body: some View {
        HStack(spacing: 12) {
            // 左: ステータステキスト
            HStack(spacing: 6) {
                statusIcon
                Text(statusText)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            Spacer()

            // 右: 残り時間 or ステータス
            Text(detailText)
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextSecondary)
        }

        // プログレスバー
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.mmBgCard)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: geo.size.width * viewModel.recoveryProgress, height: 6)
            }
        }
        .frame(height: 6)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .padding(.top, -4)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var barColor: Color {
        let p = viewModel.recoveryProgress
        if p < 0.3 { return Color.mmMuscleFatigued }
        if p < 0.7 { return Color.mmMuscleModerate }
        return Color.mmMuscleRecovered
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch viewModel.recoveryStatus {
        case .recovering:
            Image(systemName: "clock.fill")
                .foregroundStyle(barColor)
        case .fullyRecovered:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.mmMuscleRecovered)
        case .neglected, .neglectedSevere:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.mmMuscleNeglected)
        }
    }

    private var statusText: String {
        if viewModel.lastStimulationDate == nil {
            return isJapanese ? "記録なし" : "No Record"
        }
        switch viewModel.recoveryStatus {
        case .recovering(let p):
            let pct = Int(p * 100)
            return isJapanese ? "回復中 \(pct)%" : "Recovering \(pct)%"
        case .fullyRecovered:
            return isJapanese ? "回復済み" : "Recovered"
        case .neglected:
            return isJapanese ? "7日以上未トレーニング" : "7d+ No Training"
        case .neglectedSevere:
            return isJapanese ? "14日以上未トレーニング" : "14d+ No Training"
        }
    }

    private var detailText: String {
        if viewModel.lastStimulationDate == nil {
            return ""
        }
        if let remaining = viewModel.remainingHours {
            let h = Int(remaining)
            if h >= 24 {
                return isJapanese ? "残り\(h/24)日\(h%24)時間" : "\(h/24)d \(h%24)h left"
            }
            return isJapanese ? "残り\(h)時間" : "\(h)h left"
        }
        return isJapanese ? "✅ 回復済み" : "✅ Recovered"
    }
}

// MARK: - 期間チップピッカー

private struct DetailPeriodPicker: View {
    @Binding var selected: DetailPeriod

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(DetailPeriod.allCases) { period in
                    Button {
                        HapticManager.lightTap()
                        selected = period
                    } label: {
                        Text(period.localizedLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(selected == period ? Color.mmBgPrimary : Color.mmTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selected == period ? Color.mmAccentPrimary : Color.mmBgCard)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - 期間サマリーカード（3枚）

private struct PeriodSummaryCards: View {
    let viewModel: MuscleDetailViewModel
    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    var body: some View {
        HStack(spacing: 8) {
            // 最終
            summaryCard(
                icon: "calendar",
                iconColor: Color.mmAccentSecondary,
                label: isJapanese ? "最終" : "Last",
                value: lastDateText,
                sub: relativeDateText
            )

            // ベスト
            summaryCard(
                icon: "trophy.fill",
                iconColor: Color.mmPRGold,
                label: isJapanese ? "ベスト" : "Best",
                value: bestText,
                sub: growthText
            )

            // セット
            summaryCard(
                icon: "number",
                iconColor: Color.mmAccentPrimary,
                label: isJapanese ? "セット" : "Sets",
                value: "\(viewModel.periodTotalSets)",
                sub: viewModel.monthlyAverageSets > 0
                    ? (isJapanese ? "月平均\(viewModel.monthlyAverageSets)" : "avg \(viewModel.monthlyAverageSets)/mo")
                    : nil
            )
        }
    }

    private var lastDateText: String {
        guard let date = viewModel.periodLastDate else { return "-" }
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d"
        return fmt.string(from: date)
    }

    private var relativeDateText: String? {
        guard let date = viewModel.periodLastDate else { return nil }
        let fmt = RelativeDateTimeFormatter()
        fmt.locale = isJapanese ? Locale(identifier: "ja_JP") : Locale(identifier: "en_US")
        fmt.unitsStyle = .short
        return fmt.localizedString(for: date, relativeTo: Date())
    }

    private var bestText: String {
        guard let w = viewModel.periodBestWeight, let r = viewModel.periodBestReps else { return "-" }
        return "\(Int(w))kg×\(r)"
    }

    private var growthText: String? {
        guard let pct = viewModel.growthPercent else { return nil }
        return pct > 0 ? "↑\(Int(pct))%" : "↓\(Int(abs(pct)))%"
    }

    @ViewBuilder
    private func summaryCard(
        icon: String, iconColor: Color, label: String,
        value: String, sub: String?
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let sub {
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(
                        sub.hasPrefix("↑") ? Color.mmAccentPrimary :
                        sub.hasPrefix("↓") ? Color.mmDestructive :
                        Color.mmTextSecondary
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - エリアチャート

private struct DetailAreaChart: View {
    let entries: [DetailWeightEntry]
    let period: DetailPeriod
    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isJapanese ? "重量推移" : "Weight Progress")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmTextPrimary)

            if entries.isEmpty {
                emptyState
            } else {
                chart
            }
        }
        .padding(16)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chart: some View {
        Chart(entries) { entry in
            // エリア塗りつぶし
            AreaMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Weight", entry.maxWeight)
            )
            .foregroundStyle(Color.mmAccentPrimary.opacity(0.08))
            .interpolationMethod(.catmullRom)

            // 折れ線
            LineMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Weight", entry.maxWeight)
            )
            .foregroundStyle(Color.mmAccentPrimary)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)

            // データ点
            PointMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Weight", entry.maxWeight)
            )
            .foregroundStyle(entry.isPR ? Color.mmPRGold : Color.mmAccentPrimary)
            .symbolSize(entry.isPR ? 64 : 16)
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatXLabel(date))
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .frame(height: 180)
    }

    // X軸ラベル値: 期間に応じて間引き
    private var xAxisValues: AxisMarkValues {
        switch period {
        case .oneWeek, .twoWeeks:
            return .stride(by: .day, count: period == .oneWeek ? 1 : 2)
        case .oneMonth, .twoMonths:
            return .stride(by: .weekOfYear, count: 1)
        case .threeMonths:
            return .stride(by: .month, count: 1)
        case .all:
            return .stride(by: .month, count: 1)
        }
    }

    // X軸ラベルフォーマット
    private func formatXLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        switch period {
        case .oneWeek, .twoWeeks:
            fmt.dateFormat = isJapanese ? "E" : "EEE"
            fmt.locale = isJapanese ? Locale(identifier: "ja_JP") : Locale(identifier: "en_US")
        case .oneMonth, .twoMonths:
            fmt.dateFormat = "M/d"
        case .threeMonths, .all:
            fmt.dateFormat = isJapanese ? "M月" : "MMM"
            fmt.locale = isJapanese ? Locale(identifier: "ja_JP") : Locale(identifier: "en_US")
        }
        return fmt.string(from: date)
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.mmTextSecondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
            .frame(height: 180)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                    Text(isJapanese ? "まだ記録がありません" : "No records yet")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
    }
}

// MARK: - 種目Netflixグリッド

private struct DetailExerciseGrid: View {
    let cards: [ExerciseCardData]
    @Binding var selectedExercise: ExerciseDefinition?
    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isJapanese ? "この期間の種目" : "Exercises")
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("\(cards.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(cards) { card in
                    Button {
                        HapticManager.lightTap()
                        selectedExercise = card.exercise
                    } label: {
                        netflixCard(card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func netflixCard(_ card: ExerciseCardData) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                // GIF or プレースホルダー
                if ExerciseGifView.hasGif(exerciseId: card.exercise.id) {
                    ExerciseGifView(exerciseId: card.exercise.id, size: .card)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Color.mmBgSecondary
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                        }
                }

                // グラデーションオーバーレイ + テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.exercise.localizedName)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(card.exercise.localizedEquipment)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))

                    if let w = card.lastWeight, let r = card.lastReps {
                        Text("\(Int(w))kg×\(r)")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // セット数バッジ（右上）
            Text("\(card.totalSets)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.mmAccentPrimary.opacity(0.8))
                .clipShape(Capsule())
                .padding(6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mmBgCard)
        )
    }
}

#Preview {
    MuscleDetailView(muscle: .chestUpper)
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

import SwiftUI
import Charts

// MARK: - マップ表示

struct HistoryMapView: View {
    let viewModel: HistoryViewModel
    let onMuscleTap: (Muscle) -> Void
    var onProBannerTap: (() -> Void)? = nil
    @State private var showFront = true
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        ScrollView {
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
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: showFront ? "person.fill" : "person.fill")
                                .font(.caption)
                            Text(showFront ? L10n.front : L10n.back)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(Color.mmTextPrimary)

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFront.toggle()
                            }
                            HapticManager.lightTap()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption.weight(.medium))
                                Text(showFront ? L10n.viewBack : L10n.viewFront)
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.mmAccentPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.mmAccentPrimary.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }

                    HistoryMuscleMapCanvas(
                        muscleSets: viewModel.periodMuscleSets,
                        showFront: showFront,
                        onMuscleTap: { muscle in
                            onMuscleTap(muscle)
                        }
                    )
                    .frame(maxHeight: 380)

                    HistoryMapLegend()
                }
                .padding()
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // 種目別推移グラフ: Pro → 実グラフ / 非Pro → ロックバナー
                if PurchaseManager.shared.isPremium {
                    ExerciseTrendSection(trendData: viewModel.exerciseTrendData)
                } else {
                    ExerciseTrendProBanner {
                        onProBannerTap?()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

// MARK: - 種目別推移グラフ（Pro専用）

struct ExerciseTrendSection: View {
    let trendData: [ExerciseTrendData]
    @State private var selectedIndex: Int = 0
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ヘッダー
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                Text("種目別 重量推移")
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text("全期間")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(Capsule())
            }

            if trendData.isEmpty {
                // データなし
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.title2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                    Text("まずトレーニングを記録しよう")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                // 種目ピッカー（横スクロール）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(trendData.enumerated()), id: \.offset) { idx, data in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedIndex = idx
                                }
                                HapticManager.lightTap()
                            } label: {
                                Text(localization.currentLanguage == .japanese
                                    ? data.exercise.nameJA
                                    : data.exercise.nameEN
                                )
                                .font(.caption.bold())
                                .lineLimit(1)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    selectedIndex == idx
                                    ? Color.mmAccentPrimary
                                    : Color.mmBgSecondary
                                )
                                .foregroundStyle(
                                    selectedIndex == idx
                                    ? Color.mmBgPrimary
                                    : Color.mmTextPrimary
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // グラフ + 統計
                if selectedIndex < trendData.count {
                    let data = trendData[selectedIndex]

                    if data.entries.isEmpty {
                        // 空状態
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.mmTextSecondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(height: 140)
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title2)
                                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                    Text("重量データなし（体重のみの種目は表示されません）")
                                        .font(.caption)
                                        .foregroundStyle(Color.mmTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                }
                            }
                    } else {
                        // 折れ線グラフ
                        Chart(data.entries) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.maxWeight)
                            )
                            .foregroundStyle(Color.mmAccentPrimary)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.maxWeight)
                            )
                            .foregroundStyle(entry.isPR ? Color.yellow : Color.mmAccentPrimary)
                            .symbolSize(entry.isPR ? 80 : 30)
                            .annotation(position: .top) {
                                if entry.isPR {
                                    Text("PR")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(Color.yellow)
                                }
                            }

                            // エリア塗り
                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.maxWeight)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.mmAccentPrimary.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.mmTextSecondary.opacity(0.2))
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .foregroundStyle(Color.mmTextSecondary)
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.mmTextSecondary.opacity(0.2))
                                AxisValueLabel()
                                    .foregroundStyle(Color.mmTextSecondary)
                                    .font(.caption2)
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 160)
                        .padding(.top, 8)

                        // 凡例
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.yellow).frame(width: 8, height: 8)
                                Text("PR達成").font(.caption2).foregroundStyle(Color.mmTextSecondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(Color.mmAccentPrimary).frame(width: 8, height: 8)
                                Text("最大重量").font(.caption2).foregroundStyle(Color.mmTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)

                        // 統計3列
                        Divider().background(Color.mmTextSecondary.opacity(0.15))

                        HStack(spacing: 0) {
                            // 合計セット数
                            TrendStatBox(
                                icon: "number",
                                label: "合計セット",
                                value: "\(data.totalSets)"
                            )

                            Divider().frame(height: 36)
                                .background(Color.mmTextSecondary.opacity(0.2))

                            // ベスト重量
                            TrendStatBox(
                                icon: "trophy.fill",
                                iconColor: .yellow,
                                label: "ベスト",
                                value: data.bestWeight.map { "\(Int($0))kg" } ?? "-"
                            )

                            Divider().frame(height: 36)
                                .background(Color.mmTextSecondary.opacity(0.2))

                            // 成長率
                            if let progress = data.progressPercent {
                                TrendStatBox(
                                    icon: progress >= 0 ? "arrow.up.right" : "arrow.down.right",
                                    iconColor: progress >= 0 ? Color.mmAccentPrimary : .red,
                                    label: "成長率",
                                    value: String(format: "%+.1f%%", progress)
                                )
                            } else {
                                TrendStatBox(
                                    icon: "arrow.up.right",
                                    label: "成長率",
                                    value: "-"
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmAccentPrimary.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - 統計ボックス（種目推移用）

private struct TrendStatBox: View {
    let icon: String
    var iconColor: Color = .mmAccentPrimary
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.subheadline.bold())
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

// MARK: - 期間セレクター

struct PeriodSelector: View {
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

struct HistoryMuscleMapCanvas: View {
    let muscleSets: [Muscle: Int]
    let showFront: Bool
    let onMuscleTap: (Muscle) -> Void

    private var maxSets: Int {
        max(1, muscleSets.values.max() ?? 1)
    }

    var body: some View {
        let muscles = showFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let sets = muscleSets[entry.muscle] ?? 0
                    let fillColor = colorForSets(sets)

                    HistoryMusclePathView(
                        path: entry.path(rect),
                        fillColor: fillColor,
                        muscle: entry.muscle
                    ) {
                        onMuscleTap(entry.muscle)
                    }
                }
            }
            .drawingGroup()
        }
        .aspectRatio(0.6, contentMode: .fit)
    }

    private func colorForSets(_ sets: Int) -> Color {
        guard sets > 0 else {
            return Color.mmTextSecondary.opacity(0.1)
        }

        let ratio = Double(sets) / Double(maxSets)

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

// MARK: - 履歴用筋肉パスビュー（タップ対応）

struct HistoryMusclePathView: View {
    let path: Path
    let fillColor: Color
    let muscle: Muscle
    let onTap: () -> Void

    @State private var isTapped = false

    var body: some View {
        path
            .fill(fillColor)
            .overlay {
                path.stroke(Color.mmMuscleBorder.opacity(0.3), lineWidth: 0.5)
            }
            .scaleEffect(isTapped ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isTapped)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isTapped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = false
                    }
                }
                HapticManager.lightTap()
                onTap()
            }
    }
}

// MARK: - 履歴マップ凡例

struct HistoryMapLegend: View {
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 8) {
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

// MARK: - 種目別推移グラフ Proロックストリップ（非Pro用）

struct ExerciseTrendProBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.exerciseTrendTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text("全期間の種目別 重量推移グラフ")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

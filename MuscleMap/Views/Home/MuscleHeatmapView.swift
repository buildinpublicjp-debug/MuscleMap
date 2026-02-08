import SwiftUI
import SwiftData

// MARK: - マッスルヒートマップ画面

struct MuscleHeatmapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MuscleHeatmapViewModel()
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 期間切り替え
                        periodPicker

                        // ヒートマップ
                        heatmapSection

                        // 凡例
                        legendSection

                        // 統計
                        statsSection

                        // シェアボタン
                        shareButton
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.trainingHeatmap)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(
                        items: [
                            L10n.heatmapShareText(
                                viewModel.stats.trainingDays,
                                AppConstants.shareHashtag,
                                AppConstants.appStoreURL
                            ),
                            image
                        ],
                        onComplete: nil
                    )
                }
            }
        }
    }

    // MARK: - 期間ピッカー

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(HeatmapPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - ヒートマップセクション

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 期間表示
            Text(viewModel.periodRangeText)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)

            // ヒートマップグリッド
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    // 月ラベル
                    HStack(spacing: 0) {
                        ForEach(Array(viewModel.monthLabels.enumerated()), id: \.offset) { index, label in
                            let (monthName, weekIndex) = label
                            let nextWeekIndex = index + 1 < viewModel.monthLabels.count
                                ? viewModel.monthLabels[index + 1].1
                                : viewModel.heatmapData.count

                            Text(monthName)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.mmTextSecondary)
                                .frame(width: CGFloat(nextWeekIndex - weekIndex) * 14, alignment: .leading)
                        }
                    }
                    .padding(.leading, 20)

                    // グリッド本体
                    HStack(alignment: .top, spacing: 2) {
                        // 曜日ラベル
                        VStack(spacing: 2) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                Text(weekdayLabel(dayIndex))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.mmTextSecondary)
                                    .frame(width: 16, height: 12)
                            }
                        }

                        // セル
                        HStack(spacing: 2) {
                            ForEach(Array(viewModel.heatmapData.enumerated()), id: \.offset) { weekIndex, week in
                                VStack(spacing: 2) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if dayIndex < week.count {
                                            let cell = week[dayIndex]
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(cell.muscleCount >= 0 ? viewModel.cellColor(for: cell.level) : Color.clear)
                                                .frame(width: 12, height: 12)
                                        } else {
                                            Color.clear
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 凡例

    private var legendSection: some View {
        HStack(spacing: 4) {
            Text(L10n.less)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)

            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(viewModel.cellColor(for: level))
                    .frame(width: 12, height: 12)
            }

            Text(L10n.more)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - 統計セクション

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // トレーニング日数
                StatCard(
                    title: L10n.trainingDaysLabel,
                    value: "\(viewModel.stats.trainingDays)",
                    subtitle: "/ \(viewModel.stats.totalDays) \(L10n.days)"
                )

                // 最長連続
                StatCard(
                    title: L10n.longestStreak,
                    value: "\(viewModel.stats.longestStreak)",
                    subtitle: L10n.days
                )
            }

            // 週平均
            StatCard(
                title: L10n.averagePerWeek,
                value: String(format: "%.1f", viewModel.stats.averagePerWeek),
                subtitle: L10n.timesPerWeek
            )
        }
    }

    // MARK: - シェアボタン

    private var shareButton: some View {
        Button {
            generateShareImage()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text(L10n.share)
            }
            .font(.headline)
            .foregroundStyle(Color.mmBgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mmAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - ヘルパー

    private func weekdayLabel(_ index: Int) -> String {
        // 月=0, 火=1, ... 日=6
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return labels[index]
    }

    @MainActor
    private func generateShareImage() {
        let shareCard = HeatmapShareCard(viewModel: viewModel)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - 統計カード

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - シェアカード

private struct HeatmapShareCard: View {
    let viewModel: MuscleHeatmapViewModel

    var body: some View {
        ShareCardContainer(
            width: 350,
            height: 480,
            accentColor: .mmAccentPrimary,
            secondaryColor: .mmAccentSecondary,
            backgroundStyle: .gradient([Color.mmBgCard, Color.mmBgPrimary]),
            header: ShareCardHeader(
                title: "MY TRAINING HEATMAP",
                subtitle: viewModel.periodRangeText
            )
        ) {
            VStack(spacing: 16) {
                // ミニヒートマップ
                miniHeatmap
                    .padding(.horizontal, 16)

                // 凡例
                HStack(spacing: 4) {
                    Text(L10n.less)
                        .font(.system(size: 8))
                        .foregroundStyle(Color.mmTextSecondary)

                    ForEach(0..<5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(viewModel.cellColor(for: level))
                            .frame(width: 10, height: 10)
                    }

                    Text(L10n.more)
                        .font(.system(size: 8))
                        .foregroundStyle(Color.mmTextSecondary)
                }

                // 統計
                HStack(spacing: 24) {
                    ShareCardStatItem("\(viewModel.stats.trainingDays)", label: L10n.trainingDaysLabel)
                    ShareCardStatItem("\(viewModel.stats.longestStreak)", label: L10n.longestStreak)
                    ShareCardStatItem(String(format: "%.1f", viewModel.stats.averagePerWeek), label: L10n.timesPerWeek)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - ミニヒートマップ

    private var miniHeatmap: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(viewModel.heatmapData.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            if dayIndex < week.count {
                                let cell = week[dayIndex]
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(cell.muscleCount >= 0 ? viewModel.cellColor(for: cell.level) : Color.clear)
                                    .frame(width: 8, height: 8)
                            } else {
                                Color.clear
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 70)
    }

}

#Preview {
    MuscleHeatmapView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}

import SwiftUI
import Charts

// MARK: - 筋肉履歴詳細シート（リデザイン版 v2）

struct MuscleHistoryDetailSheet: View {
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
                        .font(.subheadline.bold())
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
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                    } else {
                        Text("-")
                            .font(.subheadline.bold())
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
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
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
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day(), centered: true)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
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
                            .minimumScaleFactor(0.7)

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

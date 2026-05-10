import SwiftUI
import Charts

// MARK: - e1RM 推移ミニグラフ
//
// 種目詳細画面「過去のあなた」セクション内で表示。
// 直近5セッションの最大 e1RM を折れ線+ポイントで描画。

struct E1RMTrendChart: View {
    let points: [ExerciseHistoryStats.TrendPoint]

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("e1RM", point.e1RM)
                )
                .foregroundStyle(Color.mmAccentPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("e1RM", point.e1RM)
                )
                .foregroundStyle(Color.mmAccentPrimary)
                .symbolSize(28)
            }
        }
        .chartXAxis {
            AxisMarks(values: points.map(\.date)) { value in
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day(.defaultDigits))
                    .foregroundStyle(Color.mmTextSecondary)
                    .font(.system(size: 9))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(Color.mmTextSecondary)
                    .font(.system(size: 9))
            }
        }
        .chartYScale(domain: yDomain)
    }

    /// Y軸範囲: 最小 0、最大はデータ最大の 1.2倍 (auto-fit に近づける)
    private var yDomain: ClosedRange<Double> {
        let maxValue = points.map(\.e1RM).max() ?? 0
        guard maxValue > 0 else { return 0...1 }
        return 0...(maxValue * 1.2)
    }
}

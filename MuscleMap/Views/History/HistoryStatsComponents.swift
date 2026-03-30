import SwiftUI

// MARK: - 月間サマリーカード（改善版）

struct MonthlySummaryCard: View {
    let stats: MonthlyStats

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
                    label: L10n.sessions,
                    icon: "figure.strengthtraining.traditional"
                )
                BigStatItem(
                    value: "\(stats.totalSets)",
                    label: L10n.totalSets,
                    icon: "number"
                )
                BigStatItem(
                    value: formatVolume(stats.totalVolume),
                    label: L10n.totalVolume,
                    icon: "scalemass"
                )
                BigStatItem(
                    value: "\(stats.trainingDays)",
                    label: L10n.trainingDays,
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

struct HistoryStatItem: View {
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

// MARK: - 期間内サマリーカード（改善版）

struct PeriodSummaryCard: View {
    let stats: PeriodStats
    let period: HistoryPeriod

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(L10n.periodSummaryTitle(period.localizedName))
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                BigStatItem(
                    value: "\(stats.sessionCount)",
                    label: L10n.sessions,
                    icon: "figure.strengthtraining.traditional"
                )
                BigStatItem(
                    value: "\(stats.totalSets)",
                    label: L10n.totalSets,
                    icon: "number"
                )
                BigStatItem(
                    value: formatVolume(stats.totalVolume),
                    label: L10n.totalVolume,
                    icon: "scalemass"
                )
                BigStatItem(
                    value: "\(stats.trainingDays)",
                    label: L10n.trainingDays,
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

struct BigStatItem: View {
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

// MARK: - ヘルパー

func formatVolume(_ volume: Double) -> String {
    if volume >= 1000 {
        return String(format: "%.1fk", volume / 1000)
    }
    return String(format: "%.0f", volume)
}

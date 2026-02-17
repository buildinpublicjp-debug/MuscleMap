import SwiftUI

// MARK: - 月間サマリーカード（改善版）

struct MonthlySummaryCard: View {
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

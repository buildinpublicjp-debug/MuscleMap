import SwiftUI
import SwiftData

// MARK: - 週間ボリュームバーチャート

struct WeeklyVolumeChart: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dailyVolumes: [WeeklyDayVolume] = []
    @State private var lastWeekTotal: Double = 0

    /// 今週の合計
    private var thisWeekTotal: Double {
        dailyVolumes.reduce(0) { $0 + $1.volume }
    }

    /// 先週比の変化率（%）
    private var weekOverWeekChange: Int? {
        guard lastWeekTotal > 0 else { return nil }
        return Int(((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100)
    }

    /// バーの最大高さ
    private let maxBarHeight: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ヘッダー行
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.thisWeek)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatVolume(thisWeekTotal))
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Color.mmTextPrimary)

                    Text("kg")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.mmTextSecondary)

                    // 先週比（データがある場合のみ）
                    if let change = weekOverWeekChange {
                        Text(change >= 0 ? "↑ \(change)%" : "↓ \(abs(change))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(change >= 0 ? Color.mmAccentPrimary : Color.mmWarning)
                            .padding(.leading, 4)
                    }
                }
            }

            // バーチャート
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(dailyVolumes) { day in
                    VStack(spacing: 2) {
                        // バー
                        if day.isToday && day.volume == 0 {
                            // 今日（未トレーニング）: dashed border
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3]))
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.2))
                                .frame(height: maxBarHeight)
                        } else if day.volume > 0 {
                            // トレーニング済み
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.mmAccentPrimary)
                                .frame(height: barHeight(for: day.volume))
                        } else {
                            // 過去の休息日: 極小バー
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.mmTextSecondary.opacity(0.08))
                                .frame(height: 4)
                        }

                        // 曜日ラベル
                        Text(day.dayLabel)
                            .font(.system(size: 8, weight: day.isToday ? .bold : .regular))
                            .foregroundStyle(day.isToday ? Color.mmAccentPrimary : Color.mmTextSecondary.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxBarHeight + 14) // バー + ラベル

            // フッター行
            HStack {
                if lastWeekTotal > 0 {
                    Text(L10n.lastWeekVolume(formatVolume(lastWeekTotal)))
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                }

                Spacer()

                let sessionCount = dailyVolumes.filter { $0.volume > 0 }.count
                if sessionCount > 0 {
                    Text(L10n.sessionCount(sessionCount))
                        .font(.system(size: 9))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .onAppear {
            loadData()
        }
    }

    // MARK: - バー高さ計算

    private func barHeight(for volume: Double) -> CGFloat {
        let maxVolume = dailyVolumes.map(\.volume).max() ?? 1
        guard maxVolume > 0 else { return 4 }
        let ratio = volume / maxVolume
        return max(4, maxBarHeight * ratio)
    }

    // MARK: - ボリューム表示フォーマット

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            let k = volume / 1000
            if k >= 100 {
                return "\(Int(k))k"
            } else {
                return String(format: "%.1fk", k)
            }
        }
        return "\(Int(volume))"
    }

    // MARK: - データ読み込み

    private func loadData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 今週の月曜日を取得
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // 月=0, 火=1, ... 日=6
        guard let mondayThisWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return }

        // 先週の月曜日
        guard let mondayLastWeek = calendar.date(byAdding: .day, value: -7, to: mondayThisWeek) else { return }

        // 今週の全セットを取得
        let descriptor = FetchDescriptor<WorkoutSet>()
        guard let allSets = try? modelContext.fetch(descriptor) else { return }

        // 曜日ラベル
        let dayLabels: [String] = L10n.weekdayShortLabels()

        // 今週の日別ボリューム
        var volumes: [WeeklyDayVolume] = []
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: mondayThisWeek) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isFuture = date > today

            let daySets = allSets.filter { set in
                guard let session = set.session else { return false }
                return session.startDate >= date && session.startDate < nextDate
            }

            let volume = daySets.reduce(0.0) { total, set in
                total + (set.weight * Double(set.reps))
            }

            volumes.append(WeeklyDayVolume(
                id: dayOffset,
                dayLabel: dayLabels[dayOffset],
                volume: isFuture ? 0 : volume,
                isToday: isToday,
                isFuture: isFuture
            ))
        }

        dailyVolumes = volumes

        // 先週の合計ボリューム
        let lastWeekSets = allSets.filter { set in
            guard let session = set.session else { return false }
            return session.startDate >= mondayLastWeek && session.startDate < mondayThisWeek
        }
        lastWeekTotal = lastWeekSets.reduce(0.0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
}

// MARK: - データモデル

private struct WeeklyDayVolume: Identifiable {
    let id: Int
    let dayLabel: String
    let volume: Double
    let isToday: Bool
    let isFuture: Bool
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        WeeklyVolumeChart()
            .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
    }
}

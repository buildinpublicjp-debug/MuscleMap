import SwiftUI
import SwiftData

// MARK: - 「過去のあなた」セクション (種目詳細画面)
//
// 表示分岐:
// - 履歴 0 件: セクション全体を非表示 (View が EmptyView)
// - 履歴 1〜2 件: 数値カード (前回 / Best e1RM) のみ
// - 履歴 3 件以上: 数値カード + e1RM トレンドミニグラフ

struct ExerciseHistorySection: View {
    let exerciseId: String
    @Query private var sets: [WorkoutSet]

    init(exerciseId: String) {
        self.exerciseId = exerciseId
        // 当該 exerciseId の WorkoutSet を新しい順で監視
        let target = exerciseId
        _sets = Query(
            filter: #Predicate<WorkoutSet> { $0.exerciseId == target },
            sort: [SortDescriptor(\.completedAt, order: .reverse)]
        )
    }

    private var stats: ExerciseHistoryStats? {
        ExerciseHistoryStats.aggregate(sets: sets)
    }

    var body: some View {
        if let stats {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.pastYouSection)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.mmTextPrimary)

                HStack(spacing: 12) {
                    statCard(
                        label: L10n.lastSessionLabel,
                        value: lastSessionValue(stats.lastSession),
                        sub: lastSessionSub(stats.lastSession)
                    )
                    statCard(
                        label: L10n.bestE1RMLabel,
                        value: "\(Int(stats.bestE1RM.e1RM)) kg",
                        sub: bestE1RMSub(stats.bestE1RM)
                    )
                }

                if stats.trend.count >= 3 {
                    E1RMTrendChart(points: stats.trend)
                        .frame(height: 100)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 数値カード

    private func statCard(label: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - フォーマットヘルパー

    private func lastSessionValue(_ info: ExerciseHistoryStats.LastSessionInfo) -> String {
        if info.weight > 0 {
            let weightStr = info.weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", info.weight)
                : String(format: "%.1f", info.weight)
            return "\(weightStr) kg × \(info.reps)"
        } else {
            let bw = LocalizationManager.shared.currentLanguage == .japanese ? "自重" : "BW"
            return "\(bw) × \(info.reps)"
        }
    }

    private func lastSessionSub(_ info: ExerciseHistoryStats.LastSessionInfo) -> String {
        let dateStr = shortDate(info.date)
        let rel = RelativeDate.string(from: info.date)
        return "\(dateStr) (\(rel))"
    }

    private func bestE1RMSub(_ info: ExerciseHistoryStats.BestE1RMInfo) -> String {
        let dateStr = shortDate(info.date)
        let rel = RelativeDate.string(from: info.date)
        return L10n.bestE1RMAchievedOn(dateStr, rel)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

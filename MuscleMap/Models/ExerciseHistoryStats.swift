import Foundation
import SwiftData

// MARK: - 種目ごとの履歴統計

/// 種目詳細画面「過去のあなた」セクション用の集計値。
///
/// 履歴 0件の場合は `compute` が nil を返す → UI 側でセクション全体を非表示にする。
struct ExerciseHistoryStats {
    let lastSession: LastSessionInfo
    let bestE1RM: BestE1RMInfo
    let trend: [TrendPoint]   // 直近5セッションの最大e1RM、古→新でソート済み
    let totalSessions: Int

    struct LastSessionInfo {
        let weight: Double
        let reps: Int
        let date: Date
    }

    struct BestE1RMInfo {
        let e1RM: Double
        let date: Date
    }

    struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let e1RM: Double
    }

    /// 当該 exerciseId の WorkoutSet を集計。履歴 0件なら nil。
    @MainActor
    static func compute(exerciseId: String, context: ModelContext, now: Date = Date()) -> ExerciseHistoryStats? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\WorkoutSet.completedAt, order: .reverse)]
        )
        guard let allSets = try? context.fetch(descriptor), !allSets.isEmpty else {
            return nil
        }
        return aggregate(sets: allSets, now: now)
    }

    /// テスト容易性のため SwiftData フェッチから分離した純粋集計。
    static func aggregate(sets: [WorkoutSet], now: Date = Date()) -> ExerciseHistoryStats? {
        guard !sets.isEmpty else { return nil }

        // セッション ID でグループ化 (session が nil のセットはスキップ)
        var sessionMap: [UUID: SessionGroup] = [:]
        for set in sets {
            guard let session = set.session else { continue }
            let group = sessionMap[session.id] ?? SessionGroup(date: session.startDate, sets: [])
            sessionMap[session.id] = SessionGroup(date: group.date, sets: group.sets + [set])
        }
        let sessions = sessionMap.values.sorted { $0.date > $1.date }
        guard !sessions.isEmpty else { return nil }

        // 前回 (最新セッションの最大 e1RM セット)
        let latest = sessions[0]
        guard let lastBestSet = latest.sets.max(by: { e1RM(of: $0) < e1RM(of: $1) }) else { return nil }
        let lastInfo = LastSessionInfo(
            weight: lastBestSet.weight,
            reps: lastBestSet.reps,
            date: latest.date
        )

        // Best e1RM (全セッション全セットの max、タイは最古を採用)
        var maxE1RM: Double = 0
        var bestDate = latest.date
        for session in sessions {
            for set in session.sets {
                let e = e1RM(of: set)
                if e > maxE1RM + 0.0001 {
                    maxE1RM = e
                    bestDate = session.date
                } else if abs(e - maxE1RM) < 0.0001 && session.date < bestDate {
                    bestDate = session.date
                }
            }
        }
        let bestInfo = BestE1RMInfo(e1RM: maxE1RM, date: bestDate)

        // トレンド (直近5セッションの最大 e1RM、古→新)
        let trendSessions = Array(sessions.prefix(5))
        let trend = trendSessions.reversed().map { sess -> TrendPoint in
            let maxE = sess.sets.map(e1RM(of:)).max() ?? 0
            return TrendPoint(date: sess.date, e1RM: maxE)
        }

        return ExerciseHistoryStats(
            lastSession: lastInfo,
            bestE1RM: bestInfo,
            trend: trend,
            totalSessions: sessions.count
        )
    }

    /// Epley 推定 1RM = weight × (1 + reps/30)
    private static func e1RM(of set: WorkoutSet) -> Double {
        guard set.reps > 1 else { return set.weight }
        return set.weight * (1.0 + Double(set.reps) / 30.0)
    }

    private struct SessionGroup {
        let date: Date
        let sets: [WorkoutSet]
    }
}

import Foundation
import SwiftData

// MARK: - ワークアウトリポジトリ

@MainActor
class WorkoutRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: セッション

    /// 進行中のセッションを取得
    func fetchActiveSession() -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to fetch active session: \(error)")
            #endif
            return nil
        }
    }

    /// 新しいセッションを開始
    func startSession() -> WorkoutSession {
        let session = WorkoutSession()
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to start session: \(error)")
            #endif
        }
        return session
    }

    /// セッションを終了
    func endSession(_ session: WorkoutSession) {
        session.endDate = Date()
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to end session: \(error)")
            #endif
        }
    }

    /// 直近のセッション一覧（日付降順）
    func fetchRecentSessions(limit: Int = 20) -> [WorkoutSession] {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to fetch recent sessions: \(error)")
            #endif
            return []
        }
    }

    // MARK: セット

    /// セットを追加
    func addSet(
        to session: WorkoutSession,
        exerciseId: String,
        setNumber: Int,
        weight: Double,
        reps: Int
    ) -> WorkoutSet {
        let workoutSet = WorkoutSet(
            session: session,
            exerciseId: exerciseId,
            setNumber: setNumber,
            weight: weight,
            reps: reps
        )
        modelContext.insert(workoutSet)
        session.sets.append(workoutSet)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to add set: \(error)")
            #endif
        }
        return workoutSet
    }

    /// セッション内の指定種目のセット一覧
    func fetchSets(in session: WorkoutSession, exerciseId: String) -> [WorkoutSet] {
        session.sets
            .filter { $0.exerciseId == exerciseId }
            .sorted { $0.setNumber < $1.setNumber }
    }

    /// 指定種目の前回の記録（直近セッションから）
    func fetchLastRecord(exerciseId: String) -> WorkoutSet? {
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to fetch last record: \(error)")
            #endif
            return nil
        }
    }

    /// セットを削除
    func deleteSet(_ workoutSet: WorkoutSet) {
        modelContext.delete(workoutSet)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to delete set: \(error)")
            #endif
        }
    }

    /// セッションとその全セットを削除（破棄）
    func discardSession(_ session: WorkoutSession) {
        for set in session.sets {
            modelContext.delete(set)
        }
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[WorkoutRepository] Failed to discard session: \(error)")
            #endif
        }
    }
}

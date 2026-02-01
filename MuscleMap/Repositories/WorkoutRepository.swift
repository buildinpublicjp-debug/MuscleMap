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
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// 新しいセッションを開始
    func startSession() -> WorkoutSession {
        let session = WorkoutSession()
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }

    /// セッションを終了
    func endSession(_ session: WorkoutSession) {
        session.endDate = Date()
        try? modelContext.save()
    }

    /// 直近のセッション一覧（日付降順）
    func fetchRecentSessions(limit: Int = 20) -> [WorkoutSession] {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
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
        try? modelContext.save()
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
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// セットを削除
    func deleteSet(_ workoutSet: WorkoutSet) {
        modelContext.delete(workoutSet)
        try? modelContext.save()
    }
}

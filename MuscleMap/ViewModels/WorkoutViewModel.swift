import Foundation
import SwiftData
import SwiftUI

// MARK: - ワークアウトViewModel

@MainActor
@Observable
class WorkoutViewModel {
    private let workoutRepo: WorkoutRepository
    private let muscleStateRepo: MuscleStateRepository
    private let exerciseStore: ExerciseStore

    // セッション状態
    var activeSession: WorkoutSession?
    var isSessionActive: Bool { activeSession != nil }

    // 選択中のエクササイズ
    var selectedExercise: ExerciseDefinition?

    // 現在のセット入力
    var currentWeight: Double = 0
    var currentReps: Int = 10
    var currentSetNumber: Int = 1

    // セッション内の記録済みセット（種目ごとにグループ化）
    var exerciseSets: [(exercise: ExerciseDefinition, sets: [WorkoutSet])] = []

    // 前回の記録
    var lastWeight: Double?
    var lastReps: Int?

    init(modelContext: ModelContext) {
        self.workoutRepo = WorkoutRepository(modelContext: modelContext)
        self.muscleStateRepo = MuscleStateRepository(modelContext: modelContext)
        self.exerciseStore = ExerciseStore.shared
    }

    // MARK: セッション操作

    /// セッションを開始（既存があればそれを使う）
    func startOrResumeSession() {
        if let existing = workoutRepo.fetchActiveSession() {
            activeSession = existing
            refreshExerciseSets()
        } else {
            activeSession = workoutRepo.startSession()
        }
    }

    /// セッションを終了
    func endSession() {
        guard let session = activeSession else { return }
        workoutRepo.endSession(session)
        activeSession = nil
        exerciseSets = []
    }

    // MARK: エクササイズ選択

    /// エクササイズを選択して前回記録を取得
    func selectExercise(_ exercise: ExerciseDefinition) {
        selectedExercise = exercise

        // 前回記録を取得
        if let lastRecord = workoutRepo.fetchLastRecord(exerciseId: exercise.id) {
            currentWeight = lastRecord.weight
            currentReps = lastRecord.reps
            lastWeight = lastRecord.weight
            lastReps = lastRecord.reps
        } else {
            currentWeight = 0
            currentReps = 10
            lastWeight = nil
            lastReps = nil
        }

        // セット番号を計算
        if let session = activeSession {
            let existingSets = workoutRepo.fetchSets(in: session, exerciseId: exercise.id)
            currentSetNumber = existingSets.count + 1
        } else {
            currentSetNumber = 1
        }
    }

    // MARK: セット記録

    /// セットを記録
    func recordSet() {
        guard let session = activeSession,
              let exercise = selectedExercise else { return }

        // セットを保存
        _ = workoutRepo.addSet(
            to: session,
            exerciseId: exercise.id,
            setNumber: currentSetNumber,
            weight: currentWeight,
            reps: currentReps
        )

        // 筋肉刺激を記録
        updateMuscleStimulations(exercise: exercise, session: session)

        // 次のセットへ
        currentSetNumber += 1

        // セット一覧を更新
        refreshExerciseSets()
    }

    /// 重量を調整
    func adjustWeight(by delta: Double) {
        currentWeight = max(0, currentWeight + delta)
    }

    /// レップ数を調整
    func adjustReps(by delta: Int) {
        currentReps = max(1, currentReps + delta)
    }

    // MARK: 内部

    /// セッション内の全セットを種目ごとにグループ化
    private func refreshExerciseSets() {
        guard let session = activeSession else {
            exerciseSets = []
            return
        }

        // 種目IDでグループ化
        let grouped = Dictionary(grouping: session.sets) { $0.exerciseId }
        exerciseSets = grouped.compactMap { (exerciseId, sets) in
            guard let exercise = exerciseStore.exercise(for: exerciseId) else { return nil }
            let sortedSets = sets.sorted { $0.setNumber < $1.setNumber }
            return (exercise: exercise, sets: sortedSets)
        }.sorted { ($0.sets.first?.completedAt ?? .distantPast) < ($1.sets.first?.completedAt ?? .distantPast) }
    }

    /// 筋肉刺激記録を更新
    private func updateMuscleStimulations(exercise: ExerciseDefinition, session: WorkoutSession) {
        let sessionSets = workoutRepo.fetchSets(in: session, exerciseId: exercise.id)
        let totalSets = sessionSets.count

        for (muscleId, percentage) in exercise.muscleMapping {
            guard let muscle = Muscle(rawValue: muscleId) else { continue }
            muscleStateRepo.upsertStimulation(
                muscle: muscle,
                sessionId: session.id,
                maxIntensity: Double(percentage) / 100.0,
                totalSets: totalSets
            )
        }
    }
}

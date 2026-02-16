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

    // セット間タイマー
    var restTimerSeconds: Int = 0
    var isRestTimerRunning: Bool = false
    private var restTimer: Timer?
    private var restTimerStartDate: Date?  // バックグラウンド復帰時の補正用

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

    /// セッションを終了（記録を保存）
    func endSession() {
        guard let session = activeSession else { return }
        workoutRepo.endSession(session)
        activeSession = nil
        exerciseSets = []

        // ウィジェットデータを更新
        updateWidgetAfterSession()
    }

    /// セッションを破棄（記録と筋肉刺激を削除）
    func discardSession() {
        guard let session = activeSession else { return }
        muscleStateRepo.deleteStimulations(sessionId: session.id)
        workoutRepo.discardSession(session)
        activeSession = nil
        exerciseSets = []
        selectedExercise = nil
    }

    // MARK: エクササイズ選択

    /// エクササイズを選択して前回記録を取得
    func selectExercise(_ exercise: ExerciseDefinition) {
        selectedExercise = exercise

        // 使用履歴に記録
        RecentExercisesManager.shared.recordUsage(exercise.id)

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

    // PR達成フラグ（UIからのアニメーション用）
    var lastSetWasPR: Bool = false

    // MARK: セット記録

    /// セットを記録（バリデーション済み）
    /// - Returns: PR達成かどうか
    @discardableResult
    func recordSet() -> Bool {
        guard let session = activeSession,
              let exercise = selectedExercise else { return false }

        // バリデーション: レップ数は最低1回必要
        guard currentReps >= 1 else { return false }

        // バリデーション: 重量は0以上（負の値は0に補正）
        let validatedWeight = max(0, currentWeight)

        // PR判定（セット保存前に確認）
        let isPR = validatedWeight > 0 && PRManager.shared.checkIsWeightPR(
            exerciseId: exercise.id,
            weight: validatedWeight,
            context: workoutRepo.modelContext
        )
        lastSetWasPR = isPR

        // セットを保存
        _ = workoutRepo.addSet(
            to: session,
            exerciseId: exercise.id,
            setNumber: currentSetNumber,
            weight: validatedWeight,
            reps: currentReps
        )

        // 筋肉刺激を記録
        updateMuscleStimulations(exercise: exercise, session: session)

        // 次のセットへ
        currentSetNumber += 1

        // セット一覧を更新
        refreshExerciseSets()

        // セット間タイマーを開始
        startRestTimer()

        return isPR
    }

    /// 重量を調整
    func adjustWeight(by delta: Double) {
        currentWeight = max(0, currentWeight + delta)
    }

    /// レップ数を調整
    func adjustReps(by delta: Int) {
        currentReps = max(1, currentReps + delta)
    }

    // MARK: セット間タイマー

    /// タイマーを開始
    func startRestTimer() {
        restTimerStartDate = Date()
        restTimerSeconds = 0
        isRestTimerRunning = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.restTimerSeconds += 1
            }
        }
    }

    /// タイマーを停止
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerRunning = false
        restTimerStartDate = nil
    }

    /// タイマーをリセット
    func resetRestTimer() {
        stopRestTimer()
        restTimerSeconds = 0
        restTimerStartDate = nil
    }

    /// バックグラウンド復帰時にタイマーを補正
    func recalculateRestTimerAfterBackground() {
        guard isRestTimerRunning, let startDate = restTimerStartDate else { return }
        restTimerSeconds = Int(Date().timeIntervalSince(startDate))
    }

    /// セットを削除
    func deleteSet(_ workoutSet: WorkoutSet) {
        let exerciseId = workoutSet.exerciseId
        workoutRepo.deleteSet(workoutSet)

        // セット番号を振り直し
        if let session = activeSession {
            let remaining = workoutRepo.fetchSets(in: session, exerciseId: exerciseId)
            for (index, set) in remaining.enumerated() {
                set.setNumber = index + 1
            }

            // 現在選択中の種目なら次のセット番号を更新
            if selectedExercise?.id == exerciseId {
                currentSetNumber = remaining.count + 1
            }

            // 筋肉刺激を再計算
            if let exercise = exerciseStore.exercise(for: exerciseId) {
                updateMuscleStimulations(exercise: exercise, session: session)
            }
        }

        refreshExerciseSets()
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
        }.sorted { ($0.sets.first?.completedAt ?? .distantPast) > ($1.sets.first?.completedAt ?? .distantPast) }
    }

    /// ウィジェットデータを最新の筋肉状態で更新
    private func updateWidgetAfterSession() {
        let stimulations = muscleStateRepo.fetchLatestStimulations()
        var states: [Muscle: MuscleVisualState] = [:]

        for muscle in Muscle.allCases {
            if let stim = stimulations[muscle] {
                let status = RecoveryCalculator.recoveryStatus(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets
                )
                states[muscle] = status.visualState
            } else {
                states[muscle] = .inactive
            }
        }

        WidgetDataProvider.updateWidgetData(muscleStates: states)
    }

    /// 筋肉刺激記録を更新（バッチ保存で1回のsave）
    private func updateMuscleStimulations(exercise: ExerciseDefinition, session: WorkoutSession) {
        let sessionSets = workoutRepo.fetchSets(in: session, exerciseId: exercise.id)
        let totalSets = sessionSets.count

        for (muscleId, percentage) in exercise.muscleMapping {
            guard let muscle = Muscle(rawValue: muscleId) else { continue }
            muscleStateRepo.upsertStimulation(
                muscle: muscle,
                sessionId: session.id,
                maxIntensity: Double(percentage) / 100.0,
                totalSets: totalSets,
                saveImmediately: false
            )
        }
        muscleStateRepo.save()
    }
}

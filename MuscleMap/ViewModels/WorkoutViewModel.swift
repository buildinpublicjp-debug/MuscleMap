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

    // MARK: ルーティンモード

    /// ルーティンモードか（nil = フリーモード）
    var activeRoutineDay: RoutineDay?

    /// ルーティン種目の完了状態を追跡（Key = exerciseId, Value = true で1セット以上記録済み）
    var routineExerciseCompletion: [String: Bool] = [:]

    /// ルーティンの次の未完了種目
    var nextRoutineExercise: ExerciseDefinition? {
        guard let day = activeRoutineDay else { return nil }
        for re in day.exercises {
            if routineExerciseCompletion[re.exerciseId] != true {
                return ExerciseStore.shared.exercise(for: re.exerciseId)
            }
        }
        return nil
    }

    /// ルーティン進捗（0.0〜1.0）
    var routineProgress: Double {
        guard let day = activeRoutineDay, !day.exercises.isEmpty else { return 0 }
        let completed = day.exercises.filter { routineExerciseCompletion[$0.exerciseId] == true }.count
        return Double(completed) / Double(day.exercises.count)
    }

    /// ルーティン全種目完了か
    var isRoutineComplete: Bool {
        guard let day = activeRoutineDay else { return false }
        return day.exercises.allSatisfy { routineExerciseCompletion[$0.exerciseId] == true }
    }

    /// 現在選択中の種目がルーティン内か
    var isCurrentExerciseInRoutine: Bool {
        guard let day = activeRoutineDay, let exercise = selectedExercise else { return false }
        return day.exercises.contains { $0.exerciseId == exercise.id }
    }

    // セット間タイマー
    var restTimerSeconds: Int = 0                // カウントダウン中: 残り秒数, オーバータイム: 経過秒数
    var isRestTimerRunning: Bool = false
    var isRestTimerOvertime: Bool = false         // カウントダウン完了後のオーバータイム状態
    nonisolated(unsafe) private var restTimer: Timer?
    private var restTimerStartDate: Date?         // バックグラウンド復帰時の補正用
    private var restTimerDuration: Int = 90       // このタイマーセッションの設定秒数
    private var hasPlayedCompletionHaptic: Bool = false
    private var hasPlayedWarningHaptic: Bool = false

    init(modelContext: ModelContext) {
        self.workoutRepo = WorkoutRepository(modelContext: modelContext)
        self.muscleStateRepo = MuscleStateRepository(modelContext: modelContext)
        self.exerciseStore = ExerciseStore.shared
    }

    deinit {
        restTimer?.invalidate()
    }

    // MARK: セッション操作

    /// セッションを開始（既存があればそれを使う）
    func startOrResumeSession() {
        if let existing = workoutRepo.fetchActiveSession() {
            activeSession = existing
            refreshExerciseSets()
        } else {
            activeSession = workoutRepo.startSession()
            guard activeSession != nil else { return }
        }
    }

    /// ルーティンモードでセッションを開始
    func startWithRoutine(day: RoutineDay) {
        activeRoutineDay = day
        routineExerciseCompletion = [:]
        startOrResumeSession()
        // ルーティンの最初の種目を自動選択
        if let firstExercise = day.exercises.first,
           let def = ExerciseStore.shared.exercise(for: firstExercise.exerciseId) {
            selectExercise(def)
        }
    }

    /// ルーティンの次の未完了種目に移動
    func goToNextRoutineExercise() {
        guard let next = nextRoutineExercise else { return }
        selectExercise(next)
    }

    /// セッションを終了（記録を保存）
    func endSession() {
        // [Fix #4] セッション終了時にレストタイマーを停止
        stopRestTimer()

        guard let session = activeSession else { return }

        // 0セットチェック: 1セットも記録していない場合は保存せず破棄
        let totalSets = exerciseSets.reduce(0) { $0 + $1.sets.count }
        if totalSets == 0 {
            discardSession()
            return
        }
        workoutRepo.endSession(session)
        activeSession = nil
        exerciseSets = []
        activeRoutineDay = nil
        routineExerciseCompletion = [:]

        // ウィジェットデータを更新
        updateWidgetAfterSession()

        // 無料ユーザーの週間ワークアウト回数をインクリメント
        PurchaseManager.shared.incrementWorkoutCount()
    }

    /// セッションを破棄（記録と筋肉刺激を削除）
    func discardSession() {
        // [Fix #4] セッション破棄時にレストタイマーを停止
        stopRestTimer()

        guard let session = activeSession else { return }
        muscleStateRepo.deleteStimulations(sessionId: session.id)
        workoutRepo.discardSession(session)
        activeSession = nil
        exerciseSets = []
        selectedExercise = nil
        activeRoutineDay = nil
        routineExerciseCompletion = [:]
    }

    // MARK: エクササイズ選択

    /// エクササイズを選択して前回記録を取得
    func selectExercise(_ exercise: ExerciseDefinition) {
        selectedExercise = exercise

        let isBodyweight = exercise.equipment == "自重" || exercise.equipment == "Bodyweight"

        // 使用履歴に記録
        RecentExercisesManager.shared.recordUsage(exercise.id)

        // セット番号を計算 + セッション内の直前セットを取得
        var sessionLastSet: WorkoutSet?
        if let session = activeSession {
            let existingSets = workoutRepo.fetchSets(in: session, exerciseId: exercise.id)
            currentSetNumber = existingSets.count + 1
            sessionLastSet = existingSets.last
        } else {
            currentSetNumber = 1
        }

        // 前回記録を取得（セッション内の直前セット → 過去セッションの順に優先）
        if let inSessionSet = sessionLastSet {
            // 同一セッション内で既に記録がある → その値を維持（値保持）
            currentWeight = inSessionSet.weight
            currentReps = inSessionSet.reps
            lastWeight = inSessionSet.weight
            lastReps = inSessionSet.reps
        } else if let lastRecord = workoutRepo.fetchLastRecord(exerciseId: exercise.id) {
            currentWeight = lastRecord.weight
            currentReps = lastRecord.reps
            lastWeight = lastRecord.weight
            lastReps = lastRecord.reps
        } else {
            // 履歴なし
            currentWeight = isBodyweight ? 0 : 0
            currentReps = 10
            lastWeight = nil
            lastReps = nil
        }
    }

    // 提案種目リスト（メニュー自動提案から受け取った種目）
    var recommendedExercises: [RecommendedExercise] = []

    /// メニュー自動提案の種目を適用（最初の種目を選択、提案重量をセット）
    func applyRecommendedExercises(_ exercises: [RecommendedExercise]) {
        recommendedExercises = exercises

        // 最初の種目を選択
        guard let first = exercises.first,
              let definition = exerciseStore.exercise(for: first.exerciseId) else { return }

        selectExercise(definition)

        // 提案重量・レップ数で上書き（前回記録がある場合のみ重量を提案値に）
        if first.suggestedWeight > 0 {
            currentWeight = first.suggestedWeight
        }
        currentReps = first.suggestedReps
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

        // ルーティン完了状態を更新
        if activeRoutineDay != nil {
            routineExerciseCompletion[exercise.id] = true
        }

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

    /// タイマーを開始（カウントダウン → 0到達でハプティック → オーバータイムへ）
    func startRestTimer() {
        restTimer?.invalidate()
        restTimerStartDate = Date()
        restTimerDuration = AppState.shared.defaultRestTimerDuration
        restTimerSeconds = restTimerDuration
        isRestTimerRunning = true
        isRestTimerOvertime = false
        hasPlayedCompletionHaptic = false
        hasPlayedWarningHaptic = false

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickRestTimer()
            }
        }
    }

    /// タイマーの1秒ごとの処理
    private func tickRestTimer() {
        guard isRestTimerRunning, let startDate = restTimerStartDate else { return }

        let elapsed = Int(Date().timeIntervalSince(startDate))

        if elapsed < restTimerDuration {
            // カウントダウン中
            restTimerSeconds = restTimerDuration - elapsed
            isRestTimerOvertime = false
            // 残り10秒で警告ハプティック（1回だけ）
            if restTimerSeconds == 10, !hasPlayedWarningHaptic {
                hasPlayedWarningHaptic = true
                HapticManager.lightTap()
            }
        } else {
            // オーバータイム
            restTimerSeconds = elapsed - restTimerDuration
            if !isRestTimerOvertime {
                isRestTimerOvertime = true
            }
            // 完了ハプティック（1回だけ）
            if !hasPlayedCompletionHaptic {
                hasPlayedCompletionHaptic = true
                HapticManager.restTimerCompleted()
            }
        }
    }

    /// タイマーを停止
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerRunning = false
        isRestTimerOvertime = false
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
        guard isRestTimerRunning, restTimerStartDate != nil else { return }
        tickRestTimer()
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
    /// セッション全体の全セットから筋肉ごとの合計セット数を累積して渡す
    private func updateMuscleStimulations(exercise: ExerciseDefinition, session: WorkoutSession) {
        // セッション全体の全セットから、筋肉ごとの合計セット数を計算
        var muscleTotalSets: [String: Int] = [:]
        for set in session.sets {
            guard let ex = exerciseStore.exercise(for: set.exerciseId) else { continue }
            for (muscleId, _) in ex.muscleMapping {
                muscleTotalSets[muscleId, default: 0] += 1
            }
        }

        // 今の種目がターゲットにする筋肉のみ更新
        for (muscleId, percentage) in exercise.muscleMapping {
            guard let muscle = Muscle(rawValue: muscleId) else { continue }
            let accumulatedSets = muscleTotalSets[muscleId] ?? 1
            muscleStateRepo.upsertStimulation(
                muscle: muscle,
                sessionId: session.id,
                maxIntensity: Double(percentage) / 100.0,
                totalSets: accumulatedSets,
                saveImmediately: false
            )
        }
        muscleStateRepo.save()
    }
}

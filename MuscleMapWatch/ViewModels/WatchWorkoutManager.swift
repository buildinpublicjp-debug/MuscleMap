import Foundation
import WatchConnectivity

// MARK: - Watch用セット記録（軽量構造体）

struct WatchRecordedSet: Identifiable {
    let id: UUID
    let exerciseId: String
    let exerciseName: String
    let setNumber: Int
    let weight: Double
    let reps: Int
    let completedAt: Date

    init(
        id: UUID = UUID(),
        exerciseId: String,
        exerciseName: String,
        setNumber: Int,
        weight: Double,
        reps: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.completedAt = completedAt
    }
}

// MARK: - Watch ワークアウトマネージャー
// Watchアプリの中心的なViewModel。セッション管理、セット記録、レストタイマーを担当

@Observable
final class WatchWorkoutManager {

    // MARK: - セッション状態
    var activeSessionId: UUID?
    var sessionStartDate: Date?

    /// セッションが進行中かどうか
    var isSessionActive: Bool { activeSessionId != nil }

    // MARK: - エクササイズ選択
    var selectedExercise: WatchExerciseInfo?

    // MARK: - 現在のセット入力値
    var currentWeight: Double = 0
    var currentReps: Int = 10
    var currentSetNumber: Int = 1

    // MARK: - 記録済みセット（セッション内）
    var recordedSets: [WatchRecordedSet] = []

    // MARK: - エクササイズストア参照
    let exerciseStore = WatchExerciseStore()

    // MARK: - レストタイマー
    var restTimerSeconds: Int = 0           // カウントダウン中: 残り秒数, オーバータイム: 経過秒数
    var isRestTimerRunning: Bool = false
    var isRestTimerOvertime: Bool = false    // カウントダウン完了後のオーバータイム状態
    private var restTimer: Timer?
    private var restTimerStartDate: Date?    // バックグラウンド復帰時の補正用
    private var restTimerDuration: Int = 90  // このタイマーセッションの設定秒数
    private var hasPlayedCompletionHaptic: Bool = false

    // MARK: - 前回の記録（iPhone側から取得）
    var lastWeight: Double?
    var lastReps: Int?

    // MARK: - セッション操作

    /// ワークアウトセッションを開始
    func startSession() {
        let sessionId = UUID()
        activeSessionId = sessionId
        sessionStartDate = Date()
        recordedSets = []
        currentSetNumber = 1

        // iPhone側に同期
        let record = WatchSyncRecord.sessionStart(sessionId: sessionId)
        WatchPendingSyncStore.shared.queue(record)

        #if DEBUG
        print("[WatchWorkoutManager] セッション開始: \(sessionId)")
        #endif
    }

    /// エクササイズを選択し、セット番号と前回記録を更新
    func selectExercise(_ exercise: WatchExerciseInfo) {
        selectedExercise = exercise

        // このセッション内で同じ種目の既存セット数からセット番号を計算
        let existingSets = recordedSets.filter { $0.exerciseId == exercise.id }
        currentSetNumber = existingSets.count + 1

        // 前回記録をリセット（iPhoneからのレスポンスで更新される）
        lastWeight = nil
        lastReps = nil

        // iPhone側に前回記録をリクエスト
        requestLastRecord(exerciseId: exercise.id)
    }

    /// セットを記録
    func recordSet() {
        guard let sessionId = activeSessionId,
              let exercise = selectedExercise else { return }

        // バリデーション: レップ数は最低1回必要
        guard currentReps >= 1 else { return }

        // 重量は0以上に補正
        let validatedWeight = max(0, currentWeight)

        let setId = UUID()

        // ローカライズされた種目名を取得
        let language = UserDefaults.standard.string(forKey: WatchSyncKeys.language) ?? "ja"
        let exerciseName = language == "ja" ? exercise.nameJA : exercise.nameEN

        // 記録済みセットに追加
        let recorded = WatchRecordedSet(
            id: setId,
            exerciseId: exercise.id,
            exerciseName: exerciseName,
            setNumber: currentSetNumber,
            weight: validatedWeight,
            reps: currentReps
        )
        recordedSets.append(recorded)

        // iPhone側に同期
        let syncRecord = WatchSyncRecord.setRecorded(
            sessionId: sessionId,
            setId: setId,
            exerciseId: exercise.id,
            setNumber: currentSetNumber,
            weight: validatedWeight,
            reps: currentReps
        )
        WatchPendingSyncStore.shared.queue(syncRecord)

        // ハプティックフィードバック
        WatchHapticManager.setRecorded()

        // 次のセットへ
        currentSetNumber += 1

        // レストタイマーを開始
        startRestTimer()

        #if DEBUG
        print("[WatchWorkoutManager] セット記録: \(exercise.id) Set\(recorded.setNumber) \(validatedWeight)kg x \(currentReps)")
        #endif
    }

    /// ワークアウトセッションを終了
    func endSession() {
        guard let sessionId = activeSessionId else { return }

        // iPhone側に同期
        let record = WatchSyncRecord.sessionEnd(sessionId: sessionId)
        WatchPendingSyncStore.shared.queue(record)

        // ハプティックフィードバック
        WatchHapticManager.workoutEnded()

        // 状態をリセット
        activeSessionId = nil
        sessionStartDate = nil
        selectedExercise = nil
        recordedSets = []
        currentWeight = 0
        currentReps = 10
        currentSetNumber = 1
        lastWeight = nil
        lastReps = nil
        stopRestTimer()

        #if DEBUG
        print("[WatchWorkoutManager] セッション終了: \(sessionId)")
        #endif
    }

    // MARK: - 入力値の調整

    /// 重量を調整（デルタ値で加減）
    func adjustWeight(by delta: Double) {
        currentWeight = max(0, currentWeight + delta)
        WatchHapticManager.stepperChanged()
    }

    /// レップ数を調整（デルタ値で加減）
    func adjustReps(by delta: Int) {
        currentReps = max(1, currentReps + delta)
        WatchHapticManager.stepperChanged()
    }

    // MARK: - レストタイマー（カウントダウン → オーバータイム）

    /// タイマーを開始（iPhone側と同じカウントダウン＋オーバータイムパターン）
    func startRestTimer() {
        restTimer?.invalidate()
        restTimerStartDate = Date()

        // UserDefaultsから同期された設定値を取得（デフォルト90秒）
        let syncedDuration = UserDefaults.standard.object(forKey: WatchSyncKeys.restTimerDuration) as? Int
        restTimerDuration = syncedDuration ?? 90

        restTimerSeconds = restTimerDuration
        isRestTimerRunning = true
        isRestTimerOvertime = false
        hasPlayedCompletionHaptic = false

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickRestTimer()
        }
    }

    /// タイマーを停止
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerRunning = false
        isRestTimerOvertime = false
        restTimerStartDate = nil
        restTimerSeconds = 0
    }

    /// タイマーの1秒ごとの処理
    private func tickRestTimer() {
        guard isRestTimerRunning, let startDate = restTimerStartDate else { return }

        let elapsed = Int(Date().timeIntervalSince(startDate))

        if elapsed < restTimerDuration {
            // カウントダウン中
            restTimerSeconds = restTimerDuration - elapsed
            isRestTimerOvertime = false
        } else {
            // オーバータイム
            restTimerSeconds = elapsed - restTimerDuration
            if !isRestTimerOvertime {
                isRestTimerOvertime = true
            }
            // 完了ハプティック（1回だけ）
            if !hasPlayedCompletionHaptic {
                hasPlayedCompletionHaptic = true
                WatchHapticManager.restTimerCompleted()
            }
        }
    }

    // MARK: - iPhone連携

    /// iPhoneに前回記録をリクエスト（sendMessageで即時通信）
    private func requestLastRecord(exerciseId: String) {
        guard WCSession.default.isReachable else {
            #if DEBUG
            print("[WatchWorkoutManager] iPhoneに到達不可、前回記録のリクエストをスキップ")
            #endif
            return
        }

        let message: [String: Any] = [
            "request": "lastRecord",
            "exerciseId": exerciseId
        ]

        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            guard let self = self else { return }
            // iPhoneからの前回記録を反映
            if let weight = reply["weight"] as? Double,
               let reps = reply["reps"] as? Int {
                self.lastWeight = weight
                self.lastReps = reps
                // 前回記録があれば入力値にも反映
                self.currentWeight = weight
                self.currentReps = reps
            }
            #if DEBUG
            print("[WatchWorkoutManager] 前回記録を受信: weight=\(reply["weight"] ?? "nil"), reps=\(reply["reps"] ?? "nil")")
            #endif
        }, errorHandler: { error in
            #if DEBUG
            print("[WatchWorkoutManager] 前回記録リクエスト失敗: \(error.localizedDescription)")
            #endif
        })
    }
}

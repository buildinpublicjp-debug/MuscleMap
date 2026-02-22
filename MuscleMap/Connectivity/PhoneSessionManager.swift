import Foundation
import WatchConnectivity
import SwiftData

// MARK: - iPhone側 WatchConnectivity セッション管理

@MainActor @Observable
final class PhoneSessionManager: NSObject {
    static let shared = PhoneSessionManager()

    /// WatchDataProcessorに渡すModelContext（RootView.onAppearで設定する）
    var modelContext: ModelContext?

    /// Watch接続状態
    private(set) var isWatchReachable = false

    private override init() {
        super.init()
        activateSession()
    }

    // MARK: - セッション開始

    /// WCSessionを有効化
    private func activateSession() {
        guard WCSession.isSupported() else {
            #if DEBUG
            print("[PhoneSessionManager] WCSession is not supported on this device")
            #endif
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #if DEBUG
        print("[PhoneSessionManager] WCSession activation requested")
        #endif
    }

    // MARK: - コンテキスト送信

    /// Watch側にapplicationContextを送信（エクササイズ一覧・設定など）
    func sendContextToWatch() {
        guard WCSession.default.activationState == .activated else {
            #if DEBUG
            print("[PhoneSessionManager] Session not activated, skipping context send")
            #endif
            return
        }

        // エクササイズ一覧をWatchExerciseInfoに変換してJSON→Base64
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        let watchExercises: [WatchExerciseInfo] = store.exercises.map { def in
            WatchExerciseInfo(
                id: def.id,
                nameEN: def.nameEN,
                nameJA: def.nameJA,
                category: def.category,
                equipment: def.equipment,
                muscleMapping: def.muscleMapping
            )
        }

        var exercisesBase64 = ""
        do {
            let jsonData = try JSONEncoder().encode(watchExercises)
            exercisesBase64 = jsonData.base64EncodedString()
        } catch {
            #if DEBUG
            print("[PhoneSessionManager] Failed to encode exercises: \(error)")
            #endif
        }

        // 最近使った種目・お気に入り
        let recentIds = RecentExercisesManager.shared.recentIds
        let favoriteIds = Array(FavoritesManager.shared.favoriteIds)

        // 設定
        let weightUnit = AppState.shared.weightUnit.rawValue
        let restTimerDuration = AppState.shared.defaultRestTimerDuration
        let language = LocalizationManager.shared.currentLanguage.rawValue

        // applicationContext 辞書を構築
        let context: [String: Any] = [
            WatchSyncKeys.exercises: exercisesBase64,
            WatchSyncKeys.recentIds: recentIds,
            WatchSyncKeys.favoriteIds: favoriteIds,
            WatchSyncKeys.weightUnit: weightUnit,
            WatchSyncKeys.restTimerDuration: restTimerDuration,
            WatchSyncKeys.language: language
        ]

        do {
            try WCSession.default.updateApplicationContext(context)
            #if DEBUG
            print("[PhoneSessionManager] applicationContext sent (\(watchExercises.count) exercises)")
            #endif
        } catch {
            #if DEBUG
            print("[PhoneSessionManager] Failed to send applicationContext: \(error)")
            #endif
        }
    }

    // MARK: - 前回記録の検索（sendMessageリプライ用）

    /// [Fix #3] 指定エクササイズの直近セッションの第1セットを返す
    /// WorkoutRepository.fetchLastRecord と同じロジック（疲労で後半セットは重量が下がるため第1セット基準）
    private func fetchLastRecord(exerciseId: String) -> [String: Any]? {
        guard let modelContext else {
            #if DEBUG
            print("[PhoneSessionManager] modelContext is nil, cannot fetch last record")
            #endif
            return nil
        }

        // まず直近のセットを取得してセッションを特定
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            guard let latestSet = try modelContext.fetch(descriptor).first,
                  let session = latestSet.session else {
                return nil
            }

            // そのセッションの第1セットを返す（WorkoutRepositoryと同じロジック）
            let firstSet = session.sets
                .filter { $0.exerciseId == exerciseId }
                .sorted { $0.setNumber < $1.setNumber }
                .first ?? latestSet

            return [
                "exerciseId": firstSet.exerciseId,
                "weight": firstSet.weight,
                "reps": firstSet.reps,
                "setNumber": firstSet.setNumber,
                "completedAt": firstSet.completedAt.timeIntervalSince1970
            ]
        } catch {
            #if DEBUG
            print("[PhoneSessionManager] Failed to fetch last record: \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneSessionManager: WCSessionDelegate {

    /// セッション有効化完了
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        #if DEBUG
        print("[PhoneSessionManager] Activation completed: \(activationState.rawValue), error: \(String(describing: error))")
        #endif

        if activationState == .activated {
            Task { @MainActor in
                self.isWatchReachable = session.isReachable
                self.sendContextToWatch()
            }
        }
    }

    /// iPhoneでは必須: sessionDidBecomeInactive
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        #if DEBUG
        print("[PhoneSessionManager] Session did become inactive")
        #endif
    }

    /// iPhoneでは必須: sessionDidDeactivate
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        #if DEBUG
        print("[PhoneSessionManager] Session did deactivate, reactivating...")
        #endif
        // 新しいApple Watchとのペアリング用に再アクティベート
        session.activate()
    }

    /// Watch到達可能状態の変更
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
            #if DEBUG
            print("[PhoneSessionManager] Reachability changed: \(session.isReachable)")
            #endif
        }
    }

    /// Watchからのリアルタイムメッセージ受信（前回記録リクエスト等）
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // "lastRecord" リクエストの処理
        guard let request = message["request"] as? String,
              request == "lastRecord",
              let exerciseId = message["exerciseId"] as? String else {
            replyHandler(["error": "unknown request"])
            return
        }

        Task { @MainActor in
            if let record = self.fetchLastRecord(exerciseId: exerciseId) {
                replyHandler(record)
            } else {
                replyHandler(["error": "no record found"])
            }
        }
    }

    /// WatchからのtransferUserInfo受信（セット記録・セッション開始/終了）
    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        Task { @MainActor in
            guard let modelContext = self.modelContext else {
                #if DEBUG
                print("[PhoneSessionManager] modelContext is nil, cannot process userInfo")
                #endif
                return
            }

            let processor = WatchDataProcessor(modelContext: modelContext)
            processor.process(userInfo)

            #if DEBUG
            print("[PhoneSessionManager] Processed userInfo: \(userInfo["type"] as? String ?? "unknown")")
            #endif
        }
    }
}

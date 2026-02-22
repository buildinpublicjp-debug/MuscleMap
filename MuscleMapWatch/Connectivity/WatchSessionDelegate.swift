import Foundation
import WatchConnectivity

// MARK: - Watch側 WCSessionDelegate
// iPhoneとのWatch Connectivity通信を管理
// applicationContextで種目データ・設定を受信し、WatchExerciseStoreを更新

final class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()

    /// WatchWorkoutManagerへの参照（循環参照防止のため弱参照は使わず、Appで設定）
    var workoutManager: WatchWorkoutManager?

    // MARK: - 初期化・セッション起動

    private override init() {
        super.init()
    }

    /// WCSessionをアクティベート
    func activate() {
        guard WCSession.isSupported() else {
            #if DEBUG
            print("[WatchSessionDelegate] WCSessionがサポートされていません")
            #endif
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        #if DEBUG
        print("[WatchSessionDelegate] WCSessionアクティベーション開始")
        #endif
    }

    // MARK: - WCSessionDelegate 必須メソッド

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            #if DEBUG
            print("[WatchSessionDelegate] アクティベーション失敗: \(error.localizedDescription)")
            #endif
            return
        }
        #if DEBUG
        print("[WatchSessionDelegate] アクティベーション完了: \(activationState.rawValue)")
        #endif

        // アクティベーション完了時に未送信レコードをフラッシュ
        WatchPendingSyncStore.shared.flush()
    }

    // MARK: - applicationContext受信（iPhone→Watch データ同期）

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        #if DEBUG
        print("[WatchSessionDelegate] applicationContext受信: \(applicationContext.keys)")
        #endif

        guard let manager = workoutManager else {
            #if DEBUG
            print("[WatchSessionDelegate] workoutManagerが未設定")
            #endif
            return
        }

        // エクササイズデータの同期
        if let exercisesBase64 = applicationContext[WatchSyncKeys.exercises] as? String,
           let exercisesData = Data(base64Encoded: exercisesBase64) {
            manager.exerciseStore.loadFromSync(data: exercisesData)
        }

        // 最近使った種目IDの同期
        if let recentIds = applicationContext[WatchSyncKeys.recentIds] as? [String] {
            manager.exerciseStore.updateRecentIds(recentIds)
        }

        // お気に入りIDの同期
        if let favoriteIds = applicationContext[WatchSyncKeys.favoriteIds] as? [String] {
            manager.exerciseStore.updateFavoriteIds(favoriteIds)
        }

        // 重量単位の同期
        if let weightUnit = applicationContext[WatchSyncKeys.weightUnit] as? String {
            UserDefaults.standard.set(weightUnit, forKey: WatchSyncKeys.weightUnit)
        }

        // レストタイマー設定の同期
        if let restDuration = applicationContext[WatchSyncKeys.restTimerDuration] as? Int {
            UserDefaults.standard.set(restDuration, forKey: WatchSyncKeys.restTimerDuration)
        }

        // 言語設定の同期
        if let language = applicationContext[WatchSyncKeys.language] as? String {
            UserDefaults.standard.set(language, forKey: WatchSyncKeys.language)
        }
    }

    // MARK: - sendMessage受信（iPhone→Watch リアルタイムメッセージ）

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        #if DEBUG
        print("[WatchSessionDelegate] メッセージ受信: \(message)")
        #endif
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        #if DEBUG
        print("[WatchSessionDelegate] メッセージ受信（返信あり）: \(message)")
        #endif

        // 必要に応じてiPhoneからのリクエストに応答
        replyHandler(["status": "ok"])
    }
}

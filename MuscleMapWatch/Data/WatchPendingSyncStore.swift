import Foundation
import WatchConnectivity

// MARK: - Watch→iPhone 同期キュー
// WatchSyncRecordをtransferUserInfoでiPhoneに送信するラッパー
// transferUserInfo自体がOS側でキューイングするため、このクラスは薄いラッパー

final class WatchPendingSyncStore {
    static let shared = WatchPendingSyncStore()

    // MARK: - 定数
    private let pendingKey = "watchPendingSyncRecords"

    // MARK: - プロパティ
    private(set) var pendingRecords: [WatchSyncRecord] = []

    // MARK: - 初期化

    private init() {
        loadFromDefaults()
    }

    // MARK: - キューに追加

    /// レコードをキューに追加し、即座にフラッシュを試みる
    func queue(_ record: WatchSyncRecord) {
        pendingRecords.append(record)
        saveToDefaults()
        flush()
    }

    // MARK: - フラッシュ（送信）

    /// 保留中の全レコードをtransferUserInfoで送信
    func flush() {
        guard WCSession.default.activationState == .activated else {
            #if DEBUG
            print("[WatchPendingSyncStore] WCSessionが未アクティブ、送信をスキップ")
            #endif
            return
        }

        // 送信成功したレコードを追跡
        var sentIndices: [Int] = []

        for (index, record) in pendingRecords.enumerated() {
            let dict = record.asDictionary
            WCSession.default.transferUserInfo(dict)
            sentIndices.append(index)
            #if DEBUG
            print("[WatchPendingSyncStore] transferUserInfo送信: \(record.type.rawValue)")
            #endif
        }

        // 送信済みレコードを除去（逆順で安全に削除）
        for index in sentIndices.reversed() {
            pendingRecords.remove(at: index)
        }
        saveToDefaults()
    }

    /// 指定レコードを送信済みとしてキューから除去
    func removeSent(_ record: WatchSyncRecord) {
        pendingRecords.removeAll { $0.timestamp == record.timestamp && $0.type == record.type }
        saveToDefaults()
    }

    // MARK: - 永続化（UserDefaults）

    /// UserDefaultsに保存（アプリ終了時にもデータが残る）
    private func saveToDefaults() {
        do {
            let data = try JSONEncoder().encode(pendingRecords)
            UserDefaults.standard.set(data, forKey: pendingKey)
        } catch {
            #if DEBUG
            print("[WatchPendingSyncStore] 保存に失敗: \(error)")
            #endif
        }
    }

    /// UserDefaultsから復元
    private func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: pendingKey) else { return }
        do {
            pendingRecords = try JSONDecoder().decode([WatchSyncRecord].self, from: data)
            #if DEBUG
            print("[WatchPendingSyncStore] \(pendingRecords.count)件の未送信レコードを復元")
            #endif
        } catch {
            #if DEBUG
            print("[WatchPendingSyncStore] 復元に失敗: \(error)")
            #endif
            pendingRecords = []
        }
    }
}

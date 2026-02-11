import Foundation

// MARK: - APIキー管理

enum KeyManager {
    private static let service = "com.buildinpublic.MuscleMap.keys"

    enum KeyType: String {
        case revenueCat = "revenuecat_api_key"
    }

    // MARK: - RevenueCat API Key

    /// RevenueCat APIキー
    /// ReleaseビルドではInfo.plistから読み込み、なければハードコードフォールバック
    /// DEBUGビルドではプレースホルダーを返す（開発中）
    private static var obfuscatedRevenueCatKey: String {
        #if DEBUG
        return "YOUR_REVENUECAT_API_KEY"
        #else
        // Info.plistにキーがあればそちらを優先
        if let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
           !key.isEmpty {
            return key
        }
        // フォールバック: project.ymlで設定済みのAPIキー
        return "appl_IzrrBdSVXMDZUylPnwcaJxvdlxb"
        #endif
    }

    // MARK: - 初期化

    /// 初回起動時にAPIキーをKeychainにセットアップ
    static func setupKeysIfNeeded() {
        // RevenueCat APIキー
        if getKey(.revenueCat) == nil {
            let key = obfuscatedRevenueCatKey
            if key != "YOUR_REVENUECAT_API_KEY" {
                saveKey(key, for: .revenueCat)
            }
        }
    }

    // MARK: - CRUD操作

    /// キーを保存
    static func saveKey(_ key: String, for type: KeyType) {
        guard !key.isEmpty, let data = key.data(using: .utf8) else { return }
        try? KeychainHelper.save(data, service: service, account: type.rawValue)
    }

    /// キーを取得
    static func getKey(_ type: KeyType) -> String? {
        guard let data = KeychainHelper.read(service: service, account: type.rawValue) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// キーを削除
    static func deleteKey(_ type: KeyType) {
        KeychainHelper.delete(service: service, account: type.rawValue)
    }

    // MARK: - ヘルパー

    /// RevenueCat APIキーが設定されているか
    static var hasRevenueCatKey: Bool {
        guard let key = getKey(.revenueCat) else { return false }
        return !key.isEmpty && key != "YOUR_REVENUECAT_API_KEY"
    }
}

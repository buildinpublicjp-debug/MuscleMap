import Foundation

// MARK: - APIキー管理

enum KeyManager {
    private static let service = "com.buildinpublic.MuscleMap.keys"

    enum KeyType: String {
        case generic = "generic_api_key"
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
}

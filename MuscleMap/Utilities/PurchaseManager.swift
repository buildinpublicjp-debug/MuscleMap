import Foundation
import RevenueCat

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// DEBUGビルドでPro状態を強制切替するフラグ（nil=RevenueCat判定を使用）
    #if DEBUG
    var debugOverridePremium: Bool? = nil
    /// true にするとDEBUGビルドで常にPro扱いになる（テスト用）
    private let forceProForTesting = false
    #endif

    /// Pro課金状態（DEBUG時はオーバーライド優先）
    var isPremium: Bool {
        #if DEBUG
        if forceProForTesting { return true }
        if let override = debugOverridePremium {
            return override
        }
        #endif
        return _isPremium
    }

    /// RevenueCatから取得した実際の課金状態
    fileprivate var _isPremium: Bool = false

    var isLoading: Bool = false

    func configure() {
        Purchases.configure(withAPIKey: "appl_IzrrBdSVXMDZUylPnwcaJxvdlxb")
        Purchases.shared.delegate = PurchaseDelegate.shared
        Task { await refreshPremiumStatus() }
    }

    func refreshPremiumStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            _isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            #if DEBUG
            print("RevenueCat customerInfo error: \(error)")
            #endif
        }
    }

    /// 購入実行。成功時は true を返す。失敗時は PurchaseError を throw。
    @discardableResult
    func purchase(productId: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else {
            throw PurchaseError.noOffering
        }

        let package: Package?
        if productId == "yearly" {
            package = offering.annual
                ?? offering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier.lowercased().contains("year")
                    || $0.storeProduct.productIdentifier.lowercased().contains("annual")
                    || $0.packageType == .annual
                })
        } else {
            package = offering.monthly
                ?? offering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier.lowercased().contains("month")
                    || $0.packageType == .monthly
                })
        }

        guard let pkg = package else {
            throw PurchaseError.packageNotFound
        }

        let result = try await Purchases.shared.purchase(package: pkg)

        if result.userCancelled { return false }

        _isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
        return isPremium
    }

    /// 購入復元。成功時は true を返す。失敗時は throw。
    @discardableResult
    func restore() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        _isPremium = info.entitlements["premium"]?.isActive == true
        return isPremium
    }

    // MARK: - 週間ワークアウト制限（無料ユーザー向け）

    /// 無料ユーザーの週間ワークアウト上限（週2回で超回復サイクルを1回体験可能）
    static let weeklyFreeLimit = 2

    private static let weeklyWorkoutCountKey = "weeklyWorkoutCount"
    private static let weeklyResetDateKey = "weeklyResetDate"

    /// 今週のワークアウト記録回数
    var weeklyWorkoutCount: Int {
        resetIfNewWeek()
        return UserDefaults.standard.integer(forKey: Self.weeklyWorkoutCountKey)
    }

    /// ワークアウト記録が可能か（Pro or 週間上限未満）
    var canRecordWorkout: Bool {
        isPremium || weeklyWorkoutCount < Self.weeklyFreeLimit
    }

    /// ワークアウト記録カウントをインクリメント
    func incrementWorkoutCount() {
        resetIfNewWeek()
        let current = UserDefaults.standard.integer(forKey: Self.weeklyWorkoutCountKey)
        UserDefaults.standard.set(current + 1, forKey: Self.weeklyWorkoutCountKey)
    }

    /// 週が変わっていたらカウントをリセット
    private func resetIfNewWeek() {
        let calendar = Calendar.current
        let now = Date()
        if let lastReset = UserDefaults.standard.object(forKey: Self.weeklyResetDateKey) as? Date {
            let lastWeek = calendar.component(.weekOfYear, from: lastReset)
            let currentWeek = calendar.component(.weekOfYear, from: now)
            let lastYear = calendar.component(.yearForWeekOfYear, from: lastReset)
            let currentYear = calendar.component(.yearForWeekOfYear, from: now)
            if lastWeek != currentWeek || lastYear != currentYear {
                UserDefaults.standard.set(0, forKey: Self.weeklyWorkoutCountKey)
                UserDefaults.standard.set(now, forKey: Self.weeklyResetDateKey)
            }
        } else {
            UserDefaults.standard.set(now, forKey: Self.weeklyResetDateKey)
        }
    }

    private init() {}
}

// MARK: - エラー型

enum PurchaseError: LocalizedError {
    case noOffering
    case packageNotFound

    var errorDescription: String? {
        switch self {
        case .noOffering:      return "購入情報を取得できませんでした。再度お試しください。"
        case .packageNotFound: return "対象のプランが見つかりませんでした。"
        }
    }
}

// MARK: - Delegate

final class PurchaseDelegate: NSObject, PurchasesDelegate {
    static let shared = PurchaseDelegate()
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            PurchaseManager.shared._isPremium = customerInfo.entitlements["premium"]?.isActive == true
        }
    }
}

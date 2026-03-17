import Foundation
import RevenueCat

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// DEBUGビルドでPro状態を強制切替するフラグ（nil=RevenueCat判定を使用）
    #if DEBUG
    var debugOverridePremium: Bool? = true
    #endif

    /// Pro課金状態（DEBUG時はオーバーライド優先）
    var isPremium: Bool {
        #if DEBUG
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

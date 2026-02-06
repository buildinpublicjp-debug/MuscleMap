import Foundation
import RevenueCat

// MARK: - 課金マネージャー（RevenueCat）

@MainActor
@Observable
class PurchaseManager {
    static let shared = PurchaseManager()

    // Entitlement ID
    private static let premiumEntitlementID = "pro"

    // RevenueCat API Key（Keychainから取得）
    private static var apiKey: String {
        KeyManager.getKey(.revenueCat) ?? ""
    }

    /// APIキーが有効か
    private static var hasValidAPIKey: Bool {
        KeyManager.hasRevenueCatKey
    }

    // 状態
    var isPremium: Bool = false
    var currentOffering: Offering?
    var isLoading: Bool = false

    // 利用可能なパッケージ
    var monthlyPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .monthly }
    }
    var annualPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .annual }
    }
    var lifetimePackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .lifetime }
    }

    private init() {}

    // MARK: - 初期化

    /// RevenueCatを設定
    func configure() {
        guard Self.hasValidAPIKey else {
            // APIキー未設定時はスキップ（開発中）
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)
    }

    // MARK: - プレミアム状態チェック

    /// プレミアム状態を確認
    func checkPremiumStatus() async {
        guard Self.hasValidAPIKey else {
            isPremium = false
            return
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements[Self.premiumEntitlementID]?.isActive == true
        } catch {
            isPremium = false
        }
    }

    // MARK: - オファリング取得

    /// 利用可能なプランを取得
    func fetchOfferings() async {
        guard Self.hasValidAPIKey else { return }

        isLoading = true
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOffering = offerings.current
        } catch {
            self.currentOffering = nil
        }
        isLoading = false
    }

    // MARK: - 購入

    /// 購入結果
    enum PurchaseResult {
        case success
        case cancelled
        case failed
    }

    /// パッケージを購入
    func purchase(_ package: Package) async -> PurchaseResult {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                return .cancelled
            }
            isPremium = result.customerInfo.entitlements[Self.premiumEntitlementID]?.isActive == true
            return isPremium ? .success : .failed
        } catch {
            // ErrorCodeのpurchaseCancelledErrorをチェック
            if let errorCode = (error as? ErrorCode), errorCode == .purchaseCancelledError {
                return .cancelled
            }
            return .failed
        }
    }

    // MARK: - リストア

    /// 購入を復元
    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isPremium = customerInfo.entitlements[Self.premiumEntitlementID]?.isActive == true
            return isPremium
        } catch {
            return false
        }
    }
}

// MARK: - プレミアム機能ゲート

extension PurchaseManager {
    /// プレミアム機能が利用可能か
    var canAccessPremiumFeatures: Bool {
        // APIキー未設定時もPro機能は利用不可（isPremiumはfalseのまま）
        return isPremium
    }

    /// Pro機能が利用可能か（canAccessPremiumFeaturesのエイリアス）
    var isProUser: Bool { canAccessPremiumFeatures }
}

import Foundation

// MARK: - 課金管理（Pro機能ゲート）

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    // TODO: RevenueCat差し込みポイント
    // 1. import RevenueCat
    // 2. init() で Purchases.configure(withAPIKey: "your_api_key") を呼ぶ
    // 3. isPremium を Purchases.shared.customerInfo の entitlements["premium"] で判定
    // 4. purchase() メソッドで Purchases.shared.purchase(package:) を呼ぶ
    // 5. restore() メソッドで Purchases.shared.restorePurchases() を呼ぶ

    /// Pro版かどうか（開発中はtrue固定）
    var isPremium: Bool = true

    /// 初期化（現時点はno-op、RevenueCat差し込み時にconfigure処理を追加）
    func configure() {
        // TODO: Purchases.configure(withAPIKey: KeyManager.getKey(.revenueCat) ?? "")
    }

    /// 購入処理のスタブ
    /// - Parameter productId: 購入するプロダクトID（"monthly" or "yearly"）
    func purchase(productId: String) async {
        // TODO: RevenueCat購入処理
        // let package = ... // RevenueCatからパッケージ取得
        // let result = try await Purchases.shared.purchase(package: package)
        // isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
    }

    /// 購入復元のスタブ
    func restore() async {
        // TODO: RevenueCat復元処理
        // let customerInfo = try await Purchases.shared.restorePurchases()
        // isPremium = customerInfo.entitlements["premium"]?.isActive == true
    }

    private init() {}
}

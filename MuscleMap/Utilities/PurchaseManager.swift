import Foundation
import RevenueCat

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    var isPremium: Bool = false
    var isLoading: Bool = false

    func configure() {
        Purchases.configure(withAPIKey: "appl_IzrrBdSVXMDZUylPnwcaJxvdlxb")
        Purchases.shared.delegate = PurchaseDelegate.shared
        Task { await refreshPremiumStatus() }
    }

    func refreshPremiumStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            print("RevenueCat error: \(error)")
        }
    }

    func purchase(productId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else { return }
        let package = productId == "yearly" ? offering.annual : offering.monthly
        guard let pkg = package else { return }
        let result = try await Purchases.shared.purchase(package: pkg)
        isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
    }

    func restore() async throws {
        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        isPremium = info.entitlements["premium"]?.isActive == true
    }

    private init() {}
}

final class PurchaseDelegate: NSObject, PurchasesDelegate {
    static let shared = PurchaseDelegate()
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            PurchaseManager.shared.isPremium = customerInfo.entitlements["premium"]?.isActive == true
        }
    }
}

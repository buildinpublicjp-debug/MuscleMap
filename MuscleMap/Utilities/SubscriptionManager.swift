import Foundation
import RevenueCat

// MARK: - サブスクリプション管理プロトコル

/// テスト・プレビュー用に抽象化
@MainActor
protocol SubscriptionManaging {
    var isPremium: Bool { get }
    var isLoading: Bool { get }
    var monthlyPrice: String { get }
    var annualPrice: String { get }
    var lifetimePrice: String { get }

    func purchase(plan: PlanType) async -> Bool
    func restorePurchases() async -> Bool
}

// MARK: - PurchaseManagerをプロトコル準拠

extension PurchaseManager: SubscriptionManaging {
    var monthlyPrice: String {
        monthlyPackage?.localizedPriceString ?? "¥480"
    }
    var annualPrice: String {
        annualPackage?.localizedPriceString ?? "¥3,800"
    }
    var lifetimePrice: String {
        lifetimePackage?.localizedPriceString ?? "¥7,800"
    }

    func purchase(plan: PlanType) async -> Bool {
        let package: RevenueCat.Package?
        switch plan {
        case .monthly: package = monthlyPackage
        case .annual: package = annualPackage
        case .lifetime: package = lifetimePackage
        }
        guard let package else { return false }
        return await purchase(package)
    }
}

// MARK: - モック（プレビュー・テスト用）

@MainActor
@Observable
final class MockSubscriptionManager: SubscriptionManaging {
    var isPremium: Bool = false
    var isLoading: Bool = false

    var monthlyPrice: String = "¥480"
    var annualPrice: String = "¥3,800"
    var lifetimePrice: String = "¥7,800"

    func purchase(plan: PlanType) async -> Bool {
        isLoading = true
        try? await Task.sleep(for: .seconds(1))
        isLoading = false
        isPremium = true
        return true
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        try? await Task.sleep(for: .seconds(1))
        isLoading = false
        return false
    }
}

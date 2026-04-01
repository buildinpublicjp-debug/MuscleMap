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

    // MARK: - 動的価格（RevenueCatから取得）

    /// 月額のローカライズ済み価格文字列（例: "$4.99", "¥590"）
    var monthlyPriceString: String?
    /// 年額のローカライズ済み価格文字列（例: "$39.99", "¥4,900"）
    var yearlyPriceString: String?
    /// 年額を月換算した価格文字列（例: "$3.33", "¥408"）
    var yearlyPerMonthString: String?
    /// 年額の割引率（例: "31%"）
    var yearlyDiscountPercent: String?

    /// 月額のCTAボタンテキスト（ローカライズ済み）
    var monthlyButtonText: String {
        if let price = monthlyPriceString {
            let lang = LocalizationManager.shared.currentLanguage
            switch lang {
            case .japanese:
                return "毎月 \(price) 開始"
            case .chineseSimplified:
                return "每月 \(price) 开始"
            case .korean:
                return "월 \(price) 시작"
            case .spanish:
                return "\(price)/mes"
            case .french:
                return "\(price)/mois"
            case .german:
                return "\(price)/Monat"
            default:
                return "\(price)/mo"
            }
        }
        return L10n.pwMonthlyButton
    }

    /// 年額の説明テキスト（ローカライズ済み）
    var yearlyPriceText: String {
        if let yearlyPrice = yearlyPriceString, let perMonth = yearlyPerMonthString {
            let lang = LocalizationManager.shared.currentLanguage
            switch lang {
            case .japanese:
                return "年費 \(yearlyPrice) (月 \(perMonth))"
            case .chineseSimplified:
                return "年费 \(yearlyPrice) (月 \(perMonth))"
            case .korean:
                return "연간 \(yearlyPrice) (월 \(perMonth))"
            case .spanish:
                return "Anual \(yearlyPrice) (\(perMonth)/mes)"
            case .french:
                return "Annuel \(yearlyPrice) (\(perMonth)/mois)"
            case .german:
                return "Jährlich \(yearlyPrice) (\(perMonth)/Mo.)"
            default:
                return "Yearly \(yearlyPrice) (\(perMonth)/mo)"
            }
        }
        return L10n.pwYearlyPrice
    }

    /// Offeringsを取得して価格情報をキャッシュ
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else { return }

            // 月額パッケージ
            let monthlyPkg = offering.monthly
                ?? offering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier.lowercased().contains("month")
                    || $0.packageType == .monthly
                })

            // 年額パッケージ
            let yearlyPkg = offering.annual
                ?? offering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier.lowercased().contains("year")
                    || $0.storeProduct.productIdentifier.lowercased().contains("annual")
                    || $0.packageType == .annual
                })

            if let monthly = monthlyPkg {
                monthlyPriceString = monthly.storeProduct.localizedPriceString
            }

            if let yearly = yearlyPkg {
                yearlyPriceString = yearly.storeProduct.localizedPriceString

                // 月換算価格を計算
                let yearlyDecimal = yearly.storeProduct.price
                let perMonth = yearlyDecimal / 12
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = yearly.storeProduct.priceFormatter?.locale ?? Locale.current
                yearlyPerMonthString = formatter.string(from: perMonth as NSDecimalNumber)

                // 割引率を計算
                if let monthly = monthlyPkg {
                    let monthlyAnnualized = monthly.storeProduct.price * 12
                    if monthlyAnnualized > 0 {
                        let discount = ((monthlyAnnualized - yearlyDecimal) / monthlyAnnualized * 100)
                        let discountInt = Int(truncating: discount as NSDecimalNumber)
                        if discountInt > 0 {
                            yearlyDiscountPercent = "\(discountInt)%OFF"
                        }
                    }
                }
            }
        } catch {
            #if DEBUG
            print("fetchOfferings error: \(error)")
            #endif
        }
    }

    func configure() {
        Purchases.configure(withAPIKey: "appl_IzrrBdSVXMDZUylPnwcaJxvdlxb")
        Purchases.shared.delegate = PurchaseDelegate.shared
        Task {
            await refreshPremiumStatus()
            await fetchOfferings()
        }
    }

    /// CustomerInfoからエンタイトルメント状態を判定するヘルパー
    /// Sandbox環境では .isActive が遅延する場合があるため、
    /// activeInAnyEnvironment もフォールバックとしてチェックする
    fileprivate func checkEntitlement(in info: CustomerInfo) -> Bool {
        // 1. 標準チェック
        if info.entitlements["MuscleMap Pro"]?.isActive == true {
            return true
        }
        // 2. Sandbox環境フォールバック: activeInAnyEnvironment をチェック
        if info.entitlements.activeInAnyEnvironment["MuscleMap Pro"] != nil {
            return true
        }
        return false
    }

    func refreshPremiumStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            _isPremium = checkEntitlement(in: info)
        } catch {
            #if DEBUG
            print("RevenueCat customerInfo error: \(error)")
            #endif
        }
    }

    /// キャッシュを無効化してから最新のステータスを取得
    func forceRefreshPremiumStatus() async {
        Purchases.shared.invalidateCustomerInfoCache()
        await refreshPremiumStatus()
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

        // 購入結果から即座にチェック
        _isPremium = checkEntitlement(in: result.customerInfo)

        // Sandbox環境ではentitlementの反映が遅延する場合がある
        // キャッシュを無効化してリトライ
        if !_isPremium {
            Purchases.shared.invalidateCustomerInfoCache()
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
            await refreshPremiumStatus()
        }

        // それでもダメなら2回目のリトライ（1秒後）
        if !_isPremium {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            Purchases.shared.invalidateCustomerInfoCache()
            await refreshPremiumStatus()
        }

        return isPremium
    }

    /// 購入復元。成功時は true を返す。失敗時は throw。
    @discardableResult
    func restore() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        _isPremium = checkEntitlement(in: info)

        // リストア後もフォールバック
        if !_isPremium {
            Purchases.shared.invalidateCustomerInfoCache()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await refreshPremiumStatus()
        }

        return isPremium
    }

    // MARK: - 週間ワークアウト制限（無料ユーザー向け）

    /// 無料ユーザーの週間ワークアウト上限（週2回で超回復サイクルを1回体験可能）
    static let weeklyFreeLimit = 2

    private static let weeklyWorkoutCountKey = "weeklyWorkoutCount"
    private static let weeklyResetDateKey = "weeklyResetDate"

    /// 今週のワークアウト記録回数
    var weeklyWorkoutCount: Int {
        UserDefaults.standard.integer(forKey: Self.weeklyWorkoutCountKey)
    }

    /// ワークアウト記録が可能か（Pro or 週間上限未満）
    var canRecordWorkout: Bool {
        resetIfNewWeek()
        return isPremium || weeklyWorkoutCount < Self.weeklyFreeLimit
    }

    /// ワークアウト記録カウントをインクリメント
    func incrementWorkoutCount() {
        guard !isPremium else { return }
        resetIfNewWeek()
        let current = UserDefaults.standard.integer(forKey: Self.weeklyWorkoutCountKey)
        UserDefaults.standard.set(current + 1, forKey: Self.weeklyWorkoutCountKey)
    }

    /// 週が変わっていたらカウントをリセット（月曜始まり）
    private func resetIfNewWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 月曜リセット
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

@MainActor
enum PurchaseError: LocalizedError {
    case noOffering
    case packageNotFound

    nonisolated var errorDescription: String? {
        // Locale基準でフォールバック（MainActor外からも安全にアクセス）
        let ja = Locale.current.language.languageCode?.identifier == "ja"
        switch self {
        case .noOffering:
            return ja
                ? "購入情報を取得できませんでした。再度お試しください。"
                : "Could not load purchase info. Please try again."
        case .packageNotFound:
            return ja
                ? "対象のプランが見つかりませんでした。"
                : "The selected plan was not found."
        }
    }
}

// MARK: - Delegate

final class PurchaseDelegate: NSObject, PurchasesDelegate {
    static let shared = PurchaseDelegate()
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            PurchaseManager.shared._isPremium = PurchaseManager.shared.checkEntitlement(in: customerInfo)
        }
    }
}

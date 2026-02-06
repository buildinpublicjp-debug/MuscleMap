import Foundation
import WidgetKit

// MARK: - ウィジェット共有データ（簡素化版）

/// ウィジェットとメインアプリ間で共有するデータ
struct WidgetMuscleData: Codable {
    let updatedAt: Date
    let muscleStates: [String: MuscleSnapshot]

    struct MuscleSnapshot: Codable {
        let progress: Double          // 0.0-1.0 回復進捗
        let state: StateType          // 視覚状態

        enum StateType: String, Codable {
            case inactive
            case recovering
            case neglected
            case neglectedSevere
        }
    }
}

// MARK: - ウィジェットデータ書き込み（メインアプリ用）

enum WidgetDataProvider {
    static let suiteName = "group.com.buildinpublic.MuscleMap"
    static let dataKey = "widget_muscle_data"
    static let proStatusKey = "widget_is_pro_user"

    /// Pro状態を共有UserDefaultsに書き込む
    static func updateProStatus(_ isPro: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(isPro, forKey: proStatusKey)
    }

    /// 共有UserDefaultsにウィジェットデータを書き込む
    static func write(_ data: WidgetMuscleData) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: dataKey)

        // ウィジェットをリロード
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 共有UserDefaultsからウィジェットデータを読み込む
    static func read() -> WidgetMuscleData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetMuscleData.self, from: data) else {
            return nil
        }
        return decoded
    }

    /// 現在の筋肉状態からウィジェットデータを生成して書き込む
    /// 現在の筋肉状態からウィジェットデータを生成して書き込む（Pro状態も同期）
    @MainActor
    static func updateWidgetData(muscleStates: [Muscle: MuscleVisualState]) {
        // Pro状態を同期
        updateProStatus(PurchaseManager.shared.isProUser)
        var snapshots: [String: WidgetMuscleData.MuscleSnapshot] = [:]

        for (muscle, state) in muscleStates {
            let snapshot: WidgetMuscleData.MuscleSnapshot
            switch state {
            case .inactive:
                snapshot = .init(progress: 1.0, state: .inactive)
            case .recovering(let progress):
                snapshot = .init(progress: progress, state: .recovering)
            case .neglected(let fast):
                snapshot = .init(
                    progress: 1.0,
                    state: fast ? .neglectedSevere : .neglected
                )
            }
            snapshots[muscle.rawValue] = snapshot
        }

        let data = WidgetMuscleData(
            updatedAt: Date(),
            muscleStates: snapshots
        )

        write(data)
    }
}

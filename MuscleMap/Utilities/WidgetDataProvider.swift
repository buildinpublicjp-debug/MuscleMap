import Foundation

// MARK: - ウィジェット共有データ

/// ウィジェットとメインアプリ間で共有するデータ
struct WidgetMuscleData: Codable {
    let updatedAt: Date
    let streakDays: Int
    let suggestedGroup: String
    let suggestedReason: String
    let muscleStates: [String: MuscleSnapshot]

    struct MuscleSnapshot: Codable {
        let progress: Double          // 0.0-1.0 回復進捗
        let daysSinceStimulation: Int  // 未刺激日数
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

    /// 共有UserDefaultsにウィジェットデータを書き込む
    static func write(_ data: WidgetMuscleData) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: dataKey)
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
    @MainActor
    static func updateWidgetData(
        muscleStates: [Muscle: MuscleVisualState],
        streakDays: Int,
        suggestedGroup: MuscleGroup?,
        suggestedReason: String
    ) {
        var snapshots: [String: WidgetMuscleData.MuscleSnapshot] = [:]

        for (muscle, state) in muscleStates {
            let snapshot: WidgetMuscleData.MuscleSnapshot
            switch state {
            case .inactive:
                snapshot = .init(progress: 1.0, daysSinceStimulation: 0, state: .inactive)
            case .recovering(let progress):
                snapshot = .init(progress: progress, daysSinceStimulation: 0, state: .recovering)
            case .neglected(let fast):
                snapshot = .init(
                    progress: 1.0,
                    daysSinceStimulation: fast ? 14 : 7,
                    state: fast ? .neglectedSevere : .neglected
                )
            }
            snapshots[muscle.rawValue] = snapshot
        }

        let data = WidgetMuscleData(
            updatedAt: Date(),
            streakDays: streakDays,
            suggestedGroup: suggestedGroup?.rawValue ?? "chest",
            suggestedReason: suggestedReason,
            muscleStates: snapshots
        )

        write(data)
    }
}

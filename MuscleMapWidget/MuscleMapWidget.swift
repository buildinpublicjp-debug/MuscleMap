import WidgetKit
import SwiftUI

// MARK: - タイムラインエントリ（簡素化版）

struct MuscleMapEntry: TimelineEntry {
    let date: Date
    let muscleStates: [String: MuscleState]

    struct MuscleState {
        let progress: Double      // 0.0-1.0
        let stateType: StateType

        enum StateType {
            case inactive
            case recovering
            case neglected
            case neglectedSevere
        }

        var color: Color {
            switch stateType {
            case .inactive:
                return .mmMuscleInactive
            case .recovering:
                return recoveryColor(progress: progress)
            case .neglected, .neglectedSevere:
                return .mmMuscleNeglected
            }
        }

        private func recoveryColor(progress: Double) -> Color {
            switch progress {
            case ..<0.2:
                return .mmMuscleCoral
            case 0.2..<0.4:
                return .mmMuscleAmber
            case 0.4..<0.6:
                return .mmMuscleYellow
            case 0.6..<0.8:
                return .mmMuscleLime
            default:
                return .mmMuscleBioGreen
            }
        }
    }

    static let placeholder: MuscleMapEntry = {
        var states: [String: MuscleState] = [:]
        // プレースホルダー用のサンプルデータ
        states["chest_upper"] = MuscleState(progress: 0.3, stateType: .recovering)
        states["chest_lower"] = MuscleState(progress: 0.3, stateType: .recovering)
        states["lats"] = MuscleState(progress: 0.7, stateType: .recovering)
        states["traps_upper"] = MuscleState(progress: 0.5, stateType: .recovering)
        states["deltoid_anterior"] = MuscleState(progress: 0.6, stateType: .recovering)
        states["biceps"] = MuscleState(progress: 0.4, stateType: .recovering)
        states["quadriceps"] = MuscleState(progress: 0.9, stateType: .recovering)
        states["glutes"] = MuscleState(progress: 0.8, stateType: .recovering)
        return MuscleMapEntry(date: Date(), muscleStates: states)
    }()
}

// MARK: - タイムラインプロバイダ

struct MuscleMapTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MuscleMapEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MuscleMapEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MuscleMapEntry>) -> Void) {
        let entry = createEntry()
        // 15分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> MuscleMapEntry {
        guard let data = WidgetDataReader.read() else {
            return .placeholder
        }

        var states: [String: MuscleMapEntry.MuscleState] = [:]

        for (muscleId, snapshot) in data.muscleStates {
            let stateType: MuscleMapEntry.MuscleState.StateType
            switch snapshot.state {
            case .inactive:
                stateType = .inactive
            case .recovering:
                stateType = .recovering
            case .neglected:
                stateType = .neglected
            case .neglectedSevere:
                stateType = .neglectedSevere
            }
            states[muscleId] = MuscleMapEntry.MuscleState(
                progress: snapshot.progress,
                stateType: stateType
            )
        }

        return MuscleMapEntry(date: Date(), muscleStates: states)
    }
}

// MARK: - ウィジェットデータ読み込み

enum WidgetDataReader {
    static let suiteName = "group.com.buildinpublic.MuscleMap"
    static let dataKey = "widget_muscle_data"

    static func read() -> WidgetMuscleData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetMuscleData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Smallウィジェットビュー（前面のみ）

struct SmallWidgetView: View {
    let entry: MuscleMapEntry

    var body: some View {
        WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
            .padding(6)
            .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - Mediumウィジェットビュー（前面 + 背面）

struct MediumWidgetView: View {
    let entry: MuscleMapEntry

    var body: some View {
        HStack(spacing: 12) {
            WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
            WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: false)
        }
        .padding(10)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - Largeウィジェットビュー（前面 + 背面）

struct LargeWidgetView: View {
    let entry: MuscleMapEntry

    var body: some View {
        HStack(spacing: 20) {
            WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
            WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: false)
        }
        .padding(16)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - ウィジェット用筋肉マップビュー

struct WidgetMuscleMapView: View {
    let muscleStates: [String: MuscleMapEntry.MuscleState]
    let showFront: Bool

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                // シルエット（背景）
                if showFront {
                    MusclePathData.bodyOutlineFront(in: rect)
                        .fill(Color.mmBgSecondary.opacity(0.5))
                        .overlay {
                            MusclePathData.bodyOutlineFront(in: rect)
                                .stroke(Color.mmMuscleBorder.opacity(0.4), lineWidth: 0.5)
                        }
                } else {
                    MusclePathData.bodyOutlineBack(in: rect)
                        .fill(Color.mmBgSecondary.opacity(0.5))
                        .overlay {
                            MusclePathData.bodyOutlineBack(in: rect)
                                .stroke(Color.mmMuscleBorder.opacity(0.4), lineWidth: 0.5)
                        }
                }

                // 筋肉パス
                let muscles = showFront
                    ? MusclePathData.frontMuscles
                    : MusclePathData.backMuscles

                ForEach(muscles, id: \.muscle) { entry in
                    let state = muscleStates[entry.muscle.rawValue]
                    let color = state?.color ?? Color.mmMuscleInactive

                    entry.path(rect)
                        .fill(color)
                        .overlay {
                            entry.path(rect)
                                .stroke(Color.mmMuscleBorder.opacity(0.3), lineWidth: 0.3)
                        }
                }
            }
        }
    }
}

// MARK: - カラーパレット（ウィジェット用）

extension Color {
    static let mmBgPrimary = Color(hex: "#121212")
    static let mmBgSecondary = Color(hex: "#1E1E1E")
    static let mmTextPrimary = Color.white
    static let mmTextSecondary = Color(hex: "#9E9E9E")
    static let mmAccentPrimary = Color(hex: "#00FFB3")
    static let mmMuscleCoral = Color(hex: "#FF6B6B")       // 高負荷（0-20%）
    static let mmMuscleAmber = Color(hex: "#FFA94D")       // 回復初期（20-40%）
    static let mmMuscleYellow = Color(hex: "#FFD93D")      // 回復中（40-60%）
    static let mmMuscleLime = Color(hex: "#A8E06C")        // 回復後期（60-80%）
    static let mmMuscleBioGreen = Color(hex: "#4ADE80")    // ほぼ回復（80%+）
    static let mmMuscleInactive = Color(hex: "#2A2A2E")    // 未刺激（暗いグレー）
    static let mmMuscleNeglected = Color(hex: "#9B59B6")   // 長期未刺激
    static let mmMuscleBorder = Color(hex: "#3A3A3E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}

// MARK: - ウィジェット定義

struct MuscleMapWidget: Widget {
    let kind = "MuscleMapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MuscleMapTimelineProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MuscleMap")
        .description("筋肉の回復状態を表示")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - エントリビュー（サイズ切り替え）

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MuscleMapEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    MuscleMapWidget()
} timeline: {
    MuscleMapEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    MuscleMapWidget()
} timeline: {
    MuscleMapEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    MuscleMapWidget()
} timeline: {
    MuscleMapEntry.placeholder
}

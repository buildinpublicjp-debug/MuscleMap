import WidgetKit
import SwiftUI

// MARK: - タイムラインエントリ

struct MuscleMapEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let suggestedGroup: String
    let suggestedReason: String
    let groupStates: [String: GroupState]

    struct GroupState {
        let color: Color
        let isNeglected: Bool
    }

    static let placeholder = MuscleMapEntry(
        date: Date(),
        streakDays: 3,
        suggestedGroup: "chest",
        suggestedReason: "胸が最も回復しています",
        groupStates: [
            "chest": GroupState(color: .mmMuscleBioGreen, isNeglected: false),
            "back": GroupState(color: .mmMuscleAmber, isNeglected: false),
            "shoulders": GroupState(color: .mmMuscleLime, isNeglected: false),
            "arms": GroupState(color: .mmMuscleYellow, isNeglected: false),
            "core": GroupState(color: .mmMuscleInactive, isNeglected: false),
            "lowerBody": GroupState(color: .mmMuscleCoral, isNeglected: false),
        ]
    )
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
        // 15分ごとに更新（回復は時間経過で変わるため）
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> MuscleMapEntry {
        guard let data = WidgetDataReader.read() else {
            return .placeholder
        }

        let groupStates = buildGroupStates(from: data)

        return MuscleMapEntry(
            date: Date(),
            streakDays: data.streakDays,
            suggestedGroup: data.suggestedGroup,
            suggestedReason: data.suggestedReason,
            groupStates: groupStates
        )
    }

    private func buildGroupStates(from data: WidgetMuscleData) -> [String: MuscleMapEntry.GroupState] {
        // グループごとの筋肉マッピング
        let groupMuscles: [String: [String]] = [
            "chest": ["chest_upper", "chest_lower"],
            "back": ["lats", "traps_upper", "traps_middle_lower", "erector_spinae"],
            "shoulders": ["deltoid_anterior", "deltoid_lateral", "deltoid_posterior"],
            "arms": ["biceps", "triceps", "forearms"],
            "core": ["rectus_abdominis", "obliques"],
            "lowerBody": ["glutes", "quadriceps", "hamstrings", "adductors", "hip_flexors", "gastrocnemius", "soleus"],
        ]

        var result: [String: MuscleMapEntry.GroupState] = [:]

        for (group, muscles) in groupMuscles {
            var worstProgress: Double = 1.0
            var hasNeglected = false

            for muscleId in muscles {
                if let snapshot = data.muscleStates[muscleId] {
                    switch snapshot.state {
                    case .recovering:
                        worstProgress = min(worstProgress, snapshot.progress)
                    case .neglected, .neglectedSevere:
                        hasNeglected = true
                    case .inactive:
                        break
                    }
                }
            }

            let color: Color
            if hasNeglected {
                color = .mmMuscleNeglected
            } else if worstProgress < 1.0 {
                color = recoveryColor(progress: worstProgress)
            } else {
                color = .mmMuscleInactive
            }

            result[group] = MuscleMapEntry.GroupState(color: color, isNeglected: hasNeglected)
        }

        return result
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

// MARK: - ウィジェットデータ読み込み（Widget Extension用）

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

// MARK: - Smallウィジェットビュー

struct SmallWidgetView: View {
    let entry: MuscleMapEntry

    var body: some View {
        VStack(spacing: 8) {
            // ミニ筋肉マップ（6グループ × カラードット）
            MiniMuscleMap(groupStates: entry.groupStates)

            Spacer(minLength: 0)

            // ストリーク
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(entry.streakDays > 0 ? Color.mmAccentPrimary : Color.mmTextSecondary)
                Text("\(entry.streakDays)日連続")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }
        }
        .padding(12)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - Mediumウィジェットビュー

struct MediumWidgetView: View {
    let entry: MuscleMapEntry

    private var groupLocalizedName: String {
        switch entry.suggestedGroup {
        case "chest": return String(localized: "胸")
        case "back": return String(localized: "背中")
        case "shoulders": return String(localized: "肩")
        case "arms": return String(localized: "腕")
        case "core": return String(localized: "体幹")
        case "lowerBody": return String(localized: "下半身")
        default: return entry.suggestedGroup
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // 左: ミニ筋肉マップ
            VStack(spacing: 8) {
                MiniMuscleMap(groupStates: entry.groupStates)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(entry.streakDays > 0 ? Color.mmAccentPrimary : Color.mmTextSecondary)
                    Text("\(entry.streakDays)日")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .frame(maxWidth: .infinity)

            // 右: 今日のおすすめ
            VStack(alignment: .leading, spacing: 8) {
                Text("今日のおすすめ")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(groupLocalizedName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Text(entry.suggestedReason)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - ミニ筋肉マップ（6グループのカラードット配置）

struct MiniMuscleMap: View {
    let groupStates: [String: MuscleMapEntry.GroupState]

    var body: some View {
        // 人体シルエット風の配置
        // 上から: 肩、胸+背中、腕、体幹、下半身
        VStack(spacing: 4) {
            // 肩
            groupDot("shoulders")

            // 胸 + 背中
            HStack(spacing: 8) {
                groupDot("chest")
                groupDot("back")
            }

            // 腕 + 体幹
            HStack(spacing: 8) {
                groupDot("arms")
                groupDot("core")
            }

            // 下半身
            groupDot("lowerBody")
        }
    }

    private func groupDot(_ group: String) -> some View {
        let state = groupStates[group]
        return RoundedRectangle(cornerRadius: 4)
            .fill(state?.color ?? Color.mmMuscleInactive)
            .frame(width: 28, height: 16)
    }
}

// MARK: - カラーパレット（ウィジェット用）

extension Color {
    static let mmBgPrimary = Color(hex: "#121212")
    static let mmBgSecondary = Color(hex: "#1E1E1E")
    static let mmTextPrimary = Color.white
    static let mmTextSecondary = Color(hex: "#9E9E9E")
    static let mmAccentPrimary = Color(hex: "#00FFB3")
    static let mmMuscleCoral = Color(hex: "#FF6B6B")
    static let mmMuscleAmber = Color(hex: "#FFA726")
    static let mmMuscleYellow = Color(hex: "#FFEE58")
    static let mmMuscleLime = Color(hex: "#C6FF00")
    static let mmMuscleBioGreen = Color(hex: "#00E676")
    static let mmMuscleInactive = Color(hex: "#2A2A2E")
    static let mmMuscleNeglected = Color(hex: "#9B59B6")

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
        .description("筋肉の回復状態と今日のおすすめを表示")
        .supportedFamilies([.systemSmall, .systemMedium])
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

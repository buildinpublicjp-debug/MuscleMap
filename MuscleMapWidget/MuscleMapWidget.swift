import WidgetKit
import SwiftUI

// MARK: - タイムラインエントリ（簡素化版）

struct MuscleMapEntry: TimelineEntry {
    let date: Date
    let muscleStates: [String: MuscleState]
    let isProUser: Bool

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
        return MuscleMapEntry(date: Date(), muscleStates: states, isProUser: true)
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
        let isPro = WidgetDataReader.isProUser()

        guard let data = WidgetDataReader.read() else {
            return MuscleMapEntry(date: Date(), muscleStates: [:], isProUser: isPro)
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

        return MuscleMapEntry(date: Date(), muscleStates: states, isProUser: isPro)
    }
}

// MARK: - ウィジェットデータ読み込み

enum WidgetDataReader {
    static let suiteName = "group.com.buildinpublic.MuscleMap"
    static let dataKey = "widget_muscle_data"
    static let proStatusKey = "widget_is_pro_user"
    static let languageKey = "appLanguage"

    static func read() -> WidgetMuscleData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetMuscleData.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func isProUser() -> Bool {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return false }
        return defaults.bool(forKey: proStatusKey)
    }

    static func isJapanese() -> Bool {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let lang = defaults.string(forKey: languageKey) else {
            // デフォルトはシステム言語を参照
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            return preferredLanguage.hasPrefix("ja")
        }
        return lang == "ja"
    }
}

// MARK: - ウィジェット用ローカライズ

enum WidgetL10n {
    static var recovered: String {
        WidgetDataReader.isJapanese() ? "回復済み" : "Recovered"
    }
    static var recovering: String {
        WidgetDataReader.isJapanese() ? "回復中" : "Recovering"
    }
    static var upgradeToProTitle: String {
        "MuscleMap Pro"
    }
    static var upgradeToPro: String {
        WidgetDataReader.isJapanese() ? "Proにアップグレード" : "Upgrade to Pro"
    }
    static var widgetDescription: String {
        WidgetDataReader.isJapanese() ? "筋肉の回復状態を表示" : "Display muscle recovery status"
    }
}

// MARK: - Smallウィジェットビュー（前面のみ）

struct SmallWidgetView: View {
    let entry: MuscleMapEntry

    var body: some View {
        GeometryReader { geo in
            WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
                .frame(width: geo.size.height * 0.5, height: geo.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - Mediumウィジェットビュー（前面 + 背面）

struct MediumWidgetView: View {
    let entry: MuscleMapEntry

    private var recoveringCount: Int {
        entry.muscleStates.values.filter { $0.stateType == .recovering }.count
    }

    private var readyCount: Int {
        21 - entry.muscleStates.values.filter { $0.stateType == .recovering || $0.stateType == .neglected || $0.stateType == .neglectedSevere }.count
    }

    var body: some View {
        GeometryReader { geo in
            let bodyHeight = geo.size.height
            let bodyWidth = bodyHeight * 0.5
            HStack(spacing: 4) {
                WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
                    .frame(width: bodyWidth, height: bodyHeight)
                WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: false)
                    .frame(width: bodyWidth, height: bodyHeight)

                // 情報カラム
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(WidgetL10n.recovered)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.mmTextSecondary)
                        Text("\(readyCount)/21")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.mmAccentPrimary)
                    }

                    Rectangle()
                        .fill(Color.mmMuscleBorder.opacity(0.3))
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(WidgetL10n.recovering)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.mmTextSecondary)
                        Text("\(recoveringCount)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.mmMuscleCoral)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, 4)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - Largeウィジェットビュー（前面 + 背面 + ステータス）

struct LargeWidgetView: View {
    let entry: MuscleMapEntry

    private var recoveringCount: Int {
        entry.muscleStates.values.filter { $0.stateType == .recovering }.count
    }

    private var readyCount: Int {
        entry.muscleStates.values.filter { $0.stateType == .inactive }.count
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
                        .frame(width: geo.size.width * 0.38)
                    WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: false)
                        .frame(width: geo.size.width * 0.38)
                }
                .frame(height: geo.size.height * 0.8)

                // 簡易ステータス
                HStack {
                    Label("\(recoveringCount)", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.mmMuscleCoral)
                    Spacer()
                    Label("\(readyCount)", systemImage: "checkmark.circle")
                        .foregroundStyle(Color.mmMuscleBioGreen)
                }
                .font(.caption)
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
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
                // 筋肉パスのみ（シルエットなし）
                let muscles = showFront
                    ? MusclePathData.frontMuscles
                    : MusclePathData.backMuscles

                ForEach(muscles, id: \.muscle) { entry in
                    let state = muscleStates[entry.muscle.rawValue]
                    let color = state?.color ?? Color.mmMuscleInactive
                    let path = entry.path(rect)

                    path
                        .fill(color)
                    path
                        .stroke(Color.mmMuscleBorder.opacity(0.3), lineWidth: 0.3)
                }
            }
        }
        .aspectRatio(0.5, contentMode: .fit)
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
    static let mmMuscleInactive = Color(hex: "#3D3D42")    // 未刺激（暗いグレー）
    static let mmMuscleNeglected = Color(hex: "#9B59B6")   // 長期未刺激
    static let mmMuscleBorder = Color(hex: "#505058")

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
        .description(WidgetL10n.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - ロック画面（非Pro）

struct WidgetLockedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(WidgetL10n.upgradeToProTitle)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.mmTextPrimary)
            Text(WidgetL10n.upgradeToPro)
                .font(.system(size: 9))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - エントリビュー（サイズ切り替え）

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MuscleMapEntry

    var body: some View {
        if !entry.isProUser {
            WidgetLockedView()
        } else {
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

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
            return MuscleMapEntry(date: Date(), muscleStates: [:])
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
    static let languageKey = "appLanguage"

    static func read() -> WidgetMuscleData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetMuscleData.self, from: data) else {
            return nil
        }
        return decoded
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
    static var todaysSuggestion: String {
        WidgetDataReader.isJapanese() ? "今日やるなら" : "Today's Pick"
    }
    static var widgetDescription: String {
        WidgetDataReader.isJapanese() ? "筋肉の回復状態を表示" : "Display muscle recovery status"
    }
}

// MARK: - Smallウィジェットビュー（Map Hero — マップ最大化）

struct SmallWidgetView: View {
    let entry: MuscleMapEntry

    private var suggestedPairs: [WidgetTrainingPair] {
        WidgetSuggestionLogic.suggest(from: entry.muscleStates)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // マップ（前面のみ、最大サイズ）
            WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
                .padding(4)

            // ボトムバー: 提案のみ（1行）
            if let first = suggestedPairs.first {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.mmAccentPrimary)
                        .frame(width: 4, height: 4)
                    Text(first.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.mmAccentPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("MuscleMap")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [Color.mmBgPrimary.opacity(0), Color.mmBgPrimary.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - Mediumウィジェットビュー（Two-Body Hero + Bottom Bar）

struct MediumWidgetView: View {
    let entry: MuscleMapEntry

    private var suggestedPairs: [WidgetTrainingPair] {
        WidgetSuggestionLogic.suggest(from: entry.muscleStates)
    }

    private var recoveringCount: Int {
        entry.muscleStates.values.filter { $0.stateType == .recovering }.count
    }

    private var readyCount: Int {
        entry.muscleStates.values.filter {
            $0.stateType == .inactive || ($0.stateType == .recovering && $0.progress >= 0.8)
        }.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 2体のマップを中央に大きく配置
            HStack(spacing: 8) {
                WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
                WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32) // ボトムバー分のスペース

            // ボトムバー: 提案 + ステータス
            HStack {
                // 提案（左寄せ）
                HStack(spacing: 8) {
                    ForEach(suggestedPairs, id: \.label) { pair in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.mmAccentPrimary)
                                .frame(width: 4, height: 4)
                            Text(pair.label)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mmAccentPrimary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // ステータス（右寄せ）
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Circle().fill(Color.mmMuscleCoral).frame(width: 5, height: 5)
                        Text("\(recoveringCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.mmMuscleCoral)
                    }
                    HStack(spacing: 2) {
                        Circle().fill(Color.mmMuscleBioGreen).frame(width: 5, height: 5)
                        Text("\(readyCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.mmMuscleBioGreen)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color.mmBgPrimary.opacity(0), Color.mmBgPrimary.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }
}

// MARK: - ウィジェット用提案ロジック

struct WidgetTrainingPair {
    let label: String
}

enum WidgetSuggestionLogic {

    /// 筋肉グループの分類
    enum Group: String, CaseIterable {
        case chest, back, shoulders, arms, core, lowerBody

        var muscles: [Muscle] {
            switch self {
            case .chest:     return [.chestUpper, .chestLower]
            case .back:      return [.lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae]
            case .shoulders: return [.deltoidAnterior, .deltoidLateral, .deltoidPosterior]
            case .arms:      return [.biceps, .triceps, .forearms]
            case .core:      return [.rectusAbdominis, .obliques]
            case .lowerBody: return [.glutes, .quadriceps, .hamstrings, .adductors, .hipFlexors, .gastrocnemius, .soleus]
            }
        }

        /// ペアリング表示名（日/英）
        func pairLabel(isJapanese: Bool) -> String {
            switch self {
            case .chest:     return isJapanese ? "胸・三頭筋"   : "Chest & Triceps"
            case .back:      return isJapanese ? "背中・二頭筋"  : "Back & Biceps"
            case .shoulders: return isJapanese ? "肩・僧帽筋"   : "Shoulders & Traps"
            case .arms:      return isJapanese ? "腕・肩"      : "Arms & Shoulders"
            case .core:      return isJapanese ? "体幹・肩"     : "Core & Shoulders"
            case .lowerBody: return isJapanese ? "脚"          : "Legs"
            }
        }
    }

    /// 回復状態から「今日やるべき2部位」を算出
    static func suggest(from states: [String: MuscleMapEntry.MuscleState]) -> [WidgetTrainingPair] {
        let isJa = WidgetDataReader.isJapanese()

        // 各グループの「刺激の必要度」（高い=回復済み or 未記録→鍛え時）
        var groupScores: [(group: Group, score: Double)] = []
        for group in Group.allCases {
            let muscles = group.muscles
            var total: Double = 0
            for muscle in muscles {
                if let state = states[muscle.rawValue] {
                    switch state.stateType {
                    case .inactive:
                        // 未記録 = 最も刺激が必要
                        total += 2.0
                    case .recovering:
                        // 回復進捗が高いほど刺激可能
                        total += state.progress
                    case .neglected, .neglectedSevere:
                        // 長期未刺激 = 非常に必要
                        total += 2.5
                    }
                } else {
                    // データなし = 未記録扱い
                    total += 2.0
                }
            }
            let avg = total / Double(muscles.count)
            groupScores.append((group, avg))
        }

        // スコア降順（=より刺激が必要な部位が先）
        let sorted = groupScores.sorted { $0.score > $1.score }

        // 上位2グループ（重複ペアを避ける）
        var result: [WidgetTrainingPair] = []
        var usedGroups: Set<String> = []

        for item in sorted {
            guard result.count < 2 else { break }
            guard !usedGroups.contains(item.group.rawValue) else { continue }

            result.append(WidgetTrainingPair(label: item.group.pairLabel(isJapanese: isJa)))
            usedGroups.insert(item.group.rawValue)
        }

        return result
    }
}

// MARK: - Largeウィジェットビュー（コンパクトヘッダー + マップ拡大 + 提案）

struct LargeWidgetView: View {
    let entry: MuscleMapEntry

    private var suggestedPairs: [WidgetTrainingPair] {
        WidgetSuggestionLogic.suggest(from: entry.muscleStates)
    }

    private var recoveringCount: Int {
        entry.muscleStates.values.filter { $0.stateType == .recovering }.count
    }

    private var readyCount: Int {
        entry.muscleStates.values.filter {
            $0.stateType == .inactive || ($0.stateType == .recovering && $0.progress >= 0.8)
        }.count
    }

    private var neglectedCount: Int {
        entry.muscleStates.values.filter {
            $0.stateType == .neglected || $0.stateType == .neglectedSevere
        }.count
    }

    var body: some View {
        VStack(spacing: 8) {
            // ヘッダー: アプリ名 + ステータスバッジ（コンパクト）
            HStack {
                Text("MuscleMap")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color.mmAccentPrimary)
                Spacer()
                HStack(spacing: 8) {
                    statusBadge(color: .mmMuscleCoral, count: recoveringCount)
                    statusBadge(color: .mmMuscleBioGreen, count: readyCount)
                    if neglectedCount > 0 {
                        statusBadge(color: .mmMuscleNeglected, count: neglectedCount)
                    }
                }
            }

            // マップ（大きく、前面+背面）
            GeometryReader { geo in
                HStack(spacing: 8) {
                    WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: true)
                        .frame(width: geo.size.width * 0.47)
                    WidgetMuscleMapView(muscleStates: entry.muscleStates, showFront: false)
                        .frame(width: geo.size.width * 0.47)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 今日の提案（コンパクト）
            HStack(spacing: 10) {
                ForEach(suggestedPairs, id: \.label) { pair in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.mmAccentPrimary)
                            .frame(width: 5, height: 5)
                        Text(pair.label)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Color.mmAccentPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.mmAccentPrimary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .containerBackground(Color.mmBgPrimary, for: .widget)
    }

    private func statusBadge(color: Color, count: Int) -> some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
        }
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

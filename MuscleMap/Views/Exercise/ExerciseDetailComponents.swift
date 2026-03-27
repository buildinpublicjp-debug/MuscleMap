import SwiftUI
import SwiftData

// MARK: - 過去3回のパフォーマンスセクション

struct ExercisePerformanceSection: View {
    let exerciseId: String
    @Environment(\.modelContext) private var modelContext

    /// 過去3セッション分のパフォーマンスデータ
    private var recentPerformances: [(date: Date, sets: [(weight: Double, reps: Int)])] {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\WorkoutSet.completedAt, order: .reverse)]
        )
        guard let allSets = try? modelContext.fetch(descriptor) else { return [] }

        // セッション別にグループ化（sessionのstartDateでグループ）
        var sessionMap: [UUID: (date: Date, sets: [(weight: Double, reps: Int)])] = [:]
        for set in allSets {
            guard let session = set.session else { continue }
            let sessionId = session.id
            if sessionMap[sessionId] == nil {
                sessionMap[sessionId] = (date: session.startDate, sets: [])
            }
            sessionMap[sessionId]?.sets.append((weight: set.weight, reps: set.reps))
        }

        // 日付順にソートして最新3件
        return sessionMap.values
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { ($0.date, $0.sets) }
    }

    var body: some View {
        let performances = recentPerformances
        if !performances.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.previousPerformance)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)

                ForEach(Array(performances.enumerated()), id: \.offset) { _, perf in
                    PerformanceRow(date: perf.date, sets: perf.sets)
                }
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.previousPerformance)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
                Text(L10n.noPerformanceData)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - パフォーマンス行

private struct PerformanceRow: View {
    let date: Date
    let sets: [(weight: Double, reps: Int)]

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    /// 最大重量のセット
    private var bestSet: (weight: Double, reps: Int)? {
        sets.max(by: { $0.weight < $1.weight })
    }

    var body: some View {
        HStack(spacing: 12) {
            // 日付
            Text(dateString)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(Color.mmAccentSecondary)
                .frame(width: 36, alignment: .leading)

            // セット概要
            if let best = bestSet {
                Text(String(format: "%.1f kg × %d", best.weight, best.reps))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            Spacer()

            // セット数
            Text("\(sets.count) sets")
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 情報タグ

struct DetailInfoTag: View {
    let icon: String
    let text: String
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(highlight ? Color.mmPRGold : Color.mmTextSecondary)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.mmBgCard)
        .foregroundStyle(highlight ? Color.mmPRGold : Color.mmTextSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - 刺激度バー

struct DetailMuscleStimulationBar: View {
    let muscle: Muscle
    let percentage: Int
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 12) {
            Text(localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextPrimary)
                .frame(minWidth: 80, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmBgCard)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(percentage) / 100, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(percentage)%")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(barColor)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private var barColor: Color {
        switch percentage {
        case 80...: return .mmMuscleJustWorked
        case 50..<80: return .mmMuscleAmber
        default: return .mmMuscleLime
        }
    }
}

// MARK: - 強さレベルプログレスバー

struct DetailStrengthLevelProgressSection: View {
    let currentLevel: StrengthLevel
    let kgToNext: Double?
    let nextLevel: StrengthLevel?

    private let allLevels = StrengthLevel.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.strengthLevelTitle)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // プログレスバー
            HStack(spacing: 0) {
                ForEach(Array(allLevels.enumerated()), id: \.offset) { index, level in
                    let isCurrent = level == currentLevel
                    let isPassed = level.minimumScore < currentLevel.minimumScore

                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(isCurrent ? level.color : (isPassed ? level.color.opacity(0.4) : Color.mmBgCard))
                                .frame(width: isCurrent ? 28 : 20, height: isCurrent ? 28 : 20)

                            if isCurrent {
                                Circle()
                                    .stroke(level.color, lineWidth: 2)
                                    .frame(width: 34, height: 34)
                                Text(level.emoji)
                                    .font(.system(size: 12))
                            } else if isPassed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.mmBgPrimary)
                            }
                        }
                        .frame(height: 36)

                        Text(level.localizedName)
                            .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                            .foregroundStyle(isCurrent ? level.color : Color.mmTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)

                    if index < allLevels.count - 1 {
                        Rectangle()
                            .fill(isPassed ? currentLevel.color.opacity(0.4) : Color.mmBgCard)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .offset(y: -12)
                    }
                }
            }

            // 次レベルまでのテキスト
            if let kgToNext = kgToNext, let nextLevel = nextLevel {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundStyle(nextLevel.color)
                    Text(L10n.levelUpKgToNext(Int(ceil(kgToNext)), nextLevel.localizedName))
                        .font(.caption.bold())
                        .foregroundStyle(nextLevel.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(nextLevel.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if currentLevel == .freak {
                HStack(spacing: 4) {
                    Text("👑")
                    Text(L10n.maxLevelReached)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmPRGold)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

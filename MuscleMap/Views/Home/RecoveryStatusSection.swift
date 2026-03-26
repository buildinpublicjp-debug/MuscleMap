import SwiftUI

// MARK: - 回復ステータスセクション（コンパクトマップ + ステータスチップ）

/// 前面・背面マップを160ptでコンパクト表示し、横にステータスチップを並べるセクション
struct RecoveryStatusSection: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let latestStimulations: [Muscle: MuscleStimulation]
    let onMuscleTapped: (Muscle) -> Void
    let onDetailsTapped: () -> Void

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ヘッダー
            HStack {
                Text(isJapanese ? "回復ステータス" : "Recovery Status")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                Button {
                    onDetailsTapped()
                } label: {
                    HStack(spacing: 2) {
                        Text(isJapanese ? "詳細" : "Details")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.mmAccentSecondary)
                }
            }

            // マップ（前面+背面同時表示）+ チップ
            HStack(spacing: 10) {
                // MuscleMapViewは前面・背面を同時にHStackで表示する
                MuscleMapView(
                    muscleStates: muscleStates,
                    onMuscleTapped: { muscle in
                        onMuscleTapped(muscle)
                    },
                    demoMode: false
                )
                .frame(height: 160)

                // ステータスチップ
                VStack(spacing: 6) {
                    ForEach(topGroupStatuses.prefix(4)) { status in
                        RecoveryChip(status: status)
                    }
                }
                .frame(width: 110)
            }
        }
        .padding(14)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - グループ別回復ステータス計算

    /// 筋肉グループごとの回復状態を集計し、重要度順でソート
    private var topGroupStatuses: [GroupRecoveryStatus] {
        var statuses: [GroupRecoveryStatus] = []

        for group in MuscleGroup.allCases {
            let muscles = group.muscles
            var totalProgress: Double = 0
            var stimCount = 0
            var latestDate: Date?

            for muscle in muscles {
                if let stim = latestStimulations[muscle] {
                    let progress = RecoveryCalculator.recoveryProgress(
                        stimulationDate: stim.stimulationDate,
                        muscle: muscle,
                        totalSets: stim.totalSets
                    )
                    totalProgress += progress
                    stimCount += 1

                    if let current = latestDate {
                        if stim.stimulationDate > current {
                            latestDate = stim.stimulationDate
                        }
                    } else {
                        latestDate = stim.stimulationDate
                    }
                }
            }

            // 刺激記録がないグループはスキップ
            guard stimCount > 0, let date = latestDate else { continue }

            let avgProgress = totalProgress / Double(stimCount)
            let hoursAgo = Date().timeIntervalSince(date) / 3600
            let days = RecoveryCalculator.daysSinceStimulation(date)

            let chipType: RecoveryChipType
            if days >= 7 {
                chipType = .neglected
            } else if avgProgress < 0.3 {
                chipType = .fatigued
            } else if avgProgress < 0.7 {
                chipType = .recovering
            } else {
                chipType = .recovered
            }

            let groupName = isJapanese ? group.japaneseName : group.englishName

            statuses.append(GroupRecoveryStatus(
                id: group.rawValue,
                groupName: groupName,
                progress: avgProgress,
                hoursAgo: hoursAgo,
                chipType: chipType
            ))
        }

        // 疲労 → 回復中 → 未刺激 → 回復済み の順にソート
        return statuses.sorted { a, b in
            a.chipType.sortOrder < b.chipType.sortOrder
        }
    }
}

// MARK: - 回復ステータスチップ

private struct RecoveryChip: View {
    let status: GroupRecoveryStatus

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.chipType.color)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 0) {
                Text(status.groupName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

                Text(statusText)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(status.chipType.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var statusText: String {
        switch status.chipType {
        case .fatigued:
            let h = Int(status.hoursAgo)
            return isJapanese ? "\(h)h前" : "\(h)h ago"
        case .recovering:
            let pct = Int(status.progress * 100)
            return isJapanese ? "\(pct)%回復" : "\(pct)% recovered"
        case .recovered:
            return isJapanese ? "回復済み" : "Recovered"
        case .neglected:
            return isJapanese ? "未刺激警告" : "Neglected"
        }
    }
}

// MARK: - データ型

struct GroupRecoveryStatus: Identifiable {
    let id: String
    let groupName: String
    let progress: Double
    let hoursAgo: Double
    let chipType: RecoveryChipType
}

enum RecoveryChipType {
    case fatigued    // 0-30%
    case recovering  // 30-70%
    case recovered   // 70%+
    case neglected   // 7日以上

    var color: Color {
        switch self {
        case .fatigued: return .mmMuscleFatigued
        case .recovering: return .mmMuscleModerate
        case .recovered: return .mmMuscleRecovered
        case .neglected: return .mmMuscleNeglected
        }
    }

    /// ソート順: 疲労が最優先で表示
    var sortOrder: Int {
        switch self {
        case .fatigued: return 0
        case .recovering: return 1
        case .neglected: return 2
        case .recovered: return 3
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        RecoveryStatusSection(
            muscleStates: [:],
            latestStimulations: [:],
            onMuscleTapped: { _ in },
            onDetailsTapped: { }
        )
    }
}

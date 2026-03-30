import SwiftUI

// MARK: - 回復ステータスセクション（マップ + ミニチップ横並び）

struct RecoveryStatusSection: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let latestStimulations: [Muscle: MuscleStimulation]
    let onMuscleTapped: (Muscle) -> Void
    let onDetailsTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ヘッダー
            HStack {
                Text(L10n.recoveryStatus)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                Button {
                    onDetailsTapped()
                } label: {
                    HStack(spacing: 2) {
                        Text(L10n.detailsLabel)
                            .font(.system(size: 12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.mmAccentSecondary)
                }
            }

            // マップ + チップ（HStack）
            HStack(spacing: 10) {
                // マップ（左側、できるだけ広く）
                MuscleMapView(
                    muscleStates: muscleStates,
                    onMuscleTapped: { muscle in
                        onMuscleTapped(muscle)
                    },
                    demoMode: false
                )
                .frame(height: 180)

                // ミニチップ（右側、縦並び）
                VStack(spacing: 6) {
                    ForEach(topGroupStatuses.prefix(5)) { status in
                        RecoveryMiniChip(status: status)
                    }
                }
                .frame(width: 120)
            }
        }
        .padding(14)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - グループ別回復ステータス計算

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

            let groupName = group.localizedName

            statuses.append(GroupRecoveryStatus(
                id: group.rawValue,
                groupName: groupName,
                progress: avgProgress,
                hoursAgo: hoursAgo,
                chipType: chipType
            ))
        }

        return statuses.sorted { a, b in
            a.chipType.sortOrder < b.chipType.sortOrder
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
    case fatigued
    case recovering
    case recovered
    case neglected

    var color: Color {
        switch self {
        case .fatigued: return .red
        case .recovering: return .orange
        case .recovered: return .green
        case .neglected: return .purple
        }
    }

    var sortOrder: Int {
        switch self {
        case .fatigued: return 0
        case .recovering: return 1
        case .neglected: return 2
        case .recovered: return 3
        }
    }
}

// MARK: - ミニ回復チップ（コンパクト横並び）

private struct RecoveryMiniChip: View {
    let status: GroupRecoveryStatus

    var body: some View {
        HStack(spacing: 4) {
            if status.chipType == .neglected {
                Text("\u{26A0}\u{FE0F}")
                    .font(.system(size: 8))
            } else {
                Circle()
                    .fill(status.chipType.color)
                    .frame(width: 6, height: 6)
            }

            Text(chipLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status.chipType.color.opacity(0.08))
        .clipShape(Capsule())
    }

    private var chipLabel: String {
        switch status.chipType {
        case .recovered:
            return status.groupName
        case .recovering:
            let pct = Int(status.progress * 100)
            return "\(status.groupName) \(pct)%"
        case .fatigued:
            let h = Int(status.hoursAgo)
            return "\(status.groupName) \(h)h"
        case .neglected:
            return status.groupName
        }
    }
}

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

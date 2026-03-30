import SwiftUI

// MARK: - 回復詳細ビュー（フルスクリーンモーダル）

struct RecoveryDetailView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let latestStimulations: [Muscle: MuscleStimulation]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMuscle: Muscle?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        muscleMapSection
                        bodyReadinessSection
                        muscleRecoveryBars
                        nextTrainingRecommendation
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(L10n.recoveryMap)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailView(muscle: muscle)
            }
        }
    }

    // MARK: - 1. 筋肉マップ（大型表示）

    private var muscleMapSection: some View {
        ZStack {
            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.03))
                .frame(width: 340, height: 340)
                .blur(radius: 40)

            MuscleMapView(
                muscleStates: muscleStates,
                onMuscleTapped: { muscle in
                    selectedMuscle = muscle
                },
                demoMode: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: 340)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 2. Body Readiness スコア

    private var bodyReadinessSection: some View {
        let readiness = bodyReadinessPercent

        return VStack(spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text(L10n.bodyReadiness)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmTextSecondary)

                Spacer()

                Text("\(Int(readiness * 100))%")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(Color.mmTextPrimary)
            }

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmBgCard)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(readinessGradient(for: readiness))
                        .frame(width: geo.size.width * readiness, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    // MARK: - 3. 部位別回復バー

    private var muscleRecoveryBars: some View {
        let statuses = groupStatuses

        return VStack(spacing: 10) {
            ForEach(statuses) { status in
                recoveryBarRow(status)
            }
        }
        .padding(16)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func recoveryBarRow(_ status: DetailGroupStatus) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(barColor(for: status.progress))
                .frame(width: 6, height: 6)

            Text(status.groupName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.mmTextPrimary)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.mmBgCard)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: status.progress))
                        .frame(width: geo.size.width * status.progress, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(Int(status.progress * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
                .frame(width: 36, alignment: .trailing)

            Text(statusLabel(for: status))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(statusColor(for: status))
                .frame(width: 48, alignment: .trailing)
        }
    }

    // MARK: - 4. 次のトレーニング推奨

    private var nextTrainingRecommendation: some View {
        let readyGroups = groupStatuses.filter { $0.progress >= 1.0 }
        let frequency = AppState.shared.userProfile.weeklyFrequency
        let parts = WorkoutRecommendationEngine.splitParts(for: frequency)

        return Group {
            if readyGroups.isEmpty {
                recommendationCard(
                    icon: "moon.fill",
                    text: L10n.allMusclesRecoveringRestDay
                )
            } else {
                let readyGroupIds = Set(readyGroups.map { $0.groupId })
                let matchedPart = parts.first { part in
                    part.muscleGroups.allSatisfy { readyGroupIds.contains($0) }
                }

                if let part = matchedPart {
                    let names = readyGroups.map(\.groupName).joined(separator: "・")
                    let partName = part.localizedName
                    recommendationCard(
                        icon: "bolt.fill",
                        text: L10n.recoveredRecommendation(names, partName)
                    )
                } else {
                    let names = readyGroups.map(\.groupName).joined(separator: "・")
                    recommendationCard(
                        icon: "bolt.fill",
                        text: L10n.groupRecovered(names)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func recommendationCard(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.mmAccentPrimary)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(2)

            Spacer()
        }
        .padding(14)
        .background(Color.mmAccentPrimary.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mmAccentPrimary.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 計算ヘルパー

    private var bodyReadinessPercent: Double {
        let statuses = groupStatuses
        guard !statuses.isEmpty else { return 0 }
        let total = statuses.reduce(0.0) { $0 + $1.progress }
        return total / Double(statuses.count)
    }

    private var groupStatuses: [DetailGroupStatus] {
        var statuses: [DetailGroupStatus] = []

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

            let avgProgress = min(totalProgress / Double(stimCount), 1.0)
            let hoursAgo = Date().timeIntervalSince(date) / 3600
            let days = RecoveryCalculator.daysSinceStimulation(date)

            let groupName = group.localizedName

            statuses.append(DetailGroupStatus(
                groupId: group,
                groupName: groupName,
                progress: avgProgress,
                hoursAgo: hoursAgo,
                days: days
            ))
        }

        // 回復率が低い順（疲労しているものが上）
        return statuses.sorted { $0.progress < $1.progress }
    }

    // MARK: - 色 & ラベルヘルパー

    private func barColor(for progress: Double) -> Color {
        if progress < 0.3 {
            return .mmMuscleFatigued
        } else if progress < 0.7 {
            return .mmMuscleModerate
        } else {
            return .mmMuscleRecovered
        }
    }

    private func readinessGradient(for progress: Double) -> LinearGradient {
        let colors: [Color]
        if progress < 0.3 {
            colors = [.mmMuscleFatigued, .mmMuscleFatigued]
        } else if progress < 0.7 {
            colors = [.mmMuscleFatigued, .mmMuscleModerate]
        } else {
            colors = [.mmMuscleModerate, .mmMuscleRecovered]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private func statusLabel(for status: DetailGroupStatus) -> String {
        if status.days >= 7 {
            return "⚠️ 7d+"
        } else if status.progress >= 1.0 {
            return "✓ Ready"
        } else {
            // 残り時間の概算
            let remaining = estimateRemainingHours(status)
            if remaining <= 0 {
                return "✓ Ready"
            }
            return "~\(remaining)h"
        }
    }

    private func statusColor(for status: DetailGroupStatus) -> Color {
        if status.days >= 7 {
            return .mmMuscleNeglected
        } else if status.progress >= 1.0 {
            return .mmMuscleRecovered
        } else if status.progress >= 0.7 {
            return .mmMuscleModerate
        } else {
            return .mmMuscleFatigued
        }
    }

    private func estimateRemainingHours(_ status: DetailGroupStatus) -> Int {
        // 平均的な回復ベースで残り時間を概算
        guard status.progress < 1.0, status.progress > 0 else { return 0 }
        let elapsed = status.hoursAgo
        let totalEstimate = elapsed / status.progress
        let remaining = totalEstimate - elapsed
        return max(1, Int(remaining.rounded()))
    }
}

// MARK: - データ型

private struct DetailGroupStatus: Identifiable {
    let groupId: MuscleGroup
    let groupName: String
    let progress: Double
    let hoursAgo: Double
    let days: Int

    var id: String { groupId.rawValue }
}

// MARK: - Preview

#Preview {
    RecoveryDetailView(
        muscleStates: [:],
        latestStimulations: [:]
    )
}

import SwiftUI
import SwiftData
import UIKit

// MARK: - 週間サマリー画面

struct WeeklySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WeeklySummaryViewModel()
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー（日付範囲）
                        headerSection

                        // 筋肉マップ
                        muscleMapSection

                        // 統計カード
                        statsSection

                        // MVP筋肉
                        mvpSection

                        // サボり筋肉
                        lazyMuscleSection

                        // ストリーク
                        streakSection

                        // シェアボタン
                        shareButton
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.weeklySummary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [L10n.weeklySummaryShareText(viewModel.weekRangeText, AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
                }
            }
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(L10n.weeklyReport)
                .font(.caption.bold())
                .foregroundStyle(Color.mmAccentPrimary)
            Text(viewModel.weekRangeText)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
        }
    }

    // MARK: - 筋肉マップ

    private var muscleMapSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 40) {
                Text("FRONT")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(width: 140)
                Text("BACK")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(width: 140)
            }
            ShareMuscleMapView(muscleMapping: viewModel.weeklyMuscleMapping)
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 統計カード

    private var statsSection: some View {
        HStack(spacing: 0) {
            SummaryStatBox(
                value: "\(viewModel.workoutCount)",
                label: L10n.workouts,
                icon: "figure.strengthtraining.traditional"
            )
            SummaryStatBox(
                value: "\(viewModel.totalSets)",
                label: L10n.sets,
                icon: "number"
            )
            SummaryStatBox(
                value: viewModel.formattedVolume,
                label: L10n.volumeKg,
                icon: "scalemass"
            )
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - MVP筋肉

    private var mvpSection: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.mvpMuscle)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                if let mvp = viewModel.mvpMuscle {
                    Text(mvp.localizedName)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(L10n.stimulatedTimes(viewModel.mvpStimulationCount))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                } else {
                    Text(L10n.noWorkoutThisWeekYet)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - サボり筋肉

    private var lazyMuscleSection: some View {
        HStack(spacing: 12) {
            Text(viewModel.lazyMuscles.isEmpty ? "🎉" : "😴")
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.lazyMuscle)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                if viewModel.lazyMuscles.isEmpty {
                    Text(L10n.noLazyMuscles)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                } else {
                    Text(viewModel.lazyMuscles.prefix(3).map { $0.localizedName }.joined(separator: ", "))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmMuscleNeglected)
                    if viewModel.lazyMuscles.count > 3 {
                        Text(L10n.andMoreCount(viewModel.lazyMuscles.count - 3))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Text(L10n.nextWeekHomework)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ストリーク

    private var streakSection: some View {
        HStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.currentStreak)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                if viewModel.streakWeeks > 0 {
                    Text(L10n.weekStreak(viewModel.streakWeeks))
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                } else {
                    Text(L10n.noStreakYet)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - シェアボタン

    private var shareButton: some View {
        Button {
            prepareShareImage()
            showingShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text(L10n.share)
            }
            .font(.headline)
            .foregroundStyle(Color.mmBgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mmAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - シェア用画像生成

    @MainActor
    private func prepareShareImage() {
        let shareCard = WeeklySummaryShareCard(
            weekRange: viewModel.weekRangeText,
            muscleMapping: viewModel.weeklyMuscleMapping,
            workoutCount: viewModel.workoutCount,
            totalSets: viewModel.totalSets,
            totalVolume: viewModel.formattedVolume,
            mvpMuscle: viewModel.mvpMuscle,
            lazyMuscles: viewModel.lazyMuscles,
            streakWeeks: viewModel.streakWeeks
        )

        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 統計ボックス

private struct SummaryStatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - シェアカード

private struct WeeklySummaryShareCard: View {
    let weekRange: String
    let muscleMapping: [String: Int]
    let workoutCount: Int
    let totalSets: Int
    let totalVolume: String
    let mvpMuscle: Muscle?
    let lazyMuscles: [Muscle]
    let streakWeeks: Int

    var body: some View {
        ShareCardContainer(
            accentColor: .mmAccentPrimary,
            secondaryColor: .mmAccentSecondary,
            header: ShareCardHeader(title: "WEEKLY REPORT", subtitle: weekRange, date: Date())
        ) {
            VStack(spacing: 16) {
                // 筋肉マップ（大きく表示）
                ShareMuscleMapView(muscleMapping: muscleMapping)
                    .padding(.vertical, 8)

                // 統計
                HStack(spacing: 8) {
                    ShareCardStatItem("\(workoutCount)", label: L10n.workouts)
                    ShareCardStatItem("\(totalSets)", label: L10n.sets)
                    ShareCardStatItem(totalVolume, unit: "kg", label: L10n.volume)
                }
                .padding(.horizontal, 20)

                // MVP & サボり筋肉
                HStack(spacing: 16) {
                    // MVP
                    VStack(spacing: 4) {
                        Text("🏆")
                            .font(.title2)
                        if let mvp = mvpMuscle {
                            Text(mvp.localizedName)
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                        } else {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        Text("MVP")
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // サボり
                    VStack(spacing: 4) {
                        Text(lazyMuscles.isEmpty ? "🎉" : "😴")
                            .font(.title2)
                        if lazyMuscles.isEmpty {
                            Text(L10n.noSlacking)
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                        } else {
                            Text(lazyMuscles.first?.localizedName ?? "-")
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmMuscleNeglected)
                        }
                        Text(L10n.homework)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // ストリーク
                    VStack(spacing: 4) {
                        Text("🔥")
                            .font(.title2)
                        Text(streakWeeks > 0 ? "\(streakWeeks)" : "-")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(L10n.weeksStreak)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// シェアカード用統計アイテム
private struct ShareStatItemBold: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)
                if let unit = unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    WeeklySummaryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

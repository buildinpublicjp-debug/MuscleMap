import SwiftUI

// MARK: - 統計・分析メニュー画面

struct AnalyticsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingWeeklySummary = false
    @State private var showingBalanceDiagnosis = false
    @State private var showingMuscleJourney = false
    @State private var showingHeatmap = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // ウィークリーサマリー
                        AnalyticsMenuItem(
                            icon: "calendar",
                            iconColor: .mmAccentPrimary,
                            title: L10n.weeklySummary,
                            description: L10n.weeklySummaryDescription
                        ) {
                            showingWeeklySummary = true
                        }

                        // バランス診断
                        AnalyticsMenuItem(
                            icon: "scale.3d",
                            iconColor: .orange,
                            title: L10n.balanceDiagnosis,
                            description: L10n.balanceDiagnosisDescription
                        ) {
                            showingBalanceDiagnosis = true
                        }

                        // マッスル・ジャーニー
                        AnalyticsMenuItem(
                            icon: "clock.arrow.2.circlepath",
                            iconColor: .mmAccentSecondary,
                            title: L10n.muscleJourney,
                            description: L10n.journeyCardSubtitle
                        ) {
                            showingMuscleJourney = true
                        }

                        // ヒートマップ
                        AnalyticsMenuItem(
                            icon: "chart.bar.xaxis",
                            iconColor: .green,
                            title: L10n.trainingHeatmap,
                            description: L10n.heatmapCardSubtitle
                        ) {
                            showingHeatmap = true
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.analyticsMenu)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingWeeklySummary) {
                WeeklySummaryView()
            }
            .sheet(isPresented: $showingBalanceDiagnosis) {
                MuscleBalanceDiagnosisView()
            }
            .sheet(isPresented: $showingMuscleJourney) {
                MuscleJourneyView()
            }
            .sheet(isPresented: $showingHeatmap) {
                MuscleHeatmapView()
            }
        }
    }
}

// MARK: - 分析メニューアイテム

private struct AnalyticsMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AnalyticsMenuView()
}

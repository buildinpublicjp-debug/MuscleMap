import SwiftUI
import SwiftData

// MARK: - 統計・分析メニュー画面

struct AnalyticsMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingWeeklySummary = false
    @State private var showingBalanceDiagnosis = false
    @State private var showingMuscleJourney = false
    @State private var showingHeatmap = false
    @State private var showingPaywall = false

    // サマリー集計
    @State private var totalSessions: Int = 0
    @State private var totalVolume: Double = 0
    @State private var activeMuscleCount: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── 数字サマリーカード ──
                        summaryCard

                        // ── 無料分析 ──
                        sectionHeader("データ分析", isProRequired: false)

                        AnalyticsMenuItem(
                            icon: "calendar.badge.checkmark",
                            iconColor: .mmAccentPrimary,
                            title: "週間サマリー",
                            description: "今週どこを鍛えたか、ボリューム推移を確認",
                            badge: nil,
                            isPro: false
                        ) {
                            showingWeeklySummary = true
                        }

                        AnalyticsMenuItem(
                            icon: "chart.bar.xaxis",
                            iconColor: Color(red: 0.2, green: 0.8, blue: 0.5),
                            title: "トレーニング頻度マップ",
                            description: "過去90日間でどの部位を何回鍛えたか一目でわかる",
                            badge: nil,
                            isPro: false
                        ) {
                            showingHeatmap = true
                        }

                        // ── AI診断 ──
                        sectionHeader("AI診断", isProRequired: false)

                        AnalyticsMenuItem(
                            icon: "scale.3d",
                            iconColor: .mmWarning,
                            title: "筋肉バランス診断",
                            description: "4軸・8タイプで体のアンバランスを可視化。どこを強化すべきか即わかる",
                            badge: nil,
                            isPro: false
                        ) {
                            showingBalanceDiagnosis = true
                        }

                        AnalyticsMenuItem(
                            icon: "clock.arrow.2.circlepath",
                            iconColor: .mmAccentSecondary,
                            title: "マッスル・ジャーニー",
                            description: "記録開始からの筋肉変化の全記録。成長の軌跡を振り返る",
                            badge: nil,
                            isPro: false
                        ) {
                            showingMuscleJourney = true
                        }

                        // ── Pro専用 ──
                        sectionHeader("Pro機能", isProRequired: true)

                        AnalyticsMenuItem(
                            icon: "bolt.shield.fill",
                            iconColor: .mmAccentPrimary,
                            title: "Strength Map",
                            description: "全21筋肉の発達レベルをスコア化。体重比で客観的に強さを証明する",
                            badge: "Pro",
                            isPro: true
                        ) {
                            if PurchaseManager.shared.isPremium {
                                // HomeViewのStrength Mapへ遷移（Tab切替）
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    AppState.shared.selectedTab = 0
                                }
                            } else {
                                showingPaywall = true
                            }
                        }

                        AnalyticsMenuItem(
                            icon: "video.badge.checkmark",
                            iconColor: Color(red: 0.6, green: 0.4, blue: 1.0),
                            title: "90日 Recap（近日公開）",
                            description: "90日間の変化をまとめた動画を自動生成。シェアして成長を証明",
                            badge: "近日公開",
                            isPro: true
                        ) {
                            showingPaywall = true
                        }

                        Spacer(minLength: 32)
                    }
                    .padding()
                }
            }
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.lightTap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingWeeklySummary) { WeeklySummaryView() }
            .sheet(isPresented: $showingBalanceDiagnosis) { MuscleBalanceDiagnosisView() }
            .sheet(isPresented: $showingMuscleJourney) { MuscleJourneyView() }
            .sheet(isPresented: $showingHeatmap) { MuscleHeatmapView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .onAppear { loadSummary() }
        }
    }

    // MARK: - 数字サマリーカード

    private var summaryCard: some View {
        HStack(spacing: 0) {
            SummaryStatBox(
                value: "\(totalSessions)",
                label: "ワークアウト",
                icon: "figure.strengthtraining.traditional"
            )
            Divider()
                .frame(height: 40)
                .background(Color.mmTextSecondary.opacity(0.2))
            SummaryStatBox(
                value: formatVolume(totalVolume),
                label: "総ボリューム",
                icon: "scalemass"
            )
            Divider()
                .frame(height: 40)
                .background(Color.mmTextSecondary.opacity(0.2))
            SummaryStatBox(
                value: "\(activeMuscleCount)/21",
                label: "活性筋肉部位",
                icon: "bolt.fill"
            )
        }
        .padding(.vertical, 16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - セクションヘッダー

    private func sectionHeader(_ title: String, isProRequired: Bool) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .textCase(.uppercase)
                .tracking(1)

            if isProRequired {
                Text("PRO")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - データ集計

    private func loadSummary() {
        let sessionDescriptor = FetchDescriptor<WorkoutSession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        totalSessions = sessions.count

        let setsDescriptor = FetchDescriptor<WorkoutSet>()
        let sets = (try? modelContext.fetch(setsDescriptor)) ?? []
        totalVolume = sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }

        let stims = MuscleStateRepository(modelContext: modelContext).fetchLatestStimulations()
        activeMuscleCount = stims.count
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if v >= 1_000 { return String(format: "%.1fk", v / 1_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - サマリー数値ボックス

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
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 分析メニューアイテム

struct AnalyticsMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let badge: String?
    let isPro: Bool
    let action: () -> Void

    private var isLocked: Bool {
        isPro && !PurchaseManager.shared.isPremium
    }

    var body: some View {
        Button {
            HapticManager.lightTap()
            action()
        } label: {
            HStack(spacing: 14) {
                // アイコン
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isLocked ? Color.mmTextSecondary : iconColor)
                    .frame(width: 44, height: 44)
                    .background((isLocked ? Color.mmTextSecondary : iconColor).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(isLocked ? Color.mmTextSecondary : Color.mmTextPrimary)

                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(
                                    badge == "Pro" ? Color.mmAccentPrimary :
                                    badge == "近日公開" ? Color.mmTextSecondary :
                                    Color.mmAccentPrimary
                                )
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (badge == "Pro" ? Color.mmAccentPrimary :
                                     Color.mmTextSecondary).opacity(0.15)
                                )
                                .clipShape(Capsule())
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // 右端アイコン
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding(14)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPro && PurchaseManager.shared.isPremium
                            ? Color.mmAccentPrimary.opacity(0.3)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
            .opacity(badge == "近日公開" ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AnalyticsMenuView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

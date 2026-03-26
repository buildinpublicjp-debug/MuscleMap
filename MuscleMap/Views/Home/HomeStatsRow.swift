import SwiftUI
import SwiftData

// MARK: - ホームスタッツ行（セッション数 / ボリューム / PR）

/// 今月の統計を3カードで表示するセクション
struct HomeStatsRow: View {
    @Environment(\.modelContext) private var modelContext

    @State private var sessionCount: Int = 0
    @State private var totalVolume: Double = 0
    @State private var prCount: Int = 0

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        VStack(spacing: 16) {
            // スタッツカード3枚
            HStack(spacing: 10) {
                StatCard(
                    value: "\(sessionCount)",
                    label: isJapanese ? "セッション" : "Sessions"
                )
                StatCard(
                    value: formatVolume(totalVolume),
                    label: isJapanese ? "ボリューム" : "Volume"
                )
                StatCard(
                    value: "\(prCount)",
                    label: "PRs"
                )
            }
        }
        .padding(.horizontal)
        .onAppear {
            loadStats()
        }
    }

    /// 今月のスタッツを計算
    private func loadStats() {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return }

        // 今月の完了セッション
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.startDate >= monthStart && session.endDate != nil
            }
        )
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        sessionCount = sessions.count

        // 今月のボリューム合計
        let setDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { set in
                set.completedAt >= monthStart
            }
        )
        let sets = (try? modelContext.fetch(setDescriptor)) ?? []
        totalVolume = sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }

        // PR数: 今月のセッションでのPR更新をカウント
        let prManager = PRManager.shared
        var prTotal = 0
        for session in sessions {
            let updates = prManager.getSessionPRUpdates(session: session, context: modelContext)
            prTotal += updates.count
        }
        prCount = prTotal
    }

    /// ボリュームを読みやすくフォーマット（例: 76.4k）
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            let k = volume / 1000.0
            if k >= 100 {
                return "\(Int(k))k"
            }
            return String(format: "%.1fk", k)
        }
        return "\(Int(volume))"
    }
}

// MARK: - 個別スタッツカード

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Color.mmTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - クイックアクセス行（Strength Map / 履歴）

struct QuickAccessRow: View {
    let showingStrengthMap: Binding<Bool>
    let onLoadStrengthScores: () -> Void
    let onShowPaywall: () -> Void

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var isPremium: Bool {
        PurchaseManager.shared.isPremium
    }

    var body: some View {
        HStack(spacing: 10) {
            // Strength Mapボタン
            Button {
                HapticManager.lightTap()
                if isPremium {
                    onLoadStrengthScores()
                    withAnimation { showingStrengthMap.wrappedValue = true }
                } else {
                    onShowPaywall()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Strength Map")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.mmTextPrimary)
                            if !isPremium {
                                Text("Pro")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.mmBgPrimary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.mmAccentPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(isJapanese ? "筋力バランスを見る" : "See your balance")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.mmBgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.mmAccentSecondary.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // 履歴ショートカット
            Button {
                HapticManager.lightTap()
                AppState.shared.selectedTab = 3
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isJapanese ? "履歴" : "History")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(isJapanese ? "トレーニング記録" : "Training records")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.mmBgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 16) {
            HomeStatsRow()
            QuickAccessRow(
                showingStrengthMap: .constant(false),
                onLoadStrengthScores: {},
                onShowPaywall: {}
            )
        }
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}

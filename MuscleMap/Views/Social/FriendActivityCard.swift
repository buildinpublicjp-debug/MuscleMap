import SwiftUI

// MARK: - フレンドアクティビティカード

/// 1件のフレンドアクティビティを表示するカードコンポーネント
struct FriendActivityCard: View {
    let activity: FriendActivity
    @State private var fireCount: Int = 0
    @State private var hasReacted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アバター絵文字
            avatarView

            VStack(alignment: .leading, spacing: 8) {
                // 名前 + タイムスタンプ
                headerRow

                // アクティビティ内容テキスト
                activityText

                // 筋肉マップサムネイル（ワークアウト/PR時のみ）
                if !activity.stimulatedMuscles.isEmpty {
                    muscleMapThumbnail
                }

                // リアクションボタン
                reactionButton
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activity.isPR ? Color.mmPRCardBg : Color.mmBgCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    activity.isPR ? Color.mmPRBorder : Color.clear,
                    lineWidth: activity.isPR ? 1 : 0
                )
        )
    }

    // MARK: - アバター

    private var avatarView: some View {
        Text(activity.avatarEmoji)
            .font(.system(size: 28))
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color.mmBgSecondary)
            )
    }

    // MARK: - ヘッダー行（名前 + 時間）

    private var headerRow: some View {
        HStack {
            Text(activity.userName)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.mmTextPrimary)

            if activity.isPR {
                Text("PR")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.mmBgPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.mmPRAccent)
                    )
            }

            Spacer()

            Text(activity.timestamp.timeAgoDisplay())
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }

    // MARK: - アクティビティテキスト

    @MainActor
    private var activityText: some View {
        Text(activityDescription)
            .font(.subheadline)
            .foregroundStyle(Color.mmTextPrimary)
            .lineLimit(2)
    }

    @MainActor
    private var activityDescription: String {
        switch activity.activityType {
        case .workout:
            if let name = activity.exerciseName, let weight = activity.weight, let reps = activity.reps {
                return "\(name) \(formatWeight(weight))kg × \(reps) \(L10n.feedRecorded)"
            }
            return L10n.feedWorkoutCompleted

        case .pr:
            if let name = activity.exerciseName, let weight = activity.weight, let reps = activity.reps {
                return "\(name) \(formatWeight(weight))kg × \(reps) \(L10n.feedPRUpdated)"
            }
            return L10n.feedPRGeneric

        case .streak:
            return L10n.feedStreakAchieved
        }
    }

    // MARK: - 筋肉マップサムネイル

    private var muscleMapThumbnail: some View {
        let mapping = buildMuscleMapping()

        return HStack(spacing: 4) {
            MiniMuscleMapView(muscleMapping: mapping, showFront: true)
                .frame(width: 28, height: 46)

            MiniMuscleMapView(muscleMapping: mapping, showFront: false)
                .frame(width: 28, height: 46)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.mmBgPrimary.opacity(0.5))
        )
    }

    // MARK: - リアクションボタン

    private var reactionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                fireCount += 1
                hasReacted = true
            }
        } label: {
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.subheadline)

                if fireCount > 0 {
                    Text("\(fireCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(hasReacted ? Color.mmAccentPrimary : Color.mmTextSecondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(hasReacted ? Color.mmAccentPrimary.opacity(0.15) : Color.mmBgSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - ヘルパー

    /// stimulatedMuscles配列 → MiniMuscleMapView用のマッピングを構築
    private func buildMuscleMapping() -> [String: Int] {
        var mapping: [String: Int] = [:]
        for muscle in activity.stimulatedMuscles {
            mapping[muscle] = 80  // モックでは一律80%刺激
        }
        return mapping
    }

    /// 重量の表示フォーマット（小数点以下不要なら整数表示）
    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

// MARK: - Date拡張（相対時間表示）

extension Date {
    @MainActor
    func timeAgoDisplay() -> String {
        let seconds = -self.timeIntervalSinceNow
        let minutes = seconds / 60
        let hours = minutes / 60

        if minutes < 1 {
            return L10n.feedJustNow
        } else if minutes < 60 {
            return L10n.feedMinutesAgo(Int(minutes))
        } else if hours < 24 {
            return L10n.feedHoursAgo(Int(hours))
        } else {
            return L10n.feedDaysAgo(Int(hours / 24))
        }
    }
}

// MARK: - PR用カラー拡張

extension Color {
    /// PR達成カードの背景色（ゴールド系）
    static let mmPRCardBg = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.16, blue: 0.08, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0)
    })

    /// PR達成カードのボーダー色
    static let mmPRBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.4)
            : UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.3)
    })

    /// PRアクセント色（ゴールド）
    static let mmPRAccent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            : UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0)
    })
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            FriendActivityCard(
                activity: FriendActivity(
                    id: UUID(),
                    userName: "タクヤ",
                    avatarEmoji: "💪",
                    activityType: .pr,
                    exerciseName: "ベンチプレス",
                    weight: 100,
                    reps: 3,
                    isPR: true,
                    stimulatedMuscles: ["chest_upper", "chest_lower", "triceps"],
                    timestamp: Date().addingTimeInterval(-1800)
                )
            )

            FriendActivityCard(
                activity: FriendActivity(
                    id: UUID(),
                    userName: "ユウキ",
                    avatarEmoji: "🔥",
                    activityType: .workout,
                    exerciseName: "デッドリフト",
                    weight: 180,
                    reps: 5,
                    isPR: false,
                    stimulatedMuscles: ["erector_spinae", "glutes", "hamstrings"],
                    timestamp: Date().addingTimeInterval(-5400)
                )
            )

            FriendActivityCard(
                activity: FriendActivity(
                    id: UUID(),
                    userName: "ミホ",
                    avatarEmoji: "✨",
                    activityType: .streak,
                    exerciseName: nil,
                    weight: nil,
                    reps: nil,
                    isPR: false,
                    stimulatedMuscles: [],
                    timestamp: Date().addingTimeInterval(-14400)
                )
            )
        }
        .padding(16)
    }
    .background(Color.mmBgPrimary)
}

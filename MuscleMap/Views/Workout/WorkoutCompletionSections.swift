import SwiftUI

// MARK: - 統計ボックス（レガシー互換用）

struct StatBox: View {
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
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PR祝福データモデル

struct PRCelebrationItem: Identifiable {
    let id = UUID()
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let increasePercent: Int
}

// MARK: - 次回おすすめ日セクション

struct NextRecommendedDaySection: View {
    let stimulatedMuscles: [(muscle: Muscle, totalSets: Int)]
    var nextRoutineName: String?

    @State private var reminderScheduled = false

    private var recommendedDate: Date {
        let now = Date()
        var maxHours: Double = 0
        for entry in stimulatedMuscles {
            let hours = RecoveryCalculator.adjustedRecoveryHours(
                muscle: entry.muscle,
                totalSets: entry.totalSets
            )
            maxHours = max(maxHours, hours)
        }
        return now.addingTimeInterval(maxHours * 3600)
    }

    private var daysUntil: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: recommendedDate)
        return max(0, cal.dateComponents([.day], from: today, to: target).day ?? 0)
    }

    private var dateLabel: String {
        if daysUntil <= 0 { return L10n.today }
        if daysUntil == 1 { return L10n.tomorrow }
        let fmt = DateFormatter()
        fmt.dateFormat = LocalizationManager.shared.currentLanguage == .japanese
            ? "M月d日（E）"
            : "MMM d (EEE)"
        fmt.locale = LocalizationManager.shared.currentLanguage.locale
        return fmt.string(from: recommendedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(Color.mmAccentSecondary)

                Text(L10n.nextWorkoutSuggestion)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(dateLabel)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color.mmAccentPrimary)

                if daysUntil > 1 {
                    Text(L10n.nextBestDateLabel(""))
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            if let routineName = nextRoutineName {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text(routineName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }

            Text(L10n.basedOnRecoveryPrediction)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)

            Button {
                HapticManager.lightTap()
                NotificationManager.shared.scheduleRecoveryReminder(
                    nextPartName: nextRoutineName ?? (LocalizationManager.shared.currentLanguage == .japanese ? "トレーニング" : "Training"),
                    recoveryDate: recommendedDate
                )
                withAnimation {
                    reminderScheduled = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: reminderScheduled ? "checkmark.circle.fill" : "bell.badge")
                        .font(.subheadline)
                    Text(reminderScheduled ? L10n.reminderScheduled : L10n.scheduleReminder)
                        .font(.subheadline.bold())
                }
                .foregroundStyle(reminderScheduled ? Color.mmAccentPrimary : Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(reminderScheduled ? Color.mmAccentPrimary.opacity(0.15) : Color.mmAccentPrimary)
                )
            }
            .buttonStyle(.plain)
            .disabled(reminderScheduled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 完了ボタンセクション（レガシー互換用）

struct CompletionButtonSection: View {
    let onShare: () -> Void
    let onDismiss: () -> Void
    var onProTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onShare) {
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

            Button(action: onDismiss) {
                Text(L10n.close)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
}


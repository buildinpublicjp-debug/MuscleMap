import SwiftUI

// MARK: - セッション履歴

struct SessionHistorySection: View {
    let sessions: [WorkoutSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.sessionHistory)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                    Text(L10n.noSessionsYet)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(sessions) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - セッション行

struct SessionRowView: View {
    let session: WorkoutSession
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var exerciseNames: String {
        let ids = Set(session.sets.map(\.exerciseId))
        let names = ids.compactMap { id -> String? in
            guard let exercise = ExerciseStore.shared.exercise(for: id) else { return nil }
            return localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
        }
        let displayNames = names.prefix(3).joined(separator: ", ")
        return names.count > 3 ? "\(displayNames) \(L10n.andMore)" : displayNames
    }

    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private var duration: String {
        guard let end = session.endDate else { return L10n.inProgress }
        let interval = end.timeIntervalSince(session.startDate)
        let minutes = Int(interval / 60)
        return L10n.minutes(minutes)
    }

    /// セッション内の種目から筋肉マッピングを集約
    private var aggregatedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        let ids = Set(session.sets.map(\.exerciseId))
        for id in ids {
            guard let exercise = ExerciseStore.shared.exercise(for: id) else { continue }
            for (muscle, intensity) in exercise.muscleMapping {
                mapping[muscle] = max(mapping[muscle] ?? 0, intensity)
            }
        }
        return mapping
    }

    var body: some View {
        HStack(spacing: 12) {
            // ミニ筋肉マップ（ビジュアル要素）
            MiniMuscleMapView(muscleMapping: aggregatedMuscleMapping)
                .frame(width: 36, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                    Text(duration)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                Text(exerciseNames)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 16) {
                    Label(L10n.setsLabel(session.sets.count), systemImage: "number")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                    Label(formatVolume(totalVolume), systemImage: "scalemass")
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(.vertical, 8)

        Divider()
            .background(Color.mmBgSecondary)
    }
}

import SwiftUI
import SwiftData

// MARK: - 日付別ワークアウト詳細ビュー

struct DayWorkoutDetailView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var localizedDateString: String {
        let formatter = DateFormatter()
        if localization.currentLanguage == .japanese {
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy年M月d日"
        } else {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateStyle = .medium
        }
        return formatter.string(from: date)
    }

    private var sessions: [WorkoutSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.startDate)]
        )
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        return allSessions.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        Text(L10n.noSessionsYet)
                            .font(.headline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(sessions) { session in
                                SessionDetailCard(session: session)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(localizedDateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - セッション詳細カード

private struct SessionDetailCard: View {
    let session: WorkoutSession
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var duration: String {
        guard let end = session.endDate else { return L10n.inProgress }
        let interval = end.timeIntervalSince(session.startDate)
        let minutes = Int(interval / 60)
        if minutes < 1 {
            return L10n.lessThanOneMinute
        }
        return L10n.minutes(minutes)
    }

    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    /// 刺激した筋肉のマッピング（筋肉ID → 最大刺激度%）
    private var stimulatedMuscleMapping: [String: Int] {
        var muscleIntensity: [String: Int] = [:]
        for set in session.sets {
            guard let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) else { continue }
            for (muscleId, percentage) in exercise.muscleMapping {
                muscleIntensity[muscleId] = max(muscleIntensity[muscleId] ?? 0, percentage)
            }
        }
        return muscleIntensity
    }

    /// 種目ごとにセットをグループ化
    private var exerciseSets: [(exercise: ExerciseDefinition, sets: [WorkoutSet])] {
        var seen = Set<String>()
        var result: [(exercise: ExerciseDefinition, sets: [WorkoutSet])] = []

        for set in session.sets {
            if !seen.contains(set.exerciseId) {
                seen.insert(set.exerciseId)
                if let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) {
                    let sets = session.sets.filter { $0.exerciseId == set.exerciseId }
                    result.append((exercise: exercise, sets: sets))
                }
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(session.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                HStack(spacing: 12) {
                    Label(duration, systemImage: "clock")
                    Label(L10n.setsLabel(session.sets.count), systemImage: "number")
                }
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
            }

            // サマリー行（種目数・合計ボリューム）
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text("\(exerciseSets.count)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text("種目")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(totalVolume >= 1000 ? String(format: "%.1fk", totalVolume / 1000) : String(format: "%.0f", totalVolume))
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text("kg")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
            }

            // ミニ筋肉マップ（アスペクト比を維持・サイズ拡大）
            if !stimulatedMuscleMapping.isEmpty {
                HStack(spacing: 12) {
                    MiniMuscleMapView(muscleMapping: stimulatedMuscleMapping, showFront: true)
                        .aspectRatio(0.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    MiniMuscleMapView(muscleMapping: stimulatedMuscleMapping, showFront: false)
                        .aspectRatio(0.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                }
                .padding(.vertical, 8)
            }

            Divider().background(Color.mmBgSecondary)

            // 種目ごとのセット（種目名 + セット数 + 種目ボリューム）
            ForEach(exerciseSets, id: \.exercise.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(localization.currentLanguage == .japanese ? entry.exercise.nameJA : entry.exercise.nameEN)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        Spacer()
                        let exerciseVolume = entry.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                        Text("\(entry.sets.count)セット")
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                        if exerciseVolume > 0 {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                            Text(String(format: "%.0fkg", exerciseVolume))
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }

                    ForEach(entry.sets, id: \.id) { set in
                        HStack {
                            Text(L10n.setNumber(set.setNumber))
                                .font(.caption)
                                .foregroundStyle(Color.mmTextSecondary)
                                .frame(width: 50, alignment: .leading)

                            if set.weight > 0 {
                                Text(L10n.weightReps(set.weight, set.reps))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(Color.mmTextPrimary)
                            } else {
                                Text(L10n.repsOnly(set.reps))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(Color.mmTextPrimary)
                            }

                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DayWorkoutDetailView(date: Date())
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

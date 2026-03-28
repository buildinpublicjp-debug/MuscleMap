import SwiftUI
import SwiftData

// MARK: - 日付別ワークアウト詳細ビュー

struct DayWorkoutDetailView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var daySessions: [WorkoutSession] = []
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

    /// onAppearでセッションを取得（predicateで日付フィルタ）
    private func loadDaySessions() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            daySessions = []
            return
        }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate {
                $0.startDate >= startOfDay && $0.startDate < endOfDay
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        daySessions = (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if daySessions.isEmpty {
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
                            ForEach(daySessions) { session in
                                SessionDetailCard(
                                    session: session,
                                    onSessionDeleted: { loadDaySessions() }
                                )
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
        .onAppear {
            loadDaySessions()
        }
    }
}

// MARK: - セッション詳細カード

private struct SessionDetailCard: View {
    let session: WorkoutSession
    var onSessionDeleted: () -> Void
    @Environment(\.modelContext) private var modelContext
    private var localization: LocalizationManager { LocalizationManager.shared }

    // セット編集用
    @State private var setToEdit: WorkoutSet?

    // セット削除用
    @State private var setToDelete: WorkoutSet?
    @State private var showDeleteSetConfirmation = false

    // セッション削除用
    @State private var showDeleteSessionConfirmation = false

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
                    let sets = session.sets
                        .filter { $0.exerciseId == set.exerciseId }
                        .sorted { $0.setNumber < $1.setNumber }
                    result.append((exercise: exercise, sets: sets))
                }
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー（セッション削除メニュー付き）
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

                // セッション削除メニュー
                Menu {
                    Button(role: .destructive) {
                        showDeleteSessionConfirmation = true
                    } label: {
                        Label(
                            LocalizationManager.localized(
                                ja: "セッションを削除",
                                en: "Delete Session"
                            ),
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
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
                    Text(localization.currentLanguage == .japanese ? "種目" : "exercises")
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

            // ミニ筋肉マップ（大きめ表示）
            if !stimulatedMuscleMapping.isEmpty {
                HStack(spacing: 12) {
                    MiniMuscleMapView(muscleMapping: stimulatedMuscleMapping, showFront: true)
                        .aspectRatio(0.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                    MiniMuscleMapView(muscleMapping: stimulatedMuscleMapping, showFront: false)
                        .aspectRatio(0.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                }
            }

            Divider().background(Color.mmBgSecondary)

            // 種目ごとのセット（種目名 + セット数 + 種目ボリューム）
            ForEach(exerciseSets, id: \.exercise.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        // GIFサムネイル（50x50pt、mmBgCard角丸）
                        ZStack {
                            Color.mmBgCard
                            if ExerciseGifView.hasGif(exerciseId: entry.exercise.id) {
                                ExerciseGifView(exerciseId: entry.exercise.id, size: .thumbnail)
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipped()
                            } else {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.currentLanguage == .japanese ? entry.exercise.nameJA : entry.exercise.nameEN)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            HStack(spacing: 4) {
                                let exerciseVolume = entry.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                                Text(localization.currentLanguage == .japanese ? "\(entry.sets.count)セット" : "\(entry.sets.count) sets")
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
                        }

                        Spacer()
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

                            // 編集アイコン
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(setToEdit?.id == set.id ? Color.mmAccentPrimary.opacity(0.1) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            setToEdit = set
                            HapticManager.lightTap()
                        }
                        .contextMenu {
                            Button {
                                setToEdit = set
                            } label: {
                                Label(L10n.editSet, systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                setToDelete = set
                                showDeleteSetConfirmation = true
                            } label: {
                                Label(L10n.delete, systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // セット編集シート
        .sheet(item: $setToEdit) { workoutSet in
            HistorySetEditSheet(workoutSet: workoutSet) {
                recalculateMuscleStimulations(session: session)
            }
        }
        // セット削除確認
        .alert(
            L10n.deleteSetConfirm,
            isPresented: $showDeleteSetConfirmation
        ) {
            Button(L10n.cancel, role: .cancel) {
                setToDelete = nil
            }
            Button(L10n.delete, role: .destructive) {
                if let set = setToDelete {
                    deleteSet(set)
                }
                setToDelete = nil
            }
        }
        // セッション削除確認
        .alert(
            LocalizationManager.localized(
                ja: "このセッションを削除しますか？\n全てのセットと関連データが削除されます。",
                en: "Delete this session?\nAll sets and related data will be removed."
            ),
            isPresented: $showDeleteSessionConfirmation
        ) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.delete, role: .destructive) {
                deleteSession()
            }
        }
    }

    // MARK: - セット削除処理

    private func deleteSet(_ workoutSet: WorkoutSet) {
        let exerciseId = workoutSet.exerciseId

        // 1. セット削除
        modelContext.delete(workoutSet)

        // 2. 同じ種目の残りセットのsetNumberを振り直し
        let remainingSets = session.sets
            .filter { $0.exerciseId == exerciseId && $0.id != workoutSet.id }
            .sorted { $0.setNumber < $1.setNumber }

        for (index, set) in remainingSets.enumerated() {
            set.setNumber = index + 1
        }

        // 3. セッションのセットが0件になったらセッションごと削除
        let allRemaining = session.sets.filter { $0.id != workoutSet.id }
        if allRemaining.isEmpty {
            let muscleRepo = MuscleStateRepository(modelContext: modelContext)
            muscleRepo.deleteStimulations(sessionId: session.id)
            modelContext.delete(session)
        }

        // 4. 1回だけsave
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[ERROR] deleteSet save failed: \(error)")
            #endif
        }

        // 5. セッション削除済みならコールバックして終了
        if allRemaining.isEmpty {
            HapticManager.error()
            onSessionDeleted()
            return
        }

        // 6. MuscleStimulationの再計算
        recalculateMuscleStimulations(session: session)
        HapticManager.error()
    }

    // MARK: - セッション削除処理

    private func deleteSession() {
        let muscleRepo = MuscleStateRepository(modelContext: modelContext)
        muscleRepo.deleteStimulations(sessionId: session.id)

        for set in session.sets {
            modelContext.delete(set)
        }
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[DayWorkoutDetail] Failed to save after session delete: \(error)")
            #endif
        }

        HapticManager.error()
        onSessionDeleted()
    }

    // MARK: - MuscleStimulation再計算

    private func recalculateMuscleStimulations(session: WorkoutSession) {
        let muscleRepo = MuscleStateRepository(modelContext: modelContext)

        // セッションに関連するMuscleStimulationを削除
        muscleRepo.deleteStimulations(sessionId: session.id)

        // 残りのセットから再計算
        let exerciseStore = ExerciseStore.shared
        // 種目ごとのセット数を集計
        var exerciseSetCounts: [String: Int] = [:]
        for set in session.sets {
            exerciseSetCounts[set.exerciseId, default: 0] += 1
        }

        // 筋肉ごとに最大刺激度とセット数を集計してupsert
        var muscleData: [Muscle: (maxIntensity: Double, totalSets: Int)] = [:]
        for (exerciseId, setsCount) in exerciseSetCounts {
            guard let exercise = exerciseStore.exercise(for: exerciseId) else { continue }
            for (muscleId, percentage) in exercise.muscleMapping {
                guard let muscle = Muscle(rawValue: muscleId) else { continue }
                let intensity = Double(percentage) / 100.0
                if let existing = muscleData[muscle] {
                    muscleData[muscle] = (
                        maxIntensity: max(existing.maxIntensity, intensity),
                        totalSets: existing.totalSets + setsCount
                    )
                } else {
                    muscleData[muscle] = (maxIntensity: intensity, totalSets: setsCount)
                }
            }
        }

        for (muscle, data) in muscleData {
            muscleRepo.upsertStimulation(
                muscle: muscle,
                sessionId: session.id,
                maxIntensity: data.maxIntensity,
                totalSets: data.totalSets,
                saveImmediately: false
            )
        }
        muscleRepo.save()
    }
}

// MARK: - セット編集シート（履歴用）

private struct HistorySetEditSheet: View {
    let workoutSet: WorkoutSet
    var onSaved: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editWeight: Double
    @State private var editReps: Int

    init(workoutSet: WorkoutSet, onSaved: @escaping () -> Void) {
        self.workoutSet = workoutSet
        self.onSaved = onSaved
        _editWeight = State(initialValue: workoutSet.weight)
        _editReps = State(initialValue: workoutSet.reps)
    }

    private var exerciseName: String {
        if let exercise = ExerciseStore.shared.exercise(for: workoutSet.exerciseId) {
            return LocalizationManager.shared.currentLanguage == .japanese
                ? exercise.nameJA
                : exercise.nameEN
        }
        return workoutSet.exerciseId
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgSecondary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // 種目名 + セット番号
                    VStack(spacing: 4) {
                        Text(exerciseName)
                            .font(.headline)
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(L10n.setNumber(workoutSet.setNumber))
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.top, 8)

                    // 重量入力
                    VStack(spacing: 8) {
                        Text(LocalizationManager.localized(ja: "重量 (kg)", en: "Weight (kg)"))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)

                        HStack(spacing: 16) {
                            WeightStepperButton(systemImage: "minus") {
                                if editWeight >= 0.25 {
                                    editWeight -= 0.25
                                }
                            } onLongPress: {
                                if editWeight >= 2.5 {
                                    editWeight -= 2.5
                                }
                            }

                            Text(String(format: "%.2f", editWeight))
                                .font(.system(size: 36, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Color.mmTextPrimary)
                                .frame(minWidth: 100)

                            WeightStepperButton(systemImage: "plus") {
                                editWeight += 0.25
                            } onLongPress: {
                                editWeight += 2.5
                            }
                        }
                    }
                    .padding()
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // レップ数入力
                    VStack(spacing: 8) {
                        Text(LocalizationManager.localized(ja: "レップ数", en: "Reps"))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)

                        HStack(spacing: 16) {
                            Button {
                                if editReps > 1 {
                                    editReps -= 1
                                    HapticManager.stepperChanged()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.mmTextSecondary)
                            }

                            Text("\(editReps)")
                                .font(.system(size: 36, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Color.mmTextPrimary)
                                .frame(minWidth: 100)

                            Button {
                                editReps += 1
                                HapticManager.stepperChanged()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.mmAccentPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()

                    // 保存ボタン
                    Button {
                        save()
                    } label: {
                        Text(L10n.save)
                            .font(.headline)
                            .foregroundStyle(Color.mmBgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mmAccentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.bottom, 8)
                }
                .padding()
            }
            .navigationTitle(L10n.editSet)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) { dismiss() }
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        workoutSet.weight = editWeight
        workoutSet.reps = editReps
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[DayWorkoutDetail] Failed to save set edit: \(error)")
            #endif
        }
        onSaved()
        HapticManager.lightTap()
        dismiss()
    }
}

#Preview {
    DayWorkoutDetailView(date: Date())
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

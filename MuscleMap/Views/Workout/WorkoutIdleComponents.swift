import SwiftUI
import SwiftData

// MARK: - セッション未開始時のコンポーネント

/// ワークアウト未開始時のメインビュー
struct WorkoutIdleView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onStart: () -> Void
    let onSelectExercise: (ExerciseDefinition) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var selectedMuscle: Muscle?
    @State private var showingExerciseLibrary = false
    @State private var recentExercises: [ExerciseDefinition] = []
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 筋肉マップ（タップで種目選択）
                    MuscleMapView(
                        muscleStates: muscleStates,
                        onMuscleTapped: { muscle in
                            selectedMuscle = muscle
                        }
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.40)
                    .padding(.horizontal)

                    // ヒントテキスト
                    Text(L10n.tapMuscleHint)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .multilineTextAlignment(.center)

                    // 最近使った種目
                    if !recentExercises.isEmpty {
                        RecentExercisesSection(
                            exercises: recentExercises,
                            onSelect: onSelectExercise
                        )
                    }
                }
                .padding(.vertical)
            }

            // 種目を追加して始める（統合CTA）
            Button {
                HapticManager.lightTap()
                showingExerciseLibrary = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.addExerciseAndStart)
                }
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            NavigationStack {
                ExerciseLibraryView()
            }
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleExercisePickerSheet(muscle: muscle) { exercise in
                onSelectExercise(exercise)
                selectedMuscle = nil
            }
        }
        .onAppear {
            loadRecentExercises()
        }
    }

    /// 最近使った種目を取得（completedAt降順、exerciseId重複除去、最新10種目）
    private func loadRecentExercises() {
        let descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        guard let allSets = try? modelContext.fetch(descriptor) else {
            recentExercises = []
            return
        }
        var seenIds: Set<String> = []
        var result: [ExerciseDefinition] = []
        for set in allSets {
            if seenIds.insert(set.exerciseId).inserted,
               let def = ExerciseStore.shared.exercise(for: set.exerciseId) {
                result.append(def)
            }
            if result.count >= 10 { break }
        }
        recentExercises = result
    }
}

// MARK: - 最近使った種目セクション

struct RecentExercisesSection: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.mmAccentPrimary)
                Text(localization.currentLanguage == .japanese ? "最近使った種目" : "Recent Exercises")
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        Button {
                            HapticManager.lightTap()
                            onSelect(exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)

                                HStack(spacing: 4) {
                                    Image(systemName: "dumbbell")
                                    Text(exercise.localizedEquipment)
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)

                                if let primary = exercise.primaryMuscle {
                                    Text(primary.localizedName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.mmAccentPrimary.opacity(0.15))
                                        .foregroundStyle(Color.mmAccentPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(width: 140, alignment: .leading)
                            .padding(12)
                            .background(Color.mmBgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 筋肉タップ時の種目選択シート

struct MuscleExercisePickerSheet: View {
    let muscle: Muscle
    let onSelect: (ExerciseDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var relatedExercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    private func lastRecord(for exerciseId: String) -> WorkoutSet? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if relatedExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        Text(L10n.noData)
                            .font(.headline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(relatedExercises.filter { ExerciseGifView.hasGif(exerciseId: $0.id) }) { exercise in
                                Button {
                                    HapticManager.lightTap()
                                    onSelect(exercise)
                                } label: {
                                    HStack(spacing: 12) {
                                        // サムネイルGIF
                                        ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        // 種目名 + 器具
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Color.mmTextPrimary)
                                                .lineLimit(1)
                                            Text(exercise.localizedEquipment)
                                                .font(.caption)
                                                .foregroundStyle(Color.mmTextSecondary)
                                        }

                                        Spacer()

                                        // 前回記録
                                        if let record = lastRecord(for: exercise.id) {
                                            Text(L10n.lastRecordLabel(record.weight, record.reps))
                                                .font(.caption.monospaced().bold())
                                                .foregroundStyle(Color.mmAccentPrimary)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(Color.mmTextSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 66)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .background(Color.mmBgCard)
                                    .padding(.leading, 78)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(muscle.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

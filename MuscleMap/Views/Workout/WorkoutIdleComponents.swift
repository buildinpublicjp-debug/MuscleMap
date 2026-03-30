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
            .contentShape(Rectangle())
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
        var descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 200
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
                HStack(spacing: 10) {
                    ForEach(exercises) { exercise in
                        let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
                        Button {
                            HapticManager.lightTap()
                            onSelect(exercise)
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                // GIF（固定サイズ + fit）
                                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                    ExerciseGifView(exerciseId: exercise.id, size: .gridCard)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 140, height: 120)
                                        .background(Color.white)
                                        .clipped()
                                } else {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                        .frame(width: 140, height: 120)
                                }

                                // 下部グラデーション
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.8)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )

                                // テキスト
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    if let primary = exercise.primaryMuscle {
                                        HStack(spacing: 3) {
                                            Circle()
                                                .fill(Color.mmAccentPrimary)
                                                .frame(width: 5, height: 5)
                                            Text(primary.localizedName)
                                                .font(.caption2.bold())
                                                .foregroundStyle(Color.mmAccentPrimary)
                                        }
                                    }
                                }
                                .padding(8)
                            }
                            .frame(width: 140, height: 120)
                            .background(Color.mmBgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 20)
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
    @State private var selectedEquipment: String?
    @State private var lastRecords: [String: WorkoutSet] = [:]
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var relatedExercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    /// 器具フィルター適用後の種目リスト
    private var filteredExercises: [ExerciseDefinition] {
        guard let equipment = selectedEquipment else { return relatedExercises }
        return relatedExercises.filter { $0.equipment == equipment }
    }

    /// 利用可能な器具タイプ（この筋肉の種目に存在するもののみ）
    private var availableEquipment: [LibraryEquipmentFilter] {
        let equipmentSet = Set(relatedExercises.map(\.equipment))
        return LibraryEquipmentFilter.allCases.filter { equipmentSet.contains($0.rawValue) }
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
                        VStack(spacing: 12) {
                            // 器具フィルターチップ
                            if availableEquipment.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        PickerFilterChip(
                                            title: localization.currentLanguage == .japanese ? "すべて" : "All",
                                            isSelected: selectedEquipment == nil
                                        ) {
                                            selectedEquipment = nil
                                        }

                                        ForEach(availableEquipment) { filter in
                                            PickerFilterChip(
                                                title: filter.localizedName,
                                                isSelected: selectedEquipment == filter.rawValue
                                            ) {
                                                selectedEquipment = selectedEquipment == filter.rawValue ? nil : filter.rawValue
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            // 2列グリッド（Netflixスタイル）
                            let columns = [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ]
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filteredExercises) { exercise in
                                    musclePickerGridCard(exercise)
                                }
                            }
                            .padding(.horizontal, 16)
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
            .onAppear { loadLastRecords() }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Netflixスタイルグリッドカード

    @ViewBuilder
    private func musclePickerGridCard(_ exercise: ExerciseDefinition) -> some View {
        let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
        let primary = exercise.primaryMuscle

        Button {
            HapticManager.lightTap()
            onSelect(exercise)
        } label: {
            ZStack(alignment: .bottomLeading) {
                // GIF or フォールバック（静止画 + fit）
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(Color.white)
                        .clipped()
                } else {
                    MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                }

                // 下部グラデーションオーバーレイ
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // テキスト情報
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let primary {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.mmAccentPrimary)
                                .frame(width: 5, height: 5)
                            Text(primary.localizedName)
                                .font(.caption2.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }

                    // 前回記録
                    if let record = lastRecords[exercise.id] {
                        Text(L10n.lastRecordLabel(record.weight, record.reps))
                            .font(.system(size: 9, weight: .bold).monospaced())
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
                .padding(8)
            }
            .frame(height: 160)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    // MARK: - 前回記録の一括取得

    private func loadLastRecords() {
        let exerciseIds = relatedExercises.map(\.id)
        var descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 500
        guard let allSets = try? modelContext.fetch(descriptor) else { return }

        var records: [String: WorkoutSet] = [:]
        let idSet = Set(exerciseIds)
        for set in allSets {
            if idSet.contains(set.exerciseId) && records[set.exerciseId] == nil {
                records[set.exerciseId] = set
            }
        }
        lastRecords = records
    }
}

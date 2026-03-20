import SwiftUI

// MARK: - 種目辞典タブ（筋肉マップ + 2段フィルター + 2カラムGIFグリッド）

struct ExerciseDictionaryView: View {
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedEquipment: String?   // nil=全器具, "⭐"=お気に入り, else=equipmentキー
    @State private var selectedExercise: ExerciseDefinition?
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 器具フィルターリスト（exercises.jsonのキーベース）
    private let equipmentFilters: [(key: String, jaLabel: String, enLabel: String)] = [
        ("バーベル", "バーベル", "Barbell"),
        ("ダンベル", "ダンベル", "Dumbbell"),
        ("マシン", "マシン", "Machine"),
        ("ケーブル", "ケーブル", "Cable"),
        ("自重", "自重", "Bodyweight"),
        ("ケトルベル", "ケトルベル", "Kettlebell"),
    ]

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    /// 2段フィルター適用済み種目
    private var filteredExercises: [ExerciseDefinition] {
        var result = ExerciseStore.shared.exercises

        // 1段目: 部位グループフィルター
        if let group = selectedMuscleGroup {
            let musclesInGroup = Set(Muscle.allCases.filter { $0.group == group }.map(\.rawValue))
            result = result.filter { exercise in
                exercise.muscleMapping.keys.contains(where: { musclesInGroup.contains($0) })
            }
        }

        // 2段目: 器具 or お気に入りフィルター
        if let equip = selectedEquipment {
            if equip == "⭐" {
                result = result.filter { FavoritesManager.shared.isFavorite($0.id) }
            } else {
                result = result.filter { $0.equipment == equip }
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 筋肉マップ（常時表示、タップでグループフィルター）
                    MuscleMapView(
                        muscleStates: muscleStates,
                        onMuscleTapped: { muscle in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedMuscleGroup == muscle.group {
                                    selectedMuscleGroup = nil
                                } else {
                                    selectedMuscleGroup = muscle.group
                                }
                            }
                            HapticManager.lightTap()
                        }
                    )
                    .frame(height: 200)
                    .padding(.horizontal, 16)

                    // 1段目: 部位グループチップ
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            filterChip(
                                text: isJapanese ? "すべて" : "All",
                                icon: nil,
                                isSelected: selectedMuscleGroup == nil,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMuscleGroup = nil
                                    }
                                    HapticManager.lightTap()
                                }
                            )

                            ForEach(MuscleGroup.allCases) { group in
                                filterChip(
                                    text: group.localizedName,
                                    icon: nil,
                                    isSelected: selectedMuscleGroup == group,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedMuscleGroup = selectedMuscleGroup == group ? nil : group
                                        }
                                        HapticManager.lightTap()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // 2段目: 器具チップ
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            filterChip(
                                text: isJapanese ? "全器具" : "All",
                                icon: nil,
                                isSelected: selectedEquipment == nil,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedEquipment = nil
                                    }
                                    HapticManager.lightTap()
                                }
                            )

                            filterChip(
                                text: isJapanese ? "お気に入り" : "Favorites",
                                icon: "star.fill",
                                isSelected: selectedEquipment == "⭐",
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedEquipment = selectedEquipment == "⭐" ? nil : "⭐"
                                    }
                                    HapticManager.lightTap()
                                }
                            )

                            ForEach(equipmentFilters, id: \.key) { filter in
                                filterChip(
                                    text: isJapanese ? filter.jaLabel : filter.enLabel,
                                    icon: nil,
                                    isSelected: selectedEquipment == filter.key,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedEquipment = selectedEquipment == filter.key ? nil : filter.key
                                        }
                                        HapticManager.lightTap()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // 種目数ヘッダー
                    HStack {
                        Text(isJapanese
                            ? "\(filteredExercises.count)種目"
                            : "\(filteredExercises.count) exercises")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    // 2カラムGIFグリッド
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            Button {
                                selectedExercise = exercise
                                HapticManager.lightTap()
                            } label: {
                                ZStack(alignment: .bottom) {
                                    // GIF
                                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                        ExerciseGifView(exerciseId: exercise.id, size: .card)
                                            .scaledToFill()
                                    } else {
                                        Color.mmBgSecondary
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 28))
                                            .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                                    }

                                    // 下部: 種目名 + 筋肉チップ + 器具
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.localizedName)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)

                                        HStack(spacing: 4) {
                                            // 主要筋肉チップ（1つ）
                                            if let primaryMuscleId = exercise.muscleMapping.max(by: { $0.value < $1.value })?.key,
                                               let muscle = Muscle(rawValue: primaryMuscleId) {
                                                Text(muscle.localizedName)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(Color.mmAccentPrimary)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(Color.mmAccentPrimary.opacity(0.2))
                                                    .clipShape(Capsule())
                                            }

                                            Text(exercise.localizedEquipment)
                                                .font(.system(size: 9))
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.clear, Color.black.opacity(0.75)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }
            .background(Color.mmBgPrimary)
            .navigationTitle(isJapanese ? "種目辞典" : "Exercise Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            ExerciseStore.shared.loadIfNeeded()
            updateMuscleStates()
        }
        .onChange(of: selectedMuscleGroup) {
            updateMuscleStates()
        }
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 筋肉マップ状態更新（選択グループをハイライト）

    private func updateMuscleStates() {
        var states: [Muscle: MuscleVisualState] = [:]
        if let group = selectedMuscleGroup {
            for muscle in Muscle.allCases {
                states[muscle] = muscle.group == group
                    ? .recovering(progress: 0.1)
                    : .inactive
            }
        } else {
            for muscle in Muscle.allCases {
                states[muscle] = .inactive
            }
        }
        muscleStates = states
    }

    // MARK: - フィルターチップ

    private func filterChip(text: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(text)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.mmBgPrimary : Color.mmTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.mmAccentPrimary : Color.mmBgCard)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExerciseDictionaryView()
}

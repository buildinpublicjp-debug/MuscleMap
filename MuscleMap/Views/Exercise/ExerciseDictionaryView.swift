import SwiftUI

// MARK: - 種目辞典タブ（筋肉マップ + 2カラムGIFグリッド）

struct ExerciseDictionaryView: View {
    @State private var selectedMuscle: Muscle?
    @State private var selectedExercise: ExerciseDefinition?
    @State private var searchText = ""
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]
    @State private var selectedFilter: ExerciseFilter = .all

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// フィルタータイプ
    private enum ExerciseFilter: Hashable {
        case all
        case favorites
        case equipment(String) // 日本語キー（"バーベル"等）
    }

    /// フィルター適用済み種目
    private var filteredExercises: [ExerciseDefinition] {
        var result = ExerciseStore.shared.exercises

        // テキスト検索
        if !searchText.isEmpty {
            result = result.filter {
                $0.localizedName.localizedCaseInsensitiveContains(searchText) ||
                $0.localizedEquipment.localizedCaseInsensitiveContains(searchText)
            }
        }

        // フィルター
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { FavoritesManager.shared.isFavorite($0.id) }
        case .equipment(let equip):
            result = result.filter { $0.equipment == equip }
        }

        return result
    }

    /// 器具フィルターリスト
    private let equipmentFilters: [(key: String, jaLabel: String, enLabel: String)] = [
        ("バーベル", "バーベル", "Barbell"),
        ("ダンベル", "ダンベル", "Dumbbell"),
        ("マシン", "マシン", "Machine"),
        ("ケーブル", "ケーブル", "Cable"),
        ("自重", "自重", "Bodyweight"),
    ]

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 筋肉マップ（検索中は非表示）
                    if searchText.isEmpty {
                        MuscleMapView(
                            muscleStates: muscleStates,
                            onMuscleTapped: { muscle in
                                selectedMuscle = muscle
                                HapticManager.lightTap()
                            }
                        )
                        .frame(height: 200)
                        .padding(.horizontal, 16)

                        // ヒント
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap")
                                .font(.caption)
                            Text(isJapanese ? "筋肉をタップして種目を見る" : "Tap a muscle to see exercises")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.mmTextSecondary)
                    }

                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.mmTextSecondary)
                        TextField(
                            isJapanese ? "種目を検索" : "Search exercises",
                            text: $searchText
                        )
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                    // フィルタータブ（横スクロール）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            // お気に入り
                            filterChip(
                                text: isJapanese ? "お気に入り" : "Favorites",
                                icon: "star.fill",
                                isSelected: selectedFilter == .favorites,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = selectedFilter == .favorites ? .all : .favorites
                                    }
                                    HapticManager.lightTap()
                                }
                            )

                            // すべて
                            filterChip(
                                text: isJapanese ? "すべて" : "All",
                                icon: nil,
                                isSelected: selectedFilter == .all,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFilter = .all
                                    }
                                    HapticManager.lightTap()
                                }
                            )

                            // 器具別
                            ForEach(equipmentFilters, id: \.key) { filter in
                                filterChip(
                                    text: isJapanese ? filter.jaLabel : filter.enLabel,
                                    icon: nil,
                                    isSelected: selectedFilter == .equipment(filter.key),
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFilter = selectedFilter == .equipment(filter.key) ? .all : .equipment(filter.key)
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
            if muscleStates.isEmpty {
                for muscle in Muscle.allCases {
                    muscleStates[muscle] = .inactive
                }
            }
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleExerciseDictionarySheet(muscle: muscle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
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

// MARK: - 筋肉タップ → 種目シート（2カラムGIFグリッド）

private struct MuscleExerciseDictionarySheet: View {
    let muscle: Muscle
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: ExerciseDefinition?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var exercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(exercises) { exercise in
                        Button {
                            selectedExercise = exercise
                            HapticManager.lightTap()
                        } label: {
                            ZStack(alignment: .bottom) {
                                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                                        .scaledToFill()
                                } else {
                                    Color.mmBgSecondary
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.mmTextSecondary.opacity(0.3))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.localizedName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Text(exercise.localizedEquipment)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.7))
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
                .padding(16)
            }
            .background(Color.mmBgPrimary)
            .navigationTitle(isJapanese
                ? "\(muscle.japaneseName) — \(exercises.count)種目"
                : "\(muscle.englishName) — \(exercises.count) exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ExerciseDictionaryView()
}

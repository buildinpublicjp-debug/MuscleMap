import SwiftUI

// MARK: - Biblioteca リデザイン v1.1.5 共通コンポーネント

// MARK: - 1. Explorar por 4軸セグメント

struct ExploreBySegment: View {
    @Binding var selectedAxis: ExploreAxis

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.exploreByLabel)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
                .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ForEach(ExploreAxis.allCases) { axis in
                    axisChip(axis)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func axisChip(_ axis: ExploreAxis) -> some View {
        let isActive = selectedAxis == axis
        return Button {
            HapticManager.lightTap()
            selectedAxis = axis
        } label: {
            HStack(spacing: 4) {
                Image(systemName: axis.iconName)
                    .font(.system(size: 11))
                Text(label(for: axis))
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isActive ? Color.mmAccentPrimary : Color.mmBgCard)
            .foregroundStyle(isActive ? Color.mmBgPrimary : Color.mmTextPrimary)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func label(for axis: ExploreAxis) -> String {
        switch axis {
        case .musculo:   return L10n.axisMusculo
        case .equipo:    return L10n.axisEquipo
        case .nivel:     return L10n.axisNivel
        case .favoritos: return L10n.axisFavoritos
        }
    }
}

// MARK: - 2. 主軸絞り込みチップ (横スクロール)

struct PrimaryFilterChips: View {
    @Bindable var viewModel: ExerciseListViewModel

    var body: some View {
        switch viewModel.selectedAxis {
        case .musculo:   muscleChips
        case .equipo:    equipmentChips
        case .nivel:     difficultyChips
        case .favoritos: EmptyView()
        }
    }

    private var muscleChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MuscleGroup.allCases) { group in
                    chipBase(
                        title: group.localizedName,
                        isActive: viewModel.selectedMuscleGroup == group
                    ) {
                        viewModel.selectedMuscleGroup = (viewModel.selectedMuscleGroup == group) ? nil : group
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var equipmentChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.equipmentList, id: \.self) { eq in
                    chipBase(
                        title: L10n.localizedEquipment(eq),
                        isActive: viewModel.selectedEquipment == eq
                    ) {
                        viewModel.selectedEquipment = (viewModel.selectedEquipment == eq) ? nil : eq
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var difficultyChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryDifficulty.allCases) { diff in
                    chipBase(
                        title: difficultyLabel(diff),
                        isActive: viewModel.selectedDifficulty == diff
                    ) {
                        viewModel.selectedDifficulty = (viewModel.selectedDifficulty == diff) ? nil : diff
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func difficultyLabel(_ diff: LibraryDifficulty) -> String {
        switch diff {
        case .principiante: return L10n.diffPrincipiante
        case .intermedio:   return L10n.diffIntermedio
        case .avanzado:     return L10n.diffAvanzado
        }
    }

    private func chipBase(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.lightTap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isActive ? Color.mmAccentPrimary : Color.mmBgCard)
                .foregroundStyle(isActive ? Color.mmBgPrimary : Color.mmTextPrimary)
                .clipShape(Capsule())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3. Filtros 折りたたみバー (副次フィルター)

struct FiltrosCollapsibleBar: View {
    @Bindable var viewModel: ExerciseListViewModel
    @State private var isExpanded = false

    /// 主軸以外の選択数 (バッジ表示用)
    private var secondaryActiveCount: Int {
        var n = 0
        if viewModel.selectedAxis != .musculo, viewModel.selectedMuscleGroup != nil { n += 1 }
        if viewModel.selectedAxis != .equipo, viewModel.selectedEquipment != nil { n += 1 }
        if viewModel.selectedAxis != .nivel, viewModel.selectedDifficulty != nil { n += 1 }
        return n
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                HapticManager.lightTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.filtrosLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.mmTextPrimary)
                    if secondaryActiveCount > 0 {
                        Text("\(secondaryActiveCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.mmBgPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmAccentPrimary)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedContent
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.selectedAxis != .musculo {
                secondaryGroup(title: L10n.axisMusculo) {
                    ForEach(MuscleGroup.allCases) { group in
                        smallChip(
                            title: group.localizedName,
                            isActive: viewModel.selectedMuscleGroup == group
                        ) {
                            viewModel.selectedMuscleGroup = (viewModel.selectedMuscleGroup == group) ? nil : group
                        }
                    }
                }
            }
            if viewModel.selectedAxis != .equipo {
                secondaryGroup(title: L10n.axisEquipo) {
                    ForEach(viewModel.equipmentList, id: \.self) { eq in
                        smallChip(
                            title: L10n.localizedEquipment(eq),
                            isActive: viewModel.selectedEquipment == eq
                        ) {
                            viewModel.selectedEquipment = (viewModel.selectedEquipment == eq) ? nil : eq
                        }
                    }
                }
            }
            if viewModel.selectedAxis != .nivel {
                secondaryGroup(title: L10n.axisNivel) {
                    ForEach(LibraryDifficulty.allCases) { diff in
                        smallChip(
                            title: difficultyLabel(diff),
                            isActive: viewModel.selectedDifficulty == diff
                        ) {
                            viewModel.selectedDifficulty = (viewModel.selectedDifficulty == diff) ? nil : diff
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.mmBgCard.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func secondaryGroup<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    content()
                }
            }
        }
    }

    private func smallChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.lightTap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? Color.mmAccentPrimary : Color.mmBgPrimary)
                .foregroundStyle(isActive ? Color.mmBgPrimary : Color.mmTextPrimary)
                .clipShape(Capsule())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func difficultyLabel(_ diff: LibraryDifficulty) -> String {
        switch diff {
        case .principiante: return L10n.diffPrincipiante
        case .intermedio:   return L10n.diffIntermedio
        case .avanzado:     return L10n.diffAvanzado
        }
    }
}

// MARK: - 4. 件数 + ソート行

struct LibraryCountSortRow: View {
    @Bindable var viewModel: ExerciseListViewModel

    var body: some View {
        HStack(spacing: 8) {
            Text(L10n.exerciseCountLong(viewModel.filteredExercises.count))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)

            Spacer()

            Menu {
                ForEach(LibrarySortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        if viewModel.sortOption == option {
                            Label(sortLabel(option), systemImage: "checkmark")
                        } else {
                            Text(sortLabel(option))
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(L10n.ordenarLabel): \(sortLabel(viewModel.sortOption))")
                        .font(.system(size: 13, weight: .regular))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.horizontal, 16)
    }

    private func sortLabel(_ option: LibrarySortOption) -> String {
        switch option {
        case .relevancia:        return L10n.sortRelevancia
        case .nombre:            return L10n.sortNombre
        case .recientes:         return L10n.sortRecientes
        case .favoritosPrimero:  return L10n.sortFavoritosPrimero
        }
    }
}

// MARK: - 5. 種目グリッドカード (2列)

struct ExerciseGridCardV2: View {
    let exercise: ExerciseDefinition
    let onTap: () -> Void
    @ObservedObject private var favorites = FavoritesManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    // GIF or マッスルマップ (1:1 アスペクト)
                    Group {
                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                            ExerciseGifView(exerciseId: exercise.id, size: .card)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .background(Color.mmGifBackground)
                        } else {
                            MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .clipped()

                    // ❤️ お気に入りボタン (右上)
                    Button {
                        HapticManager.lightTap()
                        favorites.toggle(exercise.id)
                    } label: {
                        Image(systemName: favorites.isFavorite(exercise.id) ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundStyle(favorites.isFavorite(exercise.id) ? Color.mmDestructive : Color.white)
                            .padding(7)
                            .background(Color.mmBgPrimary.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.localizedName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    muscleTags

                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 10))
                        Text(exercise.localizedDifficulty)
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 部位タグ (主動: 緑、補助: 灰)。最大3部位までドット区切り。
    private var muscleTags: some View {
        let sorted = exercise.muscleMapping.sorted { $0.value > $1.value }
        let topMuscles = Array(sorted.prefix(3))

        return HStack(spacing: 4) {
            ForEach(Array(topMuscles.enumerated()), id: \.offset) { index, entry in
                let (muscleId, percentage) = entry
                if index > 0 {
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmTextSecondary)
                }
                if let muscle = Muscle(rawValue: muscleId) ?? Muscle(snakeCase: muscleId) {
                    Text(muscle.localizedName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(percentage >= 80 ? Color.mmAccentPrimary : Color.mmTextSecondary)
                        .lineLimit(1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 6. 0件空状態

struct LibraryEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 32)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            Text(L10n.noExercisesMatchTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
            Text(L10n.adjustFiltersHint)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 32)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

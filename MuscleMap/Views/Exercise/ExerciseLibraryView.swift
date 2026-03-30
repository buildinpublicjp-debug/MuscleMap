import SwiftUI

// MARK: - 種目辞典画面

struct ExerciseLibraryView: View {
    @State private var viewModel = ExerciseListViewModel()
    @ObservedObject private var favorites = FavoritesManager.shared
    @ObservedObject private var recentManager = RecentExercisesManager.shared
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDefinition?
    @State private var isSearchActive = false
    @AppStorage("exerciseLibraryGridView") private var isGridView = true
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // 検索バー（トグル展開式、固定）
                if isSearchActive {
                    librarySearchBar
                }

                // 全コンテンツをScrollViewに統合
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // ── ヘッダー: マップ左 + フィルター右 ──
                        compactHeader
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // ── 種目グリッド/リスト ──
                        exerciseContent
                            .padding(.top, 4)
                    }
                }
            }
        }
        .navigationTitle(L10n.exerciseLibrary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // グリッド/リスト切替
                Button {
                    isGridView.toggle()
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(L10n.exerciseLibrary)
                    .font(.headline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                // 検索アイコン
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                            viewModel.searchText = ""
                        }
                    }
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .foregroundStyle(isSearchActive ? Color.mmTextSecondary : Color.mmAccentPrimary)
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .onAppear {
            viewModel.load()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    // MARK: - コンパクトヘッダー（マップ左 + フィルター右）

    private var compactHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            // 左: ミニ筋肉マップ（前面+背面）
            CompactLibraryMuscleMap(
                selectedGroup: Binding(
                    get: { viewModel.selectedMuscleGroup },
                    set: { group in
                        viewModel.showRecentOnly = false
                        viewModel.showFavoritesOnly = false
                        viewModel.selectedCategory = nil
                        viewModel.selectedMuscleGroup = group
                    }
                )
            )
            .frame(width: 120, height: 120)

            // 右: フィルターチップ（折り返し表示） + 種目数
            VStack(alignment: .leading, spacing: 8) {
                // 器具フィルター
                LibraryFlowLayout(spacing: 6) {
                    LibraryChip(title: L10n.all, isSelected: viewModel.selectedEquipment == nil) {
                        viewModel.selectedEquipment = nil
                    }
                    ForEach(LibraryEquipmentFilter.allCases) { filter in
                        LibraryChip(title: filter.localizedName, isSelected: viewModel.selectedEquipment == filter.rawValue) {
                            viewModel.selectedEquipment = filter.rawValue
                        }
                    }
                }

                // 部位フィルター
                LibraryFlowLayout(spacing: 6) {
                    LibraryChip(title: "⏱\(L10n.recent)", isSelected: viewModel.showRecentOnly) {
                        viewModel.showRecentOnly.toggle()
                        if viewModel.showRecentOnly {
                            viewModel.showFavoritesOnly = false
                            viewModel.selectedCategory = nil
                            viewModel.selectedMuscleGroup = nil
                        }
                    }
                    LibraryChip(title: "★\(L10n.favorites)", isSelected: viewModel.showFavoritesOnly) {
                        viewModel.showFavoritesOnly.toggle()
                        if viewModel.showFavoritesOnly {
                            viewModel.showRecentOnly = false
                            viewModel.selectedCategory = nil
                            viewModel.selectedMuscleGroup = nil
                        }
                    }
                    ForEach(MuscleGroup.allCases) { group in
                        LibraryChip(
                            title: localization.currentLanguage == .japanese ? group.japaneseName : group.englishName,
                            isSelected: viewModel.selectedMuscleGroup == group
                        ) {
                            viewModel.showRecentOnly = false
                            viewModel.showFavoritesOnly = false
                            viewModel.selectedCategory = nil
                            if viewModel.selectedMuscleGroup == group {
                                viewModel.selectedMuscleGroup = nil
                            } else {
                                viewModel.selectedMuscleGroup = group
                            }
                        }
                    }
                }

                // 種目数
                Text(L10n.exerciseCountLabel(viewModel.filteredExercises.count))
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
    }

    // MARK: - 検索バー

    private var librarySearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.mmTextSecondary)
            TextField(L10n.searchExercises, text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.mmTextPrimary)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.recordSearch(searchText)
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - 種目コンテンツ（ScrollView内）

    @ViewBuilder
    private var exerciseContent: some View {
        if viewModel.showRecentOnly && viewModel.filteredExercises.isEmpty {
            PickerEmptyState(
                icon: "clock.arrow.circlepath",
                title: L10n.noRecentExercises,
                subtitle: L10n.recentExercisesHint
            )
        } else if viewModel.showFavoritesOnly && viewModel.filteredExercises.isEmpty {
            PickerEmptyState(
                icon: "star.slash",
                title: L10n.noFavorites,
                subtitle: L10n.addFavoritesHint
            )
        } else if isGridView {
            // グリッド（ScrollView内LazyVGrid）
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    LibraryGridCard(exercise: exercise) {
                        selectedExercise = exercise
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        } else {
            // リスト（ScrollView内LazyVStack）
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredExercises) { exercise in
                    Button {
                        HapticManager.lightTap()
                        selectedExercise = exercise
                    } label: {
                        ExerciseLibraryRow(exercise: exercise)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - 器具フィルターEnum（固定順序）

@MainActor
enum LibraryEquipmentFilter: String, CaseIterable, Identifiable {
    case dumbbell = "ダンベル"
    case barbell = "バーベル"
    case machine = "マシン"
    case cable = "ケーブル"
    case bodyweight = "自重"

    var id: String { rawValue }

    var localizedName: String {
        L10n.localizedEquipment(rawValue)
    }
}

// MARK: - コンパクト筋肉マップ（タップでフィルタ連動）

struct CompactLibraryMuscleMap: View {
    @Binding var selectedGroup: MuscleGroup?

    var body: some View {
        HStack(spacing: 0) {
            LibraryMiniBodySide(
                muscles: MusclePathData.frontMuscles,
                selectedGroup: $selectedGroup
            )
            LibraryMiniBodySide(
                muscles: MusclePathData.backMuscles,
                selectedGroup: $selectedGroup
            )
        }
    }
}

// MARK: - 前面/背面の片側ビュー

private struct LibraryMiniBodySide: View {
    let muscles: [(muscle: Muscle, path: (CGRect) -> Path)]
    @Binding var selectedGroup: MuscleGroup?
    @State private var rect: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            let r = CGRect(origin: .zero, size: geo.size)
            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let group = entry.muscle.group
                    let isSelected = selectedGroup == group
                    let isOtherSelected = selectedGroup != nil && !isSelected

                    entry.path(r)
                        .fill(muscleColor(isSelected: isSelected, isOtherSelected: isOtherSelected))
                    entry.path(r)
                        .stroke(Color.mmMuscleBorder.opacity(0.4), lineWidth: 0.8)
                }
            }
            .drawingGroup()
            .allowsHitTesting(false)
            .overlay {
                Color.white.opacity(0.001)
                    .onTapGesture { location in
                        handleTap(at: location, in: r)
                    }
            }
            .onAppear { rect = r }
            .onChange(of: geo.size) { _, newSize in
                rect = CGRect(origin: .zero, size: newSize)
            }
        }
        .aspectRatio(0.55, contentMode: .fit)
    }

    private func handleTap(at point: CGPoint, in currentRect: CGRect) {
        let r = currentRect.size != .zero ? currentRect : rect
        guard r.size != .zero else { return }
        for entry in muscles.reversed() {
            let path = entry.path(r)
            if path.contains(point) {
                let tappedGroup = entry.muscle.group
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedGroup == tappedGroup {
                        selectedGroup = nil
                    } else {
                        selectedGroup = tappedGroup
                    }
                }
                HapticManager.lightTap()
                return
            }
        }
    }

    private func muscleColor(isSelected: Bool, isOtherSelected: Bool) -> Color {
        if isSelected {
            return Color.mmAccentPrimary.opacity(0.8)
        } else if isOtherSelected {
            return Color.mmMuscleInactive.opacity(0.4)
        } else {
            return Color.mmMuscleInactive
        }
    }
}

// MARK: - コンパクトフィルターチップ（種目辞典用）

private struct LibraryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.mmAccentPrimary : Color.mmBgCard)
                .foregroundStyle(isSelected ? Color.mmBgPrimary : Color.mmTextSecondary)
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

// MARK: - 折り返しレイアウト（FlowLayout）

private struct LibraryFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: width, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
}

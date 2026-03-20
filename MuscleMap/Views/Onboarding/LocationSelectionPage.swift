import SwiftUI

// MARK: - トレーニング場所

@MainActor
enum TrainingLocation: String, CaseIterable, Codable {
    case gym
    case home
    case both

    var title: String {
        switch self {
        case .gym: return L10n.locationGym
        case .home: return L10n.locationHome
        case .both: return L10n.locationBoth
        }
    }

    var sfSymbol: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .home: return "house.fill"
        case .both: return "arrow.left.arrow.right"
        }
    }

    var subtitle: String {
        switch self {
        case .gym: return L10n.locationGymDesc
        case .home: return L10n.locationHomeDesc
        case .both: return L10n.locationBothDesc
        }
    }

    /// 場所に応じた代表的な器具フィルタ
    var equipmentFilter: [String] {
        switch self {
        case .gym: return ["バーベル", "マシン", "ダンベル", "ケーブル"]
        case .home: return ["ダンベル", "自重"]
        case .both: return ["バーベル", "ダンベル", "自重"]
        }
    }
}

// MARK: - 場所選択画面（GIFギャラリー + 種目数バッジ付き）

struct LocationSelectionPage: View {
    let onNext: (TrainingLocation) -> Void

    @State private var selected: TrainingLocation?
    @State private var appeared = false
    @State private var isProceeding = false
    @State private var scrollOffset: CGFloat = 0
    @State private var autoScrollTimer: Timer?

    /// 選択した場所で使える種目（最大20件、2行グリッド用）
    private var filteredExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        let exercises: [ExerciseDefinition]
        switch selected {
        case .home:
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            exercises = store.exercises.filter { homeEquipment.contains($0.equipment) }
        case .gym, .both, .none:
            exercises = store.exercises
        }
        return Array(exercises.prefix(20))
    }

    /// 2行グリッド用カラムデータ（上下ペア）
    private var gridColumns: [(Int, (ExerciseDefinition, ExerciseDefinition?))] {
        let items = filteredExercises
        var columns: [(Int, (ExerciseDefinition, ExerciseDefinition?))] = []
        let rowCount = 2
        let colCount = (items.count + rowCount - 1) / rowCount
        for col in 0..<colCount {
            let topIndex = col
            let bottomIndex = col + colCount
            let top = items[topIndex]
            let bottom = bottomIndex < items.count ? items[bottomIndex] : nil
            columns.append((col, (top, bottom)))
        }
        return columns
    }

    /// フィルタ後の全種目数（バッジ表示用）
    private var totalFilteredCount: Int {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        switch selected {
        case .home:
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            return store.exercises.filter { homeEquipment.contains($0.equipment) }.count
        case .gym, .both, .none:
            return store.exercises.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text(L10n.locationTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.locationSubtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 12)

            // 種目数バッジ
            HStack(spacing: 8) {
                Text(L10n.exerciseCountLabel(totalFilteredCount))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingAccent)

                if selected == .home {
                    Text(L10n.locationHomeExercises)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                } else {
                    Text(L10n.locationExerciseCount)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 12)

            // GIFギャラリー（2行グリッド、マーキー自動スクロール）
            GeometryReader { geo in
                let columnWidth: CGFloat = 130 // カード幅120 + spacing10
                let contentWidth = CGFloat(gridColumns.count) * columnWidth + 48 // padding分
                HStack(alignment: .top, spacing: 10) {
                    ForEach(gridColumns, id: \.0) { _, pair in
                        VStack(spacing: 10) {
                            ExerciseGifCard(exercise: pair.0)
                            if let second = pair.1 {
                                ExerciseGifCard(exercise: second)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .offset(x: scrollOffset)
                .onChange(of: scrollOffset) {
                    // ループ: コンテンツが画面外に出たらリセット
                    let resetPoint = -(contentWidth - geo.size.width)
                    if scrollOffset < resetPoint {
                        scrollOffset = 0
                    }
                }
            }
            .clipped()
            .opacity(appeared ? 1 : 0)

            Spacer()

            // 選択カード（次へボタン直上、コンパクト）
            VStack(spacing: 6) {
                ForEach(Array(TrainingLocation.allCases.enumerated()), id: \.element) { index, location in
                    LocationCard(
                        location: location,
                        isSelected: selected == location,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selected = location
                            }
                            // マーキーをリセット＆再開
                            restartAutoScroll()
                            HapticManager.lightTap()
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.3), value: appeared)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // 次へボタン
            Button {
                guard !isProceeding, let loc = selected else { return }
                isProceeding = true
                stopAutoScroll()
                HapticManager.lightTap()
                onNext(loc)
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selected != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if selected != nil {
                                LinearGradient(
                                    colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.mmOnboardingCard
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selected == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .onAppear {
            isProceeding = false  // スワイプ戻り時にボタンを有効化
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            startAutoScroll()
        }
        .onDisappear {
            stopAutoScroll()
        }
    }

    // MARK: - マーキー自動スクロール

    private func startAutoScroll() {
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            Task { @MainActor in
                scrollOffset -= 0.5
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func restartAutoScroll() {
        scrollOffset = 0
        startAutoScroll()
    }
}

// MARK: - GIFカード（ギャラリー用）

private struct ExerciseGifCard: View {
    let exercise: ExerciseDefinition

    var body: some View {
        VStack(spacing: 6) {
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.mmOnboardingBg)
                        .frame(width: 100, height: 100)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                }
            }

            Text(exercise.localizedName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(exercise.localizedEquipment)
                .font(.system(size: 9))
                .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .frame(width: 120)
    }
}

// MARK: - 場所カード（左バー方式）

private struct LocationCard: View {
    let location: TrainingLocation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 8)

                HStack(spacing: 10) {
                    // SFシンボルアイコン
                    Image(systemName: location.sfSymbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 28, height: 28)

                    // テキスト（1行）
                    Text(location.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 22, height: 22)

                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 48)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        LocationSelectionPage(onNext: { _ in })
    }
}

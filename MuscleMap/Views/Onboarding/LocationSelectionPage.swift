import SwiftUI

// MARK: - トレーニング場所

@MainActor
enum TrainingLocation: String, CaseIterable, Codable {
    case gym
    case home
    case bodyweight
    case both

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var title: String {
        switch self {
        case .gym: return isJapanese ? "ジム" : "Gym"
        case .home: return isJapanese ? "自宅" : "Home"
        case .bodyweight: return isJapanese ? "自重のみ" : "Bodyweight Only"
        case .both: return isJapanese ? "両方" : "Both"
        }
    }

    var sfSymbol: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .home: return "house.fill"
        case .bodyweight: return "figure.walk"
        case .both: return "arrow.left.arrow.right"
        }
    }

    var subtitle: String {
        switch self {
        case .gym: return isJapanese ? "マシン・バーベル・ダンベル全部" : "Full equipment access"
        case .home: return isJapanese ? "ダンベルと自重で鍛える" : "Dumbbells & bodyweight"
        case .bodyweight: return isJapanese ? "器具なし、体ひとつで" : "No equipment needed"
        case .both: return isJapanese ? "ジムと自宅を組み合わせ" : "Mix gym and home"
        }
    }

    /// 場所に応じた代表的な器具フィルタ
    var equipmentFilter: [String] {
        switch self {
        case .gym: return isJapanese ? ["バーベル", "マシン", "ダンベル", "ケーブル"] : ["Barbell", "Machine", "Dumbbell", "Cable"]
        case .home: return isJapanese ? ["ダンベル", "自重"] : ["Dumbbell", "Bodyweight"]
        case .bodyweight: return isJapanese ? ["自重"] : ["Bodyweight"]
        case .both: return isJapanese ? ["バーベル", "ダンベル", "自重"] : ["Barbell", "Dumbbell", "Bodyweight"]
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
    @State private var selectedExercise: ExerciseDefinition?

    /// 選択した場所で使える種目（最大20件、2行グリッド用）
    private var filteredExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        let exercises: [ExerciseDefinition]
        switch selected {
        case .bodyweight:
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            exercises = store.exercises.filter { bwEquipment.contains($0.equipment) }
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
        case .bodyweight:
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            return store.exercises.filter { bwEquipment.contains($0.equipment) }.count
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

                if selected == .home || selected == .bodyweight {
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
                let columnWidth: CGFloat = 148 // カード幅140 + spacing8
                let contentWidth = CGFloat(gridColumns.count) * columnWidth + 48 // padding分
                HStack(alignment: .top, spacing: 8) {
                    ForEach(gridColumns, id: \.0) { _, pair in
                        VStack(spacing: 8) {
                            ExerciseGifCard(exercise: pair.0) {
                                selectedExercise = pair.0
                                HapticManager.lightTap()
                            }
                            if let second = pair.1 {
                                ExerciseGifCard(exercise: second) {
                                    selectedExercise = second
                                    HapticManager.lightTap()
                                }
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

            Spacer(minLength: 8)

            // 選択カード（次へボタン直上、コンパクト）
            VStack(spacing: 5) {
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
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.mmOnboardingBg)
                            .frame(width: 130, height: 130)
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                    }
                }

                Text(exercise.localizedName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(exercise.localizedEquipment)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .frame(width: 140, height: 180)
        }
        .buttonStyle(.plain)
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
                    .padding(.vertical, 6)

                HStack(spacing: 10) {
                    // SFシンボルアイコン
                    Image(systemName: location.sfSymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 24, height: 24)

                    // テキスト（1行）
                    Text(location.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 42)
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

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
    @State private var selectedExercise: ExerciseDefinition?
    @State private var scrollTimer: Timer?
    @State private var autoScrollTarget: Int = 0

    /// 器具が必要な「自重」種目を除外するID判定
    private static let bodyweightExcludeIds: Set<String> = [
        "dips", "chin_up", "pull_up", "muscle_up", "tricep_dip"
    ]

    /// ジムの種目リストから除外するID
    private static let gymExcludeIds: Set<String> = [
        "burpee"
    ]

    /// GIFカードサイズ
    private let cardSize: CGFloat = 160

    private func isTrueBodyweight(_ exercise: ExerciseDefinition) -> Bool {
        let id = exercise.id.lowercased()
        return !Self.bodyweightExcludeIds.contains(where: { id.contains($0) })
    }

    /// 選択した場所で使える種目（最大20件）
    private var filteredExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        let exercises: [ExerciseDefinition]
        switch selected {
        case .bodyweight:
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            exercises = store.exercises.filter { bwEquipment.contains($0.equipment) && isTrueBodyweight($0) }
        case .home:
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            exercises = store.exercises.filter { homeEquipment.contains($0.equipment) }
        case .gym, .both, .none:
            exercises = store.exercises.filter { !Self.gymExcludeIds.contains($0.id) }
        }
        return Array(exercises.prefix(20))
    }

    /// 上段の種目
    private var topRowExercises: [ExerciseDefinition] {
        let items = filteredExercises
        let mid = (items.count + 1) / 2
        return Array(items.prefix(mid))
    }

    /// 下段の種目
    private var bottomRowExercises: [ExerciseDefinition] {
        let items = filteredExercises
        let mid = (items.count + 1) / 2
        return Array(items.dropFirst(mid))
    }

    /// フィルタ後の全種目数（バッジ表示用）
    private var totalFilteredCount: Int {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        switch selected {
        case .bodyweight:
            let bwEquipment: Set<String> = ["自重", "Bodyweight"]
            return store.exercises.filter { bwEquipment.contains($0.equipment) && isTrueBodyweight($0) }.count
        case .home:
            let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
            return store.exercises.filter { homeEquipment.contains($0.equipment) }.count
        case .gym, .both, .none:
            return store.exercises.filter { !Self.gymExcludeIds.contains($0.id) }.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            // ヘッダー
            VStack(spacing: 4) {
                Text(L10n.locationTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.locationSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 4)

            // 種目数バッジ
            HStack(spacing: 6) {
                Text(L10n.exerciseCountLabel(totalFilteredCount))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingAccent)

                if selected == .home || selected == .bodyweight {
                    Text(L10n.locationHomeExercises)
                        .font(.caption2)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                } else {
                    Text(L10n.locationExerciseCount)
                        .font(.caption2)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 4)

            // GIFギャラリー（2行、慣性スクロール + 自動スクロール）
            gifGallery
                .opacity(appeared ? 1 : 0)

            Spacer(minLength: 2)

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
                stopScrollTimer()
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
            isProceeding = false
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .onDisappear {
            stopScrollTimer()
        }
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - GIFギャラリー（ScrollView慣性スクロール + 自動スクロール）

    private var gifGallery: some View {
        VStack(spacing: 6) {
            // 上段
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(topRowExercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseGifCard(exercise: exercise, cardSize: cardSize) {
                                selectedExercise = exercise
                                HapticManager.lightTap()
                            }
                            .id("top-\(index)")
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onAppear {
                    startAutoScroll(proxy: proxy, row: "top", count: topRowExercises.count)
                }
            }
            .frame(height: cardSize)

            // 下段
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(bottomRowExercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseGifCard(exercise: exercise, cardSize: cardSize) {
                                selectedExercise = exercise
                                HapticManager.lightTap()
                            }
                            .id("bottom-\(index)")
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onAppear {
                    startAutoScroll(proxy: proxy, row: "bottom", count: bottomRowExercises.count)
                }
            }
            .frame(height: cardSize)
        }
        .onChange(of: selected) {
            stopScrollTimer()
            autoScrollTarget = 0
        }
    }

    // MARK: - 自動スクロール（ゆっくり1枚ずつ進む）

    private func startAutoScroll(proxy: ScrollViewProxy, row: String, count: Int) {
        guard count > 2 else { return }

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            Task { @MainActor in
                autoScrollTarget += 1
                let target = autoScrollTarget % count
                withAnimation(.easeInOut(duration: 0.8)) {
                    proxy.scrollTo("\(row)-\(target)", anchor: .leading)
                }
            }
        }
    }

    private func stopScrollTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
}

// MARK: - GIFカード（ギャラリー用、名前オーバーレイ付き）

private struct ExerciseGifCard: View {
    let exercise: ExerciseDefinition
    let cardSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                        .frame(width: cardSize, height: cardSize)
                } else {
                    ZStack {
                        Color.mmOnboardingBg
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                    }
                    .frame(width: cardSize, height: cardSize)
                }

                // 名前オーバーレイ（下部グラデーション上）
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: cardSize * 0.35)

                Text(exercise.localizedName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
            }
            .frame(width: cardSize, height: cardSize)
            .clipShape(RoundedRectangle(cornerRadius: 14))
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

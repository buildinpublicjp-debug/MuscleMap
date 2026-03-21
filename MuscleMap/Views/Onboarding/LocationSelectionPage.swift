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

    var equipmentFilter: [String] {
        switch self {
        case .gym: return isJapanese ? ["バーベル", "マシン", "ダンベル", "ケーブル"] : ["Barbell", "Machine", "Dumbbell", "Cable"]
        case .home: return isJapanese ? ["ダンベル", "自重"] : ["Dumbbell", "Bodyweight"]
        case .bodyweight: return isJapanese ? ["自重"] : ["Bodyweight"]
        case .both: return isJapanese ? ["バーベル", "ダンベル", "自重"] : ["Barbell", "Dumbbell", "Bodyweight"]
        }
    }
}

// MARK: - 場所選択画面

struct LocationSelectionPage: View {
    let onNext: (TrainingLocation) -> Void

    @State private var selected: TrainingLocation?
    @State private var appeared = false
    @State private var isProceeding = false
    @State private var selectedExercise: ExerciseDefinition?

    private static let bodyweightExcludeIds: Set<String> = [
        "dips", "chin_up", "pull_up", "muscle_up", "tricep_dip"
    ]
    private static let gymExcludeIds: Set<String> = ["burpee"]

    private let cardSize: CGFloat = 140

    private func isTrueBodyweight(_ exercise: ExerciseDefinition) -> Bool {
        let id = exercise.id.lowercased()
        return !Self.bodyweightExcludeIds.contains(where: { id.contains($0) })
    }

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
        return Array(exercises.prefix(12))
    }

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
            Spacer().frame(height: 16)

            // ヘッダー
            VStack(spacing: 4) {
                Text(L10n.locationTitle)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.locationSubtitle)
                    .font(.system(size: 13))
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

            // GIFギャラリー（1行マーキー — GeometryReaderで幅制約）
            GeometryReader { geo in
                SingleRowMarqueeContent(
                    exercises: filteredExercises,
                    cardSize: cardSize,
                    speed: 30,
                    containerWidth: geo.size.width,
                    onTap: { exercise in
                        selectedExercise = exercise
                        HapticManager.lightTap()
                    }
                )
            }
            .frame(height: cardSize)
            .clipped()
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 12)

            // 選択カード
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

            Spacer(minLength: 8)

            // 次へボタン
            Button {
                guard !isProceeding, let loc = selected else { return }
                isProceeding = true
                HapticManager.mediumTap()
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
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - マーキーコンテンツ（GeometryReader内で使用、幅制約済み）

private struct SingleRowMarqueeContent: View {
    let exercises: [ExerciseDefinition]
    let cardSize: CGFloat
    let speed: Double
    let containerWidth: CGFloat
    let onTap: (ExerciseDefinition) -> Void

    private let spacing: CGFloat = 8

    private var setWidth: CGFloat {
        let count = max(exercises.count, 1)
        return CGFloat(count) * (cardSize + spacing)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let totalWidth = setWidth
            let offset: CGFloat = totalWidth > 0
                ? -CGFloat(elapsed.truncatingRemainder(dividingBy: Double(totalWidth) / speed) * speed)
                : 0

            HStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { _ in
                    ForEach(exercises, id: \.id) { exercise in
                        ExerciseGifCard(exercise: exercise, cardSize: cardSize) {
                            onTap(exercise)
                        }
                    }
                }
            }
            .offset(x: offset)
        }
        .frame(width: containerWidth, alignment: .leading)
    }
}

// MARK: - GIFカード

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
                            .font(.system(size: 24))
                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                    }
                    .frame(width: cardSize, height: cardSize)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: cardSize * 0.4)

                Text(exercise.localizedName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .frame(width: cardSize, height: cardSize)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 場所カード

private struct LocationCard: View {
    let location: TrainingLocation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 6)

                HStack(spacing: 10) {
                    Image(systemName: location.sfSymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 24, height: 24)

                    Text(location.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Spacer()

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

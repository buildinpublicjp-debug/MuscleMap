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
        case .gym: return L10n.locGym
        case .home: return L10n.locHome
        case .bodyweight: return L10n.locBodyweight
        case .both: return L10n.locBoth
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
        case .gym: return L10n.locGymSub
        case .home: return L10n.locHomeSub
        case .bodyweight: return L10n.locBodyweightSub
        case .both: return L10n.locBothSub
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
    var currentPage: Int = 0

    @State private var selected: TrainingLocation?
    @State private var appeared = false
    @State private var isProceeding = false
    @State private var selectedExercise: ExerciseDefinition?

    private static let bodyweightExcludeIds: Set<String> = [
        "dips", "chin_up", "pull_up", "muscle_up", "tricep_dip"
    ]
    private static let gymExcludeIds: Set<String> = ["burpee"]

    private func isTrueBodyweight(_ exercise: ExerciseDefinition) -> Bool {
        let id = exercise.id.lowercased()
        return !Self.bodyweightExcludeIds.contains(where: { id.contains($0) })
    }

    /// マーキー用: 選択に連動（切り替え時のアニメーションリセットは許容）
    private var filteredExercisesForMarquee: [ExerciseDefinition] {
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
        return Array(exercises.filter { ExerciseGifView.hasGif(exerciseId: $0.id) }.prefix(20))
    }

    private var topRowExercises: [ExerciseDefinition] {
        let items = filteredExercisesForMarquee
        let mid = (items.count + 1) / 2
        return Array(items.prefix(mid))
    }

    private var bottomRowExercises: [ExerciseDefinition] {
        let items = filteredExercisesForMarquee
        let mid = (items.count + 1) / 2
        return Array(items.dropFirst(mid))
    }

    /// バッジ用: 選択に連動
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
        GeometryReader { geo in
            let h = geo.size.height
            let cardSize = min(max(h * 0.20, 130), 200)
            let selectionCardHeight = min(max(h * 0.07, 48), 72)

            VStack(spacing: 0) {
                Spacer().frame(height: 8)

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

                HStack(spacing: 6) {
                    Text(L10n.exerciseCountLabel(totalFilteredCount))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: totalFilteredCount)

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

                // 2行マーキー（選択連動: 種目が切り替わる、アニメーションリセットOK）
                VStack(spacing: 6) {
                    LocationMarqueeRow(exercises: topRowExercises, cardSize: cardSize, speed: 25, reversed: false) { exercise in
                        selectedExercise = exercise
                        HapticManager.lightTap()
                    }
                    .id("top-\(selected?.rawValue ?? "none")")
                    LocationMarqueeRow(exercises: bottomRowExercises, cardSize: cardSize, speed: 20, reversed: false) { exercise in
                        selectedExercise = exercise
                        HapticManager.lightTap()
                    }
                    .id("bottom-\(selected?.rawValue ?? "none")")
                }
                .frame(height: cardSize * 2 + 6)
                .clipped()
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 14)

                VStack(spacing: 7) {
                    ForEach(Array(TrainingLocation.allCases.enumerated()), id: \.element) { index, location in
                        LocationCard(
                            location: location,
                            isSelected: selected == location,
                            cardHeight: selectionCardHeight,
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

                Spacer().frame(height: 16)

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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selected == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .animation(.easeInOut(duration: 0.2), value: selected)
            }
        }
        .onChange(of: currentPage) {
            isProceeding = false
        }
        .onAppear {
            isProceeding = false
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - マーキー行

private struct LocationMarqueeRow: View {
    let exercises: [ExerciseDefinition]
    let cardSize: CGFloat
    let speed: CGFloat
    let reversed: Bool
    let onTap: (ExerciseDefinition) -> Void

    @State private var offset: CGFloat = 0

    private var setWidth: CGFloat {
        CGFloat(exercises.count) * (cardSize + 8)
    }

    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { batch in
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        Button {
                            onTap(exercise)
                        } label: {
                            ZStack(alignment: .bottom) {
                                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                                        .scaledToFill()
                                        .frame(width: cardSize, height: cardSize)
                                        .clipped()
                                } else {
                                    ZStack {
                                        Color.mmOnboardingBg
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                                    }
                                    .frame(width: cardSize, height: cardSize)
                                }

                                Text(exercise.localizedName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.bottom, 6)
                                    .padding(.top, 22)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            colors: [.clear, Color.black.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .frame(width: cardSize, height: cardSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id("\(batch)-\(index)")
                    }
                }
            }
            .offset(x: offset)
            .onAppear {
                guard setWidth > 0 else { return }
                offset = reversed ? -setWidth : 0
                let duration = setWidth / speed
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = reversed ? 0 : -setWidth
                }
            }
        }
        .frame(height: cardSize)
        .clipped()
    }
}

// MARK: - 場所カード

private struct LocationCard: View {
    let location: TrainingLocation
    let isSelected: Bool
    var cardHeight: CGFloat = 66
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
            .frame(height: cardHeight)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
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

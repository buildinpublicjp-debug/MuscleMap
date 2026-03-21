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

    private let cardSize: CGFloat = 120

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
        return Array(exercises.prefix(20))
    }

    private var topRowExercises: [ExerciseDefinition] {
        let items = filteredExercises
        let mid = (items.count + 1) / 2
        return Array(items.prefix(mid))
    }

    private var bottomRowExercises: [ExerciseDefinition] {
        let items = filteredExercises
        let mid = (items.count + 1) / 2
        return Array(items.dropFirst(mid))
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

            // 2行マーキーGIF（PaywallViewと同じ方式 — GeometryReader + withAnimation）
            VStack(spacing: 6) {
                LocationMarqueeRow(exercises: topRowExercises, cardSize: cardSize, speed: 25, reversed: false) { exercise in
                    selectedExercise = exercise
                    HapticManager.lightTap()
                }
                LocationMarqueeRow(exercises: bottomRowExercises, cardSize: cardSize, speed: 20, reversed: true) { exercise in
                    selectedExercise = exercise
                    HapticManager.lightTap()
                }
            }
            .frame(height: cardSize * 2 + 6)
            .clipped()
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 10)

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

// MARK: - マーキー行（PaywallMarqueeRowと同じ方式）

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
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.bottom, 4)
                                    .padding(.top, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            colors: [.clear, Color.black.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .frame(width: cardSize, height: cardSize)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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

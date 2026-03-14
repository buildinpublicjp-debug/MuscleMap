import SwiftUI
import SwiftData

// MARK: - 直近トレーニング入力画面（家トレ勢向け初期設定）

struct RecentTrainingInputPage: View {
    let onNext: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var selectedMuscles: Set<Muscle> = []
    @State private var showingFront = true
    @State private var selectedTiming: TrainingTiming = .today
    @State private var appeared = false
    @State private var isProceeding = false

    /// タップ筋肉 → ビジュアル状態マップ
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if selectedMuscles.contains(muscle) {
                states[muscle] = .recovering(progress: 0.15)
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let headerHeight: CGFloat = 80
            let groupButtonHeight: CGFloat = 64
            let timingHeight: CGFloat = 56
            let bottomHeight: CGFloat = 120
            let mapHeight = geometry.size.height - headerHeight - groupButtonHeight - timingHeight - bottomHeight - safeArea.top

            VStack(spacing: 0) {
                // タイトルエリア
                VStack(spacing: 4) {
                    Text(L10n.recentTrainingTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .multilineTextAlignment(.center)

                    Text(L10n.recentTrainingSub)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)

                // 前面/背面トグル
                HStack(spacing: 0) {
                    RecentToggleButton(
                        title: L10n.front,
                        isSelected: showingFront
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFront = true
                        }
                        HapticManager.lightTap()
                    }

                    RecentToggleButton(
                        title: L10n.back,
                        isSelected: !showingFront
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFront = false
                        }
                        HapticManager.lightTap()
                    }
                }
                .padding(3)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .opacity(appeared ? 1 : 0)

                // 筋肉マップ（前面/背面スワイプ）
                TabView(selection: $showingFront) {
                    RecentDemoMapView(
                        muscleStates: muscleStates,
                        showFront: true,
                        onMuscleTapped: handleMuscleTap
                    )
                    .tag(true)

                    RecentDemoMapView(
                        muscleStates: muscleStates,
                        showFront: false,
                        onMuscleTapped: handleMuscleTap
                    )
                    .tag(false)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: max(mapHeight, 260))
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.95)

                // 部位グループボタン
                HStack(spacing: 8) {
                    ForEach(MuscleGroupButton.allGroups, id: \.group) { item in
                        let isActive = isMuscleGroupSelected(item.group)
                        Button {
                            toggleMuscleGroup(item.group)
                        } label: {
                            Text(item.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isActive ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(isActive ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: groupButtonHeight)
                .opacity(appeared ? 1 : 0)

                // 「いつ鍛えた？」セグメント
                HStack(spacing: 0) {
                    ForEach(TrainingTiming.allCases, id: \.self) { timing in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTiming = timing
                            }
                            HapticManager.lightTap()
                        } label: {
                            Text(timing.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(
                                    selectedTiming == timing
                                        ? Color.mmOnboardingBg
                                        : Color.mmOnboardingTextSub
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    selectedTiming == timing
                                        ? Color.mmOnboardingAccent
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .opacity(selectedMuscles.isEmpty ? 0.4 : 1.0)
                .disabled(selectedMuscles.isEmpty)

                Spacer()

                // 未選択時テキスト / 次へボタン
                if selectedMuscles.isEmpty {
                    Text(L10n.recentTrainingEmpty)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .padding(.bottom, 8)
                }

                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    HapticManager.lightTap()
                    saveRecentTraining()
                    onNext()
                } label: {
                    Text(L10n.next)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingBg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mmOnboardingAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - 筋肉タップ処理

    private func handleMuscleTap(_ muscle: Muscle) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if selectedMuscles.contains(muscle) {
                selectedMuscles.remove(muscle)
            } else {
                selectedMuscles.insert(muscle)
            }
        }
        HapticManager.lightTap()
    }

    // MARK: - グループ一括トグル

    private func isMuscleGroupSelected(_ group: MuscleGroup) -> Bool {
        let muscles = group.muscles
        return muscles.allSatisfy { selectedMuscles.contains($0) }
    }

    private func toggleMuscleGroup(_ group: MuscleGroup) {
        let muscles = group.muscles
        withAnimation(.easeInOut(duration: 0.25)) {
            if muscles.allSatisfy({ selectedMuscles.contains($0) }) {
                // 全選択済み → 全解除
                muscles.forEach { selectedMuscles.remove($0) }
            } else {
                // 未選択あり → 全選択
                muscles.forEach { selectedMuscles.insert($0) }
            }
        }
        HapticManager.mediumTap()
    }

    // MARK: - データ保存

    /// 選択した筋肉をMuscleStimulationとして保存（ホーム画面で回復表示に反映）
    private func saveRecentTraining() {
        guard !selectedMuscles.isEmpty else { return }

        let stimulationDate = selectedTiming.stimulationDate
        let onboardingSessionId = UUID()

        for muscle in selectedMuscles {
            let stim = MuscleStimulation(
                muscle: muscle.rawValue,
                stimulationDate: stimulationDate,
                maxIntensity: 0.8,
                totalSets: 3,
                sessionId: onboardingSessionId
            )
            modelContext.insert(stim)
        }

        try? modelContext.save()
    }
}

// MARK: - トレーニング時期

@MainActor
private enum TrainingTiming: CaseIterable {
    case today
    case yesterday
    case twoDaysAgo

    var label: String {
        switch self {
        case .today: return L10n.recentTimingToday
        case .yesterday: return L10n.recentTimingYesterday
        case .twoDaysAgo: return L10n.recentTimingTwoDaysAgo
        }
    }

    var stimulationDate: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .today:
            return calendar.date(byAdding: .hour, value: -4, to: now) ?? now
        case .yesterday:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .twoDaysAgo:
            return calendar.date(byAdding: .day, value: -2, to: now) ?? now
        }
    }
}

// MARK: - 部位グループボタン定義

private struct MuscleGroupButton {
    let group: MuscleGroup
    let label: String

    static let allGroups: [MuscleGroupButton] = [
        .init(group: .chest, label: "胸"),
        .init(group: .back, label: "背中"),
        .init(group: .lowerBody, label: "脚"),
        .init(group: .shoulders, label: "肩"),
        .init(group: .arms, label: "腕"),
        .init(group: .core, label: "腹"),
    ]
}

// MARK: - トグルボタン

private struct RecentToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption)

                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.mmOnboardingAccent : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - デモ用筋肉マップ

private struct RecentDemoMapView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let showFront: Bool
    let onMuscleTapped: (Muscle) -> Void

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let muscles = showFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let state = muscleStates[entry.muscle] ?? .inactive
                    let isActive = state != .inactive

                    entry.path(rect)
                        .fill(state.color)
                        .overlay {
                            entry.path(rect)
                                .stroke(
                                    isActive ? Color.mmMuscleActiveBorder.opacity(0.8) : Color.mmOnboardingTextSub.opacity(0.3),
                                    lineWidth: isActive ? 1.5 : 0.5
                                )
                        }
                        .shadow(
                            color: isActive ? state.color.opacity(0.5) : .clear,
                            radius: isActive ? 8 : 0
                        )
                        .onTapGesture {
                            onMuscleTapped(entry.muscle)
                        }
                }
            }
        }
        .aspectRatio(0.5, contentMode: .fit)
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        RecentTrainingInputPage(onNext: {})
    }
}

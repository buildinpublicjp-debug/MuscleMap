import SwiftUI

// MARK: - トレーニング場所

enum TrainingLocation: String, CaseIterable, Codable {
    case gym
    case home
    case both

    var title: String {
        switch self {
        case .gym: return "ジム"
        case .home: return "自宅"
        case .both: return "両方"
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
        case .gym: return "マシン・バーベル・ダンベル全部使える"
        case .home: return "自重とダンベルでしっかり鍛える"
        case .both: return "ジムと自宅を組み合わせる"
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

// MARK: - 場所選択画面（SF Symbols + 種目サンプル付き）

struct LocationSelectionPage: View {
    let onNext: (TrainingLocation) -> Void

    @State private var selected: TrainingLocation?
    @State private var appeared = false
    @State private var isProceeding = false
    @State private var sampleAppeared = false

    /// 選択した場所で使える種目サンプル（最大3件）
    private var sampleExercises: [ExerciseDefinition] {
        guard let location = selected else { return [] }
        ExerciseStore.shared.loadIfNeeded()
        let equipments = location.equipmentFilter
        let filtered = ExerciseStore.shared.exercises
            .filter { ex in equipments.contains(where: { ex.equipment.contains($0) }) }
        return Array(filtered.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text("どこで鍛える？")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text("使える器具に合わせて種目を提案します")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 32)

            // 選択カード（左バー方式）
            VStack(spacing: 10) {
                ForEach(Array(TrainingLocation.allCases.enumerated()), id: \.element) { index, location in
                    LocationCard(
                        location: location,
                        isSelected: selected == location,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selected = location
                            }
                            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                                sampleAppeared = true
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

            // 種目サンプル表示（選択時にフェードイン）
            if selected != nil, !sampleExercises.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("使える種目の例")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .padding(.horizontal, 24)

                    VStack(spacing: 4) {
                        ForEach(sampleExercises, id: \.id) { exercise in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.mmOnboardingAccent)

                                Text(exercise.nameJA)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.mmOnboardingTextMain)
                                    .lineLimit(1)

                                Spacer()

                                Text(exercise.localizedEquipment)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.mmOnboardingTextSub)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeOut(duration: 0.4), value: selected)
            }

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding, let loc = selected else { return }
                isProceeding = true
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
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
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
                    .padding(.vertical, 12)

                HStack(spacing: 12) {
                    // SFシンボルアイコン
                    Image(systemName: location.sfSymbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 36, height: 36)

                    // テキスト
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingTextMain)

                        Text(location.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 60)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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

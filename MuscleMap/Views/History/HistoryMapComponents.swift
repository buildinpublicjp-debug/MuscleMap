import SwiftUI

// MARK: - マップ表示

struct HistoryMapView: View {
    let viewModel: HistoryViewModel
    let onMuscleTap: (Muscle) -> Void
    @State private var showFront = true
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 16) {
            // 期間セレクター
            PeriodSelector(
                selectedPeriod: viewModel.selectedPeriod,
                onPeriodChanged: { period in
                    viewModel.updatePeriod(period)
                }
            )

            // 筋肉マップカード
            VStack(spacing: 16) {
                // 前面/背面トグル（改善版）
                HStack {
                    // 現在の表示面
                    HStack(spacing: 6) {
                        Image(systemName: showFront ? "person.fill" : "person.fill")
                            .font(.caption)
                        Text(showFront ? L10n.front : L10n.back)
                        .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color.mmTextPrimary)

                    Spacer()

                    // トグルボタン
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showFront.toggle()
                        }
                        HapticManager.lightTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption.weight(.medium))
                            Text(showFront ? L10n.viewBack : L10n.viewFront)
                            .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.mmAccentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mmAccentPrimary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                // 筋肉マップ（ホーム画面と同じ表示品質を維持）
                HistoryMuscleMapCanvas(
                    muscleSets: viewModel.periodMuscleSets,
                    showFront: showFront,
                    onMuscleTap: { muscle in
                        onMuscleTap(muscle)
                    }
                )
                .frame(maxHeight: 380)

                // 凡例
                HistoryMapLegend()
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer(minLength: 0)
        }
        .padding()
    }
}

// MARK: - 期間セレクター（改善版）

struct PeriodSelector: View {
    let selectedPeriod: HistoryPeriod
    let onPeriodChanged: (HistoryPeriod) -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(HistoryPeriod.allCases, id: \.self) { period in
                Button {
                    onPeriodChanged(period)
                    HapticManager.lightTap()
                } label: {
                    Text(localization.currentLanguage == .japanese ? period.rawValue : period.englishName)
                        .font(.subheadline.weight(selectedPeriod == period ? .bold : .medium))
                        .foregroundStyle(selectedPeriod == period ? Color.mmBgPrimary : Color.mmTextPrimary.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedPeriod == period {
                                    LinearGradient(
                                        colors: [Color.mmAccentPrimary, Color.mmAccentPrimary.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                } else {
                                    Color.mmBgSecondary.opacity(0.6)
                                }
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedPeriod == period ? Color.clear : Color.mmTextSecondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                }
            }
            Spacer()
        }
    }
}

// MARK: - 履歴筋肉マップキャンバス

struct HistoryMuscleMapCanvas: View {
    let muscleSets: [Muscle: Int]
    let showFront: Bool
    let onMuscleTap: (Muscle) -> Void

    private var maxSets: Int {
        max(1, muscleSets.values.max() ?? 1)
    }

    var body: some View {
        let muscles = showFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let sets = muscleSets[entry.muscle] ?? 0
                    let fillColor = colorForSets(sets)

                    HistoryMusclePathView(
                        path: entry.path(rect),
                        fillColor: fillColor,
                        muscle: entry.muscle
                    ) {
                        onMuscleTap(entry.muscle)
                    }
                }
            }
        }
        .aspectRatio(0.6, contentMode: .fit)
    }

    private func colorForSets(_ sets: Int) -> Color {
        guard sets > 0 else {
            return Color.mmTextSecondary.opacity(0.1)
        }

        let ratio = Double(sets) / Double(maxSets)

        // セット数に応じたグラデーション
        if ratio < 0.25 {
            return Color.mmMuscleLime.opacity(0.4)
        } else if ratio < 0.5 {
            return Color.mmMuscleLime.opacity(0.6)
        } else if ratio < 0.75 {
            return Color.mmAccentPrimary.opacity(0.7)
        } else {
            return Color.mmAccentPrimary
        }
    }
}

// MARK: - 履歴用筋肉パスビュー（タップ対応）

struct HistoryMusclePathView: View {
    let path: Path
    let fillColor: Color
    let muscle: Muscle
    let onTap: () -> Void

    @State private var isTapped = false

    var body: some View {
        path
            .fill(fillColor)
            .overlay {
                path.stroke(Color.mmMuscleBorder.opacity(0.3), lineWidth: 0.5)
            }
            .scaleEffect(isTapped ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isTapped)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isTapped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = false
                    }
                }
                HapticManager.lightTap()
                onTap()
            }
    }
}


// MARK: - 履歴マップ凡例（改善版）

struct HistoryMapLegend: View {
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(spacing: 8) {
            // グラデーションバー
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.mmTextSecondary.opacity(0.15))
                    .frame(width: 40)
                LinearGradient(
                    colors: [
                        Color.mmMuscleLime.opacity(0.4),
                        Color.mmMuscleLime.opacity(0.6),
                        Color.mmAccentPrimary.opacity(0.7),
                        Color.mmAccentPrimary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // ラベル
            HStack {
                Text(localization.currentLanguage == .japanese ? "未トレ" : "None")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(localization.currentLanguage == .japanese ? "少" : "Low")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(localization.currentLanguage == .japanese ? "中" : "Mid")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(localization.currentLanguage == .japanese ? "多" : "High")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .padding(.top, 12)
    }
}

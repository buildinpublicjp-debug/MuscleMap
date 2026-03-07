import SwiftUI
import SwiftData

// MARK: - Strength Map View（Pro限定）

struct StrengthMapView: View {
    let muscleScores: [String: Double]

    @State private var showingFront = true
    @State private var shareImage: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            // ヘッダー: タイトル + 前後切替 + シェアボタン
            HStack {
                Text(showingFront ? L10n.front : L10n.back)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()

                // シェアボタン
                if let image = shareImage {
                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(
                            "私の筋力マップ",
                            image: Image(uiImage: image)
                        )
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.lightTap()
                    })
                } else {
                    Button {
                        HapticManager.lightTap()
                        generateAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFront.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text(showingFront ? L10n.viewBack : L10n.viewFront)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.mmAccentSecondary)
                }
            }
            .padding(.horizontal, 8)

            // 筋肉マップ描画
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
                    let muscles = showingFront
                        ? MusclePathData.frontMuscles
                        : MusclePathData.backMuscles

                    ForEach(muscles, id: \.muscle) { entry in
                        let score = muscleScores[entry.muscle.rawValue] ?? 0
                        let params = StrengthScoreCalculator.shared.displayParams(score: score)

                        entry.path(rect)
                            .fill(params.color.opacity(params.opacity))
                            .overlay {
                                entry.path(rect).stroke(
                                    score > 0
                                        ? params.color.opacity(0.6)
                                        : Color.mmMuscleBorder,
                                    lineWidth: params.strokeWidth
                                )
                            }
                    }
                }
            }
            .aspectRatio(0.6, contentMode: .fit)

            // トップ3スコア表示
            topMusclesSection
        }
        .onAppear {
            generateAndShare()
        }
        .onChange(of: muscleScores) {
            shareImage = nil
            generateAndShare()
        }
    }

    // MARK: - シェア画像生成

    @MainActor
    private func generateAndShare() {
        let profile = UserProfile.load()
        let image = generateStrengthShareImage(
            scores: muscleScores,
            userName: profile.nickname,
            date: Date()
        )
        shareImage = image
    }

    // MARK: - トップ3筋肉スコア表示

    @MainActor
    private var topMusclesSection: some View {
        let sorted = muscleScores
            .compactMap { (key, value) -> (Muscle, Double)? in
                guard let muscle = Muscle(rawValue: key), value > 0 else { return nil }
                return (muscle, value)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(3)

        return Group {
            if !sorted.isEmpty {
                HStack(spacing: 16) {
                    ForEach(Array(sorted), id: \.0) { muscle, score in
                        let params = StrengthScoreCalculator.shared.displayParams(score: score)
                        VStack(spacing: 4) {
                            Text(muscle.localizedName)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                                .lineLimit(1)
                            Text("\(Int(score * 100))")
                                .font(.title3.bold())
                                .foregroundStyle(params.color)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

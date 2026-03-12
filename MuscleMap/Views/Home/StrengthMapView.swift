import SwiftUI
import SwiftData

// MARK: - Strength Map View（Pro限定）

struct StrengthMapView: View {
    let muscleScores: [String: Double]

    @State private var shareImage: UIImage?

    // MARK: - 計算プロパティ

    /// 全21筋肉の平均スコア（未記録=0として計算）
    private var averageScore: Double {
        let allScores = Muscle.allCases.map { muscleScores[$0.rawValue] ?? 0.0 }
        return allScores.reduce(0, +) / Double(allScores.count)
    }

    private var overallGrade: String {
        StrengthScoreCalculator.grade(score: averageScore)
    }

    private var gradeColor: Color {
        StrengthScoreCalculator.gradeColor(grade: overallGrade)
    }

    var body: some View {
        VStack(spacing: 8) {
            // ヘッダー: タイトル + シェアボタン
            headerSection

            // 前後マップ横並び表示
            bodySection

            // 総合グレードバッジ
            gradeBadgeSection

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

    // MARK: - ヘッダー

    private var headerSection: some View {
        HStack {
            Text("STRENGTH MAP")
                .font(.caption.bold())
                .foregroundStyle(Color.mmTextSecondary)
                .tracking(1.0)
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
        }
        .padding(.horizontal, 8)
    }

    // MARK: - 前後同時表示ボディ

    private var bodySection: some View {
        GeometryReader { geo in
            let mapWidth = (geo.size.width - 24) / 2 // 左右余白8+中央spacing8
            HStack(spacing: 8) {
                strengthMapColumn(
                    muscles: MusclePathData.frontMuscles,
                    label: L10n.front,
                    width: mapWidth
                )
                strengthMapColumn(
                    muscles: MusclePathData.backMuscles,
                    label: L10n.back,
                    width: mapWidth
                )
            }
            .padding(.horizontal, 8)
        }
        .aspectRatio(0.75, contentMode: .fit)
    }

    /// 前面/背面のマップ列（ラベル + マップ）
    private func strengthMapColumn(
        muscles: [(muscle: Muscle, path: (CGRect) -> Path)],
        label: String,
        width: CGFloat
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)

            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                ZStack {
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
            .aspectRatio(0.5, contentMode: .fit)
        }
        .frame(width: width)
    }

    // MARK: - 総合グレードバッジ

    private var gradeBadgeSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Overall Grade")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.mmTextSecondary)
                Text("\(Int(averageScore * 100))pt")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Circle()
                    .stroke(gradeColor.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 44, height: 44)

                Text(overallGrade)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(gradeColor)
            }
        }
        .padding(.horizontal, 8)
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
                        let grade = StrengthScoreCalculator.grade(score: score)
                        let color = StrengthScoreCalculator.gradeColor(grade: grade)
                        VStack(spacing: 4) {
                            Text(muscle.localizedName)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                                .lineLimit(1)
                            Text(grade)
                                .font(.title3.bold())
                                .foregroundStyle(color)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

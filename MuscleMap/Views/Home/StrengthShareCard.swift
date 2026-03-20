import SwiftUI

// MARK: - Strength Map シェアカード（9:16、1080×1920px @3x）

struct StrengthShareCard: View {
    let scores: [String: Double]  // muscle.rawValue → 0.0-1.0
    let userName: String
    let date: Date

    // MARK: - 定数

    private enum Layout {
        static let cardWidth: CGFloat = 360
        static let cardHeight: CGFloat = 640
        static let headerHeight: CGFloat = 56
        static let bodyHeight: CGFloat = 340
        static let rankingHeight: CGFloat = 140
        static let footerHeight: CGFloat = 64
        static let gridSpacing: CGFloat = 24
    }

    // MARK: - 計算プロパティ

    /// 全21筋肉の平均スコア（未記録=0として計算）
    private var averageScore: Double {
        let allScores = Muscle.allCases.map { scores[$0.rawValue] ?? 0.0 }
        return allScores.reduce(0, +) / Double(allScores.count)
    }

    private var overallGrade: String {
        StrengthScoreCalculator.grade(score: averageScore)
    }

    private var gradeColor: Color {
        StrengthScoreCalculator.gradeColor(grade: overallGrade)
    }

    private var overallLevel: StrengthLevel {
        StrengthScoreCalculator.level(score: averageScore)
    }

    /// スコア上位3筋肉
    private var topMuscles: [(muscle: Muscle, score: Double)] {
        Muscle.allCases
            .compactMap { muscle -> (Muscle, Double)? in
                let s = scores[muscle.rawValue] ?? 0
                guard s > 0 else { return nil }
                return (muscle, s)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { ($0.0, $0.1) }
    }

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            bodySection
            rankingSection
            footerSection
        }
        .frame(width: Layout.cardWidth, height: Layout.cardHeight)
        .background(Color.mmBgPrimary)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - ヘッダー (56pt)

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                // ロゴ
                HStack(spacing: 4) {
                    Text("M")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text("MuscleMap")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                Spacer()

                // 日付
                Text(dateString)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal, 20)
            .frame(height: Layout.headerHeight)

            // 区切り線
            Rectangle()
                .fill(Color.mmBorder)
                .frame(height: 0.5)
        }
    }

    // MARK: - 人体図エリア (340pt)

    private var bodySection: some View {
        ZStack {
            // グリッド線（装飾）
            gridOverlay

            // 前面・背面を並列表示
            HStack(spacing: 8) {
                muscleMapView(muscles: MusclePathData.frontMuscles)
                muscleMapView(muscles: MusclePathData.backMuscles)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: Layout.bodyHeight)
    }

    /// グリッド装飾
    private var gridOverlay: some View {
        Canvas { context, size in
            let lineColor = Color.mmBgSecondary
            // 縦線
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                x += Layout.gridSpacing
            }
            // 横線
            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                y += Layout.gridSpacing
            }
        }
    }

    /// 個別筋肉マップ（前面 or 背面）
    private func muscleMapView(muscles: [(muscle: Muscle, path: (CGRect) -> Path)]) -> some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let score = scores[entry.muscle.rawValue] ?? 0
                    let params = shareCardDisplayParams(score: score)

                    entry.path(rect)
                        .fill(params.color.opacity(params.opacity))
                        .overlay {
                            entry.path(rect).stroke(
                                score > 0
                                    ? params.color.opacity(0.6)
                                    : Color.mmBorder,
                                lineWidth: params.strokeWidth
                            )
                        }
                }
            }
        }
        .aspectRatio(0.5, contentMode: .fit)
    }

    /// シェアカード専用のdisplayParams（仕様書のstrokeWidth/opacity/fill colorに準拠）
    private func shareCardDisplayParams(score: Double) -> StrengthDisplayParams {
        if score <= 0 {
            return StrengthDisplayParams(strokeWidth: 1.0, opacity: 0.20, color: Color.mmMuscleInactive)
        } else if score < 0.2 {
            return StrengthDisplayParams(strokeWidth: 1.5, opacity: 0.35, color: Color.mmAccentPrimary)
        } else if score < 0.4 {
            return StrengthDisplayParams(strokeWidth: 2.5, opacity: 0.50, color: Color.mmAccentPrimary)
        } else if score < 0.6 {
            return StrengthDisplayParams(strokeWidth: 3.5, opacity: 0.65, color: Color.mmAccentPrimary)
        } else if score < 0.8 {
            return StrengthDisplayParams(strokeWidth: 5.0, opacity: 0.80, color: Color.mmAccentPrimary)
        } else {
            // 0.8-1.0: mmAccentPrimary → 白ハイライト
            let t = (score - 0.8) / 0.2
            let c = Color.interpolate(from: Color.mmAccentPrimary, to: .white, t: t)
            return StrengthDisplayParams(strokeWidth: 7.0, opacity: 1.0, color: c)
        }
    }

    // MARK: - ランキングエリア (140pt)

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // セクションタイトル
            Text("STRENGTH RANKING")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(Color.mmTextSecondary)
                .tracking(1.5)
                .padding(.bottom, 8)

            // ランク行（3行 or 少なければ少なく）
            let medals = ["🥇", "🥈", "🥉"]
            ForEach(Array(topMuscles.prefix(3).enumerated()), id: \.offset) { index, entry in
                rankRow(
                    medal: medals[index],
                    name: muscleJapaneseName(entry.muscle),
                    score: entry.score
                )
            }

            // 3件未満ならスペーサー
            if topMuscles.count < 3 {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: Layout.rankingHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmBgSecondary)
    }

    private func rankRow(medal: String, name: String, score: Double) -> some View {
        HStack(spacing: 8) {
            Text(medal)
                .font(.system(size: 14))

            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .leading)

            // スコアバー
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.mmMuscleInactive)
                    .frame(width: 80, height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.mmAccentPrimary)
                    .frame(width: 80 * score, height: 6)
            }

            // グレード + レベル
            let grade = StrengthScoreCalculator.grade(score: score)
            Text(grade)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(StrengthScoreCalculator.gradeColor(grade: grade))
                .frame(width: 28, alignment: .trailing)
        }
        .frame(height: 36)
    }

    // MARK: - フッター (64pt)

    private var footerSection: some View {
        HStack {
            // 左: ユーザー名 + レベル
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(userName.isEmpty ? "MuscleMap User" : userName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    // レベルバッジ
                    HStack(spacing: 3) {
                        Text(overallLevel.emoji)
                            .font(.system(size: 10))
                        Text(overallLevel.localizedName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(overallLevel.color)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(overallLevel.color.opacity(0.12))
                    .clipShape(Capsule())
                }

                Text("Overall Grade")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.mmTextSecondary)
            }

            Spacer()

            // 右: グレードバッジ
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                Circle()
                    .stroke(gradeColor.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 52, height: 52)

                Text(overallGrade)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(gradeColor)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: Layout.footerHeight)
        .background(Color.mmBgPrimary)
    }

    // MARK: - 筋肉名日本語マッピング（シェアカード用）

    private func muscleJapaneseName(_ muscle: Muscle) -> String {
        switch muscle {
        case .chestUpper:       return "大胸筋（上部）"
        case .chestLower:       return "大胸筋（下部）"
        case .lats:             return "広背筋"
        case .trapsUpper:       return "僧帽筋（上部）"
        case .trapsMiddleLower: return "僧帽筋（中下部）"
        case .erectorSpinae:    return "脊柱起立筋"
        case .deltoidAnterior:  return "三角筋（前部）"
        case .deltoidLateral:   return "三角筋（側部）"
        case .deltoidPosterior: return "三角筋（後部）"
        case .biceps:           return "上腕二頭筋"
        case .triceps:          return "上腕三頭筋"
        case .forearms:         return "前腕"
        case .rectusAbdominis:  return "腹直筋"
        case .obliques:         return "腹斜筋"
        case .glutes:           return "大臀筋"
        case .quadriceps:       return "大腿四頭筋"
        case .hamstrings:       return "ハムストリングス"
        case .adductors:        return "内転筋"
        case .hipFlexors:       return "腸腰筋"
        case .gastrocnemius:    return "腓腹筋"
        case .soleus:           return "ヒラメ筋"
        }
    }
}

// MARK: - シェア画像生成

@MainActor
func generateStrengthShareImage(scores: [String: Double], userName: String, date: Date) -> UIImage {
    let card = StrengthShareCard(scores: scores, userName: userName, date: date)
        .environment(\.colorScheme, .dark)

    let renderer = ImageRenderer(content: card)
    renderer.scale = 3.0  // @3x で 1080×1920px
    return renderer.uiImage ?? UIImage()
}

// MARK: - Preview

#Preview("Strength Share Card") {
    ScrollView {
        StrengthShareCard(
            scores: [
                "chest_upper": 0.87,
                "chest_lower": 0.72,
                "lats": 0.74,
                "traps_upper": 0.45,
                "traps_middle_lower": 0.55,
                "deltoid_anterior": 0.68,
                "deltoid_lateral": 0.52,
                "biceps": 0.61,
                "triceps": 0.58,
                "quadriceps": 0.65,
                "hamstrings": 0.48,
                "glutes": 0.42,
            ],
            userName: "トレーニー太郎",
            date: Date()
        )
    }
    .background(Color.mmBgPrimary)
}

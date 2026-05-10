import SwiftUI
import UIKit

// MARK: - 全身制覇画面（v1.1.x リデザイン版）
//
// 鏡哲学準拠: 装飾排除、データ反映のみ。
// 上→下: ヘッダー → 大マップ(前/後) → 達成日数カード → 21部位最終刺激リスト → 注釈 → フッター → 閉じる
// シェアはヘッダー右上アイコンのみ（緑大ボタン廃止）。紙吹雪・絵文字・祝賀大文字も廃止。

struct FullBodyConquestView: View {

    /// 全21部位それぞれの最終刺激日（必ず21筋肉分入っている前提）
    let lastStimulations: [Muscle: Date]
    /// 全身制覇達成と判定された日（フッター期間の終了日 / 達成日数の起点）
    let achievementDate: Date
    let onShare: () -> Void
    let onDismiss: () -> Void

    init(
        lastStimulations: [Muscle: Date],
        achievementDate: Date = Date(),
        onShare: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.lastStimulations = lastStimulations
        self.achievementDate = achievementDate
        self.onShare = onShare
        self.onDismiss = onDismiss
    }

    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    private var calendar: Calendar { Calendar.current }

    /// 21部位中で最も古い最終刺激日（達成期間の開始日）
    private var periodStartDate: Date {
        lastStimulations.values.min() ?? achievementDate
    }

    /// 達成日数 = end - start を「日」で切り上げ + 1
    private var achievementDays: Int {
        let startDay = calendar.startOfDay(for: periodStartDate)
        let endDay = calendar.startOfDay(for: achievementDate)
        let diff = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return max(1, diff + 1)
    }

    /// 「データ期間」表示用の YYYY/MM/DD - YYYY/MM/DD
    private var dataPeriodString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return "\(formatter.string(from: periodStartDate)) - \(formatter.string(from: achievementDate))"
    }

    /// 「X日前」「今日」のローカライズ済み相対表記
    private func daysAgoString(from date: Date) -> String {
        let baseline = calendar.startOfDay(for: achievementDate)
        let target = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: target, to: baseline).day ?? 0
        if diff <= 0 { return L10n.fullBodyCoverageToday }
        return L10n.fullBodyCoverageDaysAgo(diff)
    }

    /// マップに渡す muscleMapping（21部位全て点灯フラグ）
    private var allLitMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        for muscle in Muscle.allCases { mapping[muscle.rawValue] = 100 }
        return mapping
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            ScrollView {
                conquestContent
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                ShareSheet(
                    items: [
                        L10n.fullBodyConquestShareText(AppConstants.shareHashtag, AppConstants.appStoreURL),
                        image
                    ],
                    onComplete: nil
                )
            }
        }
        .onAppear { HapticManager.workoutEnded() }
    }

    /// ScrollView の中身、もしくは ImageRenderer で個別レンダリング可能なコンテンツ部
    @ViewBuilder
    var conquestContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            muscleMapSection
            achievementDataCard
            lastStimulatedCard
            footnoteText
            footerLine
            closeButton
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }

    // MARK: - 1. ヘッダー

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text(L10n.fullBodyCoverageTitle)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)

            Spacer()

            Button {
                prepareShareImage()
                showingShareSheet = true
                onShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.mmTextPrimary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - 2. マッスルマップ section

    private var muscleMapSection: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 8) {
                Text("FRONT")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.mmTextSecondary)
                FullBodyCoverageStaticMap(muscles: MusclePathData.frontMuscles)
            }
            VStack(spacing: 8) {
                Text("BACK")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.mmTextSecondary)
                FullBodyCoverageStaticMap(muscles: MusclePathData.backMuscles)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - 3. 達成データ card

    private var achievementDataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.fullBodyCoverageAchievementData)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.fullBodyCoverageDaysValue(achievementDays))
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
                Text(L10n.fullBodyCoverageAchievedSuffix)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.mmTextPrimary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    // MARK: - 4. 最終刺激 card (21部位、2列)

    private var lastStimulatedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.fullBodyCoverageLastStimulated)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12, alignment: .leading),
                    GridItem(.flexible(), spacing: 12, alignment: .leading)
                ],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(Array(Muscle.allCases.enumerated()), id: \.offset) { index, muscle in
                    muscleRow(index: index, muscle: muscle)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func muscleRow(index: Int, muscle: Muscle) -> some View {
        let date = lastStimulations[muscle]
        return HStack(spacing: 4) {
            Text("\(index + 1).")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.mmTextSecondary)
                .frame(width: 22, alignment: .leading)

            Text(muscle.localizedName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            if let date {
                Text(daysAgoString(from: date))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.mmAccentPrimary)
                    .lineLimit(1)
            } else {
                Text("—")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
    }

    // MARK: - 5. 注釈

    private var footnoteText: some View {
        Text(L10n.fullBodyCoverageFootnote)
            .font(.system(size: 10, weight: .regular))
            .foregroundStyle(Color.mmTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
    }

    // MARK: - 6. フッター

    private var footerLine: some View {
        HStack {
            Text("MuscleMap")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
            Spacer()
            Text("\(L10n.fullBodyCoverageDataPeriod): \(dataPeriodString)")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 閉じるボタン (控えめ)

    private var closeButton: some View {
        Button {
            onDismiss()
        } label: {
            Text(L10n.close)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }

    // MARK: - シェア用画像生成

    @MainActor
    private func prepareShareImage() {
        let shareCard = FullBodyConquestShareCard(
            muscleMapping: allLitMapping,
            achievementDays: achievementDays,
            dataPeriod: dataPeriodString
        )
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 全身制覇用 静的筋肉マップ
// 21部位全てを mmAccentPrimary で塗る達成画面専用ビュー。
// ShareMuscleMapView は刺激度→色変換を持つため流用せず、専用の単色描画にする。

private struct FullBodyCoverageStaticMap: View {
    let muscles: [(muscle: Muscle, path: (CGRect) -> Path)]

    /// マップは縦長（人体比率）。GeometryReader で親の幅に合わせる。
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 2.0 // 人体比率 1:2 (高さ = 幅 × 2)
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in muscles {
                    let path = entry.path(rect)
                    // 軽いグロー層
                    context.drawLayer { ctx in
                        ctx.addFilter(.shadow(color: Color.mmAccentPrimary.opacity(0.5), radius: 4, x: 0, y: 0))
                        ctx.fill(path, with: .color(Color.mmAccentPrimary.opacity(0.01)))
                    }
                    context.fill(path, with: .color(Color.mmAccentPrimary))
                    context.stroke(path, with: .color(Color.mmBorder.opacity(0.4)), lineWidth: 0.8)
                }
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(0.5, contentMode: .fit) // 幅:高 = 1:2
    }
}

// MARK: - 全身制覇シェアカード（最小データ反映版）

private struct FullBodyConquestShareCard: View {
    let muscleMapping: [String: Int]
    let achievementDays: Int
    let dataPeriod: String

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dataPeriod)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text(L10n.fullBodyConqueredLabel)
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(Color.mmAccentPrimary)

                ShareMuscleMapView(muscleMapping: muscleMapping)
                    .padding(.vertical, 8)

                Text(L10n.fullBodyCoverageAchievedInDays(achievementDays))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    Text("MuscleMap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 390, height: 693)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - 2回目以降用のバナー（既存維持、今は別画面で使用される）

struct FullBodyConquestBanner: View {
    let count: Int
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.fullBodyConquestAgain)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.conquestCount(count))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Button {
                    withAnimation { isVisible = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding()
            .background(Color.mmAccentPrimary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 1)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview("Full Body Coverage — 7日達成") {
    let now = Date()
    let cal = Calendar.current
    let dates: [Muscle: Date] = Dictionary(uniqueKeysWithValues: Muscle.allCases.enumerated().map { index, muscle in
        let daysBack = (index % 7) + 1 // 1〜7日前を循環
        let date = cal.date(byAdding: .day, value: -daysBack, to: now) ?? now
        return (muscle, date)
    })
    return FullBodyConquestView(
        lastStimulations: dates,
        achievementDate: now,
        onShare: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Full Body Coverage — Light Mode") {
    let now = Date()
    let cal = Calendar.current
    let dates: [Muscle: Date] = Dictionary(uniqueKeysWithValues: Muscle.allCases.enumerated().map { index, muscle in
        let daysBack = (index % 4) + 1
        let date = cal.date(byAdding: .day, value: -daysBack, to: now) ?? now
        return (muscle, date)
    })
    return FullBodyConquestView(
        lastStimulations: dates,
        achievementDate: now,
        onShare: {},
        onDismiss: {}
    )
    .preferredColorScheme(.light)
}

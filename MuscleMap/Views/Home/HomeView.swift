import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins

// MARK: - ホーム画面

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var streakViewModel = StreakViewModel()
    @State private var showingWorkout = false
    @State private var selectedMuscle: Muscle?
    @State private var showDemo = false
    @State private var showingPaywall = false
    @State private var showingMilestone = false
    @State private var showingWeeklySummary = false
    @State private var showingBalanceDiagnosis = false
    @State private var showingMuscleJourney = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 週間ストリークバッジ（タップで週間サマリーへ）
                            Button {
                                showingWeeklySummary = true
                            } label: {
                                WeeklyStreakBadge(
                                    weeks: streakViewModel.currentStreak,
                                    isCurrentWeekCompleted: streakViewModel.isCurrentWeekCompleted
                                )
                            }
                            .buttonStyle(.plain)

                            // 筋肉マップ
                            MuscleMapView(
                                muscleStates: vm.muscleStates,
                                onMuscleTapped: { muscle in
                                    selectedMuscle = muscle
                                },
                                demoMode: showDemo
                            )
                            .frame(maxHeight: 500)
                            .padding(.horizontal)

                            // Pro機能バナー（非Proユーザー向け）
                            if !PurchaseManager.shared.isProUser {
                                ProFeatureBanner(feature: .recovery) {
                                    showingPaywall = true
                                }
                                .padding(.horizontal)
                            }

                            // 筋肉バランス診断カード
                            BalanceDiagnosisCard {
                                showingBalanceDiagnosis = true
                            }
                            .padding(.horizontal)

                            // マッスル・ジャーニーカード
                            MuscleJourneyCard {
                                showingMuscleJourney = true
                            }
                            .padding(.horizontal)

                            // 未刺激警告
                            if !vm.neglectedMuscleInfos.isEmpty {
                                NeglectedWarningView(muscleInfos: vm.neglectedMuscleInfos)
                                    .padding(.horizontal)
                            }

                            // 凡例
                            MuscleMapLegend()
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("MuscleMap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MuscleMap")
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                viewModel?.loadMuscleStates()
                viewModel?.checkActiveSession()

                // ストリーク計算
                streakViewModel.configure(with: modelContext)

                // マイルストーン達成チェック
                if streakViewModel.achievedMilestone != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingMilestone = true
                    }
                }

                // 初回デモアニメーション
                if !AppState.shared.hasSeenDemoAnimation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDemo = true
                        AppState.shared.hasSeenDemoAnimation = true
                    }
                }
            }
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailView(muscle: muscle)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingMilestone) {
                if let milestone = streakViewModel.achievedMilestone {
                    MilestoneView(
                        milestone: milestone,
                        streakWeeks: streakViewModel.currentStreak
                    ) {
                        streakViewModel.dismissMilestone()
                        showingMilestone = false
                    }
                }
            }
            .sheet(isPresented: $showingWeeklySummary) {
                WeeklySummaryView()
            }
            .sheet(isPresented: $showingBalanceDiagnosis) {
                MuscleBalanceDiagnosisView()
            }
            .sheet(isPresented: $showingMuscleJourney) {
                MuscleJourneyView()
            }
        }
    }
}

// MARK: - マッスル・ジャーニーカード

private struct MuscleJourneyCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.muscleJourney)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.journeyCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 筋肉バランス診断カード

private struct BalanceDiagnosisCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.muscleBalanceDiagnosis)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.diagnosisCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 週間ストリークバッジ

private struct WeeklyStreakBadge: View {
    let weeks: Int
    let isCurrentWeekCompleted: Bool

    @State private var glowAnimation = false

    private var showBadge: Bool {
        weeks > 0 || !isCurrentWeekCompleted
    }

    var body: some View {
        if showBadge {
            HStack(spacing: 8) {
                // 炎アイコン
                Image(systemName: "flame.fill")
                    .foregroundStyle(isCurrentWeekCompleted ? .orange : Color.mmTextSecondary)
                    .shadow(color: isCurrentWeekCompleted ? .orange.opacity(glowAnimation ? 0.6 : 0.2) : .clear, radius: glowAnimation ? 8 : 4)

                // テキスト
                if weeks > 0 {
                    Text(L10n.weekStreak(weeks))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                } else {
                    Text(L10n.noWorkoutThisWeek)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.mmBgCard)
            .clipShape(Capsule())
            .onAppear {
                if isCurrentWeekCompleted {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowAnimation = true
                    }
                }
            }
        }
    }
}

// MARK: - マイルストーン祝福画面

private struct MilestoneView: View {
    let milestone: StreakMilestone
    let streakWeeks: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 絵文字
                Text(milestone.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                // タイトル
                Text(milestone.localizedTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // サブタイトル
                Text(L10n.streakCongrats(streakWeeks))
                    .font(.title3)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer()

                // シェアボタン
                Button {
                    generateShareImage()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.shareAchievement)
                    }
                    .font(.headline)
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

                // 閉じるボタン
                Button {
                    onDismiss()
                } label: {
                    Text(L10n.close)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            HapticManager.workoutEnded()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [L10n.milestoneShareText(streakWeeks, AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
            }
        }
    }

    @MainActor
    private func generateShareImage() {
        let shareCard = MilestoneShareCard(milestone: milestone, streakWeeks: streakWeeks)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - マイルストーンシェアカード

private struct MilestoneShareCard: View {
    let milestone: StreakMilestone
    let streakWeeks: Int

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 24) {
                Spacer()

                // 絵文字
                Text(milestone.emoji)
                    .font(.system(size: 60))

                // タイトル
                Text(milestone.localizedTitle)
                    .font(.title.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                // ストリーク数
                Text(L10n.weekStreak(streakWeeks))
                    .font(.title2)
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                // フッター
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)

                    HStack {
                        Text(AppConstants.appName)
                            .font(.headline.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text("—")
                            .foregroundStyle(Color.mmTextSecondary)
                        Text(L10n.shareTagline)
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 24)
            }
        }
        .frame(width: 350, height: 400)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }
}

// MARK: - 未刺激警告

private struct NeglectedWarningView: View {
    let muscleInfos: [NeglectedMuscleInfo]
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.mmMuscleNeglected)
                Text(L10n.neglectedMuscles)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(muscleInfos) { info in
                    Text(info.muscle.localizedName)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.mmMuscleNeglected.opacity(0.2))
                        .foregroundStyle(Color.mmMuscleNeglected)
                        .clipShape(Capsule())
                }
            }

            // シェアボタン
            Button {
                prepareShareImage()
                showingShareSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.shareShame)
                }
                .font(.caption.bold())
                .foregroundStyle(Color.mmMuscleNeglected)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.mmMuscleNeglected.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                let worstMuscle = muscleInfos.first
                let shareText = L10n.neglectedShareText(
                    worstMuscle?.muscle.localizedName ?? "",
                    worstMuscle?.daysSinceStimulation ?? 0,
                    AppConstants.shareHashtag,
                    AppConstants.appStoreURL
                )
                ShareSheet(items: [shareText, image], onComplete: nil)
            }
        }
    }

    @MainActor
    private func prepareShareImage() {
        let shareCard = NeglectedShareCard(muscleInfos: muscleInfos)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 未刺激シェアカード

private struct NeglectedShareCard: View {
    let muscleInfos: [NeglectedMuscleInfo]

    private var neglectedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        // 未刺激の筋肉を紫表示用に設定（-1は特別な値として紫を示す）
        for info in muscleInfos {
            mapping[info.muscle.rawValue] = -1
        }
        return mapping
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション（紫系）
            LinearGradient(
                colors: [Color.mmMuscleNeglected, Color.mmMuscleNeglected.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // タイトル
                VStack(spacing: 4) {
                    Text("NEGLECTED ALERT ⚠️")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmMuscleNeglected)
                    Text(L10n.neglectedShareSubtitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
                .padding(.top, 20)

                // 筋肉マップ（紫ハイライト）
                NeglectedMuscleMapView(neglectedMuscles: Set(muscleInfos.map { $0.muscle }))
                    .frame(height: 200)

                // 未刺激部位リスト
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(muscleInfos.prefix(5)) { info in
                        HStack {
                            Circle()
                                .fill(Color.mmMuscleNeglected)
                                .frame(width: 8, height: 8)
                            Text(info.muscle.localizedName)
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                            Spacer()
                            Text(L10n.daysNeglected(info.daysSinceStimulation))
                                .font(.caption)
                                .foregroundStyle(Color.mmMuscleNeglected)
                        }
                    }
                    if muscleInfos.count > 5 {
                        Text(L10n.andMoreCount(muscleInfos.count - 5))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // フッター
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.mmMuscleNeglected.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        // QRコード
                        if let qrImage = generateQRCode(from: AppConstants.appStoreURL) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(AppConstants.appName)
                                .font(.headline.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text(L10n.shareTagline)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: 350, height: 520)
        .background(
            LinearGradient(
                colors: [Color.mmBgCard, Color.mmBgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmMuscleNeglected.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - 未刺激筋肉マップビュー（紫ハイライト）

private struct NeglectedMuscleMapView: View {
    let neglectedMuscles: Set<Muscle>

    var body: some View {
        HStack(spacing: 20) {
            // 前面
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in MusclePathData.frontMuscles {
                    let path = entry.path(rect)
                    let isNeglected = neglectedMuscles.contains(entry.muscle)
                    let color = isNeglected ? Color.mmMuscleNeglected : Color.mmBgSecondary

                    context.fill(path, with: .color(color))
                    context.stroke(
                        path,
                        with: .color(Color.mmMuscleBorder.opacity(0.4)),
                        lineWidth: 0.5
                    )
                }
            }
            .frame(width: 100, height: 180)

            // 背面
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in MusclePathData.backMuscles {
                    let path = entry.path(rect)
                    let isNeglected = neglectedMuscles.contains(entry.muscle)
                    let color = isNeglected ? Color.mmMuscleNeglected : Color.mmBgSecondary

                    context.fill(path, with: .color(color))
                    context.stroke(
                        path,
                        with: .color(Color.mmMuscleBorder.opacity(0.4)),
                        lineWidth: 0.5
                    )
                }
            }
            .frame(width: 100, height: 180)
        }
    }
}

// MARK: - 凡例（3×2グリッド）

private struct MuscleMapLegend: View {
    private var items: [(Color, String)] {
        [
            (.mmMuscleCoral, L10n.highLoad),
            (.mmMuscleAmber, L10n.earlyRecovery),
            (.mmMuscleYellow, L10n.midRecovery),
            (.mmMuscleLime, L10n.lateRecovery),
            (.mmMuscleBioGreen, L10n.almostRecovered),
            (.mmMuscleNeglected, L10n.notStimulated),
        ]
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.0)
                        .frame(width: 10, height: 10)
                    Text(item.1)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }
}

// MARK: - FlowLayout（タグ表示用）

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

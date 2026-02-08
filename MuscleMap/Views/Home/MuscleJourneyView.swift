import SwiftUI
import SwiftData

// MARK: - マッスル・ジャーニー画面

struct MuscleJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MuscleJourneyViewModel()
    @State private var showingFront = true
    @State private var showingDatePicker = false
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if viewModel.isCalculating {
                    ProgressView()
                        .tint(Color.mmAccentPrimary)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 期間セレクター
                            periodSelector

                            // Before/After比較
                            comparisonSection

                            // 前面/背面トグル
                            frontBackToggle

                            // 変化サマリー
                            if viewModel.hasPastData {
                                changeSummarySection
                            } else {
                                noDataSection
                            }

                            // シェアボタン
                            if viewModel.hasPastData {
                                shareButton
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.muscleJourney)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .sheet(isPresented: $showingDatePicker) {
                customDatePicker
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [L10n.journeyShareText(viewModel.progressText, AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
                }
            }
        }
    }

    // MARK: - 期間セレクター

    private var periodSelector: some View {
        VStack(spacing: 12) {
            // セグメントコントロール
            HStack(spacing: 0) {
                ForEach(JourneyPeriod.allCases, id: \.self) { period in
                    Button {
                        if period == .custom {
                            showingDatePicker = true
                        }
                        viewModel.selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(viewModel.selectedPeriod == period ? Color.mmBgPrimary : Color.mmTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedPeriod == period ? Color.mmAccentPrimary : Color.clear)
                    }
                }
            }
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Before/After比較

    private var comparisonSection: some View {
        HStack(spacing: 16) {
            // Before (過去)
            VStack(spacing: 8) {
                Text(viewModel.periodText)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)

                JourneyMuscleMapView(
                    muscleMapping: viewModel.pastSnapshot?.muscleMapping ?? [:],
                    showingFront: showingFront
                )
                .frame(height: 200)
            }
            .frame(maxWidth: .infinity)

            // 矢印
            Image(systemName: "arrow.right")
                .font(.title2)
                .foregroundStyle(Color.mmAccentPrimary)

            // After (現在)
            VStack(spacing: 8) {
                Text(L10n.now)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                JourneyMuscleMapView(
                    muscleMapping: viewModel.currentSnapshot?.muscleMapping ?? [:],
                    showingFront: showingFront
                )
                .frame(height: 200)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 前面/背面トグル

    private var frontBackToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingFront.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                Text(showingFront ? L10n.viewBack : L10n.viewFront)
            }
            .font(.subheadline)
            .foregroundStyle(Color.mmAccentSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.mmBgCard)
            .clipShape(Capsule())
        }
    }

    // MARK: - 変化サマリー

    private var changeSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.changeSummary)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // 新たに刺激した部位
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.newlyStimulated)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(L10n.countParts(viewModel.changeSummary?.newlyStimulated.count ?? 0))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Spacer()
            }

            // 最も改善した部位
            if let mostImproved = viewModel.changeSummary?.mostImproved {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.mmAccentSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.mostImproved)
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                        Text(mostImproved.localizedName)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                    }

                    Spacer()
                }
            }

            // まだ未刺激の部位
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundStyle(Color.mmMuscleNeglected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.stillNeglected)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(L10n.countParts(viewModel.changeSummary?.stillNeglected.count ?? 0))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - データなしセクション

    private var noDataSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.mmTextSecondary)

            Text(L10n.noDataForPeriod)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - シェアボタン

    private var shareButton: some View {
        Button {
            prepareShareImage()
            showingShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text(L10n.share)
            }
            .font(.headline)
            .foregroundStyle(Color.mmBgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mmAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - カスタム日付ピッカー

    private var customDatePicker: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    L10n.selectDate,
                    selection: $viewModel.customDate,
                    in: (viewModel.earliestWorkoutDate ?? Date())...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.mmAccentPrimary)
                .padding()

                Button {
                    showingDatePicker = false
                } label: {
                    Text(L10n.done)
                        .font(.headline)
                        .foregroundStyle(Color.mmBgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.mmAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .background(Color.mmBgPrimary)
            .navigationTitle(L10n.selectDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingDatePicker = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - シェア画像生成

    @MainActor
    private func prepareShareImage() {
        let shareCard = JourneyShareCard(
            periodText: viewModel.periodText,
            progressText: viewModel.progressText,
            pastMapping: viewModel.pastSnapshot?.muscleMapping ?? [:],
            currentMapping: viewModel.currentSnapshot?.muscleMapping ?? [:],
            newlyStimulatedCount: viewModel.changeSummary?.newlyStimulated.count ?? 0,
            mostImproved: viewModel.changeSummary?.mostImproved
        )

        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - ジャーニー用筋肉マップビュー

private struct JourneyMuscleMapView: View {
    let muscleMapping: [String: Int]
    let showingFront: Bool

    private let mapSize = CGSize(width: 120, height: 200)

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let muscles = showingFront ? MusclePathData.frontMuscles : MusclePathData.backMuscles

            for entry in muscles {
                let path = entry.path(rect)
                let stimulation = muscleMapping[entry.muscle.rawValue] ?? 0
                let color = colorFor(stimulation: stimulation)

                context.fill(path, with: .color(color))
                context.stroke(
                    path,
                    with: .color(Color.mmMuscleBorder.opacity(0.4)),
                    lineWidth: 0.5
                )
            }
        }
        .frame(width: mapSize.width, height: mapSize.height)
    }

    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            return Color.mmBgSecondary
        }

        switch stimulation {
        case 80...100:
            return Color.mmMuscleJustWorked
        case 50..<80:
            return Color.mmMuscleCoral
        case 20..<50:
            return Color.mmMuscleAmber
        default:
            return Color.mmAccentPrimary.opacity(0.5)
        }
    }
}

// MARK: - シェアカード

private struct JourneyShareCard: View {
    let periodText: String
    let progressText: String
    let pastMapping: [String: Int]
    let currentMapping: [String: Int]
    let newlyStimulatedCount: Int
    let mostImproved: Muscle?

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // タイトル
                VStack(spacing: 4) {
                    Text("MY MUSCLE JOURNEY")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(progressText)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
                .padding(.top, 20)

                // Before/After
                HStack(spacing: 24) {
                    // Before
                    VStack(spacing: 4) {
                        Text("BEFORE")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                        ShareMuscleMapView(muscleMapping: pastMapping)
                            .scaleEffect(0.6)
                            .frame(width: 120, height: 180)
                    }

                    // 矢印
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundStyle(Color.mmAccentPrimary)

                    // After
                    VStack(spacing: 4) {
                        Text("AFTER")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        ShareMuscleMapView(muscleMapping: currentMapping)
                            .scaleEffect(0.6)
                            .frame(width: 120, height: 180)
                    }
                }

                // サマリー
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("+\(newlyStimulatedCount)")
                            .font(.title2.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(L10n.newMuscles)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }

                    if let improved = mostImproved {
                        VStack(spacing: 2) {
                            Text("MVP")
                                .font(.title2.bold())
                                .foregroundStyle(Color.mmAccentSecondary)
                            Text(improved.localizedName)
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                    }
                }

                Spacer()

                // フッター
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        // QRコード
                        if let qrImage = QRCodeGenerator.generate(from: AppConstants.appStoreURL) {
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
        .frame(width: 350, height: 550)
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

// MARK: - Preview

#Preview {
    MuscleJourneyView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

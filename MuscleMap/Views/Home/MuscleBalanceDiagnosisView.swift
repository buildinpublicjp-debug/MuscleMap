import SwiftUI
import SwiftData

// MARK: - 筋肉バランス診断画面

struct MuscleBalanceDiagnosisView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MuscleBalanceDiagnosisViewModel()
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if viewModel.isAnalyzing {
                    analyzingView
                } else if viewModel.hasResult {
                    resultView
                } else {
                    startView
                }
            }
            .navigationTitle(L10n.muscleBalanceDiagnosis)
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
            .sheet(isPresented: $showingShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [L10n.balanceDiagnosisShareText(viewModel.trainerType.localizedName, AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
                }
            }
        }
    }

    // MARK: - 開始画面

    private var startView: some View {
        VStack(spacing: 32) {
            Spacer()

            // アイコン
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(Color.mmAccentPrimary)

            // タイトル
            VStack(spacing: 8) {
                Text(L10n.muscleBalanceDiagnosis)
                    .font(.title.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                Text(L10n.diagnosisDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // 診断開始ボタン
            Button {
                Task {
                    await viewModel.runDiagnosis()
                }
            } label: {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text(L10n.startDiagnosis)
                }
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - 分析中画面

    private var analyzingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // アニメーション
            AnalyzingAnimation()

            Text(L10n.analyzing)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)

            Text(L10n.analyzingSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)

            Spacer()
        }
    }

    // MARK: - 結果画面

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // タイプ表示
                typeSection

                // データ不足の場合は早期リターン
                if viewModel.trainerType == .dataInsufficient {
                    dataInsufficientSection
                } else {
                    // バランス軸チャート
                    balanceAxesSection

                    // アドバイス
                    adviceSection

                    // シェアボタン
                    shareButton
                }

                // 再診断ボタン
                retryButton
            }
            .padding()
        }
    }

    // MARK: - タイプセクション

    private var typeSection: some View {
        VStack(spacing: 16) {
            // 絵文字
            Text(viewModel.trainerType.emoji)
                .font(.system(size: 60))

            // タイプ名
            Text(viewModel.trainerType.localizedName)
                .font(.title.bold())
                .foregroundStyle(Color.mmAccentPrimary)

            // 説明
            Text(viewModel.trainerType.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - データ不足セクション

    private var dataInsufficientSection: some View {
        VStack(spacing: 16) {
            Text(L10n.needMoreData)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)

            HStack {
                Text(L10n.currentSessions)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text("\(viewModel.totalSessions) / 10")
                    .font(.headline)
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    // MARK: - バランス軸セクション

    private var balanceAxesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.balanceAnalysis)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            ForEach(viewModel.balanceAxes, id: \.name) { axis in
                BalanceAxisBar(axis: axis)
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - アドバイスセクション

    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.mmAccentPrimary)
                Text(L10n.improvementAdvice)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }

            Text(viewModel.trainerType.localizedAdvice)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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
                Text(L10n.shareResult)
            }
            .font(.headline)
            .foregroundStyle(Color.mmBgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mmAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 再診断ボタン

    private var retryButton: some View {
        Button {
            viewModel.reset()
        } label: {
            Text(L10n.retryDiagnosis)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.bottom, 16)
    }

    // MARK: - シェア画像生成

    @MainActor
    private func prepareShareImage() {
        let shareCard = BalanceDiagnosisShareCard(
            trainerType: viewModel.trainerType,
            balanceAxes: viewModel.balanceAxes,
            totalSessions: viewModel.totalSessions
        )

        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 分析中アニメーション

private struct AnalyzingAnimation: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 外側の円
            Circle()
                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 4)
                .frame(width: 100, height: 100)

            // 回転する円弧
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.mmAccentPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(rotation))

            // 中央のアイコン
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 32))
                .foregroundStyle(Color.mmAccentPrimary)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - バランス軸バー

private struct BalanceAxisBar: View {
    let axis: BalanceAxis

    var body: some View {
        VStack(spacing: 8) {
            // ラベル
            HStack {
                Text(axis.leftLabel)
                    .font(.caption)
                    .foregroundStyle(axis.leftRatio > 0.5 ? Color.mmAccentPrimary : Color.mmTextSecondary)
                Spacer()
                Text(axis.rightLabel)
                    .font(.caption)
                    .foregroundStyle(axis.rightRatio > 0.5 ? Color.mmAccentPrimary : Color.mmTextSecondary)
            }

            // バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmBgSecondary)
                        .frame(height: 8)

                    // 左側（グリーン）
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmAccentPrimary)
                        .frame(width: geometry.size.width * axis.leftRatio, height: 8)

                    // 中央マーカー
                    Rectangle()
                        .fill(Color.mmTextSecondary)
                        .frame(width: 2, height: 16)
                        .offset(x: geometry.size.width * 0.5 - 1)
                }
            }
            .frame(height: 16)

            // パーセンテージ
            HStack {
                Text(String(format: "%.0f%%", axis.leftRatio * 100))
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                if axis.isBalanced {
                    Text("✓ " + L10n.balanced)
                        .font(.caption2)
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                Spacer()
                Text(String(format: "%.0f%%", axis.rightRatio * 100))
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
    }
}

// MARK: - シェアカード

private struct BalanceDiagnosisShareCard: View {
    let trainerType: TrainerType
    let balanceAxes: [BalanceAxis]
    let totalSessions: Int

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 20) {
                // ヘッダー（統一デザイン）
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // タイトル
                VStack(spacing: 4) {
                    Text("MUSCLE BALANCE")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(L10n.diagnosisResult)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                // タイプ（大きく表示）
                VStack(spacing: 12) {
                    Text(trainerType.emoji)
                        .font(.system(size: 70))
                    Text(trainerType.localizedName)
                        .font(.title.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                }

                // バランス軸（簡易版）
                VStack(spacing: 16) {
                    ForEach(balanceAxes, id: \.name) { axis in
                        ShareBalanceAxisBar(axis: axis)
                    }
                }
                .padding(.horizontal, 24)

                // セッション数
                Text("\(totalSessions) " + L10n.sessionsAnalyzed)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                Spacer()

                // フッター（シンプル）
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
    }
}

// MARK: - シェア用バランス軸バー

private struct ShareBalanceAxisBar: View {
    let axis: BalanceAxis

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(axis.leftLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Text(axis.rightLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.mmBgSecondary)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.mmAccentPrimary)
                        .frame(width: geometry.size.width * axis.leftRatio, height: 6)

                    Rectangle()
                        .fill(Color.mmTextSecondary.opacity(0.5))
                        .frame(width: 1, height: 10)
                        .offset(x: geometry.size.width * 0.5)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Preview

#Preview {
    MuscleBalanceDiagnosisView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

import SwiftUI
import UIKit

// MARK: - 全身制覇祝福画面

struct FullBodyConquestView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onShare: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    /// 全21部位の筋肉マッピング（シェアカード用）
    private var allMusclesMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        for muscle in Muscle.allCases {
            // 刺激済みの筋肉に高い刺激度を設定
            if let state = muscleStates[muscle], state != .inactive {
                mapping[muscle.rawValue] = 80
            }
        }
        return mapping
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            // Confetti アニメーション
            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 絵文字
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                // タイトル
                Text(L10n.fullBodyConquestTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // サブタイトル
                Text(L10n.fullBodyConquestSubtitle)
                    .font(.title3)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // 筋肉マップ表示
                ShareMuscleMapView(muscleMapping: allMusclesMapping)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                // シェアボタン
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
            if let image = renderedImage {
                ShareSheet(items: [L10n.fullBodyConquestShareText(AppConstants.shareHashtag, AppConstants.appStoreURL), image], onComplete: nil)
            }
        }
    }

    // MARK: - シェア用画像生成

    @MainActor
    private func prepareShareImage() {
        let shareCard = FullBodyConquestShareCard(muscleMapping: allMusclesMapping)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 全身制覇シェアカード

private struct FullBodyConquestShareCard: View {
    let muscleMapping: [String: Int]

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
                Spacer()

                // タイトル
                VStack(spacing: 8) {
                    Text("FULL BODY CONQUERED")
                        .font(.title2.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text("💪")
                        .font(.system(size: 50))
                }

                // 筋肉マップ
                VStack(spacing: 8) {
                    HStack(spacing: 40) {
                        Text("FRONT")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                            .frame(width: 140)
                        Text("BACK")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmTextSecondary)
                            .frame(width: 140)
                    }
                    ShareMuscleMapView(muscleMapping: muscleMapping)
                }

                // 達成メッセージ
                Text(L10n.allMusclesStimulated)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                // フッター
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)

                    HStack(spacing: 16) {
                        // QRコード
                        if let qrImage = QRCodeGenerator.generate(from: AppConstants.appStoreURL) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.fullBodyConquestAchieved)
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text(AppConstants.appName)
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

// MARK: - Confetti アニメーション

private struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var isAnimating = false

    private let colors: [Color] = [
        .mmAccentPrimary, .mmAccentSecondary,
        .mmMuscleCoral, .mmMuscleAmber, .mmMuscleLime,
        .yellow, .orange, .pink, .purple
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate

                for piece in confettiPieces {
                    let elapsed = now - piece.startTime
                    guard elapsed > 0 && elapsed < piece.duration else { continue }

                    let progress = elapsed / piece.duration
                    let x = piece.startX + piece.velocityX * CGFloat(elapsed) + sin(CGFloat(elapsed) * piece.wobbleFreq) * piece.wobbleAmp
                    let y = piece.startY + piece.velocityY * CGFloat(elapsed) + 0.5 * 500 * CGFloat(elapsed * elapsed)
                    let rotation = Angle(degrees: piece.rotation + piece.rotationSpeed * elapsed)
                    let opacity = 1.0 - pow(progress, 2)

                    guard y < size.height + 50 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height)
                    context.fill(Path(rect), with: .color(piece.color))

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .onAppear {
            confettiPieces = Self.createConfettiPieces(colors: colors)
        }
    }

    private static func createConfettiPieces(colors: [Color]) -> [ConfettiPiece] {
        let screenWidth = UIScreen.main.bounds.width
        var pieces: [ConfettiPiece] = []
        let now = Date().timeIntervalSinceReferenceDate

        for i in 0..<100 {
            let delay = Double(i) * 0.02
            pieces.append(ConfettiPiece(
                startTime: now + delay,
                duration: Double.random(in: 3...5),
                startX: CGFloat.random(in: 0...screenWidth),
                startY: -20,
                velocityX: CGFloat.random(in: -50...50),
                velocityY: CGFloat.random(in: 100...200),
                width: CGFloat.random(in: 8...15),
                height: CGFloat.random(in: 8...15),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                wobbleFreq: CGFloat.random(in: 2...5),
                wobbleAmp: CGFloat.random(in: 10...30)
            ))
        }

        return pieces
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let startTime: TimeInterval
    let duration: TimeInterval
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let rotation: Double
    let rotationSpeed: Double
    let wobbleFreq: CGFloat
    let wobbleAmp: CGFloat
}

// MARK: - 2回目以降用のバナー

struct FullBodyConquestBanner: View {
    let count: Int
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Text("🎉")
                    .font(.title2)

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
                    withAnimation {
                        isVisible = false
                    }
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

#Preview {
    FullBodyConquestView(
        muscleStates: Dictionary(uniqueKeysWithValues: Muscle.allCases.map { ($0, MuscleVisualState.recovering(progress: 0.3)) }),
        onShare: {},
        onDismiss: {}
    )
}

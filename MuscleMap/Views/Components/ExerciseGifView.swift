import SwiftUI
import UIKit

// MARK: - GIF表示サイズ

enum ExerciseGifSize {
    case fullWidth     // ExerciseDetailView用（アニメーション、maxHeight: 300）
    case previewCard   // ExercisePreviewSheet用（アニメーション、height: 120）
    case card          // MuscleDetailView カード型リスト用（静止画、height: 160）
    case thumbnail     // ExerciseLibraryView等のリスト行用（静止画、100x75）

    var shouldAnimate: Bool {
        self == .fullWidth || self == .previewCard
    }
}

// MARK: - ExerciseGifView

/// GymVisual GIFアニメーションを表示するコンポーネント
struct ExerciseGifView: View {
    let exerciseId: String
    let size: ExerciseGifSize

    var body: some View {
        if let gifData = Self.loadGifData(exerciseId: exerciseId) {
            switch size {
            case .fullWidth:
                // アニメーションGIF（ExerciseDetailView用 — AspectFitで全体表示）
                GifImageView(gifData: gifData, useFill: false)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 300)
                    .background(Color.mmGifBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mmBorder.opacity(0.3), lineWidth: 1)
                    )

            case .previewCard:
                // アニメーションGIF（ExercisePreviewSheet用 — Fillで黒帯なし）
                GifImageView(gifData: gifData, useFill: true)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.mmBorder.opacity(0.3), lineWidth: 1)
                    )

            case .card:
                // カード型サムネイル（グリッド用 — Fillで黒帯なし、frameは呼び出し元で指定）
                if let firstFrame = UIImage.gifFirstFrame(data: gifData) {
                    Image(uiImage: firstFrame)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }

            case .thumbnail:
                // リスト行用サムネイル（ExerciseLibraryView用）
                if let firstFrame = UIImage.gifFirstFrame(data: gifData) {
                    Image(uiImage: firstFrame)
                        .resizable()
                        .scaledToFill()
                        .padding(4)
                        .frame(width: 100, height: 75)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.mmBorder.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - GIFファイル存在チェック

    /// 指定されたexerciseIdに対応するGIFファイルが存在するかチェック
    static func hasGif(exerciseId: String) -> Bool {
        return loadGifData(exerciseId: exerciseId) != nil
    }

    // MARK: - GIFデータ読み込み

    private static func loadGifData(exerciseId: String) -> Data? {
        // exercises_gif/{exerciseId}.gif を探す
        guard let url = Bundle.main.url(
            forResource: exerciseId,
            withExtension: "gif",
            subdirectory: "exercises_gif"
        ) else {
            return nil
        }

        return try? Data(contentsOf: url)
    }
}

// MARK: - UIKit GIF ImageView (UIViewRepresentable) - アニメーション専用

private struct GifImageView: UIViewRepresentable {
    let gifData: Data
    var useFill: Bool = false

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = useFill ? .scaleAspectFill : .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        // Auto Layout対応: 親のサイズにフィット
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        if let animatedImage = UIImage.gif(data: gifData) {
            imageView.image = animatedImage
        }
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        // contentModeが変わった場合にも対応
        let expectedMode: UIView.ContentMode = useFill ? .scaleAspectFill : .scaleAspectFit
        if imageView.contentMode != expectedMode {
            imageView.contentMode = expectedMode
        }
    }

    /// 画面外でアニメーションを停止しメモリ解放
    static func dismantleUIView(_ imageView: UIImageView, coordinator: ()) {
        imageView.stopAnimating()
        imageView.image = nil
    }
}

// MARK: - UIImage GIF Extension

extension UIImage {
    /// GIFデータからアニメーション画像を生成
    static func gif(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var images: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))

                // フレームの表示時間を取得
                let frameDuration = UIImage.frameDuration(at: i, source: source)
                totalDuration += frameDuration
            }
        }

        guard !images.isEmpty else { return nil }

        // 最低限のアニメーション時間を確保
        if totalDuration < 0.1 {
            totalDuration = Double(count) * 0.1
        }

        return UIImage.animatedImage(with: images, duration: totalDuration)
    }

    /// GIFデータから最初のフレームのみ取得（静止画用）
    static func gifFirstFrame(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        guard CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// GIFフレームの表示時間を取得
    private static func frameDuration(at index: Int, source: CGImageSource) -> Double {
        let defaultDuration = 0.1

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return defaultDuration
        }

        // Unclamped delay time を優先、なければ通常の delay time
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double,
           unclampedDelay > 0 {
            return unclampedDelay
        }

        if let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double,
           delay > 0 {
            return delay
        }

        return defaultDuration
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                // Full width preview
                VStack {
                    Text("Full Width (animated)")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)

                    ExerciseGifView(exerciseId: "barbell_bench_press", size: .fullWidth)
                        .padding(.horizontal)
                }

                // Card size preview
                VStack {
                    Text("Card (160pt height)")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)

                    ExerciseGifView(exerciseId: "barbell_bench_press", size: .card)
                        .padding(.horizontal)
                }

                // Thumbnail size preview
                VStack {
                    Text("Thumbnail (100x75)")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)

                    ExerciseGifView(exerciseId: "barbell_bench_press", size: .thumbnail)
                }
            }
            .padding()
        }
    }
}

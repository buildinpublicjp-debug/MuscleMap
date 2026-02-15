import SwiftUI
import UIKit

// MARK: - GIF表示サイズ

enum ExerciseGifSize {
    case fullWidth  // 画面幅 - ExerciseDetailView用
    case large      // 200pt - 詳細プレビュー用
    case medium     // 150pt - ExercisePreviewSheet用
    case listRow    // 64pt - リスト行用（静止画）
    case thumbnail  // 48pt - 小さいサムネイル用（静止画）

    var dimension: CGFloat {
        switch self {
        case .fullWidth: return 280
        case .large: return 200
        case .medium: return 150
        case .listRow: return 64
        case .thumbnail: return 48
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .fullWidth: return 12
        case .large, .medium: return 12
        case .listRow: return 8
        case .thumbnail: return 6
        }
    }

    var shouldAnimate: Bool {
        switch self {
        case .fullWidth, .large, .medium: return true
        case .listRow, .thumbnail: return false
        }
    }
}

// MARK: - GIF背景色（白背景GIF用）
private let gifBackgroundColor = Color(white: 0.95)

// MARK: - ExerciseGifView

/// GymVisual GIFアニメーションを表示するコンポーネント
struct ExerciseGifView: View {
    let exerciseId: String
    let size: ExerciseGifSize

    var body: some View {
        if let gifData = Self.loadGifData(exerciseId: exerciseId) {
            // 全サイズ共通: アスペクト比を維持して全体表示
            // サイズ制御は呼び出し元に任せる
            GifImageView(
                gifData: gifData,
                animate: size.shouldAnimate
            )
            .aspectRatio(contentMode: .fit)
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

// MARK: - UIKit GIF ImageView (UIViewRepresentable)

private struct GifImageView: UIViewRepresentable {
    let gifData: Data
    let animate: Bool

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        if animate {
            // アニメーションGIF表示
            if let animatedImage = UIImage.gif(data: gifData) {
                imageView.image = animatedImage
            }
        } else {
            // 静止画（最初のフレーム）
            if let staticImage = UIImage.gifFirstFrame(data: gifData) {
                imageView.image = staticImage
            }
        }
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
                    Text("Full Width")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)

                    ExerciseGifView(exerciseId: "barbell_bench_press", size: .fullWidth)
                        .padding(.horizontal)
                }

                // List row size preview
                VStack {
                    Text("List Row (80pt)")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)

                    ExerciseGifView(exerciseId: "barbell_bench_press", size: .listRow)
                }

                // Thumbnail size preview
                VStack {
                    Text("Thumbnail (56pt)")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)

                    ExerciseGifView(exerciseId: "barbell_bench_press", size: .thumbnail)
                }
            }
            .padding()
        }
    }
}

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - QRコード生成ユーティリティ

struct QRCodeGenerator {
    private static let context = CIContext()

    /// QRコードを生成する
    /// - Parameters:
    ///   - string: エンコードする文字列
    ///   - size: 出力サイズ（デフォルト80pt）
    /// - Returns: 生成されたQRコード画像（失敗時はnil）
    static func generate(from string: String, size: CGFloat = 80) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        let scale = size / outputImage.extent.size.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

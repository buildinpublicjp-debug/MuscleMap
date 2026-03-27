import Foundation
import SwiftData
import UIKit

// MARK: - プログレスフォトモデル

@Model
class ProgressPhoto {
    var id: UUID
    var captureDate: Date
    var imagePath: String
    var sessionId: UUID?
    var note: String?

    init(captureDate: Date = Date(), imagePath: String, sessionId: UUID? = nil, note: String? = nil) {
        self.id = UUID()
        self.captureDate = captureDate
        self.imagePath = imagePath
        self.sessionId = sessionId
        self.note = note
    }

    /// Documents内の完全パスを取得
    var fullImageURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(imagePath)
    }

    /// 画像ファイルを削除
    func deleteImageFile() {
        guard let url = fullImageURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - ヘルパー

    /// progress_photos ディレクトリを確保し、JPEG保存してパスを返す
    static func savePhoto(_ image: UIImage, sessionId: UUID?) -> String? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let dir = docs.appendingPathComponent("progress_photos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "\(formatter.string(from: Date())).jpg"
        let filePath = dir.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: filePath)
            return "progress_photos/\(filename)"
        } catch {
            return nil
        }
    }

    /// 最後の写真撮影からの日数
    static func daysSinceLastPhoto(context: ModelContext) -> Int? {
        var descriptor = FetchDescriptor<ProgressPhoto>(
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let lastPhoto = try? context.fetch(descriptor).first else { return nil }
        return Calendar.current.dateComponents([.day], from: lastPhoto.captureDate, to: Date()).day
    }
}

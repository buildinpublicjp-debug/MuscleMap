import Foundation
import Vision
import UIKit

// MARK: - 画像認識パーサー

/// 画像からワークアウトデータを抽出
struct ImageRecognitionParser {

    // MARK: - 正規表現パターン

    /// 重量パターン: 60kg, 60KG, 60キロ, 135lb など
    private static let weightPattern = #"(\d+\.?\d*)\s*(kg|KG|キロ|lb|LB|lbs|LBS|ポンド)"#

    /// 回数パターン: 10rep, 10reps, 10回, ×10, x10 など
    private static let repsPattern = #"(\d+)\s*(reps|rep|REPS|REP|回)"#

    /// 回数パターン（×/x形式）: ×10, x10, X10
    private static let repsAltPattern = #"[×xX]\s*(\d+)"#

    /// セットパターン: 3set, 3sets, 3セット など
    private static let setPattern = #"(\d+)\s*(set|sets|セット|SET|SETS)"#

    /// 日付パターン: 2026/1/18, 2026-01-18, 1/18 など
    private static let datePattern = #"(\d{4})?[/\-年]?(\d{1,2})[/\-月](\d{1,2})日?"#

    // MARK: - メイン処理

    /// 画像からテキストを抽出してパース
    static func parse(image: UIImage) async throws -> [ParsedWorkout] {
        let recognizedText = try await extractText(from: image)
        return parseText(recognizedText)
    }

    /// CGImageからテキストを抽出してパース
    static func parse(cgImage: CGImage) async throws -> [ParsedWorkout] {
        let recognizedText = try await extractText(from: cgImage)
        return parseText(recognizedText)
    }

    // MARK: - テキスト抽出（Vision Framework）

    /// UIImageからテキストを抽出
    static func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ImageRecognitionError.invalidImage
        }
        return try await extractText(from: cgImage)
    }

    /// CGImageからテキストを抽出
    static func extractText(from cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // 認識設定
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - テキストパース

    /// 抽出されたテキストをパースしてワークアウトデータに変換
    static func parseText(_ text: String) -> [ParsedWorkout] {
        let lines = text.components(separatedBy: .newlines)
        var workouts: [ParsedWorkout] = []
        var currentExercises: [ParsedExercise] = []
        var currentDate = Date()
        var foundDate = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            // 日付を検出
            if let date = extractDate(from: trimmedLine) {
                // 前のワークアウトを保存
                if foundDate && !currentExercises.isEmpty {
                    workouts.append(ParsedWorkout(
                        date: currentDate,
                        muscleGroup: nil,
                        exercises: currentExercises
                    ))
                    currentExercises = []
                }
                currentDate = date
                foundDate = true
                continue
            }

            // セット情報を抽出
            if let setInfo = extractSetInfo(from: trimmedLine) {
                // 種目名を推定（行の先頭部分）
                let exerciseName = extractExerciseName(from: trimmedLine) ?? "不明な種目"

                // 同じ種目が既にあれば追加、なければ新規作成
                if let index = currentExercises.firstIndex(where: { $0.name == exerciseName }) {
                    var exercise = currentExercises[index]
                    var sets = exercise.sets
                    sets.append(contentsOf: setInfo.sets)
                    currentExercises[index] = ParsedExercise(name: exerciseName, sets: sets)
                } else {
                    currentExercises.append(ParsedExercise(name: exerciseName, sets: setInfo.sets))
                }
            }
        }

        // 最後のワークアウトを保存
        if !currentExercises.isEmpty {
            workouts.append(ParsedWorkout(
                date: currentDate,
                muscleGroup: nil,
                exercises: currentExercises
            ))
        }

        return workouts.sorted { $0.date < $1.date }
    }

    // MARK: - 抽出ヘルパー

    /// 日付を抽出
    static func extractDate(from text: String) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: datePattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        var year = Calendar.current.component(.year, from: Date())
        var month = 1
        var day = 1

        // 年（オプション）
        if let yearRange = Range(match.range(at: 1), in: text),
           let yearValue = Int(text[yearRange]) {
            year = yearValue
        }

        // 月
        if let monthRange = Range(match.range(at: 2), in: text),
           let monthValue = Int(text[monthRange]) {
            month = monthValue
        }

        // 日
        if let dayRange = Range(match.range(at: 3), in: text),
           let dayValue = Int(text[dayRange]) {
            day = dayValue
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        return Calendar.current.date(from: components)
    }

    /// 重量を抽出
    static func extractWeight(from text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: weightPattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        guard let valueRange = Range(match.range(at: 1), in: text),
              let value = Double(text[valueRange]) else {
            return nil
        }

        // 単位を確認（lb/LBならkgに変換）
        if let unitRange = Range(match.range(at: 2), in: text) {
            let unit = text[unitRange].lowercased()
            if unit.contains("lb") || unit.contains("ポンド") {
                return value * 0.453592 // lb → kg
            }
        }

        return value
    }

    /// 回数を抽出
    static func extractReps(from text: String) -> Int? {
        // パターン1: 10rep, 10回 など
        if let regex = try? NSRegularExpression(pattern: repsPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: text),
               let value = Int(text[valueRange]) {
                return value
            }
        }

        // パターン2: ×10, x10 など
        if let regex = try? NSRegularExpression(pattern: repsAltPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: text),
               let value = Int(text[valueRange]) {
                return value
            }
        }

        return nil
    }

    /// セット数を抽出
    static func extractSetCount(from text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: setPattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: text),
              let value = Int(text[valueRange]) else {
            return nil
        }

        return value
    }

    /// セット情報をまとめて抽出
    static func extractSetInfo(from text: String) -> (sets: [ParsedSet], confidence: Double)? {
        let weight = extractWeight(from: text)
        let reps = extractReps(from: text)
        let setCount = extractSetCount(from: text) ?? 1

        // 重量または回数が見つからない場合はスキップ
        guard weight != nil || reps != nil else {
            return nil
        }

        // 信頼度を計算
        var confidence = 0.0
        if weight != nil { confidence += 0.4 }
        if reps != nil { confidence += 0.4 }
        if setCount > 1 { confidence += 0.2 }

        // セットを生成
        var sets: [ParsedSet] = []
        for _ in 0..<setCount {
            sets.append(ParsedSet(
                weight: weight ?? 0,
                reps: reps ?? 0
            ))
        }

        return (sets: sets, confidence: confidence)
    }

    /// 種目名を抽出
    static func extractExerciseName(from text: String) -> String? {
        // 数字や単位を除去して種目名を推定
        var cleanedText = text

        // 重量パターンを除去
        if let regex = try? NSRegularExpression(pattern: weightPattern, options: []) {
            cleanedText = regex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: NSRange(cleanedText.startIndex..., in: cleanedText),
                withTemplate: ""
            )
        }

        // 回数パターンを除去
        if let regex = try? NSRegularExpression(pattern: repsPattern, options: []) {
            cleanedText = regex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: NSRange(cleanedText.startIndex..., in: cleanedText),
                withTemplate: ""
            )
        }

        // ×/x形式を除去（数字も含めて）
        if let regex = try? NSRegularExpression(pattern: repsAltPattern, options: []) {
            cleanedText = regex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: NSRange(cleanedText.startIndex..., in: cleanedText),
                withTemplate: ""
            )
        }

        // セットパターンを除去
        if let regex = try? NSRegularExpression(pattern: setPattern, options: []) {
            cleanedText = regex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: NSRange(cleanedText.startIndex..., in: cleanedText),
                withTemplate: ""
            )
        }

        // 残った数字を除去
        if let regex = try? NSRegularExpression(pattern: #"\d+"#, options: []) {
            cleanedText = regex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: NSRange(cleanedText.startIndex..., in: cleanedText),
                withTemplate: ""
            )
        }

        // 記号を除去（×, x, Xも含む）
        cleanedText = cleanedText.replacingOccurrences(of: ":", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "-", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: "・", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "×", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: ",", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: ".", with: "")

        // 複数スペースを1つにまとめる
        while cleanedText.contains("  ") {
            cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        }

        // トリム
        cleanedText = cleanedText.trimmingCharacters(in: .whitespaces)

        return cleanedText.isEmpty ? nil : cleanedText
    }
}

// MARK: - エラー

enum ImageRecognitionError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像を読み込めませんでした"
        case .recognitionFailed(let message):
            return "テキスト認識に失敗しました: \(message)"
        }
    }
}

// MARK: - 認識結果

struct RecognizedWorkoutData {
    let rawText: String
    let workouts: [ParsedWorkout]
    let confidence: Double

    var isEmpty: Bool {
        workouts.isEmpty || workouts.allSatisfy { $0.exercises.isEmpty }
    }

    var summary: String {
        let workoutCount = workouts.count
        let exerciseCount = workouts.flatMap { $0.exercises }.count
        let setCount = workouts.flatMap { $0.exercises }.flatMap { $0.sets }.count

        return "\(workoutCount)件のワークアウト、\(exerciseCount)種目、\(setCount)セットを検出"
    }
}

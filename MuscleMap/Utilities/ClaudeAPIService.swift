import Foundation

// MARK: - Claude API Service for Image Recognition

struct ClaudeAPIService {

    private static let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private static let model = "claude-3-5-haiku-latest"

    /// 画像からワークアウトデータを解析
    static func parseWorkoutImage(
        imageData: Data,
        apiKey: String
    ) async throws -> [ParsedWorkout] {

        // Base64エンコード
        let base64Image = imageData.base64EncodedString()

        // メディアタイプを推測（JPEGとPNGをサポート）
        let mediaType = detectMediaType(from: imageData)

        // リクエストボディを構築
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": mediaType,
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": buildPrompt()
                        ]
                    ]
                ]
            ]
        ]

        // リクエスト作成
        guard let url = URL(string: apiEndpoint) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // API呼び出し
        let (data, response) = try await URLSession.shared.data(for: request)

        // レスポンスチェック
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ClaudeAPIError.apiError(statusCode: httpResponse.statusCode, message: message)
            }
            throw ClaudeAPIError.apiError(statusCode: httpResponse.statusCode, message: "Unknown error")
        }

        // レスポンス解析
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ClaudeAPIError.parseError
        }

        // JSONを抽出して解析
        return try parseWorkoutsFromResponse(text)
    }

    // MARK: - Private Methods

    private static func buildPrompt() -> String {
        """
        この画像はトレーニング記録のスクリーンショットです。
        以下のJSON形式で、すべてのワークアウトデータを抽出してください。

        ```json
        {
          "workouts": [
            {
              "date": "2024-01-15",
              "exercises": [
                {
                  "name": "ベンチプレス",
                  "sets": [
                    {"weight": 60.0, "reps": 10},
                    {"weight": 70.0, "reps": 8}
                  ]
                }
              ]
            }
          ]
        }
        ```

        注意事項:
        - 日付が見つからない場合は今日の日付を使用
        - 重量の単位はkgで統一
        - セット数、レップ数は整数
        - 種目名は日本語のまま抽出
        - 画像に複数日のデータがある場合はすべて含める
        - JSONのみを出力（説明文は不要）
        """
    }

    private static func detectMediaType(from data: Data) -> String {
        // PNGシグネチャ: 89 50 4E 47
        if data.count >= 4 {
            let bytes = [UInt8](data.prefix(4))
            if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
                return "image/png"
            }
        }
        // デフォルトはJPEG
        return "image/jpeg"
    }

    private static func parseWorkoutsFromResponse(_ text: String) throws -> [ParsedWorkout] {
        // JSONブロックを抽出（```json ... ``` または直接JSON）
        var jsonString = text

        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            jsonString = String(text[jsonStart.upperBound..<jsonEnd.lowerBound])
        } else if let jsonStart = text.range(of: "{"),
                  let jsonEnd = text.range(of: "}", options: .backwards) {
            jsonString = String(text[jsonStart.lowerBound...jsonEnd.upperBound])
        }

        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let workoutsArray = json["workouts"] as? [[String: Any]] else {
            throw ClaudeAPIError.parseError
        }

        var result: [ParsedWorkout] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for workoutDict in workoutsArray {
            let dateString = workoutDict["date"] as? String ?? ""
            let date = dateFormatter.date(from: dateString) ?? Date()

            var exercises: [ParsedExercise] = []

            if let exercisesArray = workoutDict["exercises"] as? [[String: Any]] {
                for exerciseDict in exercisesArray {
                    let name = exerciseDict["name"] as? String ?? ""
                    var sets: [ParsedSet] = []

                    if let setsArray = exerciseDict["sets"] as? [[String: Any]] {
                        for setDict in setsArray {
                            let weight = setDict["weight"] as? Double ?? 0
                            let reps = setDict["reps"] as? Int ?? 0
                            sets.append(ParsedSet(weight: weight, reps: reps))
                        }
                    }

                    if !name.isEmpty && !sets.isEmpty {
                        exercises.append(ParsedExercise(name: name, sets: sets))
                    }
                }
            }

            if !exercises.isEmpty {
                result.append(ParsedWorkout(
                    date: date,
                    muscleGroup: nil,
                    exercises: exercises
                ))
            }
        }

        return result
    }
}

// MARK: - Errors

enum ClaudeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .parseError:
            return "Failed to parse response"
        case .noAPIKey:
            return "API key not configured"
        }
    }
}

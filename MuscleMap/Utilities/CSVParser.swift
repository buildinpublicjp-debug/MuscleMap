import Foundation

// MARK: - CSV パーサー (Strong/Hevy互換)

struct CSVParser {
    /// CSV形式を検出
    enum CSVFormat {
        case strongHevy  // Date,Exercise,Weight (kg),Reps,Sets
        case unknown
    }

    /// CSVテキストをパースして[ParsedWorkout]を返す
    static func parse(_ text: String) -> [ParsedWorkout] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count > 1 else { return [] }

        let header = lines[0].lowercased()
        let format = detectFormat(header)

        switch format {
        case .strongHevy:
            return parseStrongHevy(lines: Array(lines.dropFirst()))
        case .unknown:
            return []
        }
    }

    /// CSVフォーマットを検証して形式を返す
    static func detectFormat(_ header: String) -> CSVFormat {
        let lowercased = header.lowercased()
        // Strong/Hevy: Date,Exercise,Weight (kg),Reps,Sets または類似
        if lowercased.contains("date") &&
           lowercased.contains("exercise") &&
           (lowercased.contains("weight") || lowercased.contains("kg")) &&
           lowercased.contains("reps") {
            return .strongHevy
        }
        return .unknown
    }

    // MARK: - Private

    private static func parseStrongHevy(lines: [String]) -> [ParsedWorkout] {
        // 日付 → [種目名 → セット配列]
        var workoutsByDate: [Date: [String: [ParsedSet]]] = [:]

        for line in lines {
            let columns = parseCSVLine(line)
            guard columns.count >= 4 else { continue }

            // Date,Exercise,Weight (kg),Reps,Sets
            let dateString = columns[0]
            let exerciseName = columns[1]
            let weightString = columns[2]
            let repsString = columns[3]
            let setsCount = columns.count > 4 ? Int(columns[4]) ?? 1 : 1

            guard let date = parseDate(dateString),
                  let weight = Double(weightString.replacingOccurrences(of: ",", with: ".")),
                  let reps = Int(repsString) else {
                continue
            }

            let dayStart = Calendar.current.startOfDay(for: date)

            if workoutsByDate[dayStart] == nil {
                workoutsByDate[dayStart] = [:]
            }

            if workoutsByDate[dayStart]?[exerciseName] == nil {
                workoutsByDate[dayStart]?[exerciseName] = []
            }

            // setsCountが指定されている場合、その数だけセットを追加
            for _ in 0..<setsCount {
                workoutsByDate[dayStart]?[exerciseName]?.append(
                    ParsedSet(weight: weight, reps: reps)
                )
            }
        }

        // ParsedWorkoutに変換
        return workoutsByDate.map { date, exercisesDict in
            let exercises = exercisesDict.map { name, sets in
                ParsedExercise(name: name, sets: sets)
            }
            return ParsedWorkout(date: date, muscleGroup: nil, exercises: exercises)
        }.sorted { $0.date < $1.date }
    }

    /// CSVの1行をパース（カンマ区切り、ダブルクォート対応）
    private static func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        columns.append(current.trimmingCharacters(in: .whitespaces))

        return columns
    }

    /// 日付文字列をパース（複数フォーマット対応）
    private static func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            createFormatter("yyyy-MM-dd"),
            createFormatter("yyyy/MM/dd"),
            createFormatter("MM/dd/yyyy"),
            createFormatter("dd/MM/yyyy"),
            createFormatter("yyyy-MM-dd HH:mm:ss"),
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    private static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

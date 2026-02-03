import Foundation

// MARK: - Obsidian Markdown パーサー

/// パース結果の1日分のワークアウト
struct ParsedWorkout {
    let date: Date
    let muscleGroup: String?
    let exercises: [ParsedExercise]
}

/// パース結果の1種目
struct ParsedExercise {
    let name: String
    let sets: [ParsedSet]
}

/// パース結果の1セット
struct ParsedSet {
    let weight: Double  // マイナス = アシスト
    let reps: Int
}

// MARK: - MarkdownParser

struct MarkdownParser {
    // 日付パターン: ### YYYY/M/D（部位）
    private static let datePattern = #"###\s*(\d{4})/(\d{1,2})/(\d{1,2})(?:（([^）]+)）)?"#
    // 種目パターン: - 種目名: セットデータ
    private static let exercisePattern = #"^-\s*(.+?):\s*(.+)$"#
    // セットパターン: 数値kg×数値回 or -数値kg×数値回
    private static let setPattern = #"(-?\d+(?:\.\d+)?)\s*kg\s*[×x]\s*(\d+)回?"#

    /// Markdownテキストをパースして[ParsedWorkout]を返す
    static func parse(_ text: String) -> [ParsedWorkout] {
        var workouts: [ParsedWorkout] = []
        var currentDate: Date?
        var currentGroup: String?
        var currentExercises: [ParsedExercise] = []

        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 日付ヘッダー検出
            if let dateMatch = parseDate(trimmed) {
                // 前のワークアウトを保存
                if let date = currentDate, !currentExercises.isEmpty {
                    workouts.append(ParsedWorkout(
                        date: date,
                        muscleGroup: currentGroup,
                        exercises: currentExercises
                    ))
                }
                currentDate = dateMatch.date
                currentGroup = dateMatch.group
                currentExercises = []
                continue
            }

            // 種目行検出
            if let exercise = parseExercise(trimmed) {
                currentExercises.append(exercise)
            }
        }

        // 最後のワークアウトを保存
        if let date = currentDate, !currentExercises.isEmpty {
            workouts.append(ParsedWorkout(
                date: date,
                muscleGroup: currentGroup,
                exercises: currentExercises
            ))
        }

        return workouts
    }

    // MARK: - Private

    private static func parseDate(_ line: String) -> (date: Date, group: String?)? {
        guard let regex = try? NSRegularExpression(pattern: datePattern, options: []),
              let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard let yearRange = Range(match.range(at: 1), in: line),
              let monthRange = Range(match.range(at: 2), in: line),
              let dayRange = Range(match.range(at: 3), in: line),
              let year = Int(line[yearRange]),
              let month = Int(line[monthRange]),
              let day = Int(line[dayRange]) else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12  // デフォルト正午

        guard let date = Calendar.current.date(from: components) else {
            return nil
        }

        // 部位を取得（オプション）
        var group: String? = nil
        if match.range(at: 4).location != NSNotFound,
           let groupRange = Range(match.range(at: 4), in: line) {
            group = String(line[groupRange])
        }

        return (date, group)
    }

    private static func parseExercise(_ line: String) -> ParsedExercise? {
        guard let regex = try? NSRegularExpression(pattern: exercisePattern, options: []),
              let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard let nameRange = Range(match.range(at: 1), in: line),
              let setsRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
        let setsString = String(line[setsRange])
        let sets = parseSets(setsString)

        guard !sets.isEmpty else { return nil }

        return ParsedExercise(name: name, sets: sets)
    }

    private static func parseSets(_ text: String) -> [ParsedSet] {
        var sets: [ParsedSet] = []

        guard let regex = try? NSRegularExpression(pattern: setPattern, options: []) else {
            return sets
        }

        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

        for match in matches {
            guard let weightRange = Range(match.range(at: 1), in: text),
                  let repsRange = Range(match.range(at: 2), in: text),
                  let weight = Double(text[weightRange]),
                  let reps = Int(text[repsRange]) else {
                continue
            }

            sets.append(ParsedSet(weight: weight, reps: reps))
        }

        // "×4回" のような複数セット表記の検出
        // 例: "-18kg×4回" は1セット4レップではなく4セットの場合がある
        // → 仕様に基づき1セット4レップとして扱う（カンマ区切りで複数セット）

        return sets
    }
}

// MARK: - テスト用ヘルパー

extension ParsedWorkout: Equatable {
    static func == (lhs: ParsedWorkout, rhs: ParsedWorkout) -> Bool {
        lhs.date == rhs.date &&
        lhs.muscleGroup == rhs.muscleGroup &&
        lhs.exercises == rhs.exercises
    }
}

extension ParsedExercise: Equatable {}
extension ParsedSet: Equatable {}

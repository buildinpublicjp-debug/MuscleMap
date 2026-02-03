import XCTest
@testable import MuscleMap

final class MarkdownParserTests: XCTestCase {

    // MARK: - 正常フォーマット

    func test_パース_正常フォーマット() {
        let markdown = """
        ### 2026/1/18（背中）
        - ラットプルダウン: 68kg×21回, 75kg×8回
        - シーテッドロー: 73kg×8回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].muscleGroup, "背中")
        XCTAssertEqual(result[0].exercises.count, 2)

        // ラットプルダウン
        XCTAssertEqual(result[0].exercises[0].name, "ラットプルダウン")
        XCTAssertEqual(result[0].exercises[0].sets.count, 2)
        XCTAssertEqual(result[0].exercises[0].sets[0].weight, 68)
        XCTAssertEqual(result[0].exercises[0].sets[0].reps, 21)
        XCTAssertEqual(result[0].exercises[0].sets[1].weight, 75)
        XCTAssertEqual(result[0].exercises[0].sets[1].reps, 8)

        // シーテッドロー
        XCTAssertEqual(result[0].exercises[1].name, "シーテッドロー")
        XCTAssertEqual(result[0].exercises[1].sets.count, 1)
    }

    func test_パース_複数日() {
        let markdown = """
        ### 2026/1/18（背中）
        - ラットプルダウン: 68kg×21回

        ### 2026/1/16（足）
        - レッグプレス: 182.5kg×11回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].muscleGroup, "背中")
        XCTAssertEqual(result[1].muscleGroup, "足")
    }

    // MARK: - マイナス重量（アシスト種目）

    func test_パース_マイナス重量() {
        let markdown = """
        ### 2026/1/18（背中）
        - アシストチンニング: -27kg×10回, -18kg×4回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].exercises[0].sets.count, 2)
        XCTAssertEqual(result[0].exercises[0].sets[0].weight, -27)
        XCTAssertEqual(result[0].exercises[0].sets[0].reps, 10)
        XCTAssertEqual(result[0].exercises[0].sets[1].weight, -18)
        XCTAssertEqual(result[0].exercises[0].sets[1].reps, 4)
    }

    // MARK: - 日付フォーマットのバリエーション

    func test_パース_日付1桁月() {
        let markdown = """
        ### 2026/1/5（胸）
        - ベンチプレス: 60kg×10回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 1)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: result[0].date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 5)
    }

    func test_パース_日付2桁月日() {
        let markdown = """
        ### 2026/12/25（胸）
        - ベンチプレス: 60kg×10回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 1)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: result[0].date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }

    // MARK: - 部位なし

    func test_パース_部位なし() {
        let markdown = """
        ### 2026/1/18
        - ベンチプレス: 60kg×10回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result[0].muscleGroup)
    }

    // MARK: - PR表記は無視

    func test_パース_PR表記は無視() {
        let markdown = """
        ### 2026/1/18（背中）⬆️PR更新
        - ラットプルダウン: 75kg×8回（PR）
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].exercises[0].sets[0].weight, 75)
        XCTAssertEqual(result[0].exercises[0].sets[0].reps, 8)
    }

    // MARK: - 小数点重量

    func test_パース_小数点重量() {
        let markdown = """
        ### 2026/1/16（足）
        - レッグプレス: 182.5kg×11回
        """

        let result = MarkdownParser.parse(markdown)

        XCTAssertEqual(result[0].exercises[0].sets[0].weight, 182.5)
    }

    // MARK: - 空のマークダウン

    func test_パース_空の文字列() {
        let result = MarkdownParser.parse("")
        XCTAssertTrue(result.isEmpty)
    }

    func test_パース_ワークアウトなし() {
        let markdown = """
        # 今日のメモ

        何もしなかった
        """

        let result = MarkdownParser.parse(markdown)
        XCTAssertTrue(result.isEmpty)
    }
}

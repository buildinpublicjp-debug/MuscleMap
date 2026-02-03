import XCTest
@testable import MuscleMap

final class ImageRecognitionParserTests: XCTestCase {

    // MARK: - 重量抽出

    func test_重量抽出_kg() {
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "60kg"), 60)
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "60KG"), 60)
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "60 kg"), 60)
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "ベンチプレス 60kg"), 60)
    }

    func test_重量抽出_小数点() {
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "62.5kg"), 62.5)
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "12.5 kg"), 12.5)
    }

    func test_重量抽出_キロ() {
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "60キロ"), 60)
        XCTAssertEqual(ImageRecognitionParser.extractWeight(from: "80 キロ"), 80)
    }

    func test_重量抽出_lb() {
        // lb → kg 変換（1 lb = 0.453592 kg）
        let result = ImageRecognitionParser.extractWeight(from: "135lb")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 135 * 0.453592, accuracy: 0.01)
    }

    func test_重量抽出_lbs() {
        let result = ImageRecognitionParser.extractWeight(from: "225 lbs")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 225 * 0.453592, accuracy: 0.01)
    }

    func test_重量抽出_なし() {
        XCTAssertNil(ImageRecognitionParser.extractWeight(from: "ベンチプレス"))
        XCTAssertNil(ImageRecognitionParser.extractWeight(from: "10回"))
    }

    // MARK: - 回数抽出

    func test_回数抽出_rep() {
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "10rep"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "10reps"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "10 reps"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "10REP"), 10)
    }

    func test_回数抽出_回() {
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "10回"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "12 回"), 12)
    }

    func test_回数抽出_x形式() {
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "×10"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "x10"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "X10"), 10)
        XCTAssertEqual(ImageRecognitionParser.extractReps(from: "× 8"), 8)
    }

    func test_回数抽出_なし() {
        XCTAssertNil(ImageRecognitionParser.extractReps(from: "ベンチプレス"))
        XCTAssertNil(ImageRecognitionParser.extractReps(from: "60kg"))
    }

    // MARK: - セット数抽出

    func test_セット数抽出_set() {
        XCTAssertEqual(ImageRecognitionParser.extractSetCount(from: "3set"), 3)
        XCTAssertEqual(ImageRecognitionParser.extractSetCount(from: "3sets"), 3)
        XCTAssertEqual(ImageRecognitionParser.extractSetCount(from: "3 sets"), 3)
        XCTAssertEqual(ImageRecognitionParser.extractSetCount(from: "3SET"), 3)
    }

    func test_セット数抽出_セット() {
        XCTAssertEqual(ImageRecognitionParser.extractSetCount(from: "3セット"), 3)
        XCTAssertEqual(ImageRecognitionParser.extractSetCount(from: "5 セット"), 5)
    }

    func test_セット数抽出_なし() {
        XCTAssertNil(ImageRecognitionParser.extractSetCount(from: "ベンチプレス"))
        XCTAssertNil(ImageRecognitionParser.extractSetCount(from: "60kg"))
    }

    // MARK: - 日付抽出

    func test_日付抽出_スラッシュ形式() {
        let date = ImageRecognitionParser.extractDate(from: "2026/1/18")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 18)
    }

    func test_日付抽出_ハイフン形式() {
        let date = ImageRecognitionParser.extractDate(from: "2026-01-18")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 18)
    }

    func test_日付抽出_日本語形式() {
        let date = ImageRecognitionParser.extractDate(from: "2026年1月18日")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 18)
    }

    func test_日付抽出_年なし() {
        let date = ImageRecognitionParser.extractDate(from: "1/18")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, Calendar.current.component(.year, from: Date()))
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 18)
    }

    // MARK: - 種目名抽出

    func test_種目名抽出_基本() {
        XCTAssertEqual(
            ImageRecognitionParser.extractExerciseName(from: "ベンチプレス 60kg×10回"),
            "ベンチプレス"
        )
    }

    func test_種目名抽出_英語() {
        XCTAssertEqual(
            ImageRecognitionParser.extractExerciseName(from: "Bench Press 60kg 10reps"),
            "Bench Press"
        )
    }

    func test_種目名抽出_数字のみ() {
        XCTAssertNil(ImageRecognitionParser.extractExerciseName(from: "60kg×10回"))
    }

    // MARK: - セット情報抽出

    func test_セット情報抽出_基本() {
        let result = ImageRecognitionParser.extractSetInfo(from: "60kg×10回 3セット")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.sets.count, 3)
        XCTAssertEqual(result!.sets[0].weight, 60)
        XCTAssertEqual(result!.sets[0].reps, 10)
    }

    func test_セット情報抽出_セット数なし() {
        let result = ImageRecognitionParser.extractSetInfo(from: "60kg×10回")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.sets.count, 1) // デフォルト1セット
    }

    func test_セット情報抽出_重量のみ() {
        let result = ImageRecognitionParser.extractSetInfo(from: "60kg")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.sets[0].weight, 60)
        XCTAssertEqual(result!.sets[0].reps, 0)
    }

    func test_セット情報抽出_回数のみ() {
        let result = ImageRecognitionParser.extractSetInfo(from: "10回")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.sets[0].weight, 0)
        XCTAssertEqual(result!.sets[0].reps, 10)
    }

    func test_セット情報抽出_なし() {
        let result = ImageRecognitionParser.extractSetInfo(from: "ベンチプレス")
        XCTAssertNil(result)
    }

    // MARK: - テキストパース

    func test_テキストパース_基本() {
        let text = """
        2026/1/18
        ベンチプレス 60kg×10回 3セット
        スクワット 80kg×8回 3セット
        """

        let result = ImageRecognitionParser.parseText(text)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].exercises.count, 2)
    }

    func test_テキストパース_複数日() {
        let text = """
        2026/1/18
        ベンチプレス 60kg×10回

        2026/1/19
        スクワット 80kg×8回
        """

        let result = ImageRecognitionParser.parseText(text)

        XCTAssertEqual(result.count, 2)
    }

    func test_テキストパース_日付なし() {
        let text = """
        ベンチプレス 60kg×10回
        """

        let result = ImageRecognitionParser.parseText(text)

        XCTAssertEqual(result.count, 1)
        // 日付は今日として扱われる
    }

    func test_テキストパース_空() {
        let result = ImageRecognitionParser.parseText("")
        XCTAssertTrue(result.isEmpty)
    }

    func test_テキストパース_データなし() {
        let text = """
        今日のトレーニング
        頑張った！
        """

        let result = ImageRecognitionParser.parseText(text)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - RecognizedWorkoutData

    func test_RecognizedWorkoutData_summary() {
        let workouts = [
            ParsedWorkout(
                date: Date(),
                muscleGroup: nil,
                exercises: [
                    ParsedExercise(name: "ベンチプレス", sets: [
                        ParsedSet(weight: 60, reps: 10),
                        ParsedSet(weight: 60, reps: 10),
                        ParsedSet(weight: 60, reps: 10)
                    ]),
                    ParsedExercise(name: "スクワット", sets: [
                        ParsedSet(weight: 80, reps: 8)
                    ])
                ]
            )
        ]

        let data = RecognizedWorkoutData(
            rawText: "test",
            workouts: workouts,
            confidence: 0.8
        )

        XCTAssertEqual(data.summary, "1件のワークアウト、2種目、4セットを検出")
        XCTAssertFalse(data.isEmpty)
    }

    func test_RecognizedWorkoutData_isEmpty() {
        let data = RecognizedWorkoutData(
            rawText: "test",
            workouts: [],
            confidence: 0
        )

        XCTAssertTrue(data.isEmpty)
    }
}

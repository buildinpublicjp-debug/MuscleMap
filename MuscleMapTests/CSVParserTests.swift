import XCTest
@testable import MuscleMap

final class CSVParserTests: XCTestCase {

    // MARK: - Strong/Hevy形式

    func test_パース_Strong形式() {
        let csv = """
        Date,Exercise,Weight (kg),Reps,Sets
        2026-01-18,Bench Press,60,10,3
        2026-01-18,Squat,80,8,3
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result.count, 1)  // 同日は1ワークアウト
        XCTAssertEqual(result[0].exercises.count, 2)

        // ベンチプレス: 3セット
        let benchPress = result[0].exercises.first { $0.name == "Bench Press" }
        XCTAssertNotNil(benchPress)
        XCTAssertEqual(benchPress?.sets.count, 3)
        XCTAssertEqual(benchPress?.sets[0].weight, 60)
        XCTAssertEqual(benchPress?.sets[0].reps, 10)

        // スクワット: 3セット
        let squat = result[0].exercises.first { $0.name == "Squat" }
        XCTAssertNotNil(squat)
        XCTAssertEqual(squat?.sets.count, 3)
        XCTAssertEqual(squat?.sets[0].weight, 80)
        XCTAssertEqual(squat?.sets[0].reps, 8)
    }

    func test_パース_複数日() {
        let csv = """
        Date,Exercise,Weight (kg),Reps,Sets
        2026-01-18,Bench Press,60,10,1
        2026-01-19,Squat,80,8,1
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result.count, 2)
    }

    func test_パース_日付フォーマット_スラッシュ() {
        let csv = """
        Date,Exercise,Weight (kg),Reps,Sets
        2026/01/18,Bench Press,60,10,1
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result.count, 1)
    }

    // MARK: - フォーマット検出

    func test_フォーマット検出_StrongHevy() {
        let header = "Date,Exercise,Weight (kg),Reps,Sets"
        let format = CSVParser.detectFormat(header)
        XCTAssertEqual(format, .strongHevy)
    }

    func test_フォーマット検出_不明() {
        let header = "Name,Value,Count"
        let format = CSVParser.detectFormat(header)
        XCTAssertEqual(format, .unknown)
    }

    // MARK: - エッジケース

    func test_パース_空のCSV() {
        let result = CSVParser.parse("")
        XCTAssertTrue(result.isEmpty)
    }

    func test_パース_ヘッダーのみ() {
        let csv = "Date,Exercise,Weight (kg),Reps,Sets"
        let result = CSVParser.parse(csv)
        XCTAssertTrue(result.isEmpty)
    }

    func test_パース_ダブルクォート対応() {
        let csv = """
        Date,Exercise,Weight (kg),Reps,Sets
        2026-01-18,"Bench Press, Incline",60,10,1
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].exercises[0].name, "Bench Press, Incline")
    }

    func test_パース_Setsカラムなし() {
        let csv = """
        Date,Exercise,Weight (kg),Reps
        2026-01-18,Bench Press,60,10
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].exercises[0].sets.count, 1)  // デフォルト1セット
    }

    func test_パース_小数点重量() {
        let csv = """
        Date,Exercise,Weight (kg),Reps,Sets
        2026-01-18,Dumbbell Curl,12.5,12,1
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result[0].exercises[0].sets[0].weight, 12.5)
    }

    // MARK: - 日付ソート

    func test_パース_日付でソート() {
        let csv = """
        Date,Exercise,Weight (kg),Reps,Sets
        2026-01-20,Exercise C,60,10,1
        2026-01-18,Exercise A,60,10,1
        2026-01-19,Exercise B,60,10,1
        """

        let result = CSVParser.parse(csv)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].exercises[0].name, "Exercise A")
        XCTAssertEqual(result[1].exercises[0].name, "Exercise B")
        XCTAssertEqual(result[2].exercises[0].name, "Exercise C")
    }
}

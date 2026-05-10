import XCTest
@testable import MuscleMap

final class RelativeDateTests: XCTestCase {

    private var calendar: Calendar { Calendar.current }
    private var now: Date { Date(timeIntervalSince1970: 1_715_000_000) }   // 2024-05-06 12:53 UTC、固定基準

    private func dateNDaysBefore(_ n: Int) -> Date {
        calendar.date(byAdding: .day, value: -n, to: now) ?? now
    }

    @MainActor
    override func setUp() {
        super.setUp()
        LocalizationManager.shared.currentLanguage = .japanese
    }

    @MainActor
    func testToday() {
        XCTAssertEqual(RelativeDate.string(from: now, to: now), "今日")
    }

    @MainActor
    func testYesterday() {
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(1), to: now), "昨日")
    }

    @MainActor
    func testTwoToSevenDaysAgo() {
        for n in 2...7 {
            XCTAssertEqual(
                RelativeDate.string(from: dateNDaysBefore(n), to: now),
                "\(n)日前",
                "\(n) 日前は \"\(n)日前\" であるべき"
            )
        }
    }

    @MainActor
    func testOneWeekAgo() {
        // 8〜14 日: 約1週間前
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(8), to: now), "約1週間前")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(14), to: now), "約1週間前")
    }

    @MainActor
    func testTwoWeeksAgo() {
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(15), to: now), "約2週間前")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(21), to: now), "約2週間前")
    }

    @MainActor
    func testThreeWeeksAgo() {
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(22), to: now), "約3週間前")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(30), to: now), "約3週間前")
    }

    @MainActor
    func testOneMonthAgo() {
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(31), to: now), "約1ヶ月前")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(60), to: now), "約1ヶ月前")
    }

    @MainActor
    func testTwoMonthsAgo() {
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(61), to: now), "約2ヶ月前")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(90), to: now), "約2ヶ月前")
    }

    @MainActor
    func testThreeMonthsAgo() {
        // 91 日以降は days/30 で月数算出: 91/30 = 3
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(91), to: now), "約3ヶ月前")
    }

    @MainActor
    func testEnglishLocalization() {
        LocalizationManager.shared.currentLanguage = .english
        XCTAssertEqual(RelativeDate.string(from: now, to: now), "today")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(1), to: now), "yesterday")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(3), to: now), "3 days ago")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(10), to: now), "about 1 week ago")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(20), to: now), "about 2 weeks ago")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(45), to: now), "about 1 month ago")
        XCTAssertEqual(RelativeDate.string(from: dateNDaysBefore(120), to: now), "about 4 months ago")
    }
}

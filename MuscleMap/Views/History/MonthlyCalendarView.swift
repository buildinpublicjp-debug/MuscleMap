import SwiftUI

// MARK: - 月間カレンダービュー

struct MonthlyCalendarView: View {
    let workoutDates: Set<DateComponents>
    let dailyMuscleGroups: [DateComponents: Set<MuscleGroup>]
    var onDateSelected: ((Date) -> Void)?

    @State private var currentMonth = Date()
    @State private var selectedDate: Date?

    // デフォルトイニシャライザ（後方互換性）
    init(
        workoutDates: Set<DateComponents>,
        dailyMuscleGroups: [DateComponents: Set<MuscleGroup>] = [:],
        onDateSelected: ((Date) -> Void)? = nil
    ) {
        self.workoutDates = workoutDates
        self.dailyMuscleGroups = dailyMuscleGroups
        self.onDateSelected = onDateSelected
    }

    private let calendar = Calendar.current
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()

    var body: some View {
        VStack(spacing: 16) {
            // 月ナビゲーション
            monthNavigation

            // 曜日ヘッダー
            weekdayHeader

            // カレンダーグリッド
            calendarGrid
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 月ナビゲーション

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(monthYearString)
                .font(.headline.bold())
                .foregroundStyle(Color.mmTextPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - 曜日ヘッダー

    private var weekdayHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // 日曜始まりに調整
            ForEach(0..<7, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(.caption.bold())
                    .foregroundStyle(index == 0 ? Color.mmMuscleFatigued.opacity(0.7) : Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - カレンダーグリッド

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let date = day {
                    DayCell(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        hasWorkout: hasWorkout(on: date),
                        muscleGroups: muscleGroups(on: date)
                    ) {
                        selectedDate = date
                        onDateSelected?(date)
                        HapticManager.lightTap()
                    }
                } else {
                    Color.clear
                        .frame(height: 58)
                }
            }
        }
    }

    // MARK: - ヘルパーメソッド

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.currentLanguage == .japanese
            ? Locale(identifier: "ja_JP")
            : Locale(identifier: "en_US")
        formatter.dateFormat = LocalizationManager.shared.currentLanguage == .japanese
            ? "yyyy年M月"
            : "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = []

        // 月の最初の日の前の空白
        let emptyDays = firstWeekday - 1
        for _ in 0..<emptyDays {
            days.append(nil)
        }

        // 月の日数
        let daysCount = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        for day in 1...daysCount {
            if let date = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: currentMonth),
                month: calendar.component(.month, from: currentMonth),
                day: day
            )) {
                days.append(date)
            }
        }

        return days
    }

    private func hasWorkout(on date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return workoutDates.contains(components)
    }

    private func muscleGroups(on date: Date) -> Set<MuscleGroup> {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return dailyMuscleGroups[components] ?? []
    }
}

// MARK: - 日付セル

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasWorkout: Bool
    let muscleGroups: Set<MuscleGroup>
    let action: () -> Void

    private let calendar = Calendar.current

    // 筋肉グループの表示順と色
    private static let groupOrder: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .core, .lowerBody]

    private static func colorFor(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: return .mmMuscleJustWorked      // 赤系
        case .back: return .mmAccentSecondary        // 青系
        case .shoulders: return .mmMuscleAmber      // 黄系
        case .arms: return .mmMuscleCoral           // オレンジ系
        case .core: return .mmMuscleLime            // 黄緑系
        case .lowerBody: return .mmAccentPrimary    // 緑系
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(textColor)

                // パターン3: マイクロマップ（簡略化シルエット）
                if hasWorkout && !muscleGroups.isEmpty {
                    MicroMuscleIcon(muscleGroups: muscleGroups)
                } else if hasWorkout {
                    // 筋肉グループ情報がない場合は従来の緑ドット
                    Circle()
                        .fill(Color.mmAccentPrimary)
                        .frame(width: 6, height: 6)
                } else {
                    Color.clear
                        .frame(height: 10)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // パターン1: ドットグリッド（最大4つ）
    private var muscleGroupDots: some View {
        let sortedGroups = Self.groupOrder.filter { muscleGroups.contains($0) }

        return HStack(spacing: 2) {
            ForEach(sortedGroups.prefix(4), id: \.self) { group in
                Circle()
                    .fill(Self.colorFor(group))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 10)
    }

    // パターン2: カラーバー（セグメント分割）
    private var muscleGroupBar: some View {
        let sortedGroups = Self.groupOrder.filter { muscleGroups.contains($0) }

        return GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(sortedGroups, id: \.self) { group in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Self.colorFor(group))
                }
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .padding(.horizontal, 4)
    }

    private var textColor: Color {
        if isSelected {
            return Color.mmBgPrimary
        } else if isToday {
            return Color.mmAccentPrimary
        } else {
            return Color.mmTextPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.mmAccentPrimary
        } else if isToday {
            return Color.mmAccentPrimary.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

// MARK: - マイクロ筋肉アイコン（カレンダー用）

private struct MicroMuscleIcon: View {
    let muscleGroups: Set<MuscleGroup>

    // グループごとの色
    private func colorFor(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: return .mmMuscleJustWorked
        case .back: return .mmAccentSecondary
        case .shoulders: return .mmMuscleAmber
        case .arms: return .mmMuscleCoral
        case .core: return .mmMuscleLime
        case .lowerBody: return .mmAccentPrimary
        }
    }

    var body: some View {
        // 簡略化人体シルエット（前面ベース）
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // 胸 (上半身中央)
                if muscleGroups.contains(.chest) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(colorFor(.chest))
                        .frame(width: w * 0.5, height: h * 0.2)
                        .position(x: w * 0.5, y: h * 0.25)
                }

                // 背中 (胸の後ろ、少しずらして表示)
                if muscleGroups.contains(.back) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(colorFor(.back))
                        .frame(width: w * 0.45, height: h * 0.18)
                        .position(x: w * 0.5, y: h * 0.28)
                        .opacity(muscleGroups.contains(.chest) ? 0.7 : 1.0)
                }

                // 肩 (左右)
                if muscleGroups.contains(.shoulders) {
                    HStack(spacing: w * 0.35) {
                        Circle()
                            .fill(colorFor(.shoulders))
                            .frame(width: w * 0.2, height: w * 0.2)
                        Circle()
                            .fill(colorFor(.shoulders))
                            .frame(width: w * 0.2, height: w * 0.2)
                    }
                    .position(x: w * 0.5, y: h * 0.15)
                }

                // 腕 (左右)
                if muscleGroups.contains(.arms) {
                    HStack(spacing: w * 0.4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colorFor(.arms))
                            .frame(width: w * 0.12, height: h * 0.25)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colorFor(.arms))
                            .frame(width: w * 0.12, height: h * 0.25)
                    }
                    .position(x: w * 0.5, y: h * 0.35)
                }

                // 体幹 (中央)
                if muscleGroups.contains(.core) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(colorFor(.core))
                        .frame(width: w * 0.3, height: h * 0.15)
                        .position(x: w * 0.5, y: h * 0.48)
                }

                // 下半身 (下部)
                if muscleGroups.contains(.lowerBody) {
                    HStack(spacing: w * 0.1) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colorFor(.lowerBody))
                            .frame(width: w * 0.18, height: h * 0.35)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colorFor(.lowerBody))
                            .frame(width: w * 0.18, height: h * 0.35)
                    }
                    .position(x: w * 0.5, y: h * 0.75)
                }
            }
        }
        .frame(width: 24, height: 28)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()

        MonthlyCalendarView(
            workoutDates: [
                DateComponents(year: 2026, month: 2, day: 3),
                DateComponents(year: 2026, month: 2, day: 5),
                DateComponents(year: 2026, month: 2, day: 7),
                DateComponents(year: 2026, month: 2, day: 10),
                DateComponents(year: 2026, month: 2, day: 11)
            ],
            dailyMuscleGroups: [
                DateComponents(year: 2026, month: 2, day: 3): [.chest, .arms],
                DateComponents(year: 2026, month: 2, day: 5): [.back, .arms],
                DateComponents(year: 2026, month: 2, day: 7): [.shoulders, .core],
                DateComponents(year: 2026, month: 2, day: 10): [.lowerBody],
                DateComponents(year: 2026, month: 2, day: 11): [.chest, .back, .shoulders, .arms]
            ]
        )
        .padding()
    }
}

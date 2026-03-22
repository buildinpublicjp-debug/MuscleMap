import SwiftUI

// MARK: - 月間カレンダービュー

struct MonthlyCalendarView: View {
    let workoutDates: Set<DateComponents>
    let dailyMuscleGroups: [DateComponents: Set<MuscleGroup>]
    let dailyMuscleMappings: [DateComponents: [String: Int]]
    var onDateSelected: ((Date) -> Void)?

    @State private var currentMonth = Date()
    @State private var selectedDate: Date?

    // デフォルトイニシャライザ（後方互換性）
    init(
        workoutDates: Set<DateComponents>,
        dailyMuscleGroups: [DateComponents: Set<MuscleGroup>] = [:],
        dailyMuscleMappings: [DateComponents: [String: Int]] = [:],
        onDateSelected: ((Date) -> Void)? = nil
    ) {
        self.workoutDates = workoutDates
        self.dailyMuscleGroups = dailyMuscleGroups
        self.dailyMuscleMappings = dailyMuscleMappings
        self.onDateSelected = onDateSelected
    }

    private let calendar = Calendar.current
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()

    private var hasAnyWorkout: Bool {
        !workoutDates.isEmpty
    }

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
                HapticManager.lightTap()
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
                HapticManager.lightTap()
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

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(days, id: \.self) { day in
                if let date = day {
                    DayCell(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        hasWorkout: hasWorkout(on: date),
                        muscleMapping: muscleMapping(on: date)
                    ) {
                        selectedDate = date
                        onDateSelected?(date)
                        HapticManager.lightTap()
                    }
                } else {
                    Color.clear
                        .frame(height: 62)
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

    private func muscleMapping(on date: Date) -> [String: Int] {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return dailyMuscleMappings[components] ?? [:]
    }
}

// MARK: - 日付セル（ミニマッスルマップ付き）

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasWorkout: Bool
    let muscleMapping: [String: Int]
    let action: () -> Void

    private let calendar = Calendar.current

    private static let backMuscleIds: Set<String> = [
        "lats", "traps_upper", "traps_middle_lower", "erector_spinae",
        "hamstrings", "glutes", "deltoid_posterior", "gastrocnemius", "soleus"
    ]

    private var hasBackMuscles: Bool {
        muscleMapping.keys.contains { Self.backMuscleIds.contains($0) }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: isToday ? .bold : .regular))
                    .foregroundStyle(textColor)

                // ワークアウトした日はミニマッスルマップを表示
                if hasWorkout && !muscleMapping.isEmpty {
                    if hasBackMuscles {
                        // 背面筋肉が含まれる場合は前面+背面を横並び表示
                        HStack(spacing: 1) {
                            MiniMuscleMapView(muscleMapping: muscleMapping, showFront: true)
                                .frame(width: 14, height: 36)
                            MiniMuscleMapView(muscleMapping: muscleMapping, showFront: false)
                                .frame(width: 14, height: 36)
                        }
                        .allowsHitTesting(false)
                    } else {
                        MiniMuscleMapView(muscleMapping: muscleMapping, showFront: true)
                            .frame(width: 28, height: 36)
                            .allowsHitTesting(false)
                    }
                } else if hasWorkout {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmAccentPrimary)
                        .frame(height: 36)
                } else {
                    Color.clear
                        .frame(height: 36)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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
            ],
            dailyMuscleMappings: [
                DateComponents(year: 2026, month: 2, day: 3): ["chest_upper": 100, "chest_lower": 80, "triceps": 50],
                DateComponents(year: 2026, month: 2, day: 5): ["lats": 100, "biceps": 70, "traps_upper": 40],
                DateComponents(year: 2026, month: 2, day: 7): ["deltoid_anterior": 80, "deltoid_lateral": 100, "rectus_abdominis": 60],
                DateComponents(year: 2026, month: 2, day: 10): ["quadriceps": 100, "hamstrings": 70, "glutes": 80],
                DateComponents(year: 2026, month: 2, day: 11): ["chest_upper": 80, "lats": 60, "deltoid_lateral": 50, "biceps": 40]
            ]
        )
        .padding()
    }
}

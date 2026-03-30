import SwiftUI
import SwiftData

#if DEBUG
/// スクショ撮影用: trueにするとデモデータが注入される（撮影後falseに戻す）
private let injectDemoData = false
#endif

// MARK: - ルートビュー（オンボーディング → メインタブ）

struct ContentView: View {
    @State private var appState = AppState.shared

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                withAnimation {
                    appState.hasCompletedOnboarding = true
                }
                // ペイウォールは初回ワークアウト完了後に表示（WorkoutCompletionViewで処理）
            }
        }
    }
}

// MARK: - メインTabView

private struct MainTabView: View {
    @State private var appState = AppState.shared
    @State private var previousTab: Int = 0
    @State private var showingPaywall = false
    @State private var showWorkoutLimitAlert = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(L10n.home, systemImage: "figure.stand")
                }
                .tag(0)

            WorkoutStartView()
                .tabItem {
                    Label(L10n.workout, systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)

            ExerciseDictionaryView()
                .tabItem {
                    Label(L10n.exerciseLibrary, systemImage: "book.fill")
                }
                .tag(2)

            HistoryView()
                .tabItem {
                    Label(L10n.history, systemImage: "chart.bar")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(L10n.settings, systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(Color.mmAccentPrimary)
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            if newValue == 1 && !PurchaseManager.shared.canRecordWorkout {
                // 週間制限に達した場合はアラートで説明してからペイウォールへ
                appState.selectedTab = oldValue
                showWorkoutLimitAlert = true
            } else {
                previousTab = newValue
            }
        }
        .alert(
            L10n.freeWorkoutLimitTitle,
            isPresented: $showWorkoutLimitAlert
        ) {
            Button(L10n.upgradeToProButton) {
                showingPaywall = true
            }
            Button(L10n.close, role: .cancel) {}
        } message: {
            Text(L10n.freeWorkoutLimitMessage(PurchaseManager.weeklyFreeLimit))
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isHardPaywall: false)
        }
        #if DEBUG
        .onAppear {
            if injectDemoData {
                injectScreenshotDemoData(context: modelContext)
            }
        }
        #endif
    }

    // MARK: - スクショ撮影用デモデータ注入

    #if DEBUG
    /// UserProfile・ルーティン・SwiftDataワークアウト履歴を一括注入
    private func injectScreenshotDemoData(context: ModelContext) {
        let key = "hasInjectedScreenshotDemo_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        // --- 1. UserProfile ---
        var profile = AppState.shared.userProfile
        profile.nickname = "OG"
        profile.heightCm = 178
        profile.weightKg = 85
        profile.trainingExperience = .veteran
        profile.weeklyFrequency = 4
        profile.trainingLocation = "gym"
        profile.initialPRs = [
            "barbell_bench_press": 90,
            "barbell_back_squat": 120,
            "deadlift": 140,
        ]
        AppState.shared.userProfile = profile
        profile.save()

        // --- 2. ルーティンデータ（4日分） ---
        let routine = UserRoutine(days: [
            RoutineDay(name: "Day 1: 胸・三頭", muscleGroups: ["chest_upper", "chest_lower", "triceps"], exercises: [
                RoutineExercise(exerciseId: "barbell_bench_press", suggestedSets: 4, suggestedReps: 8),
                RoutineExercise(exerciseId: "incline_dumbbell_press", suggestedSets: 3, suggestedReps: 10),
                RoutineExercise(exerciseId: "dumbbell_fly", suggestedSets: 3, suggestedReps: 12),
                RoutineExercise(exerciseId: "tricep_pushdown", suggestedSets: 3, suggestedReps: 12),
            ]),
            RoutineDay(name: "Day 2: 背中・二頭", muscleGroups: ["lats", "traps_middle_lower", "biceps"], exercises: [
                RoutineExercise(exerciseId: "deadlift", suggestedSets: 4, suggestedReps: 5),
                RoutineExercise(exerciseId: "lat_pulldown", suggestedSets: 3, suggestedReps: 10),
                RoutineExercise(exerciseId: "dumbbell_row", suggestedSets: 3, suggestedReps: 10),
                RoutineExercise(exerciseId: "barbell_curl", suggestedSets: 3, suggestedReps: 10),
            ]),
            RoutineDay(name: "Day 3: 脚", muscleGroups: ["quadriceps", "hamstrings", "glutes"], exercises: [
                RoutineExercise(exerciseId: "barbell_back_squat", suggestedSets: 4, suggestedReps: 8),
                RoutineExercise(exerciseId: "leg_press", suggestedSets: 3, suggestedReps: 12),
                RoutineExercise(exerciseId: "romanian_deadlift", suggestedSets: 3, suggestedReps: 10),
                RoutineExercise(exerciseId: "leg_extension", suggestedSets: 3, suggestedReps: 12),
            ]),
            RoutineDay(name: "Day 4: 肩・腕", muscleGroups: ["deltoid_anterior", "deltoid_lateral", "biceps", "triceps"], exercises: [
                RoutineExercise(exerciseId: "overhead_press_barbell", suggestedSets: 4, suggestedReps: 8),
                RoutineExercise(exerciseId: "lateral_raise", suggestedSets: 3, suggestedReps: 15),
                RoutineExercise(exerciseId: "hammer_curl", suggestedSets: 3, suggestedReps: 10),
                RoutineExercise(exerciseId: "skull_crusher", suggestedSets: 3, suggestedReps: 10),
            ]),
        ], createdAt: Date())
        RoutineManager.shared.saveRoutine(routine)

        // --- 3. フラグ設定 ---
        AppState.shared.hasCompletedOnboarding = true
        AppState.shared.hasCompletedFirstWorkout = true
        AppState.shared.hasSeenDemoAnimation = true

        // --- 4. SwiftDataワークアウト履歴 ---
        let now = Date()
        let cal = Calendar.current
        func hoursAgo(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }
        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }

        // 胸トレ（6時間前）→ 赤
        let chestSID = UUID()
        let chestSession = WorkoutSession(id: chestSID, startDate: hoursAgo(7), endDate: hoursAgo(6))
        context.insert(chestSession)
        for (exId, weights) in [
            ("barbell_bench_press", [80.0, 85, 90, 85]),
            ("incline_dumbbell_press", [30.0, 32.5, 35, 32.5]),
            ("dumbbell_fly", [16.0, 18, 18, 16]),
            ("tricep_pushdown", [20.0, 22.5, 25]),
        ] as [(String, [Double])] {
            for (i, w) in weights.enumerated() {
                context.insert(WorkoutSet(
                    session: chestSession, exerciseId: exId,
                    setNumber: i + 1, weight: w, reps: i < 2 ? 10 : 8,
                    completedAt: hoursAgo(6.5)
                ))
            }
        }
        for m in ["chest_upper", "chest_lower", "deltoid_anterior", "triceps"] {
            context.insert(MuscleStimulation(
                muscle: m, stimulationDate: hoursAgo(6),
                maxIntensity: m.contains("chest") ? 1.0 : 0.5,
                totalSets: m.contains("chest") ? 16 : 7, sessionId: chestSID
            ))
        }

        // 背中トレ（28時間前）→ 黄
        let backSID = UUID()
        let backSession = WorkoutSession(id: backSID, startDate: hoursAgo(29), endDate: hoursAgo(28))
        context.insert(backSession)
        for (exId, weights) in [
            ("deadlift", [100.0, 120, 140, 130]),
            ("lat_pulldown", [55.0, 60, 65, 60]),
            ("dumbbell_row", [30.0, 32.5, 35, 32.5]),
            ("barbell_curl", [25.0, 30, 30]),
        ] as [(String, [Double])] {
            for (i, w) in weights.enumerated() {
                context.insert(WorkoutSet(
                    session: backSession, exerciseId: exId,
                    setNumber: i + 1, weight: w, reps: 10,
                    completedAt: hoursAgo(28.5)
                ))
            }
        }
        for m in ["lats", "traps_middle_lower", "erector_spinae", "deltoid_posterior", "biceps", "forearms"] {
            context.insert(MuscleStimulation(
                muscle: m, stimulationDate: hoursAgo(28),
                maxIntensity: m == "lats" ? 1.0 : 0.6,
                totalSets: m == "lats" ? 15 : 6, sessionId: backSID
            ))
        }

        // 脚トレ（4日前）→ 緑
        let legSID = UUID()
        let legSession = WorkoutSession(id: legSID, startDate: daysAgo(4).addingTimeInterval(-3600), endDate: daysAgo(4))
        context.insert(legSession)
        for (exId, weights) in [
            ("barbell_back_squat", [80.0, 90, 100, 120]),
            ("leg_press", [120.0, 140, 160, 140]),
            ("romanian_deadlift", [60.0, 70, 80, 70]),
            ("leg_extension", [40.0, 45, 50]),
        ] as [(String, [Double])] {
            for (i, w) in weights.enumerated() {
                context.insert(WorkoutSet(
                    session: legSession, exerciseId: exId,
                    setNumber: i + 1, weight: w, reps: 10,
                    completedAt: daysAgo(4).addingTimeInterval(-1800)
                ))
            }
        }
        for m in ["quadriceps", "hamstrings", "glutes", "adductors", "gastrocnemius", "soleus"] {
            context.insert(MuscleStimulation(
                muscle: m, stimulationDate: daysAgo(4),
                maxIntensity: ["quadriceps", "glutes"].contains(m) ? 1.0 : 0.7,
                totalSets: ["quadriceps", "glutes"].contains(m) ? 15 : 6, sessionId: legSID
            ))
        }

        // 肩トレ（3日前）→ 黄緑
        let shSID = UUID()
        let shSession = WorkoutSession(id: shSID, startDate: daysAgo(3).addingTimeInterval(-3600), endDate: daysAgo(3))
        context.insert(shSession)
        for (exId, weights) in [
            ("overhead_press_barbell", [40.0, 45, 50, 45]),
            ("lateral_raise", [10.0, 12, 14]),
            ("hammer_curl", [14.0, 16, 18]),
            ("skull_crusher", [20.0, 25, 25]),
        ] as [(String, [Double])] {
            for (i, w) in weights.enumerated() {
                context.insert(WorkoutSet(
                    session: shSession, exerciseId: exId,
                    setNumber: i + 1, weight: w, reps: 10,
                    completedAt: daysAgo(3).addingTimeInterval(-1800)
                ))
            }
        }
        for m in ["deltoid_anterior", "deltoid_lateral", "deltoid_posterior", "traps_upper", "biceps", "triceps"] {
            context.insert(MuscleStimulation(
                muscle: m, stimulationDate: daysAgo(3),
                maxIntensity: m == "deltoid_lateral" ? 1.0 : 0.6,
                totalSets: 10, sessionId: shSID
            ))
        }

        // 腹筋（10日前）→ 紫（未刺激）
        let coreSID = UUID()
        let coreSession = WorkoutSession(id: coreSID, startDate: daysAgo(10).addingTimeInterval(-3600), endDate: daysAgo(10))
        context.insert(coreSession)
        for (exId, weights) in [("crunch", [0.0, 0, 0]), ("plank", [0.0, 0, 0])] as [(String, [Double])] {
            for (i, w) in weights.enumerated() {
                context.insert(WorkoutSet(
                    session: coreSession, exerciseId: exId,
                    setNumber: i + 1, weight: w, reps: 15,
                    completedAt: daysAgo(10).addingTimeInterval(-1800)
                ))
            }
        }
        for m in ["rectus_abdominis", "obliques"] {
            context.insert(MuscleStimulation(
                muscle: m, stimulationDate: daysAgo(10),
                maxIntensity: 0.8, totalSets: 6, sessionId: coreSID
            ))
        }

        // 過去12週間の履歴（ストリーク + ヒートマップ用）
        let exRotation: [(String, [String])] = [
            ("barbell_bench_press", ["chest_upper", "chest_lower", "deltoid_anterior", "triceps"]),
            ("barbell_back_squat", ["quadriceps", "hamstrings", "glutes"]),
            ("deadlift", ["erector_spinae", "glutes", "hamstrings", "lats"]),
            ("overhead_press_barbell", ["deltoid_anterior", "deltoid_lateral", "triceps"]),
            ("lat_pulldown", ["lats", "traps_middle_lower", "biceps"]),
        ]
        for weekOffset in 1...12 {
            for dayInWeek in [1, 3, 5] {
                let dayOffset = weekOffset * 7 + dayInWeek
                guard dayOffset > 5 else { continue }
                let sid = UUID()
                let date = daysAgo(dayOffset)
                let session = WorkoutSession(id: sid, startDate: date.addingTimeInterval(-3600), endDate: date)
                context.insert(session)
                let (exId, muscles) = exRotation[(weekOffset * 3 + dayInWeek) % exRotation.count]
                for setIdx in 1...4 {
                    context.insert(WorkoutSet(
                        session: session, exerciseId: exId,
                        setNumber: setIdx, weight: Double(60 + setIdx * 5), reps: 10,
                        completedAt: date.addingTimeInterval(-1800)
                    ))
                }
                for m in muscles {
                    context.insert(MuscleStimulation(
                        muscle: m, stimulationDate: date,
                        maxIntensity: 0.8, totalSets: 4, sessionId: sid
                    ))
                }
            }
        }

        do {
            try context.save()
        } catch {
            print("[Screenshot] Failed to save demo data: \(error)")
        }
        UserDefaults.standard.set(true, forKey: key)

        print("[Screenshot] Demo data injected successfully")
    }
    #endif
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}

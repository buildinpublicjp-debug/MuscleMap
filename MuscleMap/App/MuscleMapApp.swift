import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct MuscleMapApp: App {
    init() {
        // エクササイズデータを起動時に読み込み
        ExerciseStore.shared.load()

        // 3Dモデルの可用性を判定
        ModelLoader.shared.evaluateModelAvailability()

        // Watch Connectivity セッション開始（shared初期化時にactivateSessionが呼ばれる）
        _ = PhoneSessionManager.shared

        // PurchaseManager初期化（現時点はno-op）
        PurchaseManager.shared.configure()

        // 初回起動時の外観設定
        MuscleMapApp.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            WorkoutSession.self,
            WorkoutSet.self,
            MuscleStimulation.self
        ])
    }

    /// UIKit外観を設定
    static func configureAppearance() {
        // TabBar外観
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.mmBgSecondary)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // NavigationBar外観
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.mmBgPrimary)
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}

// MARK: - ルートビュー（テーマ監視）

struct RootView: View {
    @State private var themeManager = ThemeManager.shared
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContentView()
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onAppear {
                // [Fix #2] Watch連携用にModelContextを設定
                PhoneSessionManager.shared.modelContext = modelContext

                #if DEBUG
                seedDemoDataIfNeeded(context: modelContext)
                #endif
            }
            .onChange(of: themeManager.currentTheme) { _, _ in
                // [Fix #5] テーマ変更時にUIKit外観を再設定
                MuscleMapApp.configureAppearance()
            }
    }

    /// スクショ用デモデータを1回だけ投入（DEBUGビルドのみ）
    private func seedDemoDataIfNeeded(context: ModelContext) {
        let key = "hasSeededScreenshotData_v3"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let now = Date()
        let cal = Calendar.current

        // --- ヘルパー ---
        func hoursAgo(_ h: Double) -> Date {
            now.addingTimeInterval(-h * 3600)
        }
        func daysAgo(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: -d, to: now)!
        }

        // --- 1. 胸トレ（6時間前）→ 赤（回復10-15%） ---
        let chestSessionId = UUID()
        let chestSession = WorkoutSession(
            id: chestSessionId,
            startDate: hoursAgo(7),
            endDate: hoursAgo(6)
        )
        context.insert(chestSession)

        let chestExercises = [
            ("barbell_bench_press", [80.0, 85, 90, 85]),
            ("incline_dumbbell_press", [30.0, 32.5, 35, 32.5]),
            ("dumbbell_fly", [16.0, 18, 18, 16]),
            ("cable_crossover", [20.0, 22.5, 25]),
            ("chest_dip", [0.0, 0, 0])
        ]
        var setNum = 0
        for (exId, weights) in chestExercises {
            for (i, w) in weights.enumerated() {
                setNum += 1
                let ws = WorkoutSet(
                    session: chestSession,
                    exerciseId: exId,
                    setNumber: i + 1,
                    weight: w,
                    reps: i < 2 ? 10 : 8,
                    completedAt: hoursAgo(6.5)
                )
                context.insert(ws)
            }
        }
        // 胸の刺激
        for m in ["chest_upper", "chest_lower", "deltoid_anterior", "triceps"] {
            context.insert(MuscleStimulation(
                muscle: m,
                stimulationDate: hoursAgo(6),
                maxIntensity: m.contains("chest") ? 1.0 : 0.5,
                totalSets: m.contains("chest") ? 18 : 8,
                sessionId: chestSessionId
            ))
        }

        // --- 2. 背中トレ（28時間前）→ 黄（回復40-50%） ---
        let backSessionId = UUID()
        let backSession = WorkoutSession(
            id: backSessionId,
            startDate: hoursAgo(29),
            endDate: hoursAgo(28)
        )
        context.insert(backSession)

        let backExercises = [
            ("barbell_bent_over_row", [70.0, 75, 80, 75]),
            ("lat_pulldown", [55.0, 60, 65, 60]),
            ("dumbbell_row", [30.0, 32.5, 35, 32.5]),
            ("seated_cable_row", [50.0, 55, 60])
        ]
        setNum = 0
        for (exId, weights) in backExercises {
            for (i, w) in weights.enumerated() {
                setNum += 1
                let ws = WorkoutSet(
                    session: backSession,
                    exerciseId: exId,
                    setNumber: i + 1,
                    weight: w,
                    reps: 10,
                    completedAt: hoursAgo(28.5)
                )
                context.insert(ws)
            }
        }
        for m in ["lats", "traps_middle_lower", "erector_spinae", "deltoid_posterior", "biceps", "forearms"] {
            context.insert(MuscleStimulation(
                muscle: m,
                stimulationDate: hoursAgo(28),
                maxIntensity: m == "lats" ? 1.0 : 0.6,
                totalSets: m == "lats" ? 15 : 6,
                sessionId: backSessionId
            ))
        }

        // --- 3. 脚トレ（4日前）→ 緑（完全回復） ---
        let legSessionId = UUID()
        let legSession = WorkoutSession(
            id: legSessionId,
            startDate: daysAgo(4).addingTimeInterval(-3600),
            endDate: daysAgo(4)
        )
        context.insert(legSession)

        let legExercises = [
            ("barbell_back_squat", [80.0, 90, 100, 90]),
            ("leg_press", [120.0, 140, 160, 140]),
            ("leg_extension", [40.0, 45, 50]),
            ("lying_leg_curl", [35.0, 40, 45]),
            ("standing_calf_raise", [60.0, 70, 80])
        ]
        setNum = 0
        for (exId, weights) in legExercises {
            for (i, w) in weights.enumerated() {
                setNum += 1
                let ws = WorkoutSet(
                    session: legSession,
                    exerciseId: exId,
                    setNumber: i + 1,
                    weight: w,
                    reps: 10,
                    completedAt: daysAgo(4).addingTimeInterval(-1800)
                )
                context.insert(ws)
            }
        }
        for m in ["quadriceps", "hamstrings", "glutes", "adductors", "gastrocnemius", "soleus"] {
            context.insert(MuscleStimulation(
                muscle: m,
                stimulationDate: daysAgo(4),
                maxIntensity: ["quadriceps", "glutes"].contains(m) ? 1.0 : 0.7,
                totalSets: ["quadriceps", "glutes"].contains(m) ? 15 : 6,
                sessionId: legSessionId
            ))
        }

        // --- 4. 肩トレ（3日前）→ 黄緑〜緑 ---
        let shoulderSessionId = UUID()
        let shoulderSession = WorkoutSession(
            id: shoulderSessionId,
            startDate: daysAgo(3).addingTimeInterval(-3600),
            endDate: daysAgo(3)
        )
        context.insert(shoulderSession)

        let shoulderExercises = [
            ("overhead_press_barbell", [40.0, 45, 50, 45]),
            ("lateral_raise", [10.0, 12, 14]),
            ("face_pull", [20.0, 25, 25])
        ]
        for (exId, weights) in shoulderExercises {
            for (i, w) in weights.enumerated() {
                let ws = WorkoutSet(
                    session: shoulderSession,
                    exerciseId: exId,
                    setNumber: i + 1,
                    weight: w,
                    reps: 10,
                    completedAt: daysAgo(3).addingTimeInterval(-1800)
                )
                context.insert(ws)
            }
        }
        for m in ["deltoid_anterior", "deltoid_lateral", "deltoid_posterior", "traps_upper"] {
            context.insert(MuscleStimulation(
                muscle: m,
                stimulationDate: daysAgo(3),
                maxIntensity: m == "deltoid_lateral" ? 1.0 : 0.6,
                totalSets: 10,
                sessionId: shoulderSessionId
            ))
        }

        // --- 5. 腹筋トレ（10日前）→ 紫（未刺激） ---
        let coreSessionId = UUID()
        let coreSession = WorkoutSession(
            id: coreSessionId,
            startDate: daysAgo(10).addingTimeInterval(-3600),
            endDate: daysAgo(10)
        )
        context.insert(coreSession)

        let coreExercises = [
            ("crunch", [0.0, 0, 0]),
            ("plank", [0.0, 0, 0])
        ]
        for (exId, weights) in coreExercises {
            for (i, w) in weights.enumerated() {
                let ws = WorkoutSet(
                    session: coreSession,
                    exerciseId: exId,
                    setNumber: i + 1,
                    weight: w,
                    reps: 15,
                    completedAt: daysAgo(10).addingTimeInterval(-1800)
                )
                context.insert(ws)
            }
        }
        for m in ["rectus_abdominis", "obliques"] {
            context.insert(MuscleStimulation(
                muscle: m,
                stimulationDate: daysAgo(10),
                maxIntensity: 0.8,
                totalSets: 6,
                sessionId: coreSessionId
            ))
        }

        // --- 6. 過去数週間の履歴（ストリーク3週+ヒートマップ用） ---
        // 過去90日間、週3-4回ペースのトレーニング
        let exerciseRotation: [(String, [String])] = [
            ("barbell_bench_press", ["chest_upper", "chest_lower", "deltoid_anterior", "triceps"]),
            ("barbell_back_squat", ["quadriceps", "hamstrings", "glutes"]),
            ("barbell_bent_over_row", ["lats", "traps_middle_lower", "biceps"]),
            ("overhead_press_barbell", ["deltoid_anterior", "deltoid_lateral", "triceps"]),
            ("deadlift", ["erector_spinae", "glutes", "hamstrings", "lats"]),
        ]

        // 週3回ペースで過去12週間
        for weekOffset in 1...12 {
            let daysInWeek = [1, 3, 5] // 月水金
            for dayInWeek in daysInWeek {
                let dayOffset = weekOffset * 7 + dayInWeek
                guard dayOffset > 5 else { continue } // 直近は上で入れた

                let sessionId = UUID()
                let sessionDate = daysAgo(dayOffset)
                let session = WorkoutSession(
                    id: sessionId,
                    startDate: sessionDate.addingTimeInterval(-3600),
                    endDate: sessionDate
                )
                context.insert(session)

                let exIdx = (weekOffset * 3 + dayInWeek) % exerciseRotation.count
                let (exId, muscles) = exerciseRotation[exIdx]

                for setIdx in 1...4 {
                    let ws = WorkoutSet(
                        session: session,
                        exerciseId: exId,
                        setNumber: setIdx,
                        weight: Double(60 + setIdx * 5),
                        reps: 10,
                        completedAt: sessionDate.addingTimeInterval(-1800)
                    )
                    context.insert(ws)
                }

                for m in muscles {
                    context.insert(MuscleStimulation(
                        muscle: m,
                        stimulationDate: sessionDate,
                        maxIntensity: 0.8,
                        totalSets: 4,
                        sessionId: sessionId
                    ))
                }
            }
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: key)

        // オンボーディング完了・初回ワークアウト完了フラグ
        AppState.shared.hasCompletedOnboarding = true
        AppState.shared.hasCompletedFirstWorkout = true
        AppState.shared.hasSeenDemoAnimation = true
    }
}

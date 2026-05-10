#if DEBUG
import Foundation
import SwiftData

// MARK: - ASC スクショ撮影用デモデータ注入 (DEBUG only)
//
// App Store Connect のスクショ撮影で「全身カラーの回復マップ」を見せるため、
// 過去 6h〜60h に分散させた 6 セッションを SwiftData に挿入する。回復計算は
// 既存 RecoveryCalculator に任せ、データだけ仕込む。
//
// 識別: WorkoutSession.note = "[ASC_DEMO]"。clear() で同タグのみ削除。
// 本番ユーザーへの影響なし: ファイル全体 #if DEBUG ガード。

enum ASCDemoDataSeeder {
    static let demoTag = "[ASC_DEMO]"

    @MainActor
    static func inject(context: ModelContext) {
        let now = Date()
        func hoursAgo(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }

        for plan in scenarios {
            let sessionId = UUID()
            let session = WorkoutSession(
                id: sessionId,
                startDate: hoursAgo(plan.hoursAgo + 1),
                endDate: hoursAgo(plan.hoursAgo),
                note: demoTag
            )
            context.insert(session)

            var setNumber = 0
            for (exerciseId, weights, reps) in plan.exercises {
                for (i, weight) in weights.enumerated() {
                    setNumber += 1
                    let ws = WorkoutSet(
                        session: session,
                        exerciseId: exerciseId,
                        setNumber: i + 1,
                        weight: weight,
                        reps: reps,
                        completedAt: hoursAgo(plan.hoursAgo + 0.5)
                    )
                    context.insert(ws)
                }
            }

            for (muscleRaw, intensity, totalSets) in plan.stimulations {
                context.insert(MuscleStimulation(
                    muscle: muscleRaw,
                    stimulationDate: hoursAgo(plan.hoursAgo),
                    maxIntensity: intensity,
                    totalSets: totalSets,
                    sessionId: sessionId
                ))
            }
        }

        try? context.save()
    }

    @MainActor
    static func clear(context: ModelContext) {
        let tag = demoTag
        let predicate = #Predicate<WorkoutSession> { $0.note == tag }
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate)
        guard let sessions = try? context.fetch(descriptor) else { return }

        let demoSessionIds = Set(sessions.map(\.id))

        // 1. Stimulation は手動FK (sessionId) で関連付けられているため明示削除。
        let stimDescriptor = FetchDescriptor<MuscleStimulation>()
        if let allStims = try? context.fetch(stimDescriptor) {
            for stim in allStims where demoSessionIds.contains(stim.sessionId) {
                context.delete(stim)
            }
        }

        // 2. Session を削除すると sets は cascade で消える。
        for session in sessions {
            context.delete(session)
        }

        try? context.save()
    }
}

// MARK: - 注入シナリオ定義

private struct DemoScenario {
    let hoursAgo: Double
    let exercises: [(id: String, weights: [Double], reps: Int)]
    /// (Muscle.rawValue, maxIntensity 0-1, totalSets)
    let stimulations: [(String, Double, Int)]
}

private let scenarios: [DemoScenario] = [
    // 胸 — 6h前 (赤、回復 ~10%)
    DemoScenario(
        hoursAgo: 6,
        exercises: [
            ("barbell_bench_press", [80, 85, 90, 85], 8),
            ("incline_dumbbell_press", [30, 32.5, 35, 32.5], 10),
            ("dumbbell_fly", [16, 18, 18], 12)
        ],
        stimulations: [
            ("chest_upper", 1.0, 11),
            ("chest_lower", 1.0, 11),
            ("deltoid_anterior", 0.5, 4),
            ("triceps", 0.5, 7)
        ]
    ),
    // 肩 — 18h前 (赤〜黄、回復 ~25%)
    DemoScenario(
        hoursAgo: 18,
        exercises: [
            ("dumbbell_shoulder_press", [22.5, 25, 27.5], 10),
            ("lateral_raise", [10, 12, 14], 12)
        ],
        stimulations: [
            ("deltoid_lateral", 1.0, 6),
            ("deltoid_posterior", 0.6, 3),
            ("deltoid_anterior", 0.6, 3),
            ("triceps", 0.4, 3)
        ]
    ),
    // 腕 — 30h前 (黄、回復 ~45%)
    DemoScenario(
        hoursAgo: 30,
        exercises: [
            ("barbell_curl", [25, 27.5, 30], 10),
            ("overhead_tricep_extension", [20, 22.5, 25], 12)
        ],
        stimulations: [
            ("biceps", 1.0, 6),
            ("triceps", 1.0, 6),
            ("forearms", 0.4, 6)
        ]
    ),
    // 体幹 — 30h前 (黄、回復 ~45%)
    DemoScenario(
        hoursAgo: 30,
        exercises: [
            ("plank", [0, 0, 0], 60),
            ("hanging_leg_raise", [0, 0, 0], 12)
        ],
        stimulations: [
            ("rectus_abdominis", 1.0, 6),
            ("obliques", 0.7, 6),
            ("hip_flexors", 0.5, 3)
        ]
    ),
    // 背中 — 44h前 (黄緑、回復 ~65%)
    DemoScenario(
        hoursAgo: 44,
        exercises: [
            ("barbell_bent_over_row", [70, 75, 80, 75], 10),
            ("lat_pulldown", [55, 60, 65], 10),
            ("seated_cable_row", [50, 55, 60], 10)
        ],
        stimulations: [
            ("lats", 1.0, 10),
            ("traps_middle_lower", 0.8, 7),
            ("traps_upper", 0.5, 3),
            ("erector_spinae", 0.7, 4),
            ("deltoid_posterior", 0.5, 3),
            ("biceps", 0.6, 6),
            ("forearms", 0.5, 10)
        ]
    ),
    // 下半身 — 60h前 (ほぼ緑、回復 ~85%)
    DemoScenario(
        hoursAgo: 60,
        exercises: [
            ("barbell_back_squat", [80, 90, 100, 90], 8),
            ("lying_leg_curl", [35, 40, 45], 10),
            ("standing_calf_raise", [60, 70, 80], 15)
        ],
        stimulations: [
            ("quadriceps", 1.0, 10),
            ("hamstrings", 0.9, 6),
            ("glutes", 0.8, 4),
            ("adductors", 0.6, 4),
            ("gastrocnemius", 1.0, 3),
            ("soleus", 0.7, 3),
            ("erector_spinae", 0.5, 4)
        ]
    )
]
#endif

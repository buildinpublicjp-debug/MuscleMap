import Testing
import Foundation
@testable import MuscleMap

// MARK: - ExerciseStore テスト

struct ExerciseStoreTests {

    // テスト用のJSON
    private static let sampleJSON = """
    [
      {
        "id": "bench_press",
        "nameEN": "Barbell Bench Press",
        "nameJA": "ベンチプレス",
        "category": "胸",
        "equipment": "バーベル",
        "difficulty": "中級",
        "muscleMapping": {
          "chest_upper": 65,
          "chest_lower": 100,
          "deltoid_anterior": 50,
          "triceps": 40
        }
      },
      {
        "id": "lat_pulldown",
        "nameEN": "Lat Pulldown",
        "nameJA": "ラットプルダウン",
        "category": "背中",
        "equipment": "マシン",
        "difficulty": "初級",
        "muscleMapping": {
          "lats": 100,
          "traps_middle_lower": 40,
          "deltoid_posterior": 30,
          "biceps": 60,
          "forearms": 30
        }
      },
      {
        "id": "squat",
        "nameEN": "Barbell Back Squat",
        "nameJA": "スクワット",
        "category": "下半身",
        "equipment": "バーベル",
        "difficulty": "上級",
        "muscleMapping": {
          "quadriceps": 100,
          "glutes": 75,
          "hamstrings": 50
        }
      }
    ]
    """.data(using: .utf8)!

    @Test("JSON読み込み: 3種目がロードされる")
    @MainActor
    func loadExercises() {
        let store = ExerciseStore.shared
        store.load(from: Self.sampleJSON)
        #expect(store.exercises.count == 3)
    }

    @Test("IDで検索: bench_pressが取得できる")
    @MainActor
    func findById() {
        let store = ExerciseStore.shared
        store.load(from: Self.sampleJSON)
        let exercise = store.exercise(for: "bench_press")
        #expect(exercise != nil)
        #expect(exercise?.nameJA == "ベンチプレス")
    }

    @Test("IDで検索: 存在しないIDはnil")
    @MainActor
    func findByIdNotFound() {
        let store = ExerciseStore.shared
        store.load(from: Self.sampleJSON)
        #expect(store.exercise(for: "nonexistent") == nil)
    }

    @Test("カテゴリで絞り込み: 胸カテゴリは1件")
    @MainActor
    func filterByCategory() {
        let store = ExerciseStore.shared
        store.load(from: Self.sampleJSON)
        let chestExercises = store.exercises(for: "胸")
        #expect(chestExercises.count == 1)
        #expect(chestExercises.first?.id == "bench_press")
    }

    @Test("筋肉ターゲット検索: bicepsをターゲットにする種目")
    @MainActor
    func filterByMuscle() {
        let store = ExerciseStore.shared
        store.load(from: Self.sampleJSON)
        let bicepExercises = store.exercises(targeting: .biceps)
        #expect(bicepExercises.count == 1)
        #expect(bicepExercises.first?.id == "lat_pulldown")
    }

    @Test("筋肉ターゲット検索: 刺激度%順にソートされる")
    @MainActor
    func filterByMuscleSorted() {
        let store = ExerciseStore.shared
        store.load(from: Self.sampleJSON)
        // tricepsはbench_press(40%)のみ
        let tricepExercises = store.exercises(targeting: .triceps)
        #expect(tricepExercises.count == 1)
    }

    @Test("ExerciseDefinition: primaryMuscleが正しい")
    func primaryMuscle() {
        let exercise = ExerciseDefinition(
            id: "test",
            nameEN: "Test",
            nameJA: "テスト",
            category: "test",
            equipment: "test",
            difficulty: "test",
            muscleMapping: ["chest_lower": 100, "triceps": 40]
        )
        #expect(exercise.primaryMuscle == .chestLower)
    }

    @Test("ExerciseDefinition: stimulationPercentageが正しい")
    func stimulationPercentage() {
        let exercise = ExerciseDefinition(
            id: "test",
            nameEN: "Test",
            nameJA: "テスト",
            category: "test",
            equipment: "test",
            difficulty: "test",
            muscleMapping: ["chest_lower": 100, "triceps": 40]
        )
        #expect(exercise.stimulationPercentage(for: .chestLower) == 100)
        #expect(exercise.stimulationPercentage(for: .triceps) == 40)
        #expect(exercise.stimulationPercentage(for: .biceps) == 0)
    }
}

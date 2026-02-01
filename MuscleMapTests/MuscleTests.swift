import Testing
import Foundation
@testable import MuscleMap

// MARK: - Muscle / MuscleGroup テスト

struct MuscleTests {

    @Test("全21筋肉が定義されている")
    func allMusclesCount() {
        #expect(Muscle.allCases.count == 21)
    }

    @Test("全6グループが定義されている")
    func allGroupsCount() {
        #expect(MuscleGroup.allCases.count == 6)
    }

    @Test("全筋肉がいずれかのグループに属する")
    func allMusclesHaveGroup() {
        for muscle in Muscle.allCases {
            let group = muscle.group
            #expect(MuscleGroup.allCases.contains(group))
        }
    }

    @Test("グループのmusclesプロパティが正しい")
    func groupMusclesProperty() {
        // 全グループのmusclesを合算すると21になる
        let total = MuscleGroup.allCases.reduce(0) { $0 + $1.muscles.count }
        #expect(total == 21)
    }

    @Test("胸グループは2筋肉")
    func chestGroupCount() {
        #expect(MuscleGroup.chest.muscles.count == 2)
    }

    @Test("背中グループは4筋肉")
    func backGroupCount() {
        #expect(MuscleGroup.back.muscles.count == 4)
    }

    @Test("下半身グループは7筋肉")
    func lowerBodyGroupCount() {
        #expect(MuscleGroup.lowerBody.muscles.count == 7)
    }

    @Test("大筋群の基準回復時間は72h")
    func largeMuscleRecoveryHours() {
        #expect(Muscle.quadriceps.baseRecoveryHours == 72)
        #expect(Muscle.lats.baseRecoveryHours == 72)
        #expect(Muscle.glutes.baseRecoveryHours == 72)
    }

    @Test("中筋群の基準回復時間は48h")
    func mediumMuscleRecoveryHours() {
        #expect(Muscle.chestUpper.baseRecoveryHours == 48)
        #expect(Muscle.biceps.baseRecoveryHours == 48)
        #expect(Muscle.deltoidLateral.baseRecoveryHours == 48)
    }

    @Test("小筋群の基準回復時間は24h")
    func smallMuscleRecoveryHours() {
        #expect(Muscle.forearms.baseRecoveryHours == 24)
        #expect(Muscle.rectusAbdominis.baseRecoveryHours == 24)
        #expect(Muscle.soleus.baseRecoveryHours == 24)
    }

    @Test("rawValueがexercises.jsonのmuscle_idと一致する")
    func rawValueMatchesJsonId() {
        #expect(Muscle.chestUpper.rawValue == "chest_upper")
        #expect(Muscle.trapsMiddleLower.rawValue == "traps_middle_lower")
        #expect(Muscle.hipFlexors.rawValue == "hip_flexors")
    }

    @Test("日本語名が設定されている")
    func japaneseNamesExist() {
        for muscle in Muscle.allCases {
            #expect(!muscle.japaneseName.isEmpty)
        }
        for group in MuscleGroup.allCases {
            #expect(!group.japaneseName.isEmpty)
        }
    }
}

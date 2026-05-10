import Testing
import Foundation
import SwiftUI
import UIKit
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

// MARK: - 全身制覇画面 PNG 書き出し（v1.1.x リデザイン版検証用）

struct FullBodyCoverageRenderTests {

    /// 21部位それぞれ N日前を割り当てた最終刺激日辞書を生成
    @MainActor
    private func makeStimulations(spreadDays: Int = 7) -> [Muscle: Date] {
        let now = Date()
        let cal = Calendar.current
        var dict: [Muscle: Date] = [:]
        for (index, muscle) in Muscle.allCases.enumerated() {
            let daysBack = (index % spreadDays) + 1
            let date = cal.date(byAdding: .day, value: -daysBack, to: now) ?? now
            dict[muscle] = date
        }
        return dict
    }

    /// レンダーのコンテンツを width 制約だけかけて生成（高さは intrinsic）
    @MainActor
    private func renderContent(
        view: some View,
        width: CGFloat,
        scale: CGFloat = 3.0,
        outputPath: String
    ) -> Bool {
        let renderer = ImageRenderer(content: view.frame(width: width))
        renderer.scale = scale
        guard let image = renderer.uiImage, let data = image.pngData() else { return false }
        let url = URL(fileURLWithPath: outputPath)
        do {
            try data.write(to: url)
            print("[FullBodyCoverage] wrote \(data.count) bytes to \(url.path)  size=\(image.size)")
            return true
        } catch {
            return false
        }
    }

    /// ImageRenderer 用のラップ：ScrollView を使わず、conquestContent 直に背景を貼る
    @MainActor
    private func wrapForRender(
        stims: [Muscle: Date],
        colorScheme: ColorScheme
    ) -> some View {
        let view = FullBodyConquestView(
            lastStimulations: stims,
            achievementDate: Date(),
            onShare: {},
            onDismiss: {}
        )
        return ZStack(alignment: .topLeading) {
            Color.mmBgPrimary
            view.conquestContent
        }
        .environment(\.colorScheme, colorScheme)
    }

    @Test("Pro Max ダーク 430 wide")
    @MainActor
    func renderProMaxDark() async {
        let ok = renderContent(
            view: wrapForRender(stims: makeStimulations(), colorScheme: .dark),
            width: 430,
            outputPath: "/tmp/musclemap_fbc_promax_dark.png"
        )
        #expect(ok)
    }

    @Test("iPhone SE ダーク 375 wide")
    @MainActor
    func renderSEDark() async {
        let ok = renderContent(
            view: wrapForRender(stims: makeStimulations(), colorScheme: .dark),
            width: 375,
            outputPath: "/tmp/musclemap_fbc_se_dark.png"
        )
        #expect(ok)
    }

    @Test("Pro Max ライト 430 wide")
    @MainActor
    func renderProMaxLight() async {
        let ok = renderContent(
            view: wrapForRender(stims: makeStimulations(), colorScheme: .light),
            width: 430,
            outputPath: "/tmp/musclemap_fbc_promax_light.png"
        )
        #expect(ok)
    }
}

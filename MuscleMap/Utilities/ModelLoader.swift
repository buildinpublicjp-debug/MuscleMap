import Foundation
import RealityKit

// MARK: - 3Dモデルローダー
// USDZファイルの読み込みとフォールバック管理

@MainActor
class ModelLoader {
    static let shared = ModelLoader()

    /// 利用可能な3Dモデルレベル
    enum ModelLevel: Equatable {
        /// レベルA: 21筋肉完全分離
        case fullSeparation
        /// レベルB: 6-8グループ分離
        case groupSeparation
        /// レベルC: 3Dモデルなし → 2Dフォールバック
        case fallback2D
    }

    /// 現在のモデルレベル（起動時に判定）
    private(set) var currentLevel: ModelLevel = .fallback2D

    /// モデルキャッシュ
    private var entityCache: [String: ModelEntity] = [:]

    private init() {}

    // MARK: - 初期化

    /// 3Dモデルの可用性を判定
    func evaluateModelAvailability() {
        // 全21筋肉のUSDZがあるか
        let allMuscles = Muscle.allCases.allSatisfy { muscle in
            Bundle.main.url(forResource: muscle.rawValue, withExtension: "usdz", subdirectory: "3DModels") != nil
        }
        if allMuscles {
            currentLevel = .fullSeparation
            return
        }

        // グループ単位のUSDZがあるか
        let allGroups = MuscleGroup.allCases.allSatisfy { group in
            Bundle.main.url(forResource: group.rawValue, withExtension: "usdz", subdirectory: "3DModels") != nil
        }
        if allGroups {
            currentLevel = .groupSeparation
            return
        }

        // 全身モデルがあるか
        if Bundle.main.url(forResource: "body_full", withExtension: "usdz", subdirectory: "3DModels") != nil {
            currentLevel = .groupSeparation
            return
        }

        currentLevel = .fallback2D
    }

    // MARK: - モデル読み込み

    /// 筋肉の3Dモデルを読み込む
    func loadMuscleEntity(for muscle: Muscle) -> ModelEntity? {
        // キャッシュチェック
        if let cached = entityCache[muscle.rawValue] {
            return cached
        }

        // レベルAの場合: 個別筋肉モデル
        if currentLevel == .fullSeparation {
            if let entity = loadEntity(named: muscle.rawValue) {
                entityCache[muscle.rawValue] = entity
                return entity
            }
        }

        // レベルBの場合: グループモデル
        if currentLevel == .groupSeparation {
            let groupName = muscle.group.rawValue
            if let entity = loadEntity(named: groupName) {
                entityCache[groupName] = entity
                return entity
            }
        }

        return nil
    }

    /// 全身モデルを読み込む
    func loadFullBodyEntity() -> ModelEntity? {
        if let cached = entityCache["body_full"] {
            return cached
        }

        if let entity = loadEntity(named: "body_full") {
            entityCache["body_full"] = entity
            return entity
        }

        return nil
    }

    /// USDZファイルからEntityを読み込む
    private func loadEntity(named name: String) -> ModelEntity? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "usdz",
            subdirectory: "3DModels"
        ) else {
            return nil
        }

        do {
            // iOS 17互換: Entity.load(contentsOf:) を使用
            let entity = try Entity.load(contentsOf: url)
            // ModelEntityにキャスト、またはModelEntity子要素を探す
            if let modelEntity = entity as? ModelEntity {
                return modelEntity
            }
            // 子階層からModelEntityを探す
            return entity.findEntity(named: name) as? ModelEntity
                ?? entity.children.compactMap({ $0 as? ModelEntity }).first
        } catch {
            return nil
        }
    }

    // MARK: - キャッシュ管理

    /// キャッシュをクリア
    func clearCache() {
        entityCache.removeAll()
    }

    /// 3Dが利用可能か
    var is3DAvailable: Bool {
        currentLevel != .fallback2D
    }
}

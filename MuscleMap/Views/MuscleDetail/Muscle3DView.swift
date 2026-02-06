import SwiftUI
import RealityKit

// MARK: - 3D筋肉ビュー（RealityKit + 2Dフォールバック）

struct Muscle3DView: View {
    let muscle: Muscle
    let visualState: MuscleVisualState

    @State private var entity: ModelEntity?
    @State private var isLoading = true

    private var is3DAvailable: Bool {
        ModelLoader.shared.is3DAvailable
    }

    var body: some View {
        Group {
            if is3DAvailable {
                // 3Dビュー（RealityKit）
                realityKitView
            } else {
                // 2Dフォールバック
                fallback2DView
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 3Dビュー

    @ViewBuilder
    private var realityKitView: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if let entity = entity {
                RealityKitContainer(entity: entity, highlightColor: visualState.color)
            } else {
                fallback2DView
            }
        }
        .onAppear {
            entity = ModelLoader.shared.loadMuscleEntity(for: muscle)
            isLoading = false
        }
    }

    // MARK: - 筋肉がフロント/バックどちらにあるか判定

    private var isBackMuscle: Bool {
        let backOnly = MusclePathData.backMuscles.contains(where: { $0.muscle == muscle })
        let frontAlso = MusclePathData.frontMuscles.contains(where: { $0.muscle == muscle })
        // バックにあってフロントにない → バック筋肉
        // 両方にある場合（forearms, gastrocnemius, soleus）→ フロントを優先
        return backOnly && !frontAlso
    }

    private var muscleEntries: [(muscle: Muscle, path: (CGRect) -> Path)] {
        isBackMuscle ? MusclePathData.backMuscles : MusclePathData.frontMuscles
    }

    // MARK: - 2Dフォールバック（ズーム版）

    private var fallback2DView: some View {
        ZStack {
            Color.mmBgCard

            GeometryReader { geo in
                let fullSize = CGSize(
                    width: geo.size.width,
                    height: geo.size.width / 0.6 // body aspect ratio
                )
                let fullRect = CGRect(origin: .zero, size: fullSize)

                // 対象筋肉のバウンディングボックスを取得
                let targetBounds = muscleBoundingBox(in: fullRect)
                // パディングを追加
                let padding = max(targetBounds.width, targetBounds.height) * 0.4
                let expandedBounds = targetBounds.insetBy(dx: -padding, dy: -padding)

                // ビューポートにフィットするスケール
                let scaleX = geo.size.width / expandedBounds.width
                let scaleY = geo.size.height / expandedBounds.height
                let scale = min(scaleX, scaleY)

                // 中心合わせのオフセット
                let offsetX = geo.size.width / 2 - expandedBounds.midX * scale
                let offsetY = geo.size.height / 2 - expandedBounds.midY * scale

                ZStack {
                    // シルエット（背景）— 対象筋肉を際立たせるため極薄
                    let outline = isBackMuscle
                        ? MusclePathData.bodyOutlineBack(in: fullRect)
                        : MusclePathData.bodyOutlineFront(in: fullRect)
                    outline
                        .fill(Color.mmBgSecondary.opacity(0.12))
                    outline
                        .stroke(Color.mmMuscleBorder.opacity(0.08), lineWidth: 0.3)

                    // すべての筋肉を薄く表示（対象筋肉のみ際立たせる）
                    ForEach(muscleEntries, id: \.muscle) { entry in
                        entry.path(fullRect)
                            .fill(entry.muscle == muscle ? highlightColor : dimColor)
                            .opacity(entry.muscle == muscle ? 1.0 : 0.08)
                    }

                    // 対象筋肉のストローク（強調）
                    ForEach(muscleEntries, id: \.muscle) { entry in
                        if entry.muscle == muscle {
                            entry.path(fullRect)
                                .stroke(highlightColor.opacity(0.6), lineWidth: 1.5)
                        }
                    }
                }
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: offsetX, y: offsetY)
            }
            .clipped()

            // 筋肉名ラベル
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text(muscle.localizedName)
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Text(muscle.group.localizedName)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(12)
                }
            }
        }
    }

    // MARK: - バウンディングボックス計算

    private func muscleBoundingBox(in rect: CGRect) -> CGRect {
        // 対象筋肉のパスからバウンディングボックスを取得
        for entry in muscleEntries {
            if entry.muscle == muscle {
                let path = entry.path(rect)
                let bounds = path.boundingRect
                if !bounds.isEmpty {
                    return bounds
                }
            }
        }
        // フォールバック：全体を返す
        return rect
    }

    // MARK: - ローディング

    private var loadingView: some View {
        ZStack {
            Color.mmBgCard
            ProgressView()
                .tint(Color.mmAccentPrimary)
        }
    }

    // MARK: - 色

    private var highlightColor: Color {
        switch visualState {
        case .inactive:
            return .mmAccentPrimary
        default:
            return visualState.color
        }
    }

    private var dimColor: Color {
        Color.mmTextSecondary.opacity(0.2)
    }
}

// MARK: - RealityKit コンテナ

private struct RealityKitContainer: UIViewRepresentable {
    let entity: ModelEntity
    let highlightColor: Color

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.cameraMode = .nonAR
        arView.environment.background = .color(UIColor(Color.mmBgCard))

        // ライティング
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 1000
        directionalLight.look(at: .zero, from: SIMD3<Float>(2, 4, 3), relativeTo: nil)

        let anchor = AnchorEntity()
        anchor.addChild(entity)
        anchor.addChild(directionalLight)

        // モデルのバウンディングボックスに合わせてスケール
        let bounds = entity.visualBounds(relativeTo: nil)
        let maxDimension = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        if maxDimension > 0 {
            let scale = 0.5 / maxDimension
            entity.scale = SIMD3<Float>(repeating: scale)
        }

        // ハイライト色のマテリアルを適用
        applyHighlightMaterial(to: entity)

        arView.scene.addAnchor(anchor)

        // カメラ位置
        let camera = PerspectiveCamera()
        camera.look(at: .zero, from: SIMD3<Float>(0, 0.3, 0.8), relativeTo: nil)
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        // ジェスチャーで回転可能に
        arView.installGestures([.rotation, .scale], for: entity)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    private func applyHighlightMaterial(to entity: ModelEntity) {
        let uiColor = UIColor(highlightColor)
        var material = SimpleMaterial()
        material.color = .init(tint: uiColor.withAlphaComponent(0.8))
        material.metallic = .float(0.3)
        material.roughness = .float(0.6)
        entity.model?.materials = [material]
    }
}

#Preview {
    VStack(spacing: 16) {
        Muscle3DView(muscle: .chestUpper, visualState: .recovering(progress: 0.3))
        Muscle3DView(muscle: .lats, visualState: .neglected(fast: false))
    }
    .padding()
    .background(Color.mmBgPrimary)
}

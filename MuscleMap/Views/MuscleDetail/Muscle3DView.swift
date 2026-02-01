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
            } else if entity != nil {
                RealityKitContainer(entity: entity!, highlightColor: visualState.color)
            } else {
                fallback2DView
            }
        }
        .onAppear {
            entity = ModelLoader.shared.loadMuscleEntity(for: muscle)
            isLoading = false
        }
    }

    // MARK: - 2Dフォールバック（強化版）

    private var fallback2DView: some View {
        ZStack {
            Color.mmBgCard

            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)

                ZStack {
                    // シルエット
                    MusclePathData.bodyOutlineFront(in: rect)
                        .fill(Color.mmBgSecondary.opacity(0.3))

                    // 対象筋肉のハイライト（フロント側）
                    ForEach(MusclePathData.frontMuscles, id: \.muscle) { entry in
                        entry.path(rect)
                            .fill(entry.muscle == muscle ? highlightColor : dimColor)
                            .opacity(entry.muscle == muscle ? 1.0 : 0.15)
                    }

                    // 対象筋肉のハイライト（バック側で見つかる場合）
                    ForEach(MusclePathData.backMuscles, id: \.muscle) { entry in
                        if entry.muscle == muscle,
                           !MusclePathData.frontMuscles.contains(where: { $0.muscle == muscle }) {
                            // バックオンリーの筋肉：バックシルエットで表示
                            entry.path(rect)
                                .fill(highlightColor)
                        }
                    }

                    // 筋肉名ラベル
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 2) {
                                Text(muscle.japaneseName)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                Text(muscle.group.japaneseName)
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
        }
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

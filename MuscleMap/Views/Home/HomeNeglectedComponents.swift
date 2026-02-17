import SwiftUI

// MARK: - 未刺激警告

struct NeglectedWarningView: View {
    let muscleInfos: [NeglectedMuscleInfo]
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.mmMuscleNeglected)
                Text(L10n.neglectedMuscles)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(muscleInfos) { info in
                    Text(info.muscle.localizedName)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.mmMuscleNeglected.opacity(0.2))
                        .foregroundStyle(Color.mmMuscleNeglected)
                        .clipShape(Capsule())
                }
            }

            // シェアボタン
            Button {
                prepareShareImage()
                showingShareSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.shareShame)
                }
                .font(.caption.bold())
                .foregroundStyle(Color.mmMuscleNeglected)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.mmMuscleNeglected.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                let worstMuscle = muscleInfos.first
                let shareText = L10n.neglectedShareText(
                    worstMuscle?.muscle.localizedName ?? "",
                    worstMuscle?.daysSinceStimulation ?? 0,
                    AppConstants.shareHashtag,
                    AppConstants.appStoreURL
                )
                ShareSheet(items: [shareText, image], onComplete: nil)
            }
        }
    }

    @MainActor
    private func prepareShareImage() {
        let shareCard = NeglectedShareCard(muscleInfos: muscleInfos)
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
        }
    }
}

// MARK: - 未刺激シェアカード

struct NeglectedShareCard: View {
    let muscleInfos: [NeglectedMuscleInfo]

    private var neglectedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        // 未刺激の筋肉を紫表示用に設定（-1は特別な値として紫を示す）
        for info in muscleInfos {
            mapping[info.muscle.rawValue] = -1
        }
        return mapping
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーション（紫系）
            LinearGradient(
                colors: [Color.mmMuscleNeglected, Color.mmMuscleNeglected.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // タイトル
                VStack(spacing: 4) {
                    Text("NEGLECTED ALERT ⚠️")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmMuscleNeglected)
                    Text(L10n.neglectedShareSubtitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                // 筋肉マップ（紫ハイライト）
                NeglectedMuscleMapView(neglectedMuscles: Set(muscleInfos.map { $0.muscle }))
                    .frame(height: 200)

                // 未刺激部位リスト
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(muscleInfos.prefix(5)) { info in
                        HStack {
                            Circle()
                                .fill(Color.mmMuscleNeglected)
                                .frame(width: 8, height: 8)
                            Text(info.muscle.localizedName)
                                .font(.caption.bold())
                                .foregroundStyle(Color.mmTextPrimary)
                            Spacer()
                            Text(L10n.daysNeglected(info.daysSinceStimulation))
                                .font(.caption)
                                .foregroundStyle(Color.mmMuscleNeglected)
                        }
                    }
                    if muscleInfos.count > 5 {
                        Text(L10n.andMoreCount(muscleInfos.count - 5))
                            .font(.caption)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // フッター
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmMuscleNeglected.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    Text("MuscleMap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 390, height: 693)
        .background(
            LinearGradient(
                colors: [Color.mmBgCard, Color.mmBgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmMuscleNeglected.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }

}

// MARK: - 未刺激筋肉マップビュー（紫ハイライト）

struct NeglectedMuscleMapView: View {
    let neglectedMuscles: Set<Muscle>

    var body: some View {
        HStack(spacing: 20) {
            // 前面
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in MusclePathData.frontMuscles {
                    let path = entry.path(rect)
                    let isNeglected = neglectedMuscles.contains(entry.muscle)
                    let color = isNeglected ? Color.mmMuscleNeglected : Color.mmBgSecondary

                    context.fill(path, with: .color(color))
                    context.stroke(
                        path,
                        with: .color(Color.mmMuscleBorder.opacity(0.4)),
                        lineWidth: 0.5
                    )
                }
            }
            .frame(width: 100, height: 180)

            // 背面
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                for entry in MusclePathData.backMuscles {
                    let path = entry.path(rect)
                    let isNeglected = neglectedMuscles.contains(entry.muscle)
                    let color = isNeglected ? Color.mmMuscleNeglected : Color.mmBgSecondary

                    context.fill(path, with: .color(color))
                    context.stroke(
                        path,
                        with: .color(Color.mmMuscleBorder.opacity(0.4)),
                        lineWidth: 0.5
                    )
                }
            }
            .frame(width: 100, height: 180)
        }
    }
}

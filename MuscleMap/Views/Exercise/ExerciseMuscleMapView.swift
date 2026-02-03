import SwiftUI

// MARK: - 種目の対象筋肉マップビュー

struct ExerciseMuscleMapView: View {
    /// 筋肉ID → 刺激度% (0-100)
    let muscleMapping: [String: Int]
    
    @State private var showingFront = true
    
    var body: some View {
        VStack(spacing: 8) {
            // 切り替えラベル
            HStack {
                Text(showingFront ? "前面" : "背面")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFront.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text(showingFront ? "背面を見る" : "前面を見る")
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.mmAccentSecondary)
                }
            }
            .padding(.horizontal, 8)
            
            // 筋肉マップ
            GeometryReader { geo in
                let rect = CGRect(origin: .zero, size: geo.size)
                
                ZStack {
                    // シルエット（背景）
                    if showingFront {
                        MusclePathData.bodyOutlineFront(in: rect)
                            .fill(Color.mmBgCard.opacity(0.4))
                            .overlay {
                                MusclePathData.bodyOutlineFront(in: rect)
                                    .stroke(Color.mmMuscleBorder, lineWidth: 1)
                            }
                    } else {
                        MusclePathData.bodyOutlineBack(in: rect)
                            .fill(Color.mmBgCard.opacity(0.4))
                            .overlay {
                                MusclePathData.bodyOutlineBack(in: rect)
                                    .stroke(Color.mmMuscleBorder, lineWidth: 1)
                            }
                    }
                    
                    // 筋肉パス
                    let muscles = showingFront
                        ? MusclePathData.frontMuscles
                        : MusclePathData.backMuscles
                    
                    ForEach(muscles, id: \.muscle) { entry in
                        let stimulation = stimulationFor(entry.muscle)
                        
                        entry.path(rect)
                            .fill(colorFor(stimulation: stimulation))
                            .overlay {
                                entry.path(rect)
                                    .stroke(Color.mmMuscleBorder, lineWidth: 0.8)
                            }
                    }
                }
            }
            .aspectRatio(0.6, contentMode: .fit)
            
            // 凡例
            legendView
        }
    }
    
    // MARK: - 刺激度の取得
    
    private func stimulationFor(_ muscle: Muscle) -> Int {
        // muscle.rawValue は "chestUpper" 形式
        // muscleMapping のキーは "chest_upper" 形式の可能性があるので両方チェック
        if let value = muscleMapping[muscle.rawValue] {
            return value
        }
        // スネークケースに変換してチェック
        let snakeCase = muscle.rawValue.toSnakeCase()
        if let value = muscleMapping[snakeCase] {
            return value
        }
        return 0
    }
    
    // MARK: - 刺激度に応じた色
    
    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            return Color.mmTextSecondary.opacity(0.1)
        }
        
        // 刺激度に応じてグラデーション
        // 低 → 黄緑、中 → 黄、高 → オレンジ/赤
        let opacity = 0.3 + (Double(stimulation) / 100.0) * 0.7
        
        switch stimulation {
        case 80...:
            return Color.mmMuscleJustWorked.opacity(opacity)
        case 50..<80:
            return Color.mmMuscleAmber.opacity(opacity)
        case 20..<50:
            return Color.mmMuscleLime.opacity(opacity)
        default:
            return Color.mmMuscleLime.opacity(0.4)
        }
    }
    
    // MARK: - 凡例
    
    private var legendView: some View {
        HStack(spacing: 16) {
            LegendItem(color: .mmMuscleJustWorked, label: "高 (80%+)")
            LegendItem(color: .mmMuscleAmber, label: "中 (50-79%)")
            LegendItem(color: .mmMuscleLime, label: "低 (1-49%)")
        }
        .font(.caption2)
    }
}

// MARK: - 凡例アイテム

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Color.mmTextSecondary)
        }
    }
}

// MARK: - String Extension (camelCase → snake_case)

private extension String {
    func toSnakeCase() -> String {
        var result = ""
        for (index, char) in self.enumerated() {
            if char.isUppercase {
                if index > 0 {
                    result += "_"
                }
                result += char.lowercased()
            } else {
                result += String(char)
            }
        }
        return result
    }
}

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        
        ExerciseMuscleMapView(muscleMapping: [
            "chest_upper": 65,
            "chest_lower": 100,
            "deltoid_anterior": 50,
            "triceps": 40
        ])
        .padding()
    }
}

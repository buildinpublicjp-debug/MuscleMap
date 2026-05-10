import SwiftUI

// MARK: - 種目辞典 + 種目選択 で共有するコンポーネント (CC-D で共通化済み)
//
// 旧 ExerciseLibraryView.swift から CC-L (v1.1.5 リデザイン) 時点で分離した。
// ExerciseLibraryView 自体は新レイアウトに置換されたが、これらの型は
// ExercisePickerView / WorkoutIdleComponents.MuscleExercisePickerSheet で
// 引き続き使用されているため、独立ファイルに残す。

// MARK: - 器具フィルターEnum（固定順序）

@MainActor
enum LibraryEquipmentFilter: String, CaseIterable, Identifiable {
    case dumbbell = "ダンベル"
    case barbell = "バーベル"
    case machine = "マシン"
    case cable = "ケーブル"
    case bodyweight = "自重"

    var id: String { rawValue }

    var localizedName: String {
        L10n.localizedEquipment(rawValue)
    }
}

// MARK: - コンパクト筋肉マップ（タップでフィルタ連動、現状の Biblioteca では未使用だが互換のため残置）

struct CompactLibraryMuscleMap: View {
    @Binding var selectedGroup: MuscleGroup?

    var body: some View {
        HStack(spacing: 0) {
            LibraryMiniBodySide(
                muscles: MusclePathData.frontMuscles,
                selectedGroup: $selectedGroup
            )
            LibraryMiniBodySide(
                muscles: MusclePathData.backMuscles,
                selectedGroup: $selectedGroup
            )
        }
    }
}

// MARK: - 前面/背面の片側ビュー

private struct LibraryMiniBodySide: View {
    let muscles: [(muscle: Muscle, path: (CGRect) -> Path)]
    @Binding var selectedGroup: MuscleGroup?
    @State private var rect: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            let r = CGRect(origin: .zero, size: geo.size)
            ZStack {
                ForEach(muscles, id: \.muscle) { entry in
                    let group = entry.muscle.group
                    let isSelected = selectedGroup == group
                    let isOtherSelected = selectedGroup != nil && !isSelected

                    entry.path(r)
                        .fill(muscleColor(isSelected: isSelected, isOtherSelected: isOtherSelected))
                    entry.path(r)
                        .stroke(Color.mmMuscleBorder.opacity(0.4), lineWidth: 0.8)
                }
            }
            .drawingGroup()
            .allowsHitTesting(false)
            .overlay {
                Color.white.opacity(0.001)
                    .onTapGesture { location in
                        handleTap(at: location, in: r)
                    }
            }
            .onAppear { rect = r }
            .onChange(of: geo.size) { _, newSize in
                rect = CGRect(origin: .zero, size: newSize)
            }
        }
        .aspectRatio(0.55, contentMode: .fit)
    }

    private func handleTap(at point: CGPoint, in currentRect: CGRect) {
        let r = currentRect.size != .zero ? currentRect : rect
        guard r.size != .zero else { return }
        for entry in muscles.reversed() {
            let path = entry.path(r)
            if path.contains(point) {
                let tappedGroup = entry.muscle.group
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedGroup == tappedGroup {
                        selectedGroup = nil
                    } else {
                        selectedGroup = tappedGroup
                    }
                }
                HapticManager.lightTap()
                return
            }
        }
    }

    private func muscleColor(isSelected: Bool, isOtherSelected: Bool) -> Color {
        if isSelected {
            return Color.mmAccentPrimary.opacity(0.8)
        } else if isOtherSelected {
            return Color.mmMuscleInactive.opacity(0.4)
        } else {
            return Color.mmMuscleInactive
        }
    }
}

// MARK: - コンパクトフィルターチップ（種目辞典 + 種目選択 共通、CC-D で共有化）

struct LibraryChip: View {
    let title: String
    let isSelected: Bool
    var recoveryDot: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let dotColor = recoveryDot {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.mmAccentPrimary : Color.mmBgCard)
            .foregroundStyle(isSelected ? Color.mmBgPrimary : Color.mmTextSecondary)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 折り返しレイアウト（FlowLayout、CC-D で共有化）

struct LibraryFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: width, height: y + rowHeight), positions)
    }
}

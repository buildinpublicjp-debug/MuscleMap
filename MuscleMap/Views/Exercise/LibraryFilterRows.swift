import SwiftUI

// MARK: - 部位 + 器具 フィルター行（Biblioteca タブ + 種目選択モーダル 共有）
//
// CC-L で Biblioteca が確定したフラットチップ 2行構造をコンポーネント化。
// 旧 ExerciseLibraryView の private chipRow / flatChip をそのまま外出し。
// ★ お気に入り toggle は呼び出し側のヘッダーに置くため含めない。

struct LibraryFilterRows: View {
    @Binding var selectedMuscleGroup: MuscleGroup?
    @Binding var selectedEquipment: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chipRow(label: L10n.axisMusculo) {
                ForEach(MuscleGroup.allCases) { group in
                    flatChip(
                        title: group.localizedName,
                        isActive: selectedMuscleGroup == group
                    ) {
                        selectedMuscleGroup = (selectedMuscleGroup == group) ? nil : group
                    }
                }
            }

            chipRow(label: L10n.axisEquipo) {
                ForEach(LibraryEquipmentFilter.allCases) { filter in
                    flatChip(
                        title: filter.localizedName,
                        isActive: selectedEquipment == filter.rawValue
                    ) {
                        selectedEquipment = (selectedEquipment == filter.rawValue) ? nil : filter.rawValue
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chipRow<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
                .frame(width: 36, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content()
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, 16)
    }

    private func flatChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.lightTap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? Color.mmAccentPrimary : Color.mmBgCard)
                .foregroundStyle(isActive ? Color.mmBgPrimary : Color.mmTextPrimary)
                .clipShape(Capsule())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

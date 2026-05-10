import Foundation

// MARK: - Biblioteca / 種目辞典 のフィルター状態 (v1.1.5)
//
// 「Explorar por」軸 + ソート選択肢の enum 定義。実際のフィルター状態は
// 既存 ExerciseListViewModel に持つ (selectedMuscleGroup / selectedEquipment /
// selectedCategory / showFavoritesOnly 等を流用)。

/// 主軸選択 (radio、1つだけ active)
enum ExploreAxis: String, CaseIterable, Identifiable {
    case musculo
    case equipo
    case nivel
    case favoritos

    var id: String { rawValue }

    /// SF Symbol アイコン
    var iconName: String {
        switch self {
        case .musculo:   return "figure.strengthtraining.traditional"
        case .equipo:    return "dumbbell"
        case .nivel:     return "chart.bar"
        case .favoritos: return "star.fill"
        }
    }
}

/// 種目グリッドのソート方式
enum LibrarySortOption: String, CaseIterable, Identifiable {
    case relevancia
    case nombre
    case recientes
    case favoritosPrimero

    var id: String { rawValue }
}

/// 難易度の正規化キー (exercises.json の文字列とアプリ内表示の橋渡し)
/// 既存 exercise.difficulty は "初級" / "中級" / "上級" 等の文字列なので、それをそのまま比較対象にする。
enum LibraryDifficulty: String, CaseIterable, Identifiable {
    case principiante  // 初級
    case intermedio    // 中級
    case avanzado      // 上級

    var id: String { rawValue }

    /// exercises.json の difficulty 文字列との照合 (日本語の rawValue)
    var matchKeys: [String] {
        switch self {
        case .principiante: return ["初級", "Beginner", "Principiante", "Débutant", "Anfänger", "초급", "初级"]
        case .intermedio:   return ["中級", "Intermediate", "Intermedio", "Intermédiaire", "Mittel", "중급", "中级"]
        case .avanzado:     return ["上級", "Advanced", "Avanzado", "Avancé", "Fortgeschritten", "고급", "高级"]
        }
    }
}

# MuscleMap - Claude Code Rules

> **v2.1 | 2026-02-01**
> 筋肉の回復状態を可視化し、最適なトレーニングを導くiOSアプリ

---

## プロジェクト概要

**MuscleMap**は、トレーニングで刺激した筋肉をリアルタイムに可視化し、回復状態を追跡するiOSアプリ。

**コンセプト:** 「筋肉の状態が見える。だから、迷わない。」

**核心機能:**
1. 2D SVG筋肉マップで21筋肉の回復状態をリアルタイム表示（ホーム画面）
2. ボリューム係数付き回復計算（セット数で回復時間が変動）
3. 7日以上未刺激の筋肉を紫で点滅警告
4. 今日のメニュー自動提案（回復データからルールベースで生成。ジムで開いた瞬間に始められる）
5. 80種目のEMGベース刺激度マッピング
6. 3D部位詳細表示（RealityKit、フォールバックあり）
7. RevenueCat課金（¥980/月、¥7,800/年、¥12,000買い切り）

**デザイントーン:** 「バイオモニター × G-SHOCK」 — ダーク基調、データが浮かび上がる

---

## 技術スタック

| 項目 | 選定 |
|:---|:---|
| Platform | iOS 17.0+ |
| Language | Swift 5.9+ |
| UI | SwiftUI |
| DB | Swift Data |
| Architecture | MVVM + Repository Pattern |
| 2D人体図 | SVG（カスタムSwiftUI Path） |
| 3D表示 | RealityKit |
| 課金 | **RevenueCat SDK** |
| 3Dモデル | TurboSquid（USDZ） |

---

## 必読ドキュメント

1. `docs/PRD/MuscleMap_PRD_v2.1.md` — **最も重要。全仕様が入っている**
2. `ROADMAP.md` — 開発フェーズとスケジュール

---

## データモデル

### 筋肉定義（21筋肉）

```swift
enum Muscle: String, CaseIterable, Codable {
    // 胸（2）
    case chestUpper = "chest_upper"
    case chestLower = "chest_lower"
    // 背中（4）
    case lats = "lats"
    case trapsUpper = "traps_upper"
    case trapsMiddleLower = "traps_middle_lower"
    case erectorSpinae = "erector_spinae"
    // 肩（3）
    case deltoidAnterior = "deltoid_anterior"
    case deltoidLateral = "deltoid_lateral"
    case deltoidPosterior = "deltoid_posterior"
    // 腕（3）
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    // 体幹（2）
    case rectusAbdominis = "rectus_abdominis"
    case obliques = "obliques"
    // 下半身（7）
    case glutes = "glutes"
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case adductors = "adductors"
    case hipFlexors = "hip_flexors"
    case gastrocnemius = "gastrocnemius"
    case soleus = "soleus"

    var japaneseName: String {
        switch self {
        case .chestUpper: return "大胸筋上部"
        case .chestLower: return "大胸筋下部"
        case .lats: return "広背筋"
        case .trapsUpper: return "僧帽筋上部"
        case .trapsMiddleLower: return "僧帽筋中部・下部"
        case .erectorSpinae: return "脊柱起立筋"
        case .deltoidAnterior: return "三角筋前部"
        case .deltoidLateral: return "三角筋中部"
        case .deltoidPosterior: return "三角筋後部"
        case .biceps: return "上腕二頭筋"
        case .triceps: return "上腕三頭筋"
        case .forearms: return "前腕筋群"
        case .rectusAbdominis: return "腹直筋"
        case .obliques: return "腹斜筋"
        case .glutes: return "臀筋群"
        case .quadriceps: return "大腿四頭筋"
        case .hamstrings: return "ハムストリングス"
        case .adductors: return "内転筋群"
        case .hipFlexors: return "腸腰筋"
        case .gastrocnemius: return "腓腹筋"
        case .soleus: return "ヒラメ筋"
        }
    }

    var group: MuscleGroup {
        switch self {
        case .chestUpper, .chestLower: return .chest
        case .lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae: return .back
        case .deltoidAnterior, .deltoidLateral, .deltoidPosterior: return .shoulders
        case .biceps, .triceps, .forearms: return .arms
        case .rectusAbdominis, .obliques: return .core
        case .glutes, .quadriceps, .hamstrings, .adductors, .hipFlexors, .gastrocnemius, .soleus: return .lowerBody
        }
    }

    /// 基準回復時間（時間）。ボリューム係数で調整される
    var baseRecoveryHours: Int {
        switch self {
        // 大筋群: 72h
        case .lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae,
             .glutes, .quadriceps, .hamstrings, .adductors, .hipFlexors:
            return 72
        // 中筋群: 48h
        case .chestUpper, .chestLower,
             .deltoidAnterior, .deltoidLateral, .deltoidPosterior,
             .biceps, .triceps:
            return 48
        // 小筋群: 24h
        case .forearms, .rectusAbdominis, .obliques, .gastrocnemius, .soleus:
            return 24
        }
    }
}

enum MuscleGroup: String, CaseIterable, Codable {
    case chest, back, shoulders, arms, core, lowerBody

    var japaneseName: String {
        switch self {
        case .chest: return "胸"
        case .back: return "背中"
        case .shoulders: return "肩"
        case .arms: return "腕"
        case .core: return "体幹"
        case .lowerBody: return "下半身"
        }
    }
}
```

### 回復計算（ボリューム係数付き）

```swift
struct RecoveryCalculator {
    /// セット数からボリューム係数を算出
    static func volumeCoefficient(sets: Int) -> Double {
        switch sets {
        case 1:     return 0.7    // 軽く触っただけ
        case 2:     return 0.85
        case 3:     return 1.0    // 標準
        case 4:     return 1.1
        default:    return 1.15   // 5セット以上（上限）
        }
    }

    /// 調整済み回復時間（時間）
    static func adjustedRecoveryHours(muscle: Muscle, totalSets: Int) -> Double {
        Double(muscle.baseRecoveryHours) * volumeCoefficient(sets: totalSets)
    }

    /// 回復進捗（0.0=直後 〜 1.0=完全回復）
    static func recoveryProgress(stimulationDate: Date, muscle: Muscle, totalSets: Int) -> Double {
        let elapsed = Date().timeIntervalSince(stimulationDate) / 3600 // 時間
        let needed = adjustedRecoveryHours(muscle: muscle, totalSets: totalSets)
        return min(1.0, max(0.0, elapsed / needed))
    }

    /// 未刺激日数
    static func daysSinceStimulation(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}
```

### Swift Data モデル

```swift
@Model
class WorkoutSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String?
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    var isActive: Bool { endDate == nil }
}

@Model
class WorkoutSet {
    var id: UUID
    var session: WorkoutSession?
    var exerciseId: String       // exercises.json の id
    var setNumber: Int           // 1, 2, 3...
    var weight: Double           // kg
    var reps: Int
    var completedAt: Date
}

@Model
class MuscleStimulation {
    var muscle: String           // Muscle.rawValue
    var stimulationDate: Date
    var maxIntensity: Double     // 0.0-1.0（刺激度%の最大値/100）
    var totalSets: Int           // その日の合計セット数（ボリューム係数用）
    var sessionId: UUID
}
```

### 種目データ（exercises.json）

`Resources/exercises.json` にバンドル同梱。起動時にExerciseStoreに読み込む。
**80種目、EMG論文ベースで刺激度%を修正済み。**

```swift
struct ExerciseDefinition: Codable, Identifiable {
    let id: String
    let nameEN: String
    let nameJA: String
    let category: String
    let equipment: String
    let difficulty: String
    let muscleMapping: [String: Int]  // muscle_id → stimulation % (20-100)
}

@MainActor
class ExerciseStore {
    static let shared = ExerciseStore()
    private(set) var exercises: [ExerciseDefinition] = []
    private var exerciseMap: [String: ExerciseDefinition] = [:]

    func load() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        exercises = (try? JSONDecoder().decode([ExerciseDefinition].self, from: data)) ?? []
        exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }

    func exercise(for id: String) -> ExerciseDefinition? { exerciseMap[id] }
    func exercises(for category: String) -> [ExerciseDefinition] { exercises.filter { $0.category == category } }
    func exercises(targeting muscle: String) -> [ExerciseDefinition] {
        exercises.filter { $0.muscleMapping[muscle] != nil }
    }
}
```

---

## カラーパレット

```swift
extension Color {
    // 背景
    static let mmBgPrimary = Color(hex: "#121212")
    static let mmBgSecondary = Color(hex: "#1E1E1E")
    static let mmBgCard = Color(hex: "#2A2A2A")

    // テキスト
    static let mmTextPrimary = Color.white
    static let mmTextSecondary = Color(hex: "#9E9E9E")

    // アクセント
    static let mmAccentPrimary = Color(hex: "#00FFB3")    // バイオグリーン
    static let mmAccentSecondary = Color(hex: "#00D4FF")  // 電光ブルー

    // 筋肉状態（バイオルミネッセンス6段階）
    static let mmMuscleJustWorked = Color(hex: "#E94560")  // 深紅（回復0-10%）
    static let mmMuscleCoral = Color(hex: "#F4845F")       // コーラル（10-30%）
    static let mmMuscleAmber = Color(hex: "#F4A261")       // アンバー（30-50%）
    static let mmMuscleMint = Color(hex: "#7EC8A0")        // ミント（50-70%）
    static let mmMuscleBioGreen = Color(hex: "#00FFB3")    // バイオグリーン（70-99%）
    static let mmMuscleNeglected = Color(hex: "#9B59B6")   // 紫（7日+未刺激）
}
```

### 色の計算

```swift
enum MuscleVisualState {
    case inactive                                    // 背景に溶け込む
    case recovering(color: Color, pulse: Bool)       // 回復中
    case neglected(fast: Bool)                       // 未刺激（fast=14日+）
}

func muscleVisualState(for muscle: Muscle) -> MuscleVisualState {
    guard let stim = latestStimulation(for: muscle) else {
        let days = RecoveryCalculator.daysSinceStimulation(lastKnownDate(for: muscle))
        if days >= 14 { return .neglected(fast: true) }
        if days >= 7 { return .neglected(fast: false) }
        return .inactive
    }

    let progress = stim.recoveryProgress
    if progress >= 1.0 { return .inactive }

    let color: Color = switch progress {
    case 0..<0.1:   .mmMuscleJustWorked
    case 0.1..<0.3: Color.interpolate(from: .mmMuscleJustWorked, to: .mmMuscleCoral, t: (progress - 0.1) / 0.2)
    case 0.3..<0.5: Color.interpolate(from: .mmMuscleCoral, to: .mmMuscleAmber, t: (progress - 0.3) / 0.2)
    case 0.5..<0.7: Color.interpolate(from: .mmMuscleAmber, to: .mmMuscleMint, t: (progress - 0.5) / 0.2)
    case 0.7..<0.9: Color.interpolate(from: .mmMuscleMint, to: .mmMuscleBioGreen, t: (progress - 0.7) / 0.2)
    default:        .mmMuscleBioGreen.opacity(max(0.1, (1.0 - progress) * 10))
    }

    return .recovering(color: color, pulse: progress < 0.1)
}
```

---

## 画面構成

```
TabBar
├── ホーム（筋肉マップ）         ← P0
├── ワークアウト（記録）          ← P0
├── 種目辞典                    ← P1
└── 履歴（統計）                ← P1

Modal / Push
├── 今日のメニュー提案           ← P0（ワークアウト開始時に表示）
├── ワークアウト実行中           ← P0
├── 種目詳細                    ← P1
├── 部位詳細（3D）              ← P1
├── 設定                        ← P1
└── Paywall                     ← P1
```

---

## 今日のメニュー提案ロジック

```swift
struct MenuSuggestionService {
    func suggestTodayMenu(
        muscleStates: [Muscle: MuscleStimulation?],
        exerciseStore: ExerciseStore
    ) -> SuggestedMenu {
        // 1. 回復完了の筋肉を取得
        // 2. グループ単位で最も長く刺激されてないものを優先
        // 3. ペアリング（胸+三頭、背中+二頭、肩+体幹、脚単独）
        // 4. 各グループの主要種目を選出（刺激度%順）
        // 5. 未刺激7日+があれば1種目追加
        // 6. 前回の重量・レップをデフォルトセット
    }

    func pairGroups(primary: MuscleGroup) -> [MuscleGroup] {
        switch primary {
        case .chest:     return [.chest, .arms]      // 胸+三頭
        case .back:      return [.back, .arms]       // 背中+二頭
        case .shoulders: return [.shoulders, .core]   // 肩+体幹
        case .lowerBody: return [.lowerBody]          // 脚単独
        default:         return [primary]
        }
    }
}

struct SuggestedMenu {
    let primaryGroup: MuscleGroup
    let reason: String
    let exercises: [SuggestedExercise]
    let neglectedWarning: Muscle?
}

struct SuggestedExercise {
    let definition: ExerciseDefinition
    let suggestedSets: Int
    let suggestedReps: Int
    let lastWeight: Double?
    let isNeglectedFix: Bool
}
```

---

## ファイル構成

```
MuscleMap/
├── App/
│   ├── MuscleMapApp.swift
│   ├── ContentView.swift
│   └── AppState.swift
├── Models/
│   ├── Muscle.swift
│   ├── ExerciseDefinition.swift
│   ├── WorkoutSession.swift
│   ├── WorkoutSet.swift
│   └── MuscleStimulation.swift
├── Repositories/
│   ├── ExerciseStore.swift
│   ├── WorkoutRepository.swift
│   └── MuscleStateRepository.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── WorkoutViewModel.swift
│   ├── ExerciseListViewModel.swift
│   ├── MuscleDetailViewModel.swift
│   └── HistoryViewModel.swift
├── Views/
│   ├── Home/
│   ├── Workout/
│   ├── Exercise/
│   ├── MuscleDetail/
│   ├── History/
│   ├── Onboarding/
│   ├── Settings/
│   └── Paywall/
├── Resources/
│   ├── exercises.json
│   ├── Assets.xcassets
│   └── 3DModels/
└── Utilities/
    ├── RecoveryCalculator.swift
    ├── MenuSuggestionService.swift
    ├── ColorCalculator.swift
    ├── ColorExtensions.swift
    └── DateExtensions.swift
```

---

## 課金（RevenueCat）

```swift
// Entitlement: "premium"
// 月額: ¥980/月（7日間トライアル）
// 年額: ¥7,800/年（14日間トライアル）← 推奨
// 買い切り: ¥12,000
```

---

## コーディング規約

### MUST（必須）
- SwiftUI Only
- Swift Data でデータ永続化
- MVVM + Repository Pattern
- `@Observable` マクロ使用（iOS 17+）
- `async/await` 使用
- 日本語コメント

### MUST NOT（禁止）
- UIKit使用（SwiftUIで代替可能な場合）
- ハードコード文字列（Localizable対応準備）
- 200行超のView（分割する）
- Force Unwrap (`!`) の乱用
- muscleMapping数値をコードにハードコード（JSONから読む）

### SHOULD（推奨）
- Preview Provider を全Viewに用意
- 8の倍数でスペーシング
- Haptic Feedback（セット完了、ワークアウト終了時）

---

## 3Dフォールバック戦略

```
Phase 3（Week 4）で3Dモデルの品質を判定:
レベルA: 21筋肉完全分離 → 理想
レベルB: 6-8グループ分離 → 現実的
レベルC: 3D断念 → 2D SVGオンリーでリリース
```

---

## テスト

- **MUST:** RecoveryCalculator の全メソッドにUnit Test
- **MUST:** Repository のデータ操作にテスト
- **MUST:** ExerciseStore のJSON読み込みテスト
- **SHOULD:** 主要フローのUIテスト

---

## 開発フェーズ（6週間）

Phase 1（Week 1）: データモデル + 回復計算 + ExerciseStore
Phase 2（Week 2-3）: SVG人体図 + ホーム画面 + ワークアウト記録 + 種目辞典
Phase 3（Week 4）: 3Dモデル調達・統合 + 部位詳細
Phase 4（Week 5）: 履歴・統計 + RevenueCat + Paywall
Phase 5（Week 6）: オンボーディング + 設定 + 磨き込み + App Store申請

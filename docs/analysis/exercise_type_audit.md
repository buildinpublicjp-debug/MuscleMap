# Exercise Type Audit — exercises.json 全92種目分類

> **v1.0 | 2026-03-20**
> StrengthScoreCalculator ロジック修正の事前分析

---

## 1. 全92種目の分類テーブル

### 分類定義

| 分類 | 説明 | kg方向 | 例 |
|:---|:---|:---|:---|
| **weighted** | 器具の重量を記録。重量=挙上量そのもの | higher=stronger | ベンチプレス、スクワット |
| **bodyweight** | 体重+追加重量。記録kgは追加重量（0kg=自重のみ） | higher=stronger（追加重量） | 懸垂、ディップス、プッシュアップ |
| **assisted** | 補助重量を記録。kgが低い=補助が少ない=強い | **lower=stronger** | アシストプルアップ |

---

### 1.1 胸（12種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 1 | barbell_bench_press | バーベルベンチプレス | バーベル | 中級 | weighted | higher=stronger | BIG3 |
| 2 | incline_barbell_bench_press | インクラインベンチプレス | バーベル | 中級 | weighted | higher=stronger | |
| 3 | decline_barbell_bench_press | デクラインベンチプレス | バーベル | 中級 | weighted | higher=stronger | |
| 4 | dumbbell_bench_press | ダンベルベンチプレス | ダンベル | 初級 | weighted | higher=stronger | |
| 5 | incline_dumbbell_press | インクラインダンベルプレス | ダンベル | 初級 | weighted | higher=stronger | |
| 6 | dumbbell_fly | ダンベルフライ | ダンベル | 初級 | weighted | higher=stronger | |
| 7 | cable_crossover | ケーブルクロスオーバー | ケーブル | 中級 | weighted | higher=stronger | |
| 8 | **push_up** | **プッシュアップ（腕立て伏せ）** | **自重** | 初級 | **bodyweight** | higher=stronger | 体重+追加重量 |
| 9 | **chest_dip** | **ディップス（胸）** | **自重** | 中級 | **bodyweight** | higher=stronger | 体重+追加重量。器具必要（平行棒） |
| 10 | pec_deck_machine | ペックデック（マシンフライ） | マシン | 初級 | weighted | higher=stronger | |
| 11 | machine_chest_press | チェストプレス（マシン） | マシン | 初級 | weighted | higher=stronger | |
| 12 | machine_incline_press | インクラインチェストプレス（マシン） | マシン | 初級 | weighted | higher=stronger | |

### 1.2 背中（13種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 13 | deadlift | デッドリフト | バーベル | 上級 | weighted | higher=stronger | BIG3 |
| 14 | barbell_bent_over_row | バーベルベントオーバーロウ | バーベル | 中級 | weighted | higher=stronger | |
| 15 | dumbbell_row | ダンベルロウ（ワンハンド） | ダンベル | 初級 | weighted | higher=stronger | |
| 16 | lat_pulldown | ラットプルダウン | マシン | 初級 | weighted | higher=stronger | |
| 17 | **pull_up** | **懸垂（プルアップ）** | **自重** | 上級 | **bodyweight** | higher=stronger | 体重+追加重量 |
| 18 | **chin_up** | **チンアップ（逆手懸垂）** | **自重** | 上級 | **bodyweight** | higher=stronger | 体重+追加重量 |
| 19 | seated_cable_row | シーテッドケーブルロウ | ケーブル | 初級 | weighted | higher=stronger | |
| 20 | t_bar_row | Tバーロウ | バーベル | 中級 | weighted | higher=stronger | |
| 21 | face_pull | フェイスプル | ケーブル | 初級 | weighted | higher=stronger | |
| 22 | **hyperextension** | **バックエクステンション** | **自重** | 初級 | **bodyweight** | higher=stronger | プレート追加可能 |
| 23 | barbell_shrug | バーベルシュラッグ | バーベル | 初級 | weighted | higher=stronger | |
| 24 | machine_row | ローイングマシン | マシン | 初級 | weighted | higher=stronger | |
| 25 | **assisted_pull_up** | **アシストプルアップ（マシン）** | **マシン** | 初級 | **assisted** | **lower=stronger** | 補助重量。0kg=完全自力 |

### 1.3 肩（10種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 26 | overhead_press_barbell | オーバーヘッドプレス | バーベル | 中級 | weighted | higher=stronger | |
| 27 | dumbbell_shoulder_press | ダンベルショルダープレス | ダンベル | 初級 | weighted | higher=stronger | |
| 28 | lateral_raise | サイドレイズ（ラテラルレイズ） | ダンベル | 初級 | weighted | higher=stronger | |
| 29 | front_raise | フロントレイズ | ダンベル | 初級 | weighted | higher=stronger | |
| 30 | rear_delt_fly | リアデルトフライ | ダンベル | 初級 | weighted | higher=stronger | |
| 31 | arnold_press | アーノルドプレス | ダンベル | 中級 | weighted | higher=stronger | |
| 32 | upright_row | アップライトロウ | バーベル | 中級 | weighted | higher=stronger | |
| 33 | cable_lateral_raise | ケーブルサイドレイズ | ケーブル | 初級 | weighted | higher=stronger | |
| 34 | machine_shoulder_press | ショルダープレス（マシン） | マシン | 初級 | weighted | higher=stronger | |
| 35 | machine_lateral_raise | サイドレイズ（マシン） | マシン | 初級 | weighted | higher=stronger | |
| 36 | machine_rear_delt | リアデルト（マシン） | マシン | 初級 | weighted | higher=stronger | |

### 1.4 腕 — 二頭筋（8種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 37 | barbell_curl | バーベルカール | バーベル | 初級 | weighted | higher=stronger | |
| 38 | dumbbell_curl | ダンベルカール | ダンベル | 初級 | weighted | higher=stronger | |
| 39 | hammer_curl | ハンマーカール | ダンベル | 初級 | weighted | higher=stronger | |
| 40 | preacher_curl | プリーチャーカール | バーベル | 初級 | weighted | higher=stronger | |
| 41 | concentration_curl | コンセントレーションカール | ダンベル | 初級 | weighted | higher=stronger | |
| 42 | cable_curl | ケーブルカール | ケーブル | 初級 | weighted | higher=stronger | |
| 43 | incline_dumbbell_curl | インクラインダンベルカール | ダンベル | 中級 | weighted | higher=stronger | |
| 44 | machine_bicep_curl | アームカール（マシン） | マシン | 初級 | weighted | higher=stronger | |

### 1.5 腕 — 三頭筋（7種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 45 | tricep_pushdown | トライセプスプッシュダウン | ケーブル | 初級 | weighted | higher=stronger | |
| 46 | overhead_tricep_extension | オーバーヘッドトライセプスEX | ダンベル | 初級 | weighted | higher=stronger | |
| 47 | skull_crusher | スカルクラッシャー | バーベル | 中級 | weighted | higher=stronger | |
| 48 | close_grip_bench_press | ナローベンチプレス | バーベル | 中級 | weighted | higher=stronger | |
| 49 | **tricep_dip** | **ディップス（三頭）** | **自重** | 中級 | **bodyweight** | higher=stronger | 体重+追加重量 |
| 50 | tricep_kickback | トライセプスキックバック | ダンベル | 初級 | weighted | higher=stronger | |
| 51 | machine_tricep_extension | トライセプスエクステンション（マシン） | マシン | 初級 | weighted | higher=stronger | |

### 1.6 腕 — 前腕（3種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 52 | wrist_curl | リストカール | ダンベル | 初級 | weighted | higher=stronger | |
| 53 | reverse_wrist_curl | リバースリストカール | ダンベル | 初級 | weighted | higher=stronger | |
| 54 | farmer's_walk | ファーマーズウォーク | ダンベル | 中級 | weighted | higher=stronger | |

### 1.7 体幹（12種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 55 | **crunch** | **クランチ** | **自重** | 初級 | **bodyweight** | higher=stronger | 追加重量は稀。多くの場合0kg記録 |
| 56 | **sit_up** | **シットアップ（腹筋）** | **自重** | 初級 | **bodyweight** | higher=stronger | 同上 |
| 57 | **hanging_leg_raise** | **ハンギングレッグレイズ** | **自重** | 上級 | **bodyweight** | higher=stronger | バーにぶら下がる。追加重量は稀 |
| 58 | **plank** | **プランク** | **自重** | 初級 | **bodyweight** | N/A | **時間ベース種目。重量記録に適さない** |
| 59 | **side_plank** | **サイドプランク** | **自重** | 初級 | **bodyweight** | N/A | **時間ベース種目。重量記録に適さない** |
| 60 | **russian_twist** | **ロシアンツイスト** | **自重** | 中級 | **bodyweight** | higher=stronger | プレート/ダンベル追加可能 |
| 61 | cable_woodchop | ケーブルウッドチョップ | ケーブル | 中級 | weighted | higher=stronger | |
| 62 | ab_roller | アブローラー | 器具 | 上級 | **bodyweight** | N/A | **基本自重のみ。重量記録に適さない** |
| 63 | **mountain_climber** | **マウンテンクライマー** | **自重** | 中級 | **bodyweight** | N/A | **有酸素/時間ベース。重量記録に適さない** |
| 64 | machine_crunch | アブドミナルクランチ（マシン） | マシン | 初級 | weighted | higher=stronger | |
| 65 | torso_rotation | トルソーローテーション | マシン | 初級 | weighted | higher=stronger | |
| 66 | **bicycle_crunch** | **バイシクルクランチ** | **自重** | 初級 | **bodyweight** | N/A | **自重のみ。重量記録に適さない** |

### 1.8 下半身 — 四頭筋（11種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 67 | barbell_back_squat | バーベルスクワット | バーベル | 上級 | weighted | higher=stronger | BIG3 |
| 68 | front_squat | フロントスクワット | バーベル | 上級 | weighted | higher=stronger | |
| 69 | goblet_squat | ゴブレットスクワット | ダンベル | 初級 | weighted | higher=stronger | |
| 70 | leg_press | レッグプレス | マシン | 初級 | weighted | higher=stronger | |
| 71 | hack_squat | ハックスクワット | マシン | 中級 | weighted | higher=stronger | |
| 72 | leg_extension | レッグエクステンション | マシン | 初級 | weighted | higher=stronger | |
| 73 | bulgarian_split_squat | ブルガリアンスプリットスクワット | ダンベル | 中級 | weighted | higher=stronger | |
| 74 | walking_lunge | ウォーキングランジ | ダンベル | 中級 | weighted | higher=stronger | |
| 75 | step_up | ステップアップ | ダンベル | 初級 | weighted | higher=stronger | |
| 76 | sumo_squat | スモウスクワット | ダンベル | 初級 | weighted | higher=stronger | |
| 77 | smith_squat | スミスマシンスクワット | マシン | 中級 | weighted | higher=stronger | |

### 1.9 下半身 — ハムストリングス（4種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 78 | romanian_deadlift | ルーマニアンデッドリフト | バーベル | 中級 | weighted | higher=stronger | |
| 79 | stiff_leg_deadlift | スティッフレッグデッドリフト | バーベル | 中級 | weighted | higher=stronger | |
| 80 | lying_leg_curl | ライイングレッグカール | マシン | 初級 | weighted | higher=stronger | |
| 81 | seated_leg_curl | シーテッドレッグカール | マシン | 初級 | weighted | higher=stronger | |

### 1.10 下半身 — 臀部（7種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 82 | hip_thrust | ヒップスラスト | バーベル | 中級 | weighted | higher=stronger | |
| 83 | **glute_bridge** | **グルートブリッジ** | **自重** | 初級 | **bodyweight** | higher=stronger | 体重+バーベル追加可能 |
| 84 | cable_kickback | ケーブルキックバック | ケーブル | 初級 | weighted | higher=stronger | |
| 85 | sumo_deadlift | スモウデッドリフト | バーベル | 上級 | weighted | higher=stronger | |
| 86 | adductor_machine | アダクターマシン（内転） | マシン | 初級 | weighted | higher=stronger | |
| 87 | hip_abductor | アブダクターマシン（外転） | マシン | 初級 | weighted | higher=stronger | |
| 88 | glute_drive | グルートドライブ（マシン） | マシン | 初級 | weighted | higher=stronger | |

### 1.11 下半身 — ふくらはぎ（2種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 89 | standing_calf_raise | スタンディングカーフレイズ | マシン | 初級 | weighted | higher=stronger | |
| 90 | seated_calf_raise | シーテッドカーフレイズ | マシン | 初級 | weighted | higher=stronger | |

### 1.12 全身（2種目）

| # | id | nameJA | equipment | difficulty | 分類 | kg方向 | 備考 |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 91 | kettlebell_swing | ケトルベルスイング | ケトルベル | 中級 | weighted | higher=stronger | |
| 92 | **burpee** | **バーピー** | **自重** | 中級 | **bodyweight** | N/A | **有酸素/高レップ。重量記録に適さない** |

---

## 2. 分類サマリー

| 分類 | 種目数 | 割合 | 種目ID一覧 |
|:---|:---:|:---:|:---|
| **weighted** | 74 | 80.4% | （上記テーブルで太字以外の全種目） |
| **bodyweight** | 17 | 18.5% | push_up, chest_dip, pull_up, chin_up, hyperextension, tricep_dip, crunch, sit_up, hanging_leg_raise, plank, side_plank, russian_twist, ab_roller, mountain_climber, bicycle_crunch, glute_bridge, burpee |
| **assisted** | 1 | 1.1% | assisted_pull_up |

### bodyweight種目のサブ分類

| サブ分類 | 種目数 | 種目 | 備考 |
|:---|:---:|:---|:---|
| **追加重量が一般的** | 6 | pull_up, chin_up, chest_dip, tricep_dip, push_up, hyperextension | `体重+追加kg` で1RM計算すべき |
| **追加重量が可能だが稀** | 4 | crunch, sit_up, hanging_leg_raise, russian_twist, glute_bridge | 0kg記録が大半。体重ベースのratio計算は不適切 |
| **重量記録に不適** | 6 | plank, side_plank, mountain_climber, bicycle_crunch, ab_roller, burpee | 時間/レップ/有酸素ベース。Strength Score算出から**除外すべき** |

---

## 3. StrengthScoreCalculator.swift 影響箇所

### 3.1 `muscleStrengthScores()` — L222-262

```swift
// L248: 問題箇所
let strengthRatio = best1RM / bodyweight
```

**問題:**
- **weighted種目**: `best1RM` = 挙上重量の推定1RM → `ratio = 挙上1RM / 体重` → **正しい**
- **bodyweight種目（追加重量型）**: `best1RM` = 追加重量の推定1RM → `ratio = 追加重量1RM / 体重` → **過小評価**
  - 例: 体重70kgの人が20kg加重懸垂×5rep → `estimated1RM = 23.3kg` → `ratio = 0.33`
  - 実際の挙上力: `70 + 23.3 = 93.3kg` → 正しい`ratio = 1.33`
  - **スコア差: 0.33→compoundLargeで0.15程度 vs 1.33→0.72程度。致命的な差**
- **bodyweight種目（重量不適）**: `best1RM` = 0kg → `ratio = 0` → スコア0。問題はないが無意味なデータ
- **assisted種目**: `best1RM` = 補助重量の推定1RM → `ratio = 補助重量1RM / 体重` → **完全に逆。低い値=強いのに高スコアになる**
  - 例: 30kgアシスト（弱い）→ `ratio = 0.43` → スコア付与。10kgアシスト（強い）→ `ratio = 0.14` → 低スコア

### 3.2 `exerciseStrengthLevel()` — L305-337

```swift
// L311: 同じ問題
let ratio = estimated1RM / bodyweight
```

**同一の問題。** bodyweight種目の推定1RMを直接体重で割っている。

### 3.3 `overallLevel()` — L340-345

`muscleStrengthScores()` の結果を使用しているため、間接的に影響を受ける。

### 3.4 `displayParams()` — L350-388

スコアベースなので直接は問題ないが、入力スコアが誤っていれば表示も誤る。

### 3.5 影響箇所まとめ

| メソッド | 行 | 問題 | 影響度 |
|:---|:---|:---|:---|
| `muscleStrengthScores()` | L248 | bodyweight種目のratioが過小 / assisted種目のratioが逆 | **致命的** |
| `exerciseStrengthLevel()` | L311 | 同上 | **致命的** |
| `overallLevel()` | L340 | 間接的に誤スコア | 高 |
| `displayParams()` | L350 | 入力スコア依存 | 間接 |
| `grade()` | L267 | 入力スコア依存 | 間接 |

---

## 4. PRManager.swift のロジック分析

### 4.1 `estimated1RM()` — L78-81

```swift
func estimated1RM(weight: Double, reps: Int) -> Double {
    guard reps > 1 else { return weight }
    return weight * (1 + Double(reps) / 30.0)
}
```

**現状:** `weight` パラメータはWorkoutSetの`.weight`をそのまま受け取る。

**問題:**
- **weighted種目**: `weight` = 挙上重量 → Epley式適用 → **正しい**
- **bodyweight種目**: `weight` = 追加重量（0kgも多い） → Epley式適用 → **体重が加算されていない**
  - 0kg × 10rep → `estimated1RM = 0.0` → 無意味
  - 20kg × 5rep → `estimated1RM = 23.3` → 体重分が欠落
- **assisted種目**: `weight` = 補助重量 → Epley式適用 → **意味が逆。体重-補助=実質挙上力**

### 4.2 修正提案

**bodyweight種目の場合:**
```
effective1RM = (bodyweight + additionalWeight) * (1 + reps / 30.0)
```
ただし `reps == 1` の場合: `effective1RM = bodyweight + additionalWeight`

**assisted種目の場合:**
```
effective1RM = (bodyweight - assistWeight) * (1 + reps / 30.0)
```
ただし `bodyweight - assistWeight` が負にならないようclamp必要。

**重量不適種目の場合:**
Strength Score計算から除外するか、レップ数ベースの別スコア体系を検討。

### 4.3 `getWeightPR()` / `getBestEstimated1RM()`

これらもWorkoutSetの`.weight`をそのまま使用しているため、bodyweight/assisted種目では意味のない比較になる。

---

## 5. difficulty フィールド値一覧

exercises.json内で使用されている`difficulty`の値:

| 値 | 種目数 | 英語相当 |
|:---|:---:|:---|
| **初級** | 47 | Beginner |
| **中級** | 32 | Intermediate |
| **上級** | 13 | Advanced |

**注:** `expert` や他の値は存在しない。全種目が3段階（初級/中級/上級）のいずれか。

### difficulty別の内訳

**上級（13種目）:**
deadlift, pull_up, chin_up, hanging_leg_raise, ab_roller, barbell_back_squat, front_squat, sumo_deadlift

**中級（32種目）:**
barbell_bench_press, incline_barbell_bench_press, decline_barbell_bench_press, cable_crossover, chest_dip, overhead_press_barbell, arnold_press, upright_row, barbell_bent_over_row, t_bar_row, incline_dumbbell_curl, skull_crusher, close_grip_bench_press, tricep_dip, farmer's_walk, russian_twist, cable_woodchop, mountain_climber, bulgarian_split_squat, walking_lunge, hack_squat, smith_squat, romanian_deadlift, stiff_leg_deadlift, hip_thrust, kettlebell_swing, burpee

**初級（47種目）:** 残り全て

---

## 6. 修正が必要な追加データ

### 6.1 ExerciseDefinitionに追加すべきフィールド（案）

```json
{
  "id": "pull_up",
  "exerciseType": "bodyweight",   // "weighted" | "bodyweight" | "assisted"
  ...
}
```

または、コード側で種目IDベースのハードコードマッピングを持つ:

```swift
private static let bodyweightExercises: Set<String> = [
    "push_up", "chest_dip", "pull_up", "chin_up", "hyperextension",
    "tricep_dip", "crunch", "sit_up", "hanging_leg_raise", "plank",
    "side_plank", "russian_twist", "ab_roller", "mountain_climber",
    "bicycle_crunch", "glute_bridge", "burpee"
]

private static let assistedExercises: Set<String> = [
    "assisted_pull_up"
]

private static let strengthScoreExcluded: Set<String> = [
    "plank", "side_plank", "mountain_climber", "bicycle_crunch",
    "ab_roller", "burpee"
]
```

### 6.2 equipment別種目数

| equipment | 種目数 |
|:---|:---:|
| バーベル | 18 |
| ダンベル | 25 |
| マシン | 27 |
| ケーブル | 8 |
| 自重 | 17 |
| ケトルベル | 1 |
| 器具 | 1 |

### 6.3 exercises.jsonの`equipment`値と分類の関係

- `equipment == "自重"` → ほぼ全てが `bodyweight` 分類（17/17）
- `equipment == "マシン"` で `assisted` は `assisted_pull_up` のみ（1/27）
- それ以外は全て `weighted`

**重要:** `equipment == "自重"` だけでは分類できない。assisted_pull_upは `equipment == "マシン"` だが分類は `assisted`。

---

## 7. 結論と次のアクション

### 影響を受けるユーザーシナリオ

1. **加重懸垂ユーザー**: pull_up/chin_upで20kg加重 → Strength Mapでlats/bicepsのスコアが実力の1/4程度に過小表示
2. **自重トレーニーユーザー**: push_up, dip等がStrength Mapにほぼ反映されない
3. **初心者がアシストプルアップ使用**: 補助30kgが「30kg挙上」扱いになり過大評価
4. **プランク/バーピーユーザー**: Strength Scoreに寄与しないのは正しいが、混乱の元

### 修正優先度

| 修正 | 優先度 | 影響 |
|:---|:---|:---|
| bodyweight種目の1RM計算に体重加算 | P0 | Strength Map精度の根幹 |
| assisted種目の1RM計算を反転 | P0 | 同上（現在は逆スコア） |
| 重量不適種目をStrength Score算出から除外 | P1 | 無意味な0スコア防止 |
| exercises.jsonにexerciseTypeフィールド追加 | P1 | ハードコード回避 |
| PRManager.estimated1RMのbodyweight対応 | P0 | 上記全ての前提 |

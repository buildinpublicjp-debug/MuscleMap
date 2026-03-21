# ハードコード文字列監査レポート

> 作成日: 2026-03-21
> 対象: MuscleMap コードベース全体

---

## サマリー

| 指標 | 件数 |
|:---|---:|
| `L10n.` 使用箇所 | 474 |
| `isJapanese ? "..."` ハードコードパターン | 119 |
| `currentLanguage == .japanese` 直接チェック | 77 |
| 対応言語（AppLanguage） | 4（ja, en, zh-Hans, ko） |

**結論:** L10nシステムは整備されているが、全体の約20%がハードコード `isJapanese ?` パターンで残存。特にオンボーディング系Viewに集中。

---

## Part A: Muscle.swift 筋肉名ローカライズ状況

### 現状

| 項目 | 状態 |
|:---|:---|
| `japaneseName` | 全21筋肉 ✅ |
| `englishName` | 全21筋肉 ✅ |
| `localizedName` | ja/en のみ切替 ⚠️ |
| 中国語名 | なし ❌ |
| 韓国語名 | なし ❌ |

### 対応

`chineseName` と `koreanName` プロパティを追加し、`localizedName` を4言語対応に拡張。
MuscleGroup にも同様に追加。

---

## Part B: ハードコード文字列一覧（ファイル別）

### 🔴 オンボーディング（74件 — 全体の62%）

| ファイル | 件数 | 主な内容 |
|:---|---:|:---|
| FrequencySelectionPage.swift | 19 | 週回数ラベル、分割法説明、凡例テキスト |
| PaywallView.swift | 14 | CTA、価格、機能リスト、法的テキスト |
| TrainingHistoryPage.swift | 11 | トレ歴ラベル、BMI判定、身長/体重ラベル |
| NotificationPermissionView.swift | 11 | 通知サンプル、ステップバッジ |
| RoutineCompletionPage.swift | 10 | 目標別キャッチコピー、カバレッジラベル |
| GoalMusclePreviewPage.swift | 9 | 目標別ヘッドライン、カバー率、ボタン |
| PRInputPage.swift | 9 | 入力ガイド、レベル表示、スキップ |
| LocationSelectionPage.swift | 8 | 場所名、説明文、器具フィルタ名 |
| RoutineBuilderPage.swift | 6 | ボタン、場所ピッカー |
| SplashView.swift | 3 | タグライン、開始ボタン |
| GoalSelectionPage.swift | 2 | 重点部位ラベル、バリデーション |

### 🟡 メイン画面（11件）

| ファイル | 件数 | 主な内容 |
|:---|---:|:---|
| SettingsView.swift | 7 | トレ歴Picker、経験レベル |
| ExerciseDictionaryView.swift | 4 | フィルタラベル（すべて、お気に入り） |

### 🟢 その他（3件）

| ファイル | 件数 | 主な内容 |
|:---|---:|:---|
| NotificationManager.swift | 3 | 通知タイトル（回復完了、トレーニング時間、週間サマリー） |
| ActiveWorkoutComponents.swift | 1 | ルーティン完了テキスト |
| HomeHelpers.swift | 1 | コーチマーク |
| MuscleDetailView.swift | 1 | フィルタ「すべて」 |

---

## 移行優先度

### P0: 即座に移行すべき（ユーザー露出度高）

- **PaywallView.swift** — 課金画面。App Store審査で多言語対応が評価される
- **NotificationManager.swift** — ローカル通知。OSレベルで表示される
- **SettingsView.swift** — 日常的に使う画面

### P1: 次バージョンで移行（オンボーディング）

- FrequencySelectionPage, LocationSelectionPage, TrainingHistoryPage
- PRInputPage, GoalMusclePreviewPage, RoutineBuilderPage
- RoutineCompletionPage, NotificationPermissionView, SplashView
- GoalSelectionPage

### P2: 低優先度（影響小）

- ActiveWorkoutComponents（1件）
- ExerciseDictionaryView（フィルタラベル）
- MuscleDetailView（1件）
- HomeHelpers（1件）

---

## 補足: `currentLanguage == .japanese` パターン（77件）

これらは `isJapanese` computed property 経由のものが多く、直接 L10n 化は不要だが、
4言語対応時には `isJapanese ? ja : en` → `LocalizedStringKey` or `L10n.key` への移行が必要。

### 影響ファイル（上位）

| ファイル | 件数 |
|:---|---:|
| HomeHelpers.swift | 21 |
| MuscleHistoryDetailSheet.swift | 13 |
| HistoryStatsComponents.swift | 9 |
| HistoryMapComponents.swift | 6 |
| FrequencySelectionPage.swift | 7 |
| WorkoutCompletionSections.swift | 5 |
| ExercisePickerView.swift | 5 |
| WorkoutCompletionView.swift | 4 |
| GoalSelectionPage.swift | 4 |

---

## 推奨アクション

1. **Muscle.swift / MuscleGroup** に中国語・韓国語名を追加 → `localizedName` を4言語対応（本タスクで実施）
2. **PaywallView + NotificationManager** のハードコード文字列を L10n に移行（P0）
3. **オンボーディング全View** の `isJapanese ?` パターンを L10n に段階的に移行（P1）
4. 新規コードでは `isJapanese ?` パターン禁止、`L10n.key` を必須化

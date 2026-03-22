# MuscleMap データ層・ユーティリティ・設定画面 コードレビュー

> **v1.0 | 2026-03-22**
> 対象: Utilities/, Models/, Views/Settings/, Views/History/, App/

---

## 総合スコア: 7.5/10

| カテゴリ | スコア | 概要 |
|:---|:---|:---|
| PurchaseManager | 6/10 | APIキーハードコード、forceProForTesting残存 |
| RoutineManager | 9/10 | 堅実な設計、swap操作のみ非アトミック |
| LocalizationManager | 7/10 | 688キー定義済みだが139箇所のハードコード残り |
| SwiftDataモデル | 7/10 | スキーマバージョニング未設定、入力検証なし |
| AppState | 9/10 | UserDefaults双方向同期が堅実 |
| RecoveryCalculator | 8/10 | 0セット安全、未来日付のガードなし |
| 設定画面 | 8/10 | 言語切替即時反映、プロフィール保存にトースト |
| 履歴画面 | 8/10 | 前面+背面表示正常、GIFサムネ実装済み |
| App Store準備 | 5/10 | Info.plist不足、Legal URLがdebugドメイン |

---

## CRITICAL（App Store提出ブロッカー）

### C-1. RevenueCat APIキーがソースにハードコード
- **ファイル**: `Utilities/PurchaseManager.swift:33`
- **現状**: `Purchases.configure(withAPIKey: "appl_IzrrBdSVXMDZUylPnwcaJxvdlxb")`
- **リスク**: リポジトリにアクセスした誰でもAPIキーを取得可能
- **対策**: Info.plist または Build Settings のUser-Defined変数に移動

### C-2. Legal URLがdebugドメイン
- **ファイル**: `Utilities/LegalURL.swift:8-11`
- **現状**: `buildinpublicjp-debug.github.io` ドメインを使用
- **リスク**: App Store審査で「テスト用ドメイン」として拒否される可能性
- **対策**: 本番ドメインに変更

### C-3. Info.plistの権限説明が不足
- **ファイル**: `MuscleMap/Info.plist`
- **現状**: `LSApplicationQueriesSchemes`（instagram-stories）のみ
- **不足項目**:
  - `NSPrivacyTracking: false`（iOS 17+ Privacy Manifest必須）
  - シェアカード生成で写真ライブラリアクセスする場合: `NSPhotoLibraryUsageDescription`
  - RevenueCat SDKのPrivacy Manifest準拠確認
- **対策**: 必要な権限説明を全て追加

### C-4. SwiftDataスキーマバージョニング未設定
- **ファイル**: `App/MuscleMapApp.swift:25-29`
- **現状**: `ModelConfiguration`なし、スキーマバージョン指定なし
- **リスク**: v1.0リリース後にフィールド追加すると既存ユーザーのアプリがクラッシュ
- **対策**: `ModelContainer`にバージョニング設定を追加

---

## HIGH（v1.0リリース前に修正推奨）

### H-1. forceProForTesting フラグが本番コードに残存
- **ファイル**: `Utilities/PurchaseManager.swift:13`
- **現状**: `private let forceProForTesting = false`
- **リスク**: 誤って`true`にしてリリースすると全ユーザーが無料Pro
- **状態**: 値は`false`で安全だが、存在自体がリスク
- **対策**: `#if DEBUG`ガードで囲むか削除

### H-2. RecoveryCalculator 未来日付ガードなし
- **ファイル**: `Utilities/RecoveryCalculator.swift:31-41`
- **現状**: `stimulationDate`が未来の場合、`elapsed`が負になる
- **影響**: 回復進捗が0.0（「たった今刺激」）と表示される
- **対策**: `guard stimulationDate <= now else { return 0.0 }` 追加

### H-3. UserProfile入力検証なし
- **ファイル**: `Models/UserProfile.swift`
- **リスク箇所**:
  - `weightKg`が0の場合 → StrengthScoreCalculatorでゼロ除算
  - `heightCm`が負の場合 → BMI計算異常
  - `goalWeights`が1.0超の場合 → メニュー提案の重み計算破綻
- **対策**: init内でバリデーション追加（`precondition`またはclamp）

### H-4. DayWorkoutDetailView セット削除後のsession.sets未更新
- **ファイル**: `Views/History/DayWorkoutDetailView.swift:375-387`
- **現状**: `modelContext.delete(workoutSet)`後に`session.sets`が自動更新されない
- **リスク**: 削除直後の残セット数チェックが不正確
- **対策**: `session.sets.removeAll { $0.id == workoutSet.id }` を明示的に実行

### H-5. RoutineEditViewに保存フィードバックなし
- **ファイル**: `Views/Settings/RoutineEditView.swift:219-222`
- **現状**: `saveRoutine()`実行後、UIにフィードバックなし
- **対比**: SettingsViewのプロフィール編集はトースト表示あり
- **対策**: 同様のトースト表示を追加

---

## MEDIUM（v1.1で対応）

### M-1. isJapaneseハードコード 139箇所
- **パターン**: `localization.currentLanguage == .japanese ? "日本語" : "English"`
- **上位ファイル**:
  - `HomeHelpers.swift`: 23箇所
  - `MuscleHistoryDetailSheet.swift`: 15箇所
  - `WorkoutCompletionSections.swift`: 5箇所
  - `ContentView.swift`: 1箇所（種目辞典タブ名）
- **対策**: L10nキーへの段階的移行（688キー定義済み、632箇所で使用中）

### M-2. 空ファイル3つが残存
- `Utilities/DateExtensions.swift`: 空extension
- `Utilities/KeyManager.swift`: 空enum
- `Utilities/KeychainHelper.swift`: 空enum
- **対策**: 削除してコードベースをクリーンに

### M-3. WorkoutSet.session がOptional
- **ファイル**: `Models/WorkoutSet.swift`
- **現状**: `var session: WorkoutSession?`
- **リスク**: 親セッションなしの孤児レコードが蓄積される可能性
- **対策**: 非Optionalにするか、定期クリーンアップクエリ追加

### M-4. MuscleStimulation入力検証なし
- **ファイル**: `Models/MuscleStimulation.swift`
- **リスク**: `maxIntensity > 1.0`や`totalSets < 0`が保存可能
- **影響**: 回復計算・色計算が異常値を返す

### M-5. WidgetDataProviderのエラーログなし
- **ファイル**: `Utilities/WidgetDataProvider.swift`
- **現状**: `try? JSONEncoder().encode(data)` でサイレント失敗
- **対策**: `#if DEBUG` ログ追加

### M-6. ExerciseDefinition.isStrengthScoreExcluded ハードコード
- **ファイル**: `Models/ExerciseDefinition.swift`
- **現状**: 6種目のIDをハードコードで除外判定
- **リスク**: exercises.json更新時に同期漏れ
- **対策**: exercises.jsonにbooleanフィールド追加

---

## LOW（改善推奨）

### L-1. ColorExtensions Hexパースの入力検証なし
- `hex.count`チェック前に`Scanner`を実行
- 空文字列でクラッシュはしないが不正な色になる

### L-2. CSVParser「チンニング→ラットプルダウン」マッピング
- `ImportDataConverter.swift:215`: 解剖学的に不正確
- チンニング（懸垂）はプルアップに近い。代用としては許容範囲だが要コメント

### L-3. UserRoutineにswap操作がない
- `RoutineManager`にはadd/replace/removeあるがswapなし
- 種目の並べ替えは非アトミック（delete→add）

### L-4. MonthlyCalendarView backMuscleIds ハードコード
- `Views/History/MonthlyCalendarView.swift:210-213`
- Muscle enumから動的に取得すべき

### L-5. Locale fallback
- `AppState.swift:69`: `Locale.current.region?.identifier`が`nil`の場合の考慮
- VPN/リージョンスプーフィング時にkg/lb判定が不安定

---

## チェック項目別サマリー

### 1. PurchaseManager
| 項目 | 状態 |
|:---|:---|
| `forceProForTesting == false` | ✅ false（ただしコードに残存） |
| `weeklyFreeLimit` | ✅ 2（正しい） |
| `canRecordWorkout`ロジック | ✅ `isPremium \|\| weeklyWorkoutCount < weeklyFreeLimit` |
| 週リセットロジック | ✅ `.weekOfYear` + `.yearForWeekOfYear` で正確 |
| RevenueCat設定 | ❌ APIキーハードコード |

### 2. RoutineManager
| 項目 | 状態 |
|:---|:---|
| 保存/読み込み | ✅ UserDefaults + JSON Codable |
| pendingStartDay管理 | ✅ エフェメラル、消費後即クリア |
| 種目追加 | ✅ bounds check + 即時保存 |
| 種目削除 | ✅ bounds check + 即時保存 |
| 種目差替え | ✅ bounds check + 即時保存 |
| スレッド安全性 | ✅ @MainActorでシリアライズ |
| 後方互換 | ✅ `decodeIfPresent`でlocationフィールド |

### 3. LocalizationManager
| 項目 | 状態 |
|:---|:---|
| 7言語対応 | ✅ 日英中韓西仏独 |
| L10nキー定義数 | 688キー |
| L10n使用箇所 | 632箇所/62ファイル |
| ハードコード残り | ❌ 139箇所（`currentLanguage == .japanese`） |
| isJapanese分岐 | ❌ 15ファイルに分散 |

### 4. SwiftDataモデル
| モデル | フィールド | リレーション | 検証 |
|:---|:---|:---|:---|
| WorkoutSession | id, startDate, endDate?, note? | sets[] (cascade) | バージョニングなし |
| WorkoutSet | id, exerciseId, setNumber, weight, reps, completedAt | session? | weight/reps検証なし |
| MuscleStimulation | muscle, stimulationDate, maxIntensity, totalSets, sessionId | なし（手動FK） | intensity範囲検証なし |

### 5. AppState
| 項目 | 状態 |
|:---|:---|
| UserDefaults双方向同期 | ✅ didSet内で保存 |
| hasCompletedOnboarding | ✅ 正常動作 |
| hasCompletedFirstWorkout | ✅ 正常動作 |
| hasSeenHomeCoachMark | ✅ 正常動作 |
| チャレンジロジック | ✅ computed propertyで安全 |
| weightUnit判定 | ⚠️ Locale fallbackが不完全 |

### 6. RecoveryCalculator
| エッジケース | 状態 |
|:---|:---|
| 0セット | ✅ `volumeCoefficient`が0.7を返す |
| 負のセット数 | ✅ `...0`ケースで0.7 |
| 未来日付 | ❌ ガードなし（recovery=0.0として表示） |
| 超長期間（365日+） | ✅ `daysSinceStimulation`で正常計算 |

### 7. 設定画面
| 項目 | 状態 |
|:---|:---|
| 言語切替後のUI更新 | ✅ SwiftUI bindingで即時反映 |
| プロフィール編集の保存 | ✅ トースト表示あり |
| ルーティン編集画面 | ⚠️ 保存フィードバックなし |
| CSVImportView | ✅ 空スタブ（未使用） |

### 8. 履歴画面
| 項目 | 状態 |
|:---|:---|
| カレンダー前面+背面表示 | ✅ MonthlyCalendarView:228-241 |
| DayWorkoutDetail GIFサムネ | ✅ 50×50pt、fallbackあり |
| セット編集0.25kg刻み | ✅ タップ±0.25kg、長押し±2.5kg |
| 重量推移グラフ | ✅ LineMark + PointMark + PR表示 |

### 9. App Store提出ブロッカー
| 項目 | 状態 |
|:---|:---|
| Info.plist権限説明 | ❌ 不足（Privacy Manifest） |
| NSAppTransportSecurity | ✅ 不要（HTTPS使用） |
| Entitlements | ✅ App Groups正常 |
| Legal URLs | ❌ debugドメイン |
| バンドルID | ✅ `com.buildinpublic.MuscleMap` |
| RevenueCat APIキー | ❌ ハードコード |

---

## ファイル別品質スコア

### Utilities/
| ファイル | スコア | 備考 |
|:---|:---|:---|
| PurchaseManager.swift | 6/10 | APIキー露出、テストフラグ残存 |
| LocalizationManager.swift | 8/10 | 688キー定義、包括的だが巨大（1481行） |
| RecoveryCalculator.swift | 8/10 | 堅実、未来日付のみ要修正 |
| WorkoutRecommendationEngine.swift | 9/10 | 5段階パイプライン、よく構造化 |
| PRManager.swift | 10/10 | Epley式正確、エッジケース全対応 |
| StrengthScoreCalculator.swift | 9/10 | 数学的実装が優秀 |
| MenuSuggestionService.swift | 9/10 | 回復ベースのロジック健全 |
| NotificationManager.swift | 10/10 | 安全性重視の実装 |
| GoalMusclePriority.swift | 10/10 | データ構造が整理されている |
| ColorExtensions.swift | 9/10 | 包括的なカラーシステム |
| HapticManager.swift | 10/10 | パターン正確 |
| ThemeManager.swift | 9/10 | シンプルで正しい |
| WidgetDataProvider.swift | 8/10 | App Groups正常、エラーログなし |
| LegalURL.swift | 3/10 | debugドメイン（ブロッカー） |
| AppConstants.swift | 9/10 | App Store URL正常 |
| CSVParser.swift | 8/10 | パース正確 |
| ImportDataConverter.swift | 7/10 | チンニングマッピング不正確 |
| DateExtensions.swift | N/A | 空ファイル |
| KeyManager.swift | N/A | 空ファイル |
| KeychainHelper.swift | N/A | 空ファイル |

### Models/
| ファイル | スコア | 備考 |
|:---|:---|:---|
| WorkoutSession.swift | 8/10 | cascade正常、バージョニングなし |
| WorkoutSet.swift | 7/10 | session Optional、weight検証なし |
| MuscleStimulation.swift | 7/10 | intensity範囲検証なし |
| Muscle.swift | 10/10 | 21筋肉完全定義 |
| ExerciseDefinition.swift | 8/10 | Codable堅牢、exclusion list要改善 |
| UserProfile.swift | 7/10 | 入力検証なし、スレッド安全性不足 |
| UserRoutine.swift | 8/10 | 後方互換あり、location検証なし |
| FriendActivity.swift | 9/10 | 将来API用モック、問題なし |

### Views/
| ファイル | スコア | 備考 |
|:---|:---|:---|
| SettingsView.swift | 8/10 | 言語切替即時、プロフィール保存にトースト |
| RoutineEditView.swift | 7/10 | GIF/0.25kg正常、保存フィードバックなし |
| DayWorkoutDetailView.swift | 7/10 | セット削除後のsession.sets未更新 |
| HistoryView.swift | 9/10 | 正常動作 |
| MonthlyCalendarView.swift | 8/10 | 前面+背面表示正常 |
| MuscleHistoryDetailSheet.swift | 8/10 | 重量推移グラフ正常 |

---

## 推奨アクション（優先順）

### P0: App Store提出前（必須）
1. RevenueCat APIキーをInfo.plistに移動
2. LegalURLを本番ドメインに変更
3. Info.plistにPrivacy Manifest追加
4. SwiftDataスキーマバージョニング設定

### P1: v1.0リリース前（強く推奨）
5. `forceProForTesting`を`#if DEBUG`で囲む
6. RecoveryCalculatorに未来日付ガード追加
7. UserProfile.weightKg > 0 のバリデーション追加
8. DayWorkoutDetailViewのセット削除ロジック修正

### P2: v1.1（次回アップデート）
9. isJapaneseハードコード139箇所のL10n移行
10. 空ファイル3つの削除
11. ExerciseDefinition.isStrengthScoreExcludedをJSON化
12. RoutineManagerにswap操作追加

---

*Generated by Claude Code — 2026-03-22*

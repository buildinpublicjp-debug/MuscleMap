# RoutineBuilder → PaywallView → MainTabView フロー監査

> **v1.0 | 2026-03-20**
> 対象: オンボーディング後半〜課金〜メイン画面初期化までの全データフロー

---

## 1. 全体フロー図

```
OnboardingV2View (8ページ TabView)
 │
 ├─ Page 0: GoalSelectionPage
 │   └─ AppState.shared.primaryOnboardingGoal = goal.rawValue
 │
 ├─ Page 1: FrequencySelectionPage
 │   └─ AppState.shared.userProfile.weeklyFrequency = frequency.rawValue
 │
 ├─ Page 2: LocationSelectionPage
 │   └─ AppState.shared.userProfile.trainingLocation = location.rawValue
 │
 ├─ Page 3: ProfileInputPage (トレ歴 + 体重 + ニックネーム)
 │   └─ AppState.shared.userProfile.trainingExperience, weightKg, nickName
 │
 ├─ Page 4: PRInputPage (条件付き: oneYearPlus/veteran のみ)
 │   └─ AppState.shared.userProfile.initialPRs
 │
 ├─ Page 5: GoalMusclePreviewPage
 │   └─ AppState.shared.userProfile.goalPriorityMuscles = muscles.map { $0.rawValue }
 │
 ├─ Page 6: RoutineBuilderPage ★ 本監査の起点
 │   └─ RoutineManager.shared.routine = UserRoutine(days:, createdAt:)
 │   └─ FavoritesManager に種目登録
 │
 ├─ Page 7: RoutineCompletionPage ★ ハードペイウォール
 │   ├─ 「Pro版を解放」 → PaywallView(isHardPaywall: true)
 │   └─ 「無料ではじめる」 → onComplete()
 │
 └─ onComplete() が呼ばれると:
     └─ OnboardingView.notification フェーズへ
         └─ NotificationPermissionView
             └─ onComplete()
                 └─ ContentView: AppState.shared.hasCompletedOnboarding = true
                     └─ MainTabView 表示
```

---

## 2. RoutineBuilderPage → RoutineCompletionPage データフロー

### 2.1 RoutineBuilderPage の保存ロジック

**ファイル:** `Views/Onboarding/RoutineBuilderPage.swift`

最終Day（selectedDayIndex == days.count - 1）で「次へ」タップ時に `saveAndProceed()` が呼ばれる:

```
saveAndProceed():
  1. UserRoutine(days: days, createdAt: Date()) を生成
  2. RoutineManager.shared.saveRoutine(routine) で UserDefaults に保存
  3. 各Day の種目を FavoritesManager に登録
  4. onNext() を呼出（→ currentPage = 7）
```

**検出事項:**

| ID | 重要度 | 内容 |
|:---|:---|:---|
| RB-01 | **MEDIUM** | `canProceed` は `!days[selectedDayIndex].exercises.isEmpty` のみチェック。**現在のDayだけ**を検証しており、他のDayが空のまま最終Dayに到達→保存される可能性がある |
| RB-02 | **LOW** | `initializeDays()` で自動ピックされた種目が、ユーザーがDayを切り替えた際に再ピックされない（意図的だが、Dayの種目を全削除→別Dayに移動→戻ると空のまま） |
| RB-03 | **INFO** | 保存後の `onNext()` は同期呼出。保存失敗時（UserDefaults容量制限等）もページ遷移してしまう |

### 2.2 RoutineCompletionPage の読み込み

**ファイル:** `Views/Onboarding/RoutineCompletionPage.swift`

```swift
private var routine: UserRoutine {
    RoutineManager.shared.routine   // UserDefaults から同期読込
}
```

- `RoutineManager.shared` は `init()` で `UserRoutine.load()` を実行
- RoutineBuilderPage が `saveRoutine()` した直後なので、通常は最新データが取得される

**検出事項:**

| ID | 重要度 | 内容 |
|:---|:---|:---|
| RC-01 | **LOW** | `RoutineManager.shared.routine` はインメモリキャッシュ。`saveRoutine()` がインメモリ更新→UserDefaults保存の順なので、直後の読取りは安全 |
| RC-02 | **LOW** | `coveragePercent` 算出: `combinedMuscleMapping.count * 100 / Muscle.allCases.count` (21)。muscleMapping のキーが Muscle.rawValue でない場合（例: exercises.json の誤り）、カバー率が実態と乖離する |
| RC-03 | **INFO** | `goalBasedHeadline` は `AppState.shared.primaryOnboardingGoal` に依存。GoalSelectionPage で未保存の場合（理論上は発生しない）、デフォルトメッセージにフォールバック |

---

## 3. PaywallView フロー分析

### 3.1 呼出パターン

| 呼出元 | isHardPaywall | トリガー |
|:---|:---|:---|
| RoutineCompletionPage | `true` | 「Pro版を解放」ボタン (`fullScreenCover`) |
| ContentView (MainTabView) | `false` | ワークアウトタブ遷移 + `canRecordWorkout == false` (`sheet`) |
| HomeView | `false` | StrengthMapPreviewBanner タップ (`sheet`) |

### 3.2 購入フロー

**ファイル:** `Views/Paywall/PaywallView.swift` (403行)

```
ユーザータップ「7日間無料で始める」
  → purchase(productId: "yearly")
    → PurchaseManager.shared.purchase(productId: "yearly")
      → Purchases.shared.offerings() でオファリング取得
      → "yearly" → offering.annual ?? contains("year"/"annual") でパッケージ検索
      → Purchases.shared.purchase(package:) 実行
      → 成功: _isPremium = true → dismiss()
      → キャンセル: return false（何もしない）
      → エラー: errorMessage 表示
```

**検出事項:**

| ID | 重要度 | 内容 |
|:---|:---|:---|
| PW-01 | **HIGH** | **価格テキストがハードコード。** `yearlyPriceText = "¥4,900/年（月¥408）"`, `monthlyPriceText = "¥590/月"` (L285-292)。RevenueCat のオファリングから取得していない。App Store Connect で価格変更した場合、UIに反映されない。**App Store 審査リスク: Apple は動的価格表示を強く推奨** |
| PW-02 | **HIGH** | **productId が文字列ベース。** `purchase(productId: "yearly")` / `"monthly"` を PurchaseManager に渡し、`lowercased().contains("year")` でパッケージ検索 (PurchaseManager L60-63)。RevenueCat のパッケージIDが変わると購入不能になる |
| PW-03 | **MEDIUM** | **ハードペイウォール dismiss 後のフロー。** RoutineCompletionPage から `PaywallView(isHardPaywall: true)` → 購入成功 → `dismiss()` のみ。**RoutineCompletionPage の `onComplete()` は呼ばれない。** ユーザーは RoutineCompletionPage に戻り、「無料ではじめる」を押す必要がある |
| PW-04 | **MEDIUM** | **「無料で続ける」（ハードペイウォール）も `dismiss()` のみ。** RoutineCompletionPage に戻るだけ。オンボーディング完了にはならない |
| PW-05 | **LOW** | 購入中オーバーレイ表示時、ハードペイウォールの閉じるボタンは非表示だが、「無料で続ける」ボタンは disable されていない。購入中にタップ→ dismiss 可能 |
| PW-06 | **INFO** | 法的表記テキスト（L362-364）は日英対応済み。Apple 審査要件の「自動更新説明」「管理方法」を含む |

### 3.3 ハードペイウォールの UX フロー

```
RoutineCompletionPage
  │
  ├─ 「Pro版を解放」
  │   └─ PaywallView(isHardPaywall: true)
  │       ├─ 閉じるボタン: 非表示
  │       ├─ スワイプ閉じ: interactiveDismissDisabled(true)
  │       ├─ 「無料で続ける」: 3秒遅延で表示 → dismiss() → RoutineCompletionPage に戻る
  │       ├─ 購入成功: dismiss() → RoutineCompletionPage に戻る (isPremium = true)
  │       └─ 復元成功: dismiss() → RoutineCompletionPage に戻る
  │
  └─ 「無料ではじめる」
      └─ onComplete() → NotificationPermissionView → hasCompletedOnboarding = true
```

**結論:** PaywallView から直接オンボーディング完了にはならない。必ず RoutineCompletionPage 経由で「無料ではじめる」を押す必要がある。これは意図的な設計（購入後もルーティンサマリーを確認できる）だが、購入直後のユーザーに「無料ではじめる」ボタンを押させるのは UX 上の違和感がある。

---

## 4. オンボーディング完了 → MainTabView 初期化

### 4.1 完了フラグの設定

**ファイル:** `App/ContentView.swift`

```swift
OnboardingView {
    withAnimation {
        appState.hasCompletedOnboarding = true  // ← ここで設定
    }
}
```

**フロー:**
1. RoutineCompletionPage → `onComplete()`
2. OnboardingView: `currentPhase = .notification`
3. NotificationPermissionView → `onComplete()`
4. ContentView: `hasCompletedOnboarding = true` → UserDefaults に永続化
5. ContentView の `if` 分岐が MainTabView に切り替わる

### 4.2 MainTabView 初期化

**ファイル:** `App/ContentView.swift` (MainTabView)

```
MainTabView 表示
  ├─ Tab 0 (HomeView) ← デフォルト表示
  │   └─ onAppear:
  │       ├─ HomeViewModel 生成
  │       ├─ loadMuscleStates() → WorkoutSet クエリ (初回は空)
  │       ├─ checkActiveSession() → nil
  │       ├─ loadTodayRoutine() → RoutineManager.shared.routine
  │       ├─ showDemo (初回デモアニメーション、0.5秒後)
  │       └─ showCoachMark (WorkoutSet 0件 && !hasSeenHomeCoachMark、1秒後)
  │
  ├─ Tab 1 (WorkoutStartView) — canRecordWorkout ゲート
  ├─ Tab 2 (HistoryView)
  └─ Tab 3 (SettingsView)
```

**検出事項:**

| ID | 重要度 | 内容 |
|:---|:---|:---|
| MT-01 | **MEDIUM** | **ワークアウトタブゲートのアラートが日本語ハードコード。** ContentView L57-76 のアラートメッセージ `"今週の無料ワークアウト"` 等が L10n を使用していない。英語ユーザーに日本語が表示される |
| MT-02 | **LOW** | `selectedTab` はランタイム専用（UserDefaults未保存）。アプリ再起動で常に Tab 0 に戻る（意図的かもしれないが確認推奨） |
| MT-03 | **LOW** | HomeView の `loadTodayRoutine()` は RoutineManager.shared.routine を読むが、オンボーディング直後は WorkoutSession が0件のため、`todayRoutineDay(modelContext:)` の「前回セッションの種目マッチ」ロジックが機能しない。初回は Day 1 がフォールバックで返される |
| MT-04 | **INFO** | コーチマーク表示は 1秒遅延。デモアニメーションは 0.5秒遅延。両方同時に表示される可能性がある |

---

## 5. データ永続化チェック

### 5.1 永続化マトリクス

| データ | 保存先 | 保存タイミング | 読取タイミング | リスク |
|:---|:---|:---|:---|:---|
| `hasCompletedOnboarding` | UserDefaults | ContentView: onComplete後 | ContentView: 起動時 | **LOW**: didSet で即保存。アプリ強制終了でも安全 |
| `userProfile` (全フィールド) | UserDefaults (JSON) | AppState.userProfile didSet | AppState.init() | **LOW**: 各ページで即保存 |
| `primaryOnboardingGoal` | UserDefaults | GoalSelectionPage タップ時 | RoutineCompletionPage, PaywallView, HomeView | **LOW**: didSet で即保存 |
| `UserRoutine` (days, exercises) | UserDefaults (JSON) | RoutineBuilderPage saveAndProceed() | RoutineManager.init(), HomeView | **MEDIUM**: JSONEncoder 失敗時はサイレント。ログのみ (DEBUG) |
| `isPremium` | RevenueCat (リモート) | 購入/復元成功時 | PurchaseManager.refreshPremiumStatus() | **MEDIUM**: ローカルキャッシュなし。オフライン時は前回状態を保持（RevenueCat SDK内部キャッシュ） |
| `weeklyWorkoutCount` | UserDefaults | incrementWorkoutCount() | canRecordWorkout アクセス時 | **LOW**: resetIfNewWeek() で週次リセット |
| `FavoritesManager` (お気に入り種目) | UserDefaults | RoutineBuilderPage saveAndProceed() | WorkoutStartView, ExercisePicker | **LOW** |

### 5.2 永続化ギャップ

| ID | 重要度 | 内容 |
|:---|:---|:---|
| DP-01 | **MEDIUM** | **UserRoutine の保存失敗がサイレント。** `UserRoutine.save()` の JSONEncoder エラーは `#if DEBUG` でのみログ出力。本番で保存失敗してもユーザーに通知されない。RoutineManager.hasRoutine が false のまま、HomeView が空ルーティンを表示する |
| DP-02 | **LOW** | **UserRoutine.createdAt は更新されない。** RoutineEditView で編集しても createdAt は初回作成時のまま。分析に使う場合は注意 |
| DP-03 | **LOW** | **exerciseId の文字列依存。** RoutineExercise.exerciseId は exercises.json の id 文字列。アプリ更新で exercises.json の id が変わると、保存済みルーティンの種目が解決不能になる。ExerciseStore.exercise(for:) が nil を返す |
| DP-04 | **INFO** | **RevenueCat の isPremium にローカル永続化なし。** ただし RevenueCat SDK v5 は内部で CustomerInfo をキャッシュするため、短時間のオフラインは問題ない |

---

## 6. PurchaseManager 詳細分析

### 6.1 購入フロー

**ファイル:** `Utilities/PurchaseManager.swift`

```
purchase(productId: "yearly" or "monthly")
  │
  ├─ isLoading = true
  ├─ Purchases.shared.offerings()
  ├─ offering = offerings.current
  ├─ パッケージ検索:
  │   ├─ "yearly"  → offering.annual ?? 名前に "year"/"annual" を含むパッケージ
  │   └─ "monthly" → offering.monthly ?? 名前に "month" を含むパッケージ
  ├─ Purchases.shared.purchase(package:)
  │   ├─ userCancelled → return false
  │   ├─ 成功 → _isPremium = entitlements["premium"]?.isActive ?? false
  │   └─ エラー → throw
  └─ isLoading = false
```

**検出事項:**

| ID | 重要度 | 内容 |
|:---|:---|:---|
| PM-01 | **HIGH** | **パッケージ検索が文字列 contains ベース。** `identifier.lowercased().contains("year")` は `"yearly_trial_v2"` や `"new_year_promo"` にもマッチする。RevenueCat の `offering.annual` / `offering.monthly` をプライマリにしているが、nil フォールバックが危険 |
| PM-02 | **MEDIUM** | **canRecordWorkout のリセットタイミング。** `resetIfNewWeek()` は `weeklyWorkoutCount` プロパティ読取り時にのみ実行。アプリを1週間開かず月曜に開くと正常リセットされるが、`Calendar.current.component(.weekOfYear)` の年跨ぎ（12月末→1月初）で誤動作する可能性がある（yearForWeekOfYear で対処済みだが、エッジケース注意） |
| PM-03 | **LOW** | **PurchaseDelegate の MainActor 競合。** `PurchaseDelegate.shared` が `purchases(_:receivedUpdated:)` で `PurchaseManager.shared._isPremium` を更新。デリゲートは RevenueCat のバックグラウンドスレッドから呼ばれる可能性があり、`@MainActor` の `PurchaseManager` との間でスレッド安全性の確認が必要 |

### 6.2 無料ユーザー制限フロー

```
ContentView.onChange(selectedTab):
  newValue == 1 (ワークアウトタブ)
    && !PurchaseManager.shared.canRecordWorkout
      → selectedTab = oldValue (元のタブに戻す)
      → showWorkoutLimitAlert = true
        → 「Proにアップグレード」 → PaywallView(isHardPaywall: false)
        → 「閉じる」 → アラートを閉じる
```

---

## 7. エッジケース・クラッシュパス

### 7.1 オンボーディング中断

| シナリオ | 現在の動作 | リスク |
|:---|:---|:---|
| RoutineBuilderPage でアプリ強制終了 | hasCompletedOnboarding = false。再起動で OnboardingView 表示 | **MEDIUM**: RoutineManager に中間保存された可能性がある（saveAndProceed 前なら未保存、後なら保存済み）。再度 RoutineBuilderPage に到達すると initializeDays() で新しいルーティンが上書きされる |
| PaywallView で購入中にアプリ強制終了 | RevenueCat SDK が transaction を追跡 | **LOW**: 次回起動時に `refreshPremiumStatus()` で復元される（RevenueCat の設計） |
| NotificationPermissionView でアプリ強制終了 | hasCompletedOnboarding = false | **LOW**: 再起動でオンボーディング再表示。RoutineManager には前回保存済みデータが残る |

### 7.2 データ不整合

| シナリオ | 影響 | リスク |
|:---|:---|:---|
| exercises.json の exerciseId 変更 | RoutineExercise.exerciseId が解決不能。ExerciseStore.exercise(for:) → nil | **MEDIUM**: RoutineCompletionPage の種目名表示が欠落。HomeView の todayRoutine の種目名も nil |
| primaryOnboardingGoal が nil | GoalSelectionPage をスキップした場合（理論上不可能だが） | **LOW**: RoutineCompletionPage はデフォルトヘッドライン、PaywallView は subtitle 非表示にフォールバック |
| goalPriorityMuscles が空 | OnboardingV2View L64-68 の `if let` が false の場合 | **LOW**: PaywallView の筋肉マップが空表示。RoutineBuilderPage の筋肉マップも空 |
| Muscle enum に新しい case 追加 | UserRoutine の muscleGroups (String配列) は影響なし | **LOW**: 古い文字列は Muscle(rawValue:) で nil になるだけ |

### 7.3 UserRoutine の後方互換性

**ファイル:** `Models/UserRoutine.swift`

```swift
// RoutineDay.init(from:) — カスタムデコーダ
location = try container.decodeIfPresent(String.self, forKey: .location) ?? "gym"
```

`location` フィールドは後から追加されたため、`decodeIfPresent` + デフォルト `"gym"` で後方互換性を確保済み。

**検出事項:**

| ID | 重要度 | 内容 |
|:---|:---|:---|
| UR-01 | **INFO** | 今後フィールド追加する場合も同様に `decodeIfPresent` + デフォルト値パターンが必要。通常の `Codable` 自動合成だとデコード失敗→ルーティン消失 |

---

## 8. 重要度別サマリー

### HIGH（修正推奨）

| ID | 箇所 | 内容 |
|:---|:---|:---|
| PW-01 | PaywallView L285-292 | 価格テキストがハードコード。RevenueCat のオファリングから動的取得すべき |
| PW-02 | PaywallView L242,264 → PurchaseManager | productId が文字列ベース。パッケージ検索が `contains` で誤マッチリスク |
| PM-01 | PurchaseManager L60-63 | パッケージ検索の `contains` マッチが曖昧。`offering.annual`/`.monthly` の nil 時フォールバックが危険 |

### MEDIUM（改善推奨）

| ID | 箇所 | 内容 |
|:---|:---|:---|
| RB-01 | RoutineBuilderPage canProceed | 現在のDayのみ検証。全Day検証なし |
| PW-03 | PaywallView → RoutineCompletionPage | 購入成功後も「無料ではじめる」押下が必要。UX違和感 |
| PW-04 | PaywallView freeOptionButton | 「無料で続ける」も dismiss() のみ。RoutineCompletionPage に戻るだけ |
| MT-01 | ContentView アラート | ワークアウト制限アラートが日本語ハードコード。L10n 未使用 |
| DP-01 | UserRoutine.save() | 保存失敗がサイレント。本番でログなし |
| PM-02 | PurchaseManager resetIfNewWeek | weeklyWorkoutCount 読取り時のみリセット |

### LOW（注意事項）

| ID | 箇所 | 内容 |
|:---|:---|:---|
| RB-02 | RoutineBuilderPage | Day種目全削除→別Day移動→戻ると空のまま |
| RC-02 | RoutineCompletionPage | coveragePercent が muscleMapping キー不一致時に乖離 |
| MT-02 | ContentView | selectedTab が永続化されない |
| MT-03 | HomeView | 初回は todayRoutineDay のマッチングが機能しない |
| DP-02 | UserRoutine | createdAt が編集時に更新されない |
| DP-03 | RoutineExercise | exerciseId が exercises.json 依存（ID変更で破損） |
| PW-05 | PaywallView | 購入中に「無料で続ける」が disable されていない |
| PM-03 | PurchaseDelegate | MainActor スレッド安全性の確認が必要 |

---

## 9. 推奨アクション（優先度順）

### P0: App Store 審査前に必須

1. **PaywallView の価格を RevenueCat オファリングから動的取得に変更** (PW-01)
   - `Purchases.shared.offerings()` → `offering.annual?.localizedPriceString` を使用
   - ローカライズ済み価格文字列が取得できるため、`¥4,900` のハードコードを排除

2. **PurchaseManager のパッケージ検索を厳密化** (PW-02, PM-01)
   - `offering.annual` / `offering.monthly` が nil の場合はエラー表示（フォールバック検索を廃止）
   - productId を enum 化して型安全にする

### P1: リリース前に対応推奨

3. **購入成功後の UX 改善** (PW-03)
   - 購入成功 → PaywallView dismiss 後、RoutineCompletionPage の「無料ではじめる」を「はじめる」に変更（isPremium 判定）
   - または: 購入成功時に dismiss + onComplete を連鎖呼出

4. **ContentView アラートの多言語対応** (MT-01)
   - `L10n` キーに移行

5. **RoutineBuilderPage の全Day検証** (RB-01)
   - saveAndProceed() 前に全Day の exercises が空でないことを確認

### P2: 品質向上

6. **UserRoutine 保存エラーのユーザー通知** (DP-01)
7. **PaywallView 購入中の「無料で続ける」disable** (PW-05)
8. **PurchaseManager.resetIfNewWeek の年跨ぎテスト** (PM-02)

---

## 10. テスト推奨項目

| テストケース | 検証ポイント |
|:---|:---|
| オンボーディング正常完了（無料） | 全ページ遷移 → RoutineManager に保存 → hasCompletedOnboarding = true → HomeView 表示 |
| オンボーディング中の購入 | RoutineCompletionPage → PaywallView → 購入成功 → dismiss → 「無料ではじめる」 → 完了 |
| オンボーディング中のアプリ強制終了 | 再起動でオンボーディング再表示。RoutineManager のデータ状態確認 |
| 購入復元 | PaywallView → 復元 → dismiss → RoutineCompletionPage に戻る |
| 無料ユーザーの週間制限 | 1回記録 → 2回目はタブ遷移ゲート → アラート表示 → 翌週リセット |
| exercises.json ID 変更後の既存ルーティン | ExerciseStore.exercise(for:) → nil のハンドリング確認 |
| オフライン時の isPremium | RevenueCat キャッシュから前回状態を復元 |

---

*Generated: 2026-03-20 | Read-only audit — no code changes*

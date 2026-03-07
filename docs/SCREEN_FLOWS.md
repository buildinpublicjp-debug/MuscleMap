# MuscleMap — 画面遷移詳細ドキュメント

> **目的:** どの操作でどの画面に遷移するか、条件・トリガーを網羅する。
> 各画面の「存在理由・ユーザー感情」は `SCREENS.md` を参照。

---

## 遷移マップ（全体）

```
[起動]
  ├── 初回起動 → OnboardingView（fullScreen）
  │    └── 「始める」タップ → MainTabView
  └── 2回目以降 → MainTabView（直接）

[MainTabView]
  ├── Tab 0: HomeView
  ├── Tab 1: WorkoutStartView
  ├── Tab 2: ExerciseLibraryView
  ├── Tab 3: HistoryView
  └── Tab 4: SettingsView
```

---

## Tab 0: ホーム画面の遷移

```
HomeView
  ├── [回復マップ ↔ Strength Map 切替ボタン]
  │    ├── isPremium == true  → StrengthMapView（ホーム内インライン切替）
  │    └── isPremium == false → PaywallView（.sheet）
  │
  ├── [分析ボタン] → AnalyticsMenuView（.sheet）
  │    ├── 「週次サマリー」タップ → WeeklySummaryView（.sheet）
  │    ├── 「バランス診断」タップ → MuscleBalanceDiagnosisView（.sheet）
  │    ├── 「筋肉ジャーニー」タップ → MuscleJourneyView（.sheet）
  │    └── 「ヒートマップ」タップ → MuscleHeatmapView（.sheet）
  │
  └── [StrengthMapView内]
       └── 「シェア」ボタン → ShareCardSheet（.sheet）
```

**遷移条件まとめ:**

| トリガー | 条件 | 遷移先 | 種別 |
|:--|:--|:--|:--|
| Strength Mapボタン | isPremium == true | StrengthMapView | インライン |
| Strength Mapボタン | isPremium == false | PaywallView | .sheet |
| 分析ボタン | なし | AnalyticsMenuView | .sheet |
| 週次サマリー | なし（将来Pro） | WeeklySummaryView | .sheet |
| バランス診断 | なし（将来Pro） | MuscleBalanceDiagnosisView | .sheet |
| 筋肉ジャーニー | なし（将来Pro） | MuscleJourneyView | .sheet |
| ヒートマップ | なし（将来Pro） | MuscleHeatmapView | .sheet |

---

## Tab 1: ワークアウトの遷移

```
WorkoutStartView
  └── [ワークアウト開始ボタン] → WorkoutActiveView（.fullScreenCover）
       ├── [セット記録] → （同画面内。State更新のみ）
       ├── [PR達成] → PRCelebrationOverlay（overlay、自動消滅）
       └── [終了ボタン] → WorkoutCompletionView（画面内 NavigationStack push）
            └── [ホームへ戻る] → MainTabView Tab 0（.dismiss × 2）
```

**遷移条件まとめ:**

| トリガー | 条件 | 遷移先 | 種別 |
|:--|:--|:--|:--|
| ワークアウト開始 | なし | WorkoutActiveView | .fullScreenCover |
| セット完了 | weight×repsがPR更新 | PRCelebrationOverlay | overlay |
| ワークアウト終了 | なし | WorkoutCompletionView | push |
| ホームへ戻る | なし | MainTabView（Tab 0） | dismiss |

**バック遷移:**
- WorkoutActiveView中は「戻るボタン」を非表示にする（誤操作防止）
- 終了は明示的な「終了ボタン」からのみ

---

## Tab 2: 種目辞典の遷移

```
ExerciseLibraryView
  ├── [種目セル タップ] → ExerciseDetailView（.sheet）
  │    └── [✕ ボタン] → ExerciseLibraryView（dismiss）
  └── [部位フィルター] → （同画面内。リストをフィルタリング）
```

**遷移条件まとめ:**

| トリガー | 条件 | 遷移先 | 種別 |
|:--|:--|:--|:--|
| 種目セルタップ | なし | ExerciseDetailView | .sheet |
| 部位フィルター変更 | なし | （同画面内フィルタ） | State更新 |

---

## Tab 3: 履歴の遷移

```
HistoryView
  ├── [マップ / カレンダー 切替] → （同画面内モード切替）
  │
  ├── [マップモード]
  │    └── [筋肉タップ] → MuscleDetailHalfModal（.sheet, .medium/.large）
  │         └── [「詳細を見る」ボタン] → MuscleDetail3DView（push）
  │
  └── [カレンダーモード]
       └── [日付タップ] → DayWorkoutSummary（将来実装。現在未対応）
```

**遷移条件まとめ:**

| トリガー | 条件 | 遷移先 | 種別 |
|:--|:--|:--|:--|
| マップ/カレンダー切替 | なし | （同画面内） | State更新 |
| 筋肉タップ（マップ） | なし | MuscleDetailHalfModal | .sheet（.medium） |
| 「詳細を見る」 | なし | MuscleDetail3DView | push |

---

## Tab 4: 設定の遷移

```
SettingsView
  ├── [プロフィール編集] → ProfileEditView（.sheet or push）
  ├── [サブスクリプション管理] → PaywallView（.sheet）
  ├── [言語設定] → LanguageSelectView（push）
  ├── [プライバシーポリシー] → SafariView（外部URL）
  ├── [利用規約] → SafariView（外部URL）
  └── [サポート] → SafariView（外部URL）
```

---

## Paywall の遷移（全エントリポイント）

PaywallView は複数の画面からシートとして呼ばれる。

| 呼び出し元 | トリガー | 閉じた後の戻り先 |
|:--|:--|:--|
| HomeView | Strength Mapボタン（未課金） | HomeView（回復マップモードのまま） |
| SettingsView | サブスクリプション管理 | SettingsView |

**課金完了後の挙動:**
- isPremium が true に更新される
- PaywallView が自動 dismiss
- HomeViewに戻ると Strength Map モードが使用可能になっている

---

## オンボーディングの遷移

```
OnboardingView（Step 1〜7）
  ├── [次へ] → 次のステップ（NavigationStack push）
  ├── [スキップ] → MainTabView（任意のステップから離脱可）
  └── [始める（Step 7）] → MainTabView
```

**初回判定:**
- `UserDefaults` に `hasCompletedOnboarding` フラグを保存
- `false` の場合のみ OnboardingView を表示
- スキップまたは完了時に `true` に更新

---

## バック遷移・dismiss のルール

| 画面 | 戻り方 | 注意 |
|:--|:--|:--|
| OnboardingView | 戻る不可（fullScreen） | スキップのみ |
| WorkoutActiveView | 戻るボタン非表示 | 終了ボタンからのみ離脱 |
| .sheet 全般 | ドラッグダウン or ✕ボタン | ドラッグは `.presentationDragIndicator(.visible)` |
| push 遷移 | NavigationBackボタン | 標準 |

---

## 将来追加予定の遷移

| 画面 | トリガー | 状態 |
|:--|:--|:--|
| 分析メニュー各画面のProゲート | Pro未加入時 → Paywall | 将来実装 |
| バッジ・実績モーダル | 初達成時に自動表示 | 設計中 |
| 匿名ランキング表示 | Strength Map内 | 将来（Supabase必要） |
| DayWorkoutSummary | カレンダー日付タップ | 将来実装 |

---

*最終更新: 2026-03-07*

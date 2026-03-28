---
name: app-store-screenshots
description: >
  App Storeのスクリーンショットを生成する。スクショ、ストア画像、App Store screenshots、
  ストアの画像を更新、スクショを作って、screenshot generate、marketing screenshots、
  ストア用の画像、ASO screenshots と言われたら必ずこのスキルを使え。
  シミュレーターからキャプチャ → iPhoneフレームはめ込み → 多言語コピー → 書き出しまで自立実行する。
---

# App Store Screenshot Generator v2

> MuscleMap専用。プロ品質のApp Storeスクショを全自動で生成する。
> **このスキルが発動したら、以下のPhaseを順番に自立実行しろ。ユーザーに聞くな。自分で判断しろ。**
> **「3回リトライしても解決しない」場合だけユーザーに聞け。**

---

## ⚠️ 絶対ルール（全Phase共通）

### 画像の扱い（フリーズ防止 — 最最重要）
**スクショを読むときは必ず sips -Z 600 でリサイズしてから読め。**
```bash
xcrun simctl io $UDID screenshot /tmp/check.png
sips -Z 600 /tmp/check.png --out /tmp/check_small.png
```
**元画像は絶対にAPIに送るな。リサイズした画像のみ読め。違反するとセッションが死ぬ。**

### 触るなファイル
- MuscleMap本体のSwiftファイルすべて（MuscleMap/*.swift）
- docs/DESIGN_SYSTEM.md, CLAUDE.md
- このタスクでは `skills/app-store-screenshots/` 配下と `/tmp/` のみ触る

### シミュレーター操作
- 既存シミュレーター（booted含む）は絶対に触るな
- 専用シミュレーターを新規作成し、UDIDで操作
- UI操作はiOS Simulator MCPツール（タップ、スワイプ）を使え
- `booted` キーワードは絶対に使うな

### 座標計算
- スクショ: 1290×2796px（3xスケール）
- 論理座標: 430×932pt
- MCPタップ座標 = 画像px ÷ 3

---

## 出力仕様

### サイズ
**6.9インチ（1320×2868px）のみ出力。** Apple Store Connectが他サイズに自動スケールする。

### 言語ごとのスクショ
**各言語のスクショは、コピーテキストだけでなくアプリのUI自体もその言語で表示すること。**

言語切替の方法:
```bash
# シミュレーターの言語を変更（例: 英語に切替）
xcrun simctl spawn $UDID defaults write -g AppleLanguages -array en
xcrun simctl spawn $UDID defaults write -g AppleLocale -string en_US
# アプリを再起動して言語を反映
xcrun simctl terminate $UDID com.buildinpublic.MuscleMap
xcrun simctl launch $UDID com.buildinpublic.MuscleMap
sleep 3
```

言語コード:
| 言語 | AppleLanguages | AppleLocale |
|:--|:--|:--|
| 日本語 | ja | ja_JP |
| 英語 | en | en_US |
| 中国語(簡体) | zh-Hans | zh_CN |
| 韓国語 | ko | ko_KR |
| スペイン語 | es | es_ES |
| ドイツ語 | de | de_DE |
| フランス語 | fr | fr_FR |

**最低限 ja と en の2言語は必須。** 他の言語はユーザーが求めた場合のみ。

---

## Phase 1: 環境セットアップ

### Step 1.1: リポジトリ準備
```bash
cd /Users/og3939397/MuscleMap
git pull origin main
```

### Step 1.2: npm install
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator
npm install
```

### Step 1.3: 専用シミュレーター作成
```bash
UDID=$(xcrun simctl create "MuscleMap-Screenshots" "iPhone 16 Pro Max")
echo "UDID: $UDID"
```

### Step 1.4: ビルド & 起動
```bash
xcrun simctl boot $UDID
cd /Users/og3939397/MuscleMap
xcodebuild -project MuscleMap.xcodeproj -scheme MuscleMap \
  -destination "id=$UDID" \
  -derivedDataPath /tmp/mm-screenshots \
  build 2>&1 | tail -5
xcrun simctl install $UDID /tmp/mm-screenshots/Build/Products/Debug-iphonesimulator/MuscleMap.app
xcrun simctl launch $UDID com.buildinpublic.MuscleMap
sleep 3
```

**✅ チェック:** スクショ撮って（リサイズして）アプリ画面が表示されていること。

---

## Phase 1.5: オンボーディング完了

スクショを読んでオンボーディング画面なら自動で完了させる。

選択方針:
- 目標: 筋肥大
- 頻度: 週4回
- 場所: ジム
- 経験: 中級者
- 「ルーティンを作成」系のCTAは即タップ。「ルーティンなしで始める」は使うな。
- 通知許可ダイアログ → 「許可」をタップ

ホーム画面（タブバー+回復マップ表示）が出たら完了。

---

## Phase 2: スクショキャプチャ（日本語）

**まず日本語UIで全ショットをキャプチャする。**

### 品質チェック（全ショット共通）
撮影後に必ずリサイズして読み、以下をチェック:
- [ ] UIが完全に表示されている（アニメーション中でない）
- [ ] ダイアログが被さっていない
- [ ] 意図した画面である

不合格 → sleep 2 → 再キャプチャ。3回失敗でユーザーに報告。

### 保存先
```bash
# 日本語
/Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/ja/shot{N}_screen.png

# 英語
/Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/en/shot{N}_screen.png
```
**言語ごとにサブフォルダを分けろ。**
```bash
mkdir -p /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/ja
mkdir -p /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/en
```

---

### Shot 1: ホーム画面（回復マップ）
ホームタブ。回復マップ（筋肉に色が付いた状態）が見えること。

### Shot 2: ワークアウト完了画面
ワークアウトを実行して完了させる:
1. ワークアウトタブ → 種目を選択
2. セット入力 → 重量デフォルト、レップ10 → 記録
3. ワークアウト完了ボタン → 完了画面をキャプチャ

### Shot 3: ホーム画面（ワークアウト後）
完了画面を閉じてホームに戻る。ワークアウト後なのでマップの色が更新されているはず。

### Shot 4: 種目ライブラリ
種目辞典タブ。2列グリッドでGIFカードが表示されていること。

### Shot 5: PR祝福 or ワークアウト完了（別バリエーション）
2回目のワークアウトで前回より重い重量 → PR祝福を狙う。
出なければShot 2を流用:
```bash
cp /tmp/shot2_raw.png /tmp/shot5_raw.png
```

### Shot 6: Strength Map
ホーム画面の「Strength Map」カードをタップ。
Paywallで阻まれる場合 → ホーム画面のStrength Mapカード自体が見えている状態をキャプチャ。
もしくはホーム画面の回復ステータスセクション（マップ+チップ）をもう一度キャプチャ。

---

## Phase 2.5: 英語UIでスクショキャプチャ

### 言語切替
```bash
xcrun simctl spawn $UDID defaults write -g AppleLanguages -array en
xcrun simctl spawn $UDID defaults write -g AppleLocale -string en_US
xcrun simctl terminate $UDID com.buildinpublic.MuscleMap
xcrun simctl launch $UDID com.buildinpublic.MuscleMap
sleep 3
```

スクショを撮ってUIが英語になっていることを確認。

**日本語と同じ6ショットを英語UIで撮り直す。**
保存先: `public/screenshots/en/shot{N}_screen.png`

ワークアウトデータは日本語フェーズで入力済みなので、ホーム画面や完了画面はデータがある状態で撮れるはず。
ワークアウト完了画面は再度ワークアウトを実行してもいいし、データが残っている画面があればそれでもOK。

---

## Phase 3: スクショ合成（HTML生成 → PNG書き出し）

### 合成の方法
Next.jsのgeneratorを使う。ただし**以下の改善を反映したpage.tsxに更新してから**実行しろ。

### page.tsxの修正要件（重要）

**1. エクスポートは1サイズのみ（1320×2868）**
EXPORT_SIZESを1つだけに:
```typescript
export const EXPORT_SIZES = [
  { name: '6.9"', width: 1320, height: 2868 },
] as const;
```

**2. 言語ごとにスクショフォルダを切替**
画像パスを `screenshots/${lang}/shot{N}_screen.png` にする。

**3. iPhoneフレームのサイズ**
- PHONE_W = 1080（キャンバス幅の82%）
- コピーエリアの上パディング: 60px
- コピーとデバイス間のギャップ: 16px
- デバイスは下に突き抜ける（完全に画面内に収めない）
- ボトムフェード高さ: 300px

**4. 見出しのサイズ**
- 日本語: 78px
- 英語: 80px
- サブコピー: 26px
- チップ: 18px

これにより、コピーエリアがコンパクト → デバイスが大きく → 下余白がなくなる。

### 実行
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator
```

page.tsxを上記要件で修正してから:
```bash
npx next dev -p 3456 &
sleep 8
```

ユーザーに http://localhost:3456 で確認してもらう。

---

## Phase 4: 書き出し

ユーザーの承認後、ブラウザのExportボタンで書き出し。
**各ショット × 1サイズ（1320×2868）× 言語数 = 合計ファイル数。**

ja: shot1_ja.png 〜 shot6_ja.png
en: shot1_en.png 〜 shot6_en.png

---

## Phase 5: クリーンアップ

```bash
kill $DEV_PID 2>/dev/null
```

ユーザーに確認してシミュレーター削除:
```bash
xcrun simctl shutdown $UDID
xcrun simctl delete $UDID
```

### 最終報告
「App Storeスクショ生成完了。

📊 結果:
- 日本語: {N}枚
- 英語: {N}枚
- サイズ: 1320×2868px（6.9"）
- 出力先: ブラウザのダウンロードフォルダ

📋 App Store Connectアップロード手順:
1. App Store Connect → アプリ → バージョン → メディア
2. ローカライゼーション "日本語" を選択 → ja のスクショをアップロード
3. ローカライゼーション "English" を選択 → en のスクショをアップロード
4. 他サイズは自動スケールされる」

---

## 技術リファレンス

### MuscleMapブランド
- 背景: #070A07
- プライマリ: #00FFB3
- セカンダリ: #00D4FF
- PR: #FFD700

### ショット定義
| # | JA見出し | EN見出し | アクセント | 画面 |
|:--|:---|:---|:--|:---|
| 1 | 昨日の筋トレ、今どこに残ってる？ | Your muscles light up. | #00FFB3 | ホーム（回復マップ） |
| 2 | 今日、ここを鍛えた | Today, you hit these muscles. | #00FFB3 | ワークアウト完了 |
| 3 | 今日やるべき種目、自動で | Never wonder what to train. | #00FFB3 | ホーム（Day切替） |
| 4 | 92種目、全部動く | See the motion, not just the name. | #00D4FF | 種目ライブラリ |
| 5 | 前回を超えろ | Break your personal record. | #FFD700 | PR祝福 |
| 6 | どこに効くか、数値で見る | See your strength in thickness. | #00D4FF | Strength Map |

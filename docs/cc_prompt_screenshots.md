# App Storeスクショ生成 — CCプロンプト

## ⚠️ 画像の扱いルール（フリーズ防止 — 最重要）
シミュレーターのスクショは 1290×2796px あり、そのままAPIに送るとフリーズする。
**確認用は必ず sips -Z 800 でリサイズしてから読め。**
```bash
xcrun simctl io booted screenshot /tmp/check.png
sips -Z 800 /tmp/check.png --out /tmp/check_small.png
```
元画像（1290×2796）は絶対にAPIに送るな。

## やること

App Storeのスクリーンショットを生成するNext.jsツールをセットアップして、シミュレーターからキャプチャしたスクショをはめ込む。

## Step 1: セットアップ

```bash
cd /path/to/MuscleMap
git pull origin main
cd skills/app-store-screenshots/generator
npm install
```

npm installが終わったら報告して。次のステップを指示する。

## Step 2: シミュレータースクショのキャプチャ

MuscleMapアプリをiOSシミュレーター（iPhone 16 Pro Max）で開いて、以下の6画面を順番にキャプチャする。
**1画面ずつやれ。全部一気にやるな。**

各画面で:
1. シミュレーターで対象画面を表示
2. `xcrun simctl io booted screenshot ./public/screenshots/shot{N}_screen.png`
3. 確認用にリサイズ: `sips -Z 800 ./public/screenshots/shot{N}_screen.png --out /tmp/shot{N}_small.png`
4. /tmp/shot{N}_small.png を読んで画面が正しいか確認
5. OKなら次の画面へ

### キャプチャする画面:
| # | ファイル名 | 画面 | 操作 |
|:--|:---|:---|:---|
| 1 | shot1_screen.png | ホーム画面（回復マップ前面、色が付いた状態） | アプリ起動→ホームタブ |
| 2 | shot2_screen.png | ワークアウト完了画面（筋肉マップハイライト） | ワークアウト完了後 |
| 3 | shot3_screen.png | ホーム画面（TodayActionCard、Day切替タブ表示） | ホーム→Day切替表示 |
| 4 | shot4_screen.png | 種目ライブラリ（2列グリッド、GIF表示） | 種目辞典タブ |
| 5 | shot5_screen.png | PR祝福表示 | ワークアウト完了→PR発生時 |
| 6 | shot6_screen.png | Strength Map（筋肉の太さ表示） | Strength Mapタブ |

**注意:** shot2とshot5はワークアウトを実際に完了させないと撮れない。ダミーデータがあるなら使え。なければ俺に聞いて。

## Step 3: dev serverで確認

```bash
npm run dev
```

ブラウザで http://localhost:3000 を開いて、6枚のプレビューが表示されることを確認。
スクショが正しくiPhoneフレームにはまっているか確認。

問題があれば報告して。

## Step 4: 書き出し

ブラウザ上で各ショットの「Export All Sizes」ボタンをクリック。
4サイズ（6.9", 6.5", 6.3", 6.1"）が自動ダウンロードされる。

## 触るなファイル
- LocalizationManager.swift
- その他MuscleMap本体のSwiftファイルすべて
- docs/DESIGN_SYSTEM.md
- CLAUDE.md

このタスクではskills/app-store-screenshots/配下のみ触る。

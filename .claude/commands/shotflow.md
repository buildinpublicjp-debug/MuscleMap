# ShotFlow操作

ShotFlowリポジトリは ../ShotFlow にある。

## 参照方法
- ファイル一覧: rg --files ../ShotFlow
- ファイル読み: cat ../ShotFlow/path/to/file
- 書き込み: 通常通り ../ShotFlow/path/to/file に書き込み

## ShotFlowの概要
ShotFlowはiOS撮影チェックリストアプリ。
- JSON動的config読み込み（day_config.json）
- タイムライン表示（Morning/Afternoon/Evening）
- 金額入力 + 合計ロジック
- VO録音 + Speech Framework文字起こし
- 「Claudeにコピー」ボタン（プロンプト埋め込み）
- トリム機能
- フック案・VO台本タップコピー

## 注意事項
- CLAUDE.mdとCC_LESSONS.mdの教訓を適用すること
- 新規.swiftファイル作成時はpbxproj登録を必ず確認
- GitHub: buildinpublicjp-debug/ShotFlow (private)

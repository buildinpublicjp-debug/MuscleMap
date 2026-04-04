# Remotion操作

Remotionリポジトリは ~/Developer/MuscleMapContent にある。

## 参照方法
- ファイル一覧: rg --files ~/Developer/MuscleMapContent
- ファイル読み: cat ~/Developer/MuscleMapContent/path/to/file
- 書き込み: 通常通り ~/Developer/MuscleMapContent/path/to/file に書き込み

## MuscleMapContentの概要
Remotionベースの動画自動生成パイプライン。
- ビートシンク + スピードランプ + ズームパンチ + フラッシュ
- カラオケスタイル字幕
- レシート風支出サマリー
- プログレスバー + Dayスタンプアニメーション + エンドカード
- 効果音システム（whoosh, coin, stamp, shutter自動割り当て）
- BGM配置（LoFi chill）
- タイムスタンプオーバーレイ
- types.ts: profile, vo_transcript, daily_summary対応済み

## レンダリングコマンド
```bash
cd ~/Developer/MuscleMapContent && git pull origin main
rm -rf /tmp/remotion-*
rm -rf public/current_day && mkdir -p public/current_day
cp ~/Videos/musclemap_content/day00X/* public/current_day/
npx remotion render DayVideo --props='{"dayNumber":X,"date":"2026-0X-XX","type":"daily","inputDir":"current_day","bgmFile":"bgm/chill_01.mp3","hasBgm":true}' --output=output/day00X_final.mp4
```

## 設計ドキュメント（MuscleMapリポ内）
- Projects/MuscleMap/system_architecture_v2.md
- Projects/MuscleMap/shotflow_dynamic_config.md
- Projects/MuscleMap/content_pipeline_spec.md

## 注意事項
- CLAUDE.mdとCC_LESSONS.mdの教訓を全て適用すること
- GitHub: buildinpublicjp-debug/MuscleMapContent (private)

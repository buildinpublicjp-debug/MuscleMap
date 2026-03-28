"use client";

import { useRef, useState, useCallback } from "react";
import { toPng } from "html-to-image";

// ─── Types ───────────────────────────────────────────────────
type Lang = "ja" | "en";

interface ShotCopy {
  headline: string;
  sub: string;
  chips: string[];
  accent: string;
}

interface ShotDef {
  id: number;
  screen: string; // filename in /screens/{lang}/
  nav: string; // description for capture guidance
  ja: ShotCopy;
  en: ShotCopy;
}

// ─── Export Sizes ────────────────────────────────────────────
const EXPORT_SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;

// Design canvas = largest size
const CANVAS_W = 1320;
const CANVAS_H = 2868;

// ─── Shot Definitions ────────────────────────────────────────
const SHOTS: ShotDef[] = [
  {
    id: 1,
    screen: "home.png",
    nav: "ホーム画面（回復マップ前面、色が付いた状態）",
    ja: {
      headline: "昨日の筋トレ、\n今どこに残ってる？",
      sub: "21部位の回復をリアルタイム表示",
      chips: ["21部位", "92種目", "EMGベース"],
      accent: "#00FFB3",
    },
    en: {
      headline: "Your muscles\nremember yesterday.",
      sub: "Real-time recovery map for 21 muscle groups",
      chips: ["21 muscles", "92 exercises", "EMG-based"],
      accent: "#00FFB3",
    },
  },
  {
    id: 2,
    screen: "library.png",
    nav: "種目ライブラリ（2列グリッド、GIFカード表示）",
    ja: {
      headline: "動きで覚える、\n92種目のGIF",
      sub: "種目名だけじゃわからない動作を一目で",
      chips: ["92種目", "GIF対応", "2列グリッド"],
      accent: "#00D4FF",
    },
    en: {
      headline: "See the motion,\nnot just the name.",
      sub: "Animated GIFs for all 92 exercises",
      chips: ["92 exercises", "GIF-powered", "Grid view"],
      accent: "#00D4FF",
    },
  },
  {
    id: 3,
    screen: "routine.png",
    nav: "ホーム画面 → 今日のルーティン（Day切替タブ表示）",
    ja: {
      headline: "今日やるべき種目、\n自動で提案",
      sub: "目標×頻度×場所→あなた専用Day分割",
      chips: ["目標", "頻度", "場所", "経験値"],
      accent: "#00FFB3",
    },
    en: {
      headline: "Never wonder\nwhat to train.",
      sub: "Goals × frequency × location → your split",
      chips: ["Goals", "Frequency", "Location"],
      accent: "#00FFB3",
    },
  },
  {
    id: 4,
    screen: "completion.png",
    nav: "ワークアウト完了画面（PR祝福 + 筋肉マップハイライト）",
    ja: {
      headline: "自己ベスト更新を\nリアルタイムで祝福",
      sub: "PR検出 → ゴールド演出 → シェア",
      chips: ["NEW PR!", "自動検出"],
      accent: "#FFD700",
    },
    en: {
      headline: "Every PR\ndeserves a crown.",
      sub: "Auto-detect personal records & celebrate",
      chips: ["NEW PR!", "Auto-detect"],
      accent: "#FFD700",
    },
  },
  {
    id: 5,
    screen: "progress.png",
    nav: "プログレスフォト（Before/After比較スライダー）",
    ja: {
      headline: "変化を写真で\n記録する",
      sub: "Before/Afterスライダーで比較",
      chips: ["カメラ撮影", "比較スライダー"],
      accent: "#00FFB3",
    },
    en: {
      headline: "See your\ntransformation.",
      sub: "Before/After slider comparison",
      chips: ["Camera", "Compare"],
      accent: "#00FFB3",
    },
  },
  {
    id: 6,
    screen: "strength.png",
    nav: "Strength Mapタブ（筋肉の太さ表示、前面+背面）",
    ja: {
      headline: "全身の強さを\n数値で可視化",
      sub: "S〜Dグレードで弱点が一目でわかる",
      chips: ["S", "A", "B", "C", "D"],
      accent: "#00D4FF",
    },
    en: {
      headline: "See your strength\nin full color.",
      sub: "S-to-D grading across your entire body",
      chips: ["S", "A", "B", "C", "D"],
      accent: "#00D4FF",
    },
  },
];

// ─── Mockup Dimensions ──────────────────────────────────────
// These define where the screen content sits inside mockup.png
// Adjust after placing your actual mockup.png
const MOCKUP = {
  frameWidth: 950, // width of the mockup frame image
  // Screen region inside the frame (relative to frame top-left)
  screen: {
    top: 18,
    left: 22,
    width: 906,
    height: 1962,
  },
};

// ─── Components ──────────────────────────────────────────────

function BackgroundLayers({ accent }: { accent: string }) {
  return (
    <>
      {/* Base */}
      <div className="absolute inset-0" style={{ background: "#070A07" }} />

      {/* Glow */}
      <div
        className="absolute pointer-events-none"
        style={{
          top: -300,
          left: "50%",
          transform: "translateX(-50%)",
          width: 1200,
          height: 1200,
          background: `radial-gradient(circle, ${accent}0D 0%, transparent 60%)`,
        }}
      />

      {/* Grid */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)
          `,
          backgroundSize: "64px 64px",
        }}
      />

      {/* Bottom fade */}
      <div
        className="absolute bottom-0 left-0 right-0 pointer-events-none"
        style={{
          height: 400,
          background: "linear-gradient(transparent 0%, #070A07 85%)",
          zIndex: 30,
        }}
      />
    </>
  );
}

function CopyArea({
  copy,
  lang,
}: {
  copy: ShotCopy;
  lang: Lang;
}) {
  const isJa = lang === "ja";
  const fontFamily = isJa
    ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
    : "'Inter', 'SF Pro Display', sans-serif";

  return (
    <div
      className="relative flex flex-col items-center text-center"
      style={{
        paddingTop: 100,
        paddingLeft: 80,
        paddingRight: 80,
        paddingBottom: 0,
        zIndex: 10,
        fontFamily,
      }}
    >
      {/* Headline */}
      <div
        style={{
          fontSize: isJa ? 82 : 88,
          fontWeight: 900,
          color: "#FFFFFF",
          lineHeight: 1.15,
          letterSpacing: isJa ? 2 : -1,
          whiteSpace: "pre-line",
        }}
      >
        {copy.headline}
      </div>

      {/* Sub copy */}
      <div
        style={{
          fontSize: 30,
          fontWeight: 500,
          color: `${copy.accent}99`,
          marginTop: 18,
          letterSpacing: isJa ? 2 : 0.5,
        }}
      >
        {copy.sub}
      </div>

      {/* Chips */}
      <div
        className="flex flex-wrap justify-center"
        style={{ gap: 12, marginTop: 24 }}
      >
        {copy.chips.map((chip, i) => {
          // Single-letter chips (grades) get special styling
          const isSolo = chip.length <= 2;
          return (
            <span
              key={i}
              style={{
                padding: isSolo ? "6px 16px" : "8px 20px",
                background: `${copy.accent}08`,
                border: `1.5px solid ${copy.accent}25`,
                borderRadius: 40,
                color: isSolo ? `${copy.accent}CC` : "rgba(255,255,255,0.6)",
                fontSize: 22,
                fontWeight: isSolo ? 700 : 500,
                letterSpacing: 1,
              }}
            >
              {chip}
            </span>
          );
        })}
      </div>
    </div>
  );
}

function DeviceFrame({
  screenSrc,
  lang,
  shotId,
}: {
  screenSrc: string;
  lang: Lang;
  shotId: number;
}) {
  return (
    <div
      className="relative flex justify-center"
      style={{
        flex: 1,
        paddingTop: 32,
        zIndex: 5,
      }}
    >
      <div
        className="relative"
        style={{ width: MOCKUP.frameWidth }}
      >
        {/* Screenshot (behind frame) */}
        <div
          className="absolute overflow-hidden"
          style={{
            top: MOCKUP.screen.top,
            left: MOCKUP.screen.left,
            width: MOCKUP.screen.width,
            height: MOCKUP.screen.height,
            borderRadius: 42,
            zIndex: 1,
          }}
        >
          <img
            src={`/screens/${lang}/${screenSrc}`}
            alt={`Shot ${shotId}`}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
            }}
            onError={(e) => {
              // Show placeholder if screenshot not found
              (e.target as HTMLImageElement).style.display = "none";
              (e.target as HTMLImageElement).parentElement!.style.background =
                "linear-gradient(180deg, #1a1a1a 0%, #0d0d0d 100%)";
              (e.target as HTMLImageElement).parentElement!.innerHTML = `
                <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,0.15);font-size:24px;">
                  screens/${lang}/${screenSrc}
                </div>
              `;
            }}
          />
        </div>

        {/* iPhone frame (on top) */}
        <img
          src="/mockup.png"
          alt="iPhone frame"
          style={{
            width: "100%",
            position: "relative",
            zIndex: 2,
          }}
          onError={(e) => {
            // If mockup.png not found, render CSS frame as fallback
            const parent = (e.target as HTMLImageElement).parentElement!;
            parent.style.border = "12px solid #2C2C2E";
            parent.style.borderRadius = "54px";
            parent.style.boxShadow =
              "0 60px 120px rgba(0,0,0,0.8), 0 0 0 1px rgba(255,255,255,0.05)";
            (e.target as HTMLImageElement).style.display = "none";
          }}
        />
      </div>
    </div>
  );
}

function ScreenshotSlide({
  shot,
  lang,
  index,
  onExport,
}: {
  shot: ShotDef;
  lang: Lang;
  index: number;
  onExport: (ref: HTMLDivElement, shot: ShotDef, lang: Lang) => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const copy = shot[lang];

  return (
    <div className="flex flex-col items-center gap-4">
      {/* Label */}
      <div className="text-white/50 text-sm font-mono">
        Shot {shot.id} — {lang.toUpperCase()} — {shot.nav}
      </div>

      {/* Canvas (click to export) */}
      <div
        ref={ref}
        onClick={() => ref.current && onExport(ref.current, shot, lang)}
        className="relative overflow-hidden cursor-pointer hover:ring-2 hover:ring-white/20 transition-all"
        style={{
          width: CANVAS_W,
          height: CANVAS_H,
        }}
      >
        <BackgroundLayers accent={copy.accent} />

        <div
          className="relative flex flex-col"
          style={{ width: CANVAS_W, height: CANVAS_H }}
        >
          <CopyArea copy={copy} lang={lang} />
          <DeviceFrame
            screenSrc={shot.screen}
            lang={lang}
            shotId={shot.id}
          />
        </div>
      </div>

      {/* Export buttons */}
      <div className="flex gap-2">
        {EXPORT_SIZES.map((size) => (
          <button
            key={size.label}
            onClick={() => {
              if (ref.current) onExport(ref.current, shot, lang);
            }}
            className="px-3 py-1 text-xs font-mono bg-white/10 hover:bg-white/20 text-white rounded transition-colors"
          >
            {size.label} ({size.w}×{size.h})
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── Main Page ───────────────────────────────────────────────
export default function ScreenshotGenerator() {
  const [lang, setLang] = useState<Lang>("ja");
  const [exporting, setExporting] = useState(false);
  const [status, setStatus] = useState("");

  const handleExport = useCallback(
    async (node: HTMLDivElement, shot: ShotDef, shotLang: Lang) => {
      setExporting(true);

      for (const size of EXPORT_SIZES) {
        setStatus(
          `Exporting shot${shot.id}_${shotLang}_${size.label}...`
        );

        try {
          const scale = size.w / CANVAS_W;
          const dataUrl = await toPng(node, {
            width: size.w,
            height: size.h,
            style: {
              transform: `scale(${scale})`,
              transformOrigin: "top left",
            },
            pixelRatio: 1,
          });

          // Trigger download
          const link = document.createElement("a");
          link.download = `shot${shot.id}_${shotLang}_${size.label.replace(/"/g, "in")}.png`;
          link.href = dataUrl;
          link.click();
        } catch (err) {
          console.error(`Export failed:`, err);
          setStatus(`Error: ${err}`);
        }
      }

      setExporting(false);
      setStatus("Done!");
      setTimeout(() => setStatus(""), 3000);
    },
    []
  );

  const handleExportAll = useCallback(async () => {
    setExporting(true);
    setStatus("Exporting all screenshots...");

    // Find all slide refs and export
    const slides = document.querySelectorAll("[data-slide]");
    for (const slide of slides) {
      const shotId = parseInt(slide.getAttribute("data-shot-id") || "0");
      const shotLang = slide.getAttribute("data-lang") as Lang;
      const shot = SHOTS.find((s) => s.id === shotId);
      if (!shot) continue;

      for (const size of EXPORT_SIZES) {
        setStatus(
          `Shot ${shotId} ${shotLang} ${size.label}...`
        );

        try {
          const scale = size.w / CANVAS_W;
          const dataUrl = await toPng(slide as HTMLElement, {
            width: size.w,
            height: size.h,
            style: {
              transform: `scale(${scale})`,
              transformOrigin: "top left",
            },
            pixelRatio: 1,
          });

          const link = document.createElement("a");
          link.download = `shot${shotId}_${shotLang}_${size.label.replace(/"/g, "in")}.png`;
          link.href = dataUrl;
          link.click();

          // Small delay between downloads
          await new Promise((r) => setTimeout(r, 300));
        } catch (err) {
          console.error(`Export failed:`, err);
        }
      }
    }

    setExporting(false);
    setStatus("All exports complete!");
    setTimeout(() => setStatus(""), 3000);
  }, []);

  return (
    <div className="min-h-screen bg-neutral-950 p-8">
      {/* Controls */}
      <div className="sticky top-0 z-50 bg-neutral-950/90 backdrop-blur-sm p-4 mb-8 rounded-xl border border-white/10 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-white font-bold text-lg">
            MuscleMap Screenshot Generator
          </h1>

          {/* Language toggle */}
          <div className="flex bg-white/10 rounded-lg overflow-hidden">
            {(["ja", "en"] as Lang[]).map((l) => (
              <button
                key={l}
                onClick={() => setLang(l)}
                className={`px-4 py-2 text-sm font-mono transition-colors ${
                  lang === l
                    ? "bg-mm-brand text-black font-bold"
                    : "text-white/60 hover:text-white"
                }`}
              >
                {l.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-4">
          {status && (
            <span className="text-white/50 text-sm font-mono">
              {status}
            </span>
          )}

          <button
            onClick={handleExportAll}
            disabled={exporting}
            className="px-6 py-2 bg-mm-brand text-black font-bold rounded-lg hover:bg-mm-brand/80 disabled:opacity-50 transition-colors"
          >
            {exporting ? "Exporting..." : "Export All"}
          </button>
        </div>
      </div>

      {/* Instructions */}
      <div className="mb-8 p-4 rounded-xl border border-white/5 text-white/40 text-sm">
        <p>
          <strong className="text-white/60">使い方:</strong>{" "}
          <code className="bg-white/5 px-1 rounded">public/screens/{"{lang}"}/</code>{" "}
          にシミュレーターのスクショを配置 →{" "}
          <code className="bg-white/5 px-1 rounded">public/mockup.png</code>{" "}
          にiPhoneフレーム画像を配置 → スライドをクリックで書き出し
        </p>
      </div>

      {/* Preview grid — scaled down for overview */}
      <div className="mb-12">
        <h2 className="text-white/40 text-sm font-mono mb-4">
          PREVIEW ({lang.toUpperCase()}) — 20% scale
        </h2>
        <div className="flex gap-4 overflow-x-auto pb-4">
          {SHOTS.map((shot) => {
            const copy = shot[lang];
            return (
              <div
                key={shot.id}
                className="flex-shrink-0 rounded-lg overflow-hidden border border-white/10"
                style={{
                  width: CANVAS_W * 0.2,
                  height: CANVAS_H * 0.2,
                }}
              >
                <div
                  data-slide
                  data-shot-id={shot.id}
                  data-lang={lang}
                  className="relative overflow-hidden"
                  style={{
                    width: CANVAS_W,
                    height: CANVAS_H,
                    transform: "scale(0.2)",
                    transformOrigin: "top left",
                  }}
                >
                  <BackgroundLayers accent={copy.accent} />
                  <div
                    className="relative flex flex-col"
                    style={{ width: CANVAS_W, height: CANVAS_H }}
                  >
                    <CopyArea copy={copy} lang={lang} />
                    <DeviceFrame
                      screenSrc={shot.screen}
                      lang={lang}
                      shotId={shot.id}
                    />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Full-size slides */}
      <div className="flex flex-col items-center gap-16">
        {SHOTS.map((shot, i) => (
          <ScreenshotSlide
            key={shot.id}
            shot={shot}
            lang={lang}
            index={i}
            onExport={handleExport}
          />
        ))}
      </div>

      {/* Mockup setup guide */}
      <div className="mt-16 p-6 rounded-xl border border-white/5 text-white/30 text-sm max-w-2xl mx-auto">
        <h3 className="text-white/50 font-bold mb-2">
          mockup.png セットアップ
        </h3>
        <ol className="list-decimal list-inside space-y-1">
          <li>
            iPhone 16 Pro Maxの正面フレーム画像（透明PNG）を取得
          </li>
          <li>
            <code className="bg-white/5 px-1 rounded">
              public/mockup.png
            </code>{" "}
            に配置
          </li>
          <li>
            page.tsx の <code className="bg-white/5 px-1 rounded">MOCKUP</code>{" "}
            オブジェクトでスクリーン領域の座標を調整
          </li>
          <li>
            ブラウザでプレビュー確認 → スクショがフレーム内に正しくはまるか確認
          </li>
        </ol>
        <p className="mt-3">
          推奨取得元:{" "}
          <a
            href="https://github.com/ParthJadhav/app-store-screenshots"
            className="text-mm-brand/60 underline"
            target="_blank"
          >
            ParthJadhav/app-store-screenshots
          </a>{" "}
          のmockup.png (MIT)
        </p>
      </div>
    </div>
  );
}

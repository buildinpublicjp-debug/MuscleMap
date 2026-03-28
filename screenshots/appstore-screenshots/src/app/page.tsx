'use client';

import { useCallback, useRef, useState } from 'react';
import { toPng } from 'html-to-image';
import { SLIDES, EXPORT_SIZES, type Locale, type SlideDefinition } from './copy';

// ═══════════════════════════════════════════════════════════════
// DESIGN CONSTANTS — 余白管理の心臓部
// Canvas: 1320×2868 (6.9" base)
// ═══════════════════════════════════════════════════════════════
const CANVAS = { w: 1320, h: 2868 };

// コピーエリア: 上部22%
const COPY_AREA = {
  paddingTop: 100,      // 上端からの余白
  paddingX: 80,         // 左右の余白
  headlineSize: {
    ja: 82,             // 日本語は少し小さめ（文字が複雑）
    en: 88,
  },
  subSize: 30,
  chipGap: 12,
};

// デバイスエリア: 下部78%
const DEVICE = {
  // mockup.pngのスクリーン領域（透明エリア）の座標
  // mockup.pngが無い場合はCSS frameで代替
  frameWidth: 880,       // iPhone枠の幅
  framePadding: 14,      // 外枠→スクリーンの余白
  borderRadius: 64,      // 外枠の角丸
  screenRadius: 50,      // スクリーンの角丸
  topOffset: 40,         // コピーエリアとの間隔
};

// ═══════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════

/** 背景レイヤー: グロー + グリッド */
function BackgroundLayers({ accent }: { accent: string }) {
  return (
    <>
      {/* アクセントグロー（上部） */}
      <div
        style={{
          position: 'absolute',
          top: -300,
          left: '50%',
          transform: 'translateX(-50%)',
          width: 1200,
          height: 1200,
          background: `radial-gradient(circle, ${accent}0D 0%, transparent 60%)`,
          pointerEvents: 'none',
        }}
      />
      {/* グリッドパターン */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)
          `,
          backgroundSize: '64px 64px',
          pointerEvents: 'none',
        }}
      />
    </>
  );
}

/** 下部フェード（デバイスが背景に溶け込む） */
function BottomFade() {
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        height: 400,
        background: 'linear-gradient(transparent 0%, #070A07 85%)',
        pointerEvents: 'none',
        zIndex: 3,
      }}
    />
  );
}

/** コピーエリア: 見出し + サブコピー + チップ */
function CopyArea({
  slide,
  locale,
}: {
  slide: SlideDefinition;
  locale: Locale;
}) {
  const copy = slide.copy[locale];
  const isJa = locale === 'ja';
  const fontSize = isJa ? COPY_AREA.headlineSize.ja : COPY_AREA.headlineSize.en;

  return (
    <div
      style={{
        padding: `${COPY_AREA.paddingTop}px ${COPY_AREA.paddingX}px 0`,
        textAlign: 'center',
        width: '100%',
        position: 'relative',
        zIndex: 2,
        flexShrink: 0,
      }}
    >
      {/* Headline */}
      <div
        style={{
          fontSize,
          fontWeight: 900,
          color: '#FFFFFF',
          lineHeight: 1.18,
          letterSpacing: isJa ? '2px' : '-1px',
          fontFamily: isJa
            ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
            : "'Inter', 'SF Pro Display', sans-serif",
          whiteSpace: 'pre-line',
        }}
      >
        {copy.headline.split('\\n').map((line, i) => (
          <div key={i}>{line}</div>
        ))}
      </div>

      {/* Sub copy */}
      <div
        style={{
          fontSize: COPY_AREA.subSize,
          fontWeight: 500,
          color: `${slide.accent}99`,
          marginTop: 16,
          letterSpacing: isJa ? '2px' : '0.5px',
          fontFamily: isJa
            ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
            : "'Inter', sans-serif",
        }}
      >
        {copy.sub}
      </div>

      {/* Chips */}
      <div
        style={{
          display: 'flex',
          gap: COPY_AREA.chipGap,
          justifyContent: 'center',
          marginTop: 24,
          flexWrap: 'wrap',
        }}
      >
        {copy.chips.map((chip, i) => (
          <span
            key={i}
            style={{
              padding: '8px 20px',
              background: `${slide.accent}08`,
              border: `1.5px solid ${slide.accent}25`,
              borderRadius: 40,
              color: chip.desc
                ? 'rgba(255, 255, 255, 0.6)'
                : `${slide.accent}CC`,
              fontSize: 22,
              fontWeight: chip.desc ? 500 : 700,
              letterSpacing: '1px',
              fontFamily: "'Inter', sans-serif",
            }}
          >
            {chip.desc ? (
              <>
                <strong style={{ color: slide.accent, fontWeight: 900 }}>
                  {chip.label}
                </strong>{' '}
                {chip.desc}
              </>
            ) : (
              chip.label
            )}
          </span>
        ))}
      </div>
    </div>
  );
}

/** iPhone CSS Frame（mockup.png未使用時のフォールバック） */
function IPhoneCSSFrame({
  screenFile,
  accent,
}: {
  screenFile: string;
  accent: string;
}) {
  return (
    <div
      style={{
        width: DEVICE.frameWidth,
        position: 'relative',
      }}
    >
      {/* 外枠（チタン風） */}
      <div
        style={{
          position: 'relative',
          borderRadius: DEVICE.borderRadius,
          padding: DEVICE.framePadding,
          background:
            'linear-gradient(145deg, #3A3A3C 0%, #1C1C1E 50%, #2C2C2E 100%)',
          boxShadow: `
            0 60px 120px rgba(0, 0, 0, 0.8),
            0 0 0 1px rgba(255,255,255,0.05),
            0 4px 80px ${accent}12,
            inset 0 1px 0 rgba(255,255,255,0.08)
          `,
        }}
      >
        {/* サイドボタン — 右（電源） */}
        <div
          style={{
            position: 'absolute',
            top: 280,
            right: -3,
            width: 4,
            height: 100,
            background:
              'linear-gradient(180deg, #4A4A4C, #2C2C2E, #4A4A4C)',
            borderRadius: '0 2px 2px 0',
          }}
        />
        {/* サイドボタン — 左（音量上） */}
        <div
          style={{
            position: 'absolute',
            top: 240,
            left: -3,
            width: 4,
            height: 55,
            background:
              'linear-gradient(180deg, #4A4A4C, #2C2C2E, #4A4A4C)',
            borderRadius: '2px 0 0 2px',
          }}
        />
        {/* サイドボタン — 左（音量下） */}
        <div
          style={{
            position: 'absolute',
            top: 310,
            left: -3,
            width: 4,
            height: 55,
            background:
              'linear-gradient(180deg, #4A4A4C, #2C2C2E, #4A4A4C)',
            borderRadius: '2px 0 0 2px',
          }}
        />

        {/* スクリーン */}
        <div
          style={{
            borderRadius: DEVICE.screenRadius,
            overflow: 'hidden',
            background: '#000',
            position: 'relative',
          }}
        >
          {/* Dynamic Island */}
          <div
            style={{
              position: 'absolute',
              top: 14,
              left: '50%',
              transform: 'translateX(-50%)',
              width: 140,
              height: 34,
              background: '#000',
              borderRadius: 17,
              zIndex: 10,
            }}
          />
          {/* ガラスリフレクション */}
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              background:
                'linear-gradient(180deg, rgba(255,255,255,0.03) 0%, transparent 100%)',
              pointerEvents: 'none',
              zIndex: 5,
            }}
          />
          {/* スクショ画像 */}
          <img
            src={`/screenshots/${screenFile}`}
            alt={screenFile}
            style={{
              width: '100%',
              display: 'block',
            }}
            onError={(e) => {
              // プレースホルダー表示
              const el = e.target as HTMLImageElement;
              el.style.display = 'none';
              el.parentElement!.style.aspectRatio = '1179 / 2556';
              el.parentElement!.style.background =
                'linear-gradient(180deg, #1a1a1a 0%, #0d0d0d 100%)';
            }}
          />
        </div>
      </div>
    </div>
  );
}

/** mockup.pngを使ったフレーム（高品質版） */
function IPhoneMockupFrame({
  screenFile,
}: {
  screenFile: string;
}) {
  // mockup.pngのスクリーン領域座標（要調整）
  // ParthJadhavスキルの仕様: mockup.pngに透明スクリーンエリアがある
  const SCREEN_TOP = 58;
  const SCREEN_LEFT = 26;
  const SCREEN_WIDTH = 828;
  const SCREEN_HEIGHT = 1792;
  const MOCKUP_WIDTH = 880;

  return (
    <div style={{ width: MOCKUP_WIDTH, position: 'relative' }}>
      {/* スクリーン画像（背面） */}
      <img
        src={`/screenshots/${screenFile}`}
        alt={screenFile}
        style={{
          position: 'absolute',
          top: SCREEN_TOP,
          left: SCREEN_LEFT,
          width: SCREEN_WIDTH,
          height: SCREEN_HEIGHT,
          objectFit: 'cover',
          borderRadius: 40,
        }}
      />
      {/* モックアップフレーム（前面） */}
      <img
        src="/mockup.png"
        alt="iPhone frame"
        style={{
          width: '100%',
          display: 'block',
          position: 'relative',
          zIndex: 2,
        }}
      />
    </div>
  );
}

/** 単一スクリーンショットスライド */
function ScreenshotSlide({
  slide,
  locale,
  useMockup,
  slideRef,
}: {
  slide: SlideDefinition;
  locale: Locale;
  useMockup: boolean;
  slideRef: React.RefObject<HTMLDivElement>;
}) {
  return (
    <div
      ref={slideRef}
      style={{
        width: CANVAS.w,
        height: CANVAS.h,
        background: '#070A07',
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        flexShrink: 0,
      }}
    >
      <BackgroundLayers accent={slide.accent} />
      <CopyArea slide={slide} locale={locale} />

      {/* デバイスエリア */}
      <div
        style={{
          flex: 1,
          display: 'flex',
          justifyContent: 'center',
          paddingTop: DEVICE.topOffset,
          width: '100%',
          position: 'relative',
          zIndex: 1,
        }}
      >
        {useMockup ? (
          <IPhoneMockupFrame screenFile={slide.screenFile} />
        ) : (
          <IPhoneCSSFrame
            screenFile={slide.screenFile}
            accent={slide.accent}
          />
        )}
      </div>

      <BottomFade />
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════
export default function ScreenshotGenerator() {
  const [locale, setLocale] = useState<Locale>('ja');
  const [useMockup, setUseMockup] = useState(false);
  const [exporting, setExporting] = useState<number | null>(null);
  const slideRefs = useRef<(HTMLDivElement | null)[]>([]);

  const handleExport = useCallback(
    async (slideIndex: number) => {
      const el = slideRefs.current[slideIndex];
      if (!el) return;
      setExporting(slideIndex);

      try {
        // フォント読み込み待ち
        await document.fonts.ready;
        await new Promise((r) => setTimeout(r, 500));

        for (const size of EXPORT_SIZES) {
          const scale = size.width / CANVAS.w;
          const png = await toPng(el, {
            width: size.width,
            height: size.height,
            style: {
              transform: `scale(${scale})`,
              transformOrigin: 'top left',
            },
            pixelRatio: 1,
          });

          const link = document.createElement('a');
          link.download = `shot${SLIDES[slideIndex].id}_${locale}_${size.name.replace('"', '')}.png`;
          link.href = png;
          link.click();
        }
      } catch (err) {
        console.error('Export failed:', err);
        alert('Export failed. Check console.');
      } finally {
        setExporting(null);
      }
    },
    [locale]
  );

  const locales: Locale[] = ['ja', 'en', 'de', 'fr', 'es', 'pt', 'ko'];

  return (
    <div style={{ padding: 40, background: '#111' }}>
      {/* コントロールパネル */}
      <div
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 100,
          background: '#1a1a1a',
          padding: '16px 24px',
          borderRadius: 12,
          marginBottom: 40,
          display: 'flex',
          gap: 16,
          alignItems: 'center',
          flexWrap: 'wrap',
          border: '1px solid #333',
        }}
      >
        <span style={{ color: '#888', fontSize: 14 }}>Language:</span>
        {locales.map((l) => (
          <button
            key={l}
            onClick={() => setLocale(l)}
            style={{
              padding: '6px 16px',
              borderRadius: 8,
              border: locale === l ? '2px solid #00FFB3' : '1px solid #444',
              background: locale === l ? '#00FFB320' : 'transparent',
              color: locale === l ? '#00FFB3' : '#888',
              cursor: 'pointer',
              fontWeight: 600,
              fontSize: 14,
            }}
          >
            {l.toUpperCase()}
          </button>
        ))}

        <div style={{ width: 1, height: 30, background: '#333' }} />

        <label
          style={{
            color: '#888',
            fontSize: 14,
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            cursor: 'pointer',
          }}
        >
          <input
            type="checkbox"
            checked={useMockup}
            onChange={(e) => setUseMockup(e.target.checked)}
          />
          Use mockup.png
        </label>

        <div style={{ width: 1, height: 30, background: '#333' }} />

        <button
          onClick={async () => {
            for (let i = 0; i < SLIDES.length; i++) {
              await handleExport(i);
            }
          }}
          style={{
            padding: '8px 20px',
            borderRadius: 8,
            border: '2px solid #FFD700',
            background: '#FFD70020',
            color: '#FFD700',
            cursor: 'pointer',
            fontWeight: 700,
            fontSize: 14,
          }}
        >
          Export All ({locale.toUpperCase()})
        </button>
      </div>

      {/* スライド一覧 */}
      <div
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: 40,
          justifyContent: 'center',
        }}
      >
        {SLIDES.map((slide, i) => (
          <div key={slide.id} style={{ position: 'relative' }}>
            {/* サムネイル（25%スケール） */}
            <div
              style={{
                transform: 'scale(0.25)',
                transformOrigin: 'top left',
                width: CANVAS.w,
                height: CANVAS.h,
              }}
            >
              <ScreenshotSlide
                slide={slide}
                locale={locale}
                useMockup={useMockup}
                slideRef={{ current: null } as any}
              />
            </div>

            {/* 実サイズ（非表示、書き出し用） */}
            <div
              style={{
                position: 'absolute',
                left: -9999,
                top: 0,
              }}
            >
              <ScreenshotSlide
                slide={slide}
                locale={locale}
                useMockup={useMockup}
                slideRef={{
                  get current() {
                    return slideRefs.current[i];
                  },
                  set current(el) {
                    slideRefs.current[i] = el;
                  },
                } as React.RefObject<HTMLDivElement>}
              />
            </div>

            {/* 操作バー */}
            <div
              style={{
                width: CANVAS.w * 0.25,
                marginTop: -(CANVAS.h * 0.75),
                position: 'relative',
                zIndex: 10,
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '8px 12px',
              }}
            >
              <span style={{ color: '#666', fontSize: 13 }}>
                #{slide.id} — {slide.nav.slice(0, 20)}...
              </span>
              <button
                onClick={() => handleExport(i)}
                disabled={exporting === i}
                style={{
                  padding: '4px 12px',
                  borderRadius: 6,
                  border: '1px solid #00FFB3',
                  background: exporting === i ? '#00FFB340' : 'transparent',
                  color: '#00FFB3',
                  cursor: exporting === i ? 'wait' : 'pointer',
                  fontSize: 12,
                  fontWeight: 600,
                }}
              >
                {exporting === i ? 'Exporting...' : 'Export PNG'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

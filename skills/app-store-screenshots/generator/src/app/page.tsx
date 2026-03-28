'use client';

import { useRef, useState, useCallback } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, EXPORT_SIZES, type Lang, type ShotDef } from '@/copy';

// ─── Constants ────────────────────────────────────────────
const CANVAS_W = 1320;
const CANVAS_H = 2868;
const PHONE_W = 1060; // ~80% of canvas width (was 940/71%)
const COPY_AREA_PAD_TOP = 72; // tighter top (was 120)
const COPY_AREA_PAD_X = 60; // tighter sides (was 80)
const COPY_DEVICE_GAP = 20; // tighter gap (was 40)
const BOTTOM_FADE_H = 350; // slightly smaller (was 400)

// ─── Screenshot Slide ─────────────────────────────────────
function ScreenshotSlide({
  shot,
  lang,
  slideRef,
}: {
  shot: ShotDef;
  lang: Lang;
  slideRef: React.RefObject<HTMLDivElement | null>;
}) {
  const copy = shot.copy[lang];
  const isJa = lang === 'ja' || lang === 'zh' || lang === 'ko';

  const headlineLines = copy.headline.split('\n');

  return (
    <div
      ref={slideRef}
      style={{
        width: CANVAS_W,
        height: CANVAS_H,
        background: '#070A07',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: isJa
          ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
          : "'Inter', 'SF Pro Display', sans-serif",
      }}
    >
      {/* Background glow */}
      <div
        style={{
          position: 'absolute',
          top: -300,
          left: '50%',
          transform: 'translateX(-50%)',
          width: 1200,
          height: 1200,
          background: `radial-gradient(circle, ${shot.accent}14 0%, transparent 55%)`,
          pointerEvents: 'none',
        }}
      />

      {/* Background grid */}
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

      {/* Copy area */}
      <div
        style={{
          paddingTop: COPY_AREA_PAD_TOP,
          paddingLeft: COPY_AREA_PAD_X,
          paddingRight: COPY_AREA_PAD_X,
          textAlign: 'center',
          position: 'relative',
          zIndex: 2,
        }}
      >
        {/* Headline */}
        <div
          style={{
            fontSize: isJa ? 82 : 84,
            fontWeight: 900,
            color: '#FFFFFF',
            lineHeight: 1.15,
            letterSpacing: isJa ? 2 : -1,
          }}
        >
          {headlineLines.map((line, i) => (
            <div key={i}>{line}</div>
          ))}
        </div>

        {/* Sub copy */}
        <div
          style={{
            fontSize: 28,
            fontWeight: 500,
            color: `${shot.accent}99`,
            marginTop: 14,
            letterSpacing: isJa ? 2 : 0.5,
          }}
        >
          {copy.sub}
        </div>

        {/* Stat chips */}
        <div
          style={{
            display: 'flex',
            gap: 12,
            justifyContent: 'center',
            marginTop: 18,
            flexWrap: 'wrap' as const,
          }}
        >
          {copy.chips.map((chip, i) => (
            <span
              key={i}
              style={{
                padding: '6px 18px',
                background: `${shot.accent}08`,
                border: `1.5px solid ${shot.accent}25`,
                borderRadius: 40,
                color: chip.desc
                  ? 'rgba(255,255,255,0.6)'
                  : `${shot.accent}CC`,
                fontSize: 20,
                fontWeight: chip.desc ? 500 : 700,
                letterSpacing: 1,
              }}
            >
              {chip.desc ? (
                <>
                  <strong
                    style={{ color: shot.accent, fontWeight: 900 }}
                  >
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

      {/* Device area */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'center',
          paddingTop: COPY_DEVICE_GAP,
          position: 'relative',
          zIndex: 1,
        }}
      >
        <div style={{ width: PHONE_W, position: 'relative' }}>
          <div className="iphone-body"
            style={{
              boxShadow: `
                0 60px 120px rgba(0,0,0,0.8),
                0 0 0 1px rgba(255,255,255,0.05),
                0 4px 80px ${shot.accent}12,
                inset 0 1px 0 rgba(255,255,255,0.08)
              `,
            }}
          >
            <div className="btn-power" />
            <div className="btn-vol-up" />
            <div className="btn-vol-down" />
            <div className="iphone-screen">
              <div className="dynamic-island" />
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={`/screenshots/${shot.file}`}
                alt={`Shot ${shot.id}`}
                style={{ width: '100%', display: 'block' }}
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.style.display = 'none';
                  target.parentElement!.innerHTML += `
                    <div style="
                      width:100%;
                      aspect-ratio:1179/2556;
                      background:linear-gradient(180deg,#1a1a1a,#0d0d0d);
                      display:flex;
                      align-items:center;
                      justify-content:center;
                      color:rgba(255,255,255,0.15);
                      font-size:28px;
                    ">${shot.file}</div>
                  `;
                }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Bottom fade */}
      <div
        style={{
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          height: BOTTOM_FADE_H,
          background: 'linear-gradient(transparent 0%, #070A07 80%)',
          pointerEvents: 'none',
          zIndex: 3,
        }}
      />
    </div>
  );
}

// ─── Export Button ─────────────────────────────────────────
function ExportButton({
  slideRef,
  shotId,
  lang,
}: {
  slideRef: React.RefObject<HTMLDivElement | null>;
  shotId: number;
  lang: Lang;
}) {
  const [exporting, setExporting] = useState(false);

  const handleExport = useCallback(async () => {
    if (!slideRef.current) return;
    setExporting(true);

    try {
      for (const size of EXPORT_SIZES) {
        const scale = size.width / CANVAS_W;
        const dataUrl = await toPng(slideRef.current, {
          width: size.width,
          height: size.height,
          style: {
            transform: `scale(${scale})`,
            transformOrigin: 'top left',
          },
          pixelRatio: 1,
        });

        const link = document.createElement('a');
        link.download = `shot${shotId}_${lang}_${size.name.replace('"', '')}.png`;
        link.href = dataUrl;
        link.click();

        // Small delay between downloads
        await new Promise((r) => setTimeout(r, 500));
      }
    } catch (err) {
      console.error('Export failed:', err);
    } finally {
      setExporting(false);
    }
  }, [slideRef, shotId, lang]);

  return (
    <button
      onClick={handleExport}
      disabled={exporting}
      style={{
        padding: '8px 16px',
        background: exporting ? '#333' : '#00FFB3',
        color: '#000',
        border: 'none',
        borderRadius: 8,
        cursor: exporting ? 'not-allowed' : 'pointer',
        fontWeight: 700,
        fontSize: 14,
      }}
    >
      {exporting ? 'Exporting...' : `Export All Sizes`}
    </button>
  );
}

// ─── Main Page ────────────────────────────────────────────
export default function Page() {
  const [lang, setLang] = useState<Lang>('ja');
  const refs = useRef<(HTMLDivElement | null)[]>([]);

  const LANGS: Lang[] = ['ja', 'en', 'zh', 'ko', 'es', 'de', 'fr'];

  return (
    <div style={{ padding: 40, background: '#111' }}>
      <h1
        style={{
          fontSize: 32,
          fontWeight: 900,
          color: '#fff',
          marginBottom: 20,
        }}
      >
        MuscleMap Screenshot Generator
      </h1>

      {/* Language selector */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 40 }}>
        {LANGS.map((l) => (
          <button
            key={l}
            onClick={() => setLang(l)}
            style={{
              padding: '8px 16px',
              background: lang === l ? '#00FFB3' : '#333',
              color: lang === l ? '#000' : '#fff',
              border: 'none',
              borderRadius: 8,
              cursor: 'pointer',
              fontWeight: 700,
              fontSize: 14,
              textTransform: 'uppercase',
            }}
          >
            {l}
          </button>
        ))}
      </div>

      {/* Shots grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: 40,
        }}
      >
        {SHOTS.map((shot, idx) => {
          const ref = { current: refs.current[idx] || null };
          return (
            <div key={shot.id}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: 12,
                }}
              >
                <span style={{ color: '#888', fontSize: 14 }}>
                  Shot {shot.id} — {shot.nav}
                </span>
                <ExportButton
                  slideRef={ref}
                  shotId={shot.id}
                  lang={lang}
                />
              </div>

              {/* Preview (scaled down) */}
              <div
                style={{
                  width: 330,
                  height: (330 / CANVAS_W) * CANVAS_H,
                  overflow: 'hidden',
                  borderRadius: 12,
                  border: '1px solid #333',
                }}
              >
                <div
                  style={{
                    transform: `scale(${330 / CANVAS_W})`,
                    transformOrigin: 'top left',
                  }}
                >
                  <ScreenshotSlide
                    shot={shot}
                    lang={lang}
                    slideRef={{
                      current: refs.current[idx] || null,
                      ...{},
                    } as React.RefObject<HTMLDivElement | null>}
                  />
                </div>
              </div>

              {/* Hidden full-size render target */}
              <div
                style={{
                  position: 'absolute',
                  left: -99999,
                  top: 0,
                }}
              >
                <ScreenshotSlide
                  shot={shot}
                  lang={lang}
                  slideRef={{
                    set current(el: HTMLDivElement | null) {
                      refs.current[idx] = el;
                    },
                    get current() {
                      return refs.current[idx] || null;
                    },
                  }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const CANVAS_W = 1320;
const CANVAS_H = 2868;
const PHONE_W = 920;

// ─── Composite Slide ──────────────────────────────────────
function CompositeSlide({
  shot,
  lang,
  imageDataUrl,
  slideRef,
}: {
  shot: ShotDef;
  lang: Lang;
  imageDataUrl: string | null;
  slideRef: React.RefObject<HTMLDivElement | null>;
}) {
  const copy = shot.copy[lang];
  const isJa = lang === 'ja' || lang === 'zh' || lang === 'ko';
  const lines = copy.headline.split('\n');

  return (
    <div
      ref={slideRef}
      style={{
        width: CANVAS_W,
        height: CANVAS_H,
        background: '#050505',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: isJa
          ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
          : "'Inter', 'SF Pro Display', sans-serif",
      }}
    >
      {/* === Background layers === */}

      {/* Large accent glow — top center */}
      <div style={{
        position: 'absolute', top: -400, left: '50%', transform: 'translateX(-50%)',
        width: 1400, height: 1400,
        background: `radial-gradient(ellipse, ${shot.accent}12 0%, transparent 50%)`,
        pointerEvents: 'none',
      }} />

      {/* Secondary glow — bottom right */}
      <div style={{
        position: 'absolute', bottom: -200, right: -200,
        width: 800, height: 800,
        background: `radial-gradient(circle, ${shot.accent}08 0%, transparent 60%)`,
        pointerEvents: 'none',
      }} />

      {/* Noise texture overlay */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.015'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        pointerEvents: 'none',
        opacity: 0.6,
      }} />

      {/* Subtle grid */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: 'linear-gradient(rgba(255,255,255,0.008) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.008) 1px, transparent 1px)',
        backgroundSize: '80px 80px',
        pointerEvents: 'none',
      }} />

      {/* Top edge light line */}
      <div style={{
        position: 'absolute', top: 0, left: '10%', right: '10%', height: 1,
        background: `linear-gradient(90deg, transparent, ${shot.accent}30, transparent)`,
        pointerEvents: 'none',
      }} />

      {/* === Copy area === */}
      <div style={{
        paddingTop: 110,
        paddingLeft: 80,
        paddingRight: 80,
        textAlign: 'center',
        position: 'relative',
        zIndex: 2,
      }}>
        {/* Headline */}
        <div style={{
          fontSize: isJa ? 92 : 96,
          fontWeight: 900,
          color: '#FFFFFF',
          lineHeight: 1.08,
          letterSpacing: isJa ? 6 : -2,
          textShadow: `0 0 80px ${shot.accent}20, 0 2px 30px rgba(0,0,0,0.5)`,
        }}>
          {lines.map((l, i) => <div key={i}>{l}</div>)}
        </div>

        {/* Sub copy */}
        <div style={{
          fontSize: 28,
          fontWeight: 500,
          color: `${shot.accent}70`,
          marginTop: 20,
          letterSpacing: isJa ? 2 : 0.5,
        }}>
          {copy.sub}
        </div>

        {/* Chips */}
        <div style={{
          display: 'flex', gap: 10, justifyContent: 'center',
          marginTop: 24, flexWrap: 'wrap' as const,
        }}>
          {copy.chips.map((c, i) => (
            <span key={i} style={{
              padding: '6px 16px',
              background: `${shot.accent}06`,
              border: `1px solid ${shot.accent}15`,
              borderRadius: 100,
              color: c.desc ? 'rgba(255,255,255,0.4)' : `${shot.accent}90`,
              fontSize: 17, fontWeight: c.desc ? 500 : 700,
              backdropFilter: 'blur(8px)',
            }}>
              {c.desc ? (<><strong style={{ color: `${shot.accent}CC`, fontWeight: 800 }}>{c.label}</strong> {c.desc}</>) : c.label}
            </span>
          ))}
        </div>
      </div>

      {/* === Device === */}
      <div style={{
        display: 'flex', justifyContent: 'center',
        paddingTop: 36,
        position: 'relative', zIndex: 1,
      }}>
        {/* Accent glow behind phone */}
        <div style={{
          position: 'absolute', top: 100, left: '50%', transform: 'translateX(-50%)',
          width: PHONE_W + 100, height: PHONE_W + 100,
          background: `radial-gradient(ellipse, ${shot.accent}0A 0%, transparent 60%)`,
          pointerEvents: 'none',
        }} />

        <div style={{ width: PHONE_W, position: 'relative' }}>
          {/* Phone body */}
          <div style={{
            position: 'relative',
            borderRadius: 58,
            padding: 12,
            background: 'linear-gradient(160deg, #48484A 0%, #1C1C1E 30%, #2C2C2E 70%, #48484A 100%)',
            boxShadow: `
              0 50px 100px rgba(0,0,0,0.9),
              0 0 0 0.5px rgba(255,255,255,0.08),
              0 20px 60px ${shot.accent}08,
              inset 0 0.5px 0 rgba(255,255,255,0.12),
              inset 0 -0.5px 0 rgba(255,255,255,0.04)
            `,
          }}>
            {/* Side buttons */}
            <div style={{ position: 'absolute', top: 200, right: -2.5, width: 3, height: 80, background: 'linear-gradient(180deg, #555, #333, #555)', borderRadius: '0 2px 2px 0' }} />
            <div style={{ position: 'absolute', top: 170, left: -2.5, width: 3, height: 40, background: 'linear-gradient(180deg, #555, #333, #555)', borderRadius: '2px 0 0 2px' }} />
            <div style={{ position: 'absolute', top: 222, left: -2.5, width: 3, height: 40, background: 'linear-gradient(180deg, #555, #333, #555)', borderRadius: '2px 0 0 2px' }} />

            {/* Screen */}
            <div style={{
              borderRadius: 46,
              overflow: 'hidden',
              background: '#000',
              position: 'relative',
            }}>
              {/* Dynamic Island */}
              <div style={{
                position: 'absolute', top: 12, left: '50%', transform: 'translateX(-50%)',
                width: 126, height: 30, background: '#000', borderRadius: 15, zIndex: 10,
              }} />
              {/* Screen edge highlight */}
              <div style={{
                position: 'absolute', inset: 0,
                borderRadius: 46,
                boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.06)',
                pointerEvents: 'none', zIndex: 8,
              }} />
              {/* Glass reflection */}
              <div style={{
                position: 'absolute', top: 0, left: 0, right: 0, height: 180,
                background: 'linear-gradient(180deg, rgba(255,255,255,0.02) 0%, transparent 100%)',
                pointerEvents: 'none', zIndex: 5,
              }} />

              {imageDataUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={imageDataUrl} alt={`Shot ${shot.id}`} style={{ width: '100%', display: 'block' }} />
              ) : (
                <div style={{
                  width: '100%', aspectRatio: '1179/2556',
                  background: 'linear-gradient(180deg, #111 0%, #0a0a0a 50%, #080808 100%)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexDirection: 'column', gap: 8,
                }}>
                  <div style={{ width: 48, height: 48, borderRadius: 12, border: '2px dashed rgba(255,255,255,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <span style={{ fontSize: 20, opacity: 0.15 }}>+</span>
                  </div>
                  <div style={{ color: 'rgba(255,255,255,0.06)', fontSize: 18, fontWeight: 500 }}>Drop image</div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Bottom fade */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 420,
        background: 'linear-gradient(transparent 0%, #050505 75%)',
        pointerEvents: 'none', zIndex: 3,
      }} />

      {/* Bottom accent line */}
      <div style={{
        position: 'absolute', bottom: 40, left: '20%', right: '20%', height: 1,
        background: `linear-gradient(90deg, transparent, ${shot.accent}15, transparent)`,
        pointerEvents: 'none', zIndex: 4,
      }} />
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────
export default function Page() {
  const [lang, setLang] = useState<Lang>('ja');
  const [images, setImages] = useState<Record<number, string>>({});
  const refs = useRef<Record<number, HTMLDivElement | null>>({});
  const [exporting, setExporting] = useState(false);

  const LANGS: Lang[] = ['ja', 'en', 'zh', 'ko', 'es', 'de', 'fr'];
  const SCALE = 340 / CANVAS_W;

  const setImage = useCallback((id: number, dataUrl: string) => {
    setImages((prev) => ({ ...prev, [id]: dataUrl }));
  }, []);

  const pickFile = useCallback((id: number) => {
    const input = document.createElement('input');
    input.type = 'file'; input.accept = 'image/*';
    input.onchange = (ev) => {
      const file = (ev.target as HTMLInputElement).files?.[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = () => setImage(id, reader.result as string);
      reader.readAsDataURL(file);
    };
    input.click();
  }, [setImage]);

  const handleDrop = useCallback((id: number, e: DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (!file || !file.type.startsWith('image/')) return;
    const reader = new FileReader();
    reader.onload = () => setImage(id, reader.result as string);
    reader.readAsDataURL(file);
  }, [setImage]);

  const exportOne = useCallback(async (shotId: number) => {
    const el = refs.current[shotId];
    if (!el) return;
    const url = await toPng(el, { width: 1320, height: 2868, pixelRatio: 1 });
    const a = document.createElement('a');
    a.download = `shot${shotId}_${lang}_6.9.png`;
    a.href = url;
    a.click();
  }, [lang]);

  const exportAll = useCallback(async () => {
    setExporting(true);
    for (const shot of SHOTS) {
      if (!images[shot.id]) continue;
      await exportOne(shot.id);
      await new Promise((r) => setTimeout(r, 600));
    }
    setExporting(false);
  }, [images, exportOne]);

  const loaded = Object.keys(images).length;

  return (
    <div style={{ background: '#0a0a0a', minHeight: '100vh', color: '#fff' }}>
      {/* Header */}
      <div style={{
        padding: '14px 24px',
        borderBottom: '1px solid #181818',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        position: 'sticky', top: 0, background: 'rgba(10,10,10,0.95)',
        backdropFilter: 'blur(12px)', zIndex: 50,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <h1 style={{ fontSize: 15, fontWeight: 800, margin: 0, color: '#999', letterSpacing: -0.5 }}>MuscleMap</h1>
          <div style={{ width: 1, height: 16, background: '#222' }} />
          <div style={{ display: 'flex', gap: 2 }}>
            {LANGS.map((l) => (
              <button key={l} onClick={() => setLang(l)} style={{
                padding: '4px 10px',
                background: lang === l ? '#00E676' : 'transparent',
                color: lang === l ? '#000' : '#555',
                border: 'none', borderRadius: 4, cursor: 'pointer',
                fontWeight: 700, fontSize: 10, textTransform: 'uppercase',
                transition: 'all 0.15s',
              }}>{l}</button>
            ))}
          </div>
          <span style={{ fontSize: 11, color: '#333', fontWeight: 500 }}>{loaded}/6</span>
        </div>
        <button onClick={exportAll} disabled={loaded === 0 || exporting} style={{
          padding: '8px 24px',
          background: loaded === 0 || exporting ? '#151515' : '#00E676',
          color: loaded === 0 || exporting ? '#333' : '#000',
          border: loaded === 0 ? 'none' : '1px solid rgba(0,230,118,0.3)',
          borderRadius: 6, cursor: loaded === 0 ? 'not-allowed' : 'pointer',
          fontWeight: 800, fontSize: 12, letterSpacing: 0.5,
          transition: 'all 0.15s',
        }}>
          {exporting ? 'Exporting...' : `Export All`}
        </button>
      </div>

      {/* Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 8,
        padding: '12px 8px',
      }}>
        {SHOTS.map((shot) => (
          <div key={shot.id}>
            {/* Label */}
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              marginBottom: 4, padding: '0 4px',
            }}>
              <span style={{ fontSize: 10, color: '#444', fontWeight: 600, letterSpacing: 0.5 }}>
                {shot.id}. {shot.copy[lang].headline.split('\n')[0]}
              </span>
              <div style={{ display: 'flex', gap: 4 }}>
                {images[shot.id] && (
                  <button onClick={() => pickFile(shot.id)} style={{
                    padding: '2px 8px', background: 'transparent',
                    color: '#444', border: '1px solid #222', borderRadius: 3,
                    cursor: 'pointer', fontSize: 9, fontWeight: 600,
                  }}>Replace</button>
                )}
                <button onClick={() => exportOne(shot.id)} disabled={!images[shot.id]} style={{
                  padding: '2px 8px',
                  background: images[shot.id] ? '#00E676' : '#111',
                  color: images[shot.id] ? '#000' : '#333',
                  border: 'none', borderRadius: 3,
                  cursor: images[shot.id] ? 'pointer' : 'not-allowed',
                  fontSize: 9, fontWeight: 700,
                }}>Export</button>
              </div>
            </div>

            {/* Preview */}
            <div
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => handleDrop(shot.id, e)}
              onClick={() => { if (!images[shot.id]) pickFile(shot.id); }}
              style={{
                width: CANVAS_W * SCALE,
                height: CANVAS_H * SCALE,
                overflow: 'hidden',
                borderRadius: 6,
                border: images[shot.id] ? '1px solid #1a1a1a' : '1px dashed #252525',
                cursor: images[shot.id] ? 'default' : 'pointer',
                position: 'relative',
                transition: 'border-color 0.2s',
              }}
            >
              <div style={{
                transform: `scale(${SCALE})`,
                transformOrigin: 'top left',
              }}>
                <CompositeSlide
                  shot={shot} lang={lang}
                  imageDataUrl={images[shot.id] || null}
                  slideRef={{
                    set current(el: HTMLDivElement | null) { refs.current[shot.id] = el; },
                    get current() { return refs.current[shot.id] || null; },
                  }}
                />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

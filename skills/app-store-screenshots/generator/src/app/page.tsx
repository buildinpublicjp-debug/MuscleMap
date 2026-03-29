'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const CANVAS_W = 1320;
const CANVAS_H = 2868;
const PHONE_W = 880;
const COPY_PAD_TOP = 100;
const COPY_PAD_X = 80;
const DEVICE_GAP = 32;
const FADE_H = 380;

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
        background: 'linear-gradient(180deg, #050805 0%, #0A0A0A 30%, #0D1A10 100%)',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: isJa
          ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
          : "'Inter', 'SF Pro Display', sans-serif",
      }}
    >
      {/* Glow */}
      <div style={{
        position: 'absolute', top: -250, left: '50%', transform: 'translateX(-50%)',
        width: 1100, height: 1100,
        background: `radial-gradient(circle, ${shot.accent}16 0%, transparent 55%)`,
        pointerEvents: 'none',
      }} />

      {/* Grid */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: 'linear-gradient(rgba(255,255,255,0.012) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.012) 1px, transparent 1px)',
        backgroundSize: '60px 60px',
        pointerEvents: 'none',
      }} />

      {/* Copy area */}
      <div style={{
        paddingTop: COPY_PAD_TOP,
        paddingLeft: COPY_PAD_X,
        paddingRight: COPY_PAD_X,
        textAlign: 'center',
        position: 'relative',
        zIndex: 2,
      }}>
        {/* Headline */}
        <div style={{
          fontSize: isJa ? 96 : 98,
          fontWeight: 900,
          color: '#FFFFFF',
          lineHeight: 1.1,
          letterSpacing: isJa ? 4 : -2,
          textShadow: '0 2px 40px rgba(0,0,0,0.5)',
        }}>
          {lines.map((l, i) => <div key={i}>{l}</div>)}
        </div>

        {/* Sub */}
        <div style={{
          fontSize: 30,
          fontWeight: 500,
          color: `${shot.accent}80`,
          marginTop: 18,
          letterSpacing: isJa ? 2 : 0.3,
        }}>
          {copy.sub}
        </div>

        {/* Chips */}
        <div style={{
          display: 'flex', gap: 10, justifyContent: 'center',
          marginTop: 20, flexWrap: 'wrap' as const,
        }}>
          {copy.chips.map((c, i) => (
            <span key={i} style={{
              padding: '6px 16px',
              background: `${shot.accent}0A`,
              border: `1px solid ${shot.accent}1A`,
              borderRadius: 30,
              color: c.desc ? 'rgba(255,255,255,0.5)' : `${shot.accent}AA`,
              fontSize: 18, fontWeight: c.desc ? 500 : 700,
            }}>
              {c.desc ? (<><strong style={{ color: shot.accent, fontWeight: 900 }}>{c.label}</strong> {c.desc}</>) : c.label}
            </span>
          ))}
        </div>
      </div>

      {/* Device */}
      <div style={{
        display: 'flex', justifyContent: 'center',
        paddingTop: DEVICE_GAP,
        position: 'relative', zIndex: 1,
      }}>
        <div style={{ width: PHONE_W, position: 'relative' }}>
          <div style={{
            position: 'relative',
            borderRadius: 56,
            padding: 12,
            background: 'linear-gradient(145deg, #3A3A3C 0%, #1C1C1E 50%, #2C2C2E 100%)',
            boxShadow: `0 40px 100px rgba(0,0,0,0.85), 0 0 0 1px rgba(255,255,255,0.04), 0 4px 60px ${shot.accent}0E, inset 0 1px 0 rgba(255,255,255,0.06)`,
          }}>
            {/* Side buttons */}
            <div style={{ position: 'absolute', top: 220, right: -3, width: 4, height: 80, background: 'linear-gradient(180deg, #4A4A4C, #2C2C2E, #4A4A4C)', borderRadius: '0 2px 2px 0' }} />
            <div style={{ position: 'absolute', top: 190, left: -3, width: 4, height: 45, background: 'linear-gradient(180deg, #4A4A4C, #2C2C2E, #4A4A4C)', borderRadius: '2px 0 0 2px' }} />
            <div style={{ position: 'absolute', top: 248, left: -3, width: 4, height: 45, background: 'linear-gradient(180deg, #4A4A4C, #2C2C2E, #4A4A4C)', borderRadius: '2px 0 0 2px' }} />

            {/* Screen */}
            <div style={{
              borderRadius: 44,
              overflow: 'hidden',
              background: '#000',
              position: 'relative',
            }}>
              {/* Dynamic Island */}
              <div style={{
                position: 'absolute', top: 14, left: '50%', transform: 'translateX(-50%)',
                width: 130, height: 32, background: '#000', borderRadius: 16, zIndex: 10,
              }} />
              {/* Glass reflection */}
              <div style={{
                position: 'absolute', top: 0, left: 0, right: 0, height: 160,
                background: 'linear-gradient(180deg, rgba(255,255,255,0.025) 0%, transparent 100%)',
                pointerEvents: 'none', zIndex: 5,
              }} />

              {imageDataUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={imageDataUrl} alt={`Shot ${shot.id}`} style={{ width: '100%', display: 'block' }} />
              ) : (
                <div style={{
                  width: '100%', aspectRatio: '1179/2556',
                  background: 'linear-gradient(180deg, #141414 0%, #0a0a0a 100%)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexDirection: 'column', gap: 12,
                }}>
                  <div style={{ fontSize: 40, opacity: 0.15 }}>📱</div>
                  <div style={{ color: 'rgba(255,255,255,0.1)', fontSize: 22 }}>Drop screenshot</div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Bottom fade */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: FADE_H,
        background: 'linear-gradient(transparent 0%, #050805 80%)',
        pointerEvents: 'none', zIndex: 3,
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
  const SCALE = 320 / CANVAS_W;

  const setImage = useCallback((id: number, dataUrl: string) => {
    setImages((prev) => ({ ...prev, [id]: dataUrl }));
  }, []);

  const handleFileDrop = useCallback((id: number, e: DragEvent | React.ChangeEvent<HTMLInputElement>) => {
    let file: File | undefined;
    if ('dataTransfer' in e) {
      e.preventDefault();
      file = e.dataTransfer.files[0];
    } else {
      file = (e.target as HTMLInputElement).files?.[0];
    }
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
    <div style={{ background: '#080808', minHeight: '100vh', color: '#fff' }}>
      {/* Header */}
      <div style={{
        padding: '16px 24px',
        borderBottom: '1px solid #1a1a1a',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        position: 'sticky', top: 0, background: '#080808', zIndex: 50,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <h1 style={{ fontSize: 16, fontWeight: 800, margin: 0, color: '#ccc' }}>MuscleMap Screenshots</h1>
          <div style={{ display: 'flex', gap: 3 }}>
            {LANGS.map((l) => (
              <button key={l} onClick={() => setLang(l)} style={{
                padding: '3px 8px',
                background: lang === l ? '#00E676' : '#181818',
                color: lang === l ? '#000' : '#666',
                border: 'none', borderRadius: 4, cursor: 'pointer',
                fontWeight: 700, fontSize: 10, textTransform: 'uppercase',
              }}>{l}</button>
            ))}
          </div>
          <span style={{ fontSize: 11, color: '#444' }}>{loaded}/6</span>
        </div>
        <button onClick={exportAll} disabled={loaded === 0 || exporting} style={{
          padding: '8px 20px',
          background: loaded === 0 || exporting ? '#1a1a1a' : '#00E676',
          color: loaded === 0 || exporting ? '#444' : '#000',
          border: 'none', borderRadius: 6, cursor: loaded === 0 ? 'not-allowed' : 'pointer',
          fontWeight: 800, fontSize: 12,
        }}>
          {exporting ? 'Exporting...' : `Export All (${loaded})`}
        </button>
      </div>

      {/* Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 12,
        padding: '16px 12px',
      }}>
        {SHOTS.map((shot) => (
          <div key={shot.id}>
            {/* Label row */}
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              marginBottom: 6, padding: '0 2px',
            }}>
              <span style={{ fontSize: 11, color: '#555', fontWeight: 600 }}>
                {shot.id}. {shot.copy[lang].headline.split('\n')[0]}
              </span>
              <button onClick={() => exportOne(shot.id)} disabled={!images[shot.id]} style={{
                padding: '3px 10px',
                background: images[shot.id] ? '#00E676' : '#1a1a1a',
                color: images[shot.id] ? '#000' : '#444',
                border: 'none', borderRadius: 4, cursor: images[shot.id] ? 'pointer' : 'not-allowed',
                fontWeight: 700, fontSize: 10,
              }}>Export</button>
            </div>

            {/* Preview with drop */}
            <div
              onDragOver={(e) => { e.preventDefault(); }}
              onDrop={(e) => handleFileDrop(shot.id, e as unknown as DragEvent)}
              onClick={() => {
                if (images[shot.id]) return;
                const input = document.createElement('input');
                input.type = 'file'; input.accept = 'image/*';
                input.onchange = (ev) => handleFileDrop(shot.id, ev as unknown as React.ChangeEvent<HTMLInputElement>);
                input.click();
              }}
              style={{
                width: CANVAS_W * SCALE,
                height: CANVAS_H * SCALE,
                overflow: 'hidden',
                borderRadius: 8,
                border: images[shot.id] ? '1px solid #222' : '1px dashed #333',
                cursor: images[shot.id] ? 'default' : 'pointer',
                position: 'relative',
              }}
            >
              {/* Replace button */}
              {images[shot.id] && (
                <div
                  onClick={(e) => {
                    e.stopPropagation();
                    const input = document.createElement('input');
                    input.type = 'file'; input.accept = 'image/*';
                    input.onchange = (ev) => handleFileDrop(shot.id, ev as unknown as React.ChangeEvent<HTMLInputElement>);
                    input.click();
                  }}
                  style={{
                    position: 'absolute', top: 6, right: 6, zIndex: 10,
                    padding: '3px 8px', background: 'rgba(0,0,0,0.7)',
                    borderRadius: 4, cursor: 'pointer', fontSize: 10,
                    color: '#888', border: '1px solid #333',
                  }}
                >Replace</div>
              )}
              <div style={{
                transform: `scale(${SCALE})`,
                transformOrigin: 'top left',
              }}>
                <CompositeSlide
                  shot={shot}
                  lang={lang}
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

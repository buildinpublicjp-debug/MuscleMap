'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const W = 1320;
const H = 2868;
const COPY_TOP = 100;
const PHONE_TOP = 680;
const PHONE_W = 900;
const PHONE_X = (W - PHONE_W) / 2;

function CompositeSlide({
  shot, lang, imageDataUrl, slideRef,
}: {
  shot: ShotDef; lang: Lang; imageDataUrl: string | null;
  slideRef: React.RefObject<HTMLDivElement | null>;
}) {
  const copy = shot.copy[lang];
  const isJa = lang === 'ja' || lang === 'zh' || lang === 'ko';
  const lines = copy.headline.split('\n');
  const a = shot.accent;

  return (
    <div ref={slideRef} style={{
      width: W, height: H, background: '#030504',
      position: 'relative', overflow: 'hidden',
      fontFamily: isJa
        ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
        : "'Inter', 'SF Pro Display', -apple-system, sans-serif",
    }}>

      {/* ═══════ BACKGROUND LAYERS ═══════ */}

      {/* Deep base gradient — dark with subtle green tint */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(175deg, #040806 0%, #030504 25%, #050705 50%, #030604 75%, #020403 100%)',
      }} />

      {/* Main accent aurora — large soft glow from top */}
      <div style={{
        position: 'absolute', top: -500, left: '50%', transform: 'translateX(-50%)',
        width: 1800, height: 1600,
        background: `radial-gradient(ellipse 60% 40%, ${a}18 0%, ${a}08 30%, transparent 65%)`,
      }} />

      {/* Secondary aurora — bottom right warmth */}
      <div style={{
        position: 'absolute', bottom: -400, right: -300,
        width: 1200, height: 1000,
        background: `radial-gradient(ellipse, ${a}06 0%, transparent 60%)`,
      }} />

      {/* Tertiary aurora — left side subtle */}
      <div style={{
        position: 'absolute', top: '40%', left: -400,
        width: 800, height: 800,
        background: `radial-gradient(circle, ${a}04 0%, transparent 60%)`,
      }} />

      {/* ── Muscle fiber pattern (SVG) ── */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.03 }}
        viewBox="0 0 1320 2868" fill="none" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
        {/* Flowing organic fiber lines */}
        {Array.from({ length: 24 }).map((_, i) => {
          const y = 120 * i;
          const offset = (i % 3) * 40;
          return (
            <path key={i}
              d={`M${-100 + offset} ${y} C${300 + offset} ${y + 60}, ${600 - offset} ${y - 40}, ${W + 100} ${y + 30}`}
              stroke={a} strokeWidth={1 + (i % 3) * 0.5} strokeOpacity={0.4 + (i % 5) * 0.1}
            />
          );
        })}
        {/* Cross fibers */}
        {Array.from({ length: 8 }).map((_, i) => {
          const x = 165 * i;
          return (
            <path key={`v${i}`}
              d={`M${x} ${-100} C${x + 80} ${700}, ${x - 60} ${1400}, ${x + 40} ${H + 100}`}
              stroke={a} strokeWidth={0.5} strokeOpacity={0.2}
            />
          );
        })}
      </svg>

      {/* ── Anatomical ring — abstract muscle cross-section ── */}
      <div style={{
        position: 'absolute', top: 300, left: '50%', transform: 'translateX(-50%)',
        width: 800, height: 800, opacity: 0.04,
        borderRadius: '50%',
        border: `2px solid ${a}`,
        boxShadow: `0 0 120px ${a}20, inset 0 0 120px ${a}10`,
      }} />
      <div style={{
        position: 'absolute', top: 380, left: '50%', transform: 'translateX(-50%)',
        width: 640, height: 640, opacity: 0.025,
        borderRadius: '50%',
        border: `1px solid ${a}`,
      }} />

      {/* ── Particle dots ── */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.06 }}
        viewBox="0 0 1320 2868" xmlns="http://www.w3.org/2000/svg">
        {Array.from({ length: 40 }).map((_, i) => (
          <circle key={i}
            cx={100 + (i * 317) % W}
            cy={80 + (i * 541) % H}
            r={1 + (i % 3)}
            fill={a}
            opacity={0.3 + (i % 4) * 0.15}
          />
        ))}
      </svg>

      {/* ── Fine noise texture ── */}
      <div style={{
        position: 'absolute', inset: 0, opacity: 0.35,
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 512 512' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
      }} />

      {/* ── Top accent edge ── */}
      <div style={{
        position: 'absolute', top: 0, left: '10%', right: '10%', height: 1,
        background: `linear-gradient(90deg, transparent, ${a}35, transparent)`,
      }} />

      {/* ── Side accent lines ── */}
      <div style={{
        position: 'absolute', top: '8%', bottom: '8%', left: 0, width: 1,
        background: `linear-gradient(180deg, transparent, ${a}10, ${a}06, transparent)`,
      }} />
      <div style={{
        position: 'absolute', top: '8%', bottom: '8%', right: 0, width: 1,
        background: `linear-gradient(180deg, transparent, ${a}10, ${a}06, transparent)`,
      }} />

      {/* ═══════ COPY AREA ═══════ */}
      <div style={{
        position: 'absolute', top: COPY_TOP, left: 0, right: 0,
        textAlign: 'center', zIndex: 2, padding: '0 70px',
      }}>
        <div style={{
          fontSize: isJa ? 100 : 104,
          fontWeight: 900,
          color: '#FFF',
          lineHeight: 1.05,
          letterSpacing: isJa ? 8 : -3,
          fontFeatureSettings: "'palt' 1",
          textShadow: `0 0 100px ${a}12, 0 4px 30px rgba(0,0,0,0.4)`,
        }}>
          {lines.map((l, i) => <div key={i}>{l}</div>)}
        </div>

        <div style={{
          fontSize: 26, fontWeight: 400,
          color: `${a}5A`,
          marginTop: 22, letterSpacing: isJa ? 3 : 1,
          fontFeatureSettings: "'palt' 1",
        }}>
          {copy.sub}
        </div>

        <div style={{
          display: 'flex', gap: 8, justifyContent: 'center',
          marginTop: 26, flexWrap: 'wrap' as const,
        }}>
          {copy.chips.map((c, i) => (
            <span key={i} style={{
              padding: '5px 14px',
              background: `${a}05`,
              border: `1px solid ${a}10`,
              borderRadius: 100,
              color: c.desc ? 'rgba(255,255,255,0.3)' : `${a}70`,
              fontSize: 15, fontWeight: c.desc ? 400 : 700,
              letterSpacing: 0.5,
            }}>
              {c.desc
                ? <><strong style={{ color: `${a}AA`, fontWeight: 700 }}>{c.label}</strong> {c.desc}</>
                : c.label}
            </span>
          ))}
        </div>
      </div>

      {/* ═══════ PHONE ═══════ */}
      <div style={{
        position: 'absolute', top: PHONE_TOP, left: PHONE_X, width: PHONE_W, zIndex: 1,
      }}>
        {/* Phone glow */}
        <div style={{
          position: 'absolute', top: -60, left: -80, right: -80, bottom: -60,
          background: `radial-gradient(ellipse, ${a}0A 0%, transparent 65%)`,
          pointerEvents: 'none',
        }} />

        {/* Phone reflection arc — premium feel */}
        <div style={{
          position: 'absolute', top: -30, left: '50%', transform: 'translateX(-50%)',
          width: PHONE_W - 100, height: 60, opacity: 0.04,
          background: `radial-gradient(ellipse, ${a} 0%, transparent 70%)`,
          filter: 'blur(20px)',
          pointerEvents: 'none',
        }} />

        <div style={{
          position: 'relative', borderRadius: 56, padding: 11,
          background: 'linear-gradient(155deg, #555557 0%, #2C2C2E 15%, #1C1C1E 50%, #2C2C2E 85%, #555557 100%)',
          boxShadow: `
            0 40px 80px rgba(0,0,0,0.9),
            0 0 0 0.5px rgba(255,255,255,0.1),
            0 15px 50px ${a}06,
            inset 0 0.5px 0 rgba(255,255,255,0.18),
            inset 0 -0.5px 0 rgba(255,255,255,0.05)
          `,
        }}>
          {/* Buttons */}
          <div style={{ position: 'absolute', top: 195, right: -2, width: 3, height: 75,
            background: 'linear-gradient(180deg, #606062, #3A3A3C, #606062)', borderRadius: '0 1.5px 1.5px 0' }} />
          <div style={{ position: 'absolute', top: 165, left: -2, width: 3, height: 38,
            background: 'linear-gradient(180deg, #606062, #3A3A3C, #606062)', borderRadius: '1.5px 0 0 1.5px' }} />
          <div style={{ position: 'absolute', top: 215, left: -2, width: 3, height: 38,
            background: 'linear-gradient(180deg, #606062, #3A3A3C, #606062)', borderRadius: '1.5px 0 0 1.5px' }} />

          <div style={{
            borderRadius: 45, overflow: 'hidden', background: '#000', position: 'relative',
          }}>
            <div style={{
              position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
              width: 120, height: 28, background: '#000', borderRadius: 14, zIndex: 10,
            }} />
            <div style={{
              position: 'absolute', inset: 0, borderRadius: 45,
              boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.08)',
              pointerEvents: 'none', zIndex: 8,
            }} />
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0, height: 150,
              background: 'linear-gradient(180deg, rgba(255,255,255,0.02) 0%, transparent 100%)',
              pointerEvents: 'none', zIndex: 5,
            }} />

            {imageDataUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={imageDataUrl} alt="" style={{ width: '100%', display: 'block' }} />
            ) : (
              <div style={{
                width: '100%', aspectRatio: '1179/2556', background: '#080808',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 11,
                  border: '1.5px dashed rgba(255,255,255,0.05)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <span style={{ fontSize: 18, opacity: 0.08 }}>+</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ═══════ BOTTOM ═══════ */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 500,
        background: 'linear-gradient(transparent 0%, #030504 65%)',
        pointerEvents: 'none', zIndex: 3,
      }} />

      {/* Bottom brand accent bar */}
      <div style={{
        position: 'absolute', bottom: 50, left: '30%', right: '30%', height: 2,
        background: `linear-gradient(90deg, transparent, ${a}20, transparent)`,
        zIndex: 4, borderRadius: 1,
      }} />
      <div style={{
        position: 'absolute', bottom: 46, left: '35%', right: '35%', height: 1,
        background: `linear-gradient(90deg, transparent, ${a}08, transparent)`,
        zIndex: 4,
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
  const S = 340 / W;

  const setImg = useCallback((id: number, d: string) => setImages(p => ({ ...p, [id]: d })), []);

  const pick = useCallback((id: number) => {
    const i = document.createElement('input');
    i.type = 'file'; i.accept = 'image/*';
    i.onchange = (e) => {
      const f = (e.target as HTMLInputElement).files?.[0];
      if (!f) return;
      const r = new FileReader();
      r.onload = () => setImg(id, r.result as string);
      r.readAsDataURL(f);
    };
    i.click();
  }, [setImg]);

  const drop = useCallback((id: number, e: DragEvent) => {
    e.preventDefault();
    const f = e.dataTransfer.files[0];
    if (!f?.type.startsWith('image/')) return;
    const r = new FileReader();
    r.onload = () => setImg(id, r.result as string);
    r.readAsDataURL(f);
  }, [setImg]);

  const exp1 = useCallback(async (id: number) => {
    const el = refs.current[id]; if (!el) return;
    const u = await toPng(el, { width: W, height: H, pixelRatio: 1 });
    Object.assign(document.createElement('a'), { download: `shot${id}_${lang}.png`, href: u }).click();
  }, [lang]);

  const expAll = useCallback(async () => {
    setExporting(true);
    for (const s of SHOTS) {
      if (!images[s.id]) continue;
      await exp1(s.id);
      await new Promise(r => setTimeout(r, 500));
    }
    setExporting(false);
  }, [images, exp1]);

  const n = Object.keys(images).length;

  return (
    <div style={{ background: '#060606', minHeight: '100vh', color: '#fff' }}>
      <div style={{
        padding: '12px 20px', borderBottom: '1px solid #131313',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        position: 'sticky', top: 0, background: 'rgba(6,6,6,0.92)',
        backdropFilter: 'blur(16px)', zIndex: 50,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ fontSize: 13, fontWeight: 700, color: '#555', letterSpacing: 2, textTransform: 'uppercase' }}>Screenshots</span>
          <div style={{ width: 1, height: 14, background: '#1a1a1a' }} />
          <div style={{ display: 'flex', gap: 1 }}>
            {LANGS.map(l => (
              <button key={l} onClick={() => setLang(l)} style={{
                padding: '3px 9px', background: lang === l ? '#00E676' : 'transparent',
                color: lang === l ? '#000' : '#444', border: 'none', borderRadius: 3,
                cursor: 'pointer', fontWeight: 700, fontSize: 10, textTransform: 'uppercase',
              }}>{l}</button>
            ))}
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 10, color: '#2a2a2a' }}>{n}/6</span>
          <button onClick={expAll} disabled={!n || exporting} style={{
            padding: '7px 20px', background: !n ? '#0d0d0d' : '#00E676',
            color: !n ? '#2a2a2a' : '#000', border: 'none', borderRadius: 5,
            cursor: !n ? 'not-allowed' : 'pointer', fontWeight: 800, fontSize: 11,
          }}>{exporting ? '...' : 'Export All'}</button>
        </div>
      </div>

      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 6, padding: '10px 6px',
      }}>
        {SHOTS.map(shot => (
          <div key={shot.id}>
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              marginBottom: 3, padding: '0 4px',
            }}>
              <span style={{ fontSize: 9, color: '#333', fontWeight: 600, letterSpacing: 0.8, textTransform: 'uppercase' }}>
                {shot.id}. {shot.copy[lang].headline.split('\n')[0]}
              </span>
              <div style={{ display: 'flex', gap: 3 }}>
                {images[shot.id] && (
                  <button onClick={() => pick(shot.id)} style={{
                    padding: '1px 6px', background: 'transparent', color: '#2a2a2a',
                    border: '1px solid #1a1a1a', borderRadius: 2, cursor: 'pointer', fontSize: 8,
                  }}>↻</button>
                )}
                <button onClick={() => exp1(shot.id)} disabled={!images[shot.id]} style={{
                  padding: '1px 6px', background: images[shot.id] ? '#00E676' : '#0a0a0a',
                  color: images[shot.id] ? '#000' : '#1a1a1a', border: 'none', borderRadius: 2,
                  cursor: images[shot.id] ? 'pointer' : 'not-allowed', fontSize: 8, fontWeight: 700,
                }}>↓</button>
              </div>
            </div>

            <div
              onDragOver={e => e.preventDefault()}
              onDrop={e => drop(shot.id, e)}
              onClick={() => { if (!images[shot.id]) pick(shot.id); }}
              style={{
                width: W * S, height: H * S, overflow: 'hidden',
                borderRadius: 5, border: images[shot.id] ? '1px solid #151515' : '1px dashed #181818',
                cursor: images[shot.id] ? 'default' : 'pointer',
              }}
            >
              <div style={{ transform: `scale(${S})`, transformOrigin: 'top left' }}>
                <CompositeSlide
                  shot={shot} lang={lang}
                  imageDataUrl={images[shot.id] || null}
                  slideRef={{
                    set current(el) { refs.current[shot.id] = el; },
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

'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const W = 1320;
const H = 2868;
const COPY_TOP = 100;
const PHONE_TOP = 700;
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

      {/* ═══ BG: Base gradient with green tint ═══ */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `linear-gradient(175deg, #060C08 0%, #030504 30%, #040806 60%, #030504 100%)`,
      }} />

      {/* ═══ BG: Main aurora glow — STRONG ═══ */}
      <div style={{
        position: 'absolute', top: -300, left: '50%', transform: 'translateX(-50%)',
        width: 1600, height: 1200,
        background: `radial-gradient(ellipse 70% 50%, ${a}30 0%, ${a}15 25%, ${a}08 45%, transparent 65%)`,
        filter: 'blur(40px)',
      }} />

      {/* ═══ BG: Bottom warm glow ═══ */}
      <div style={{
        position: 'absolute', bottom: -200, left: '50%', transform: 'translateX(-50%)',
        width: 1400, height: 800,
        background: `radial-gradient(ellipse, ${a}12 0%, transparent 60%)`,
        filter: 'blur(60px)',
      }} />

      {/* ═══ BG: Muscle fiber lines — VISIBLE ═══ */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
        viewBox={`0 0 ${W} ${H}`} fill="none" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
        {/* Horizontal flowing fibers */}
        {Array.from({ length: 30 }).map((_, i) => {
          const y = 96 * i;
          const wave = Math.sin(i * 0.5) * 60;
          const wave2 = Math.cos(i * 0.3) * 40;
          return (
            <path key={`h${i}`}
              d={`M-50 ${y + wave} Q${330} ${y + wave2 + 30}, ${660} ${y - wave + 15} T${W + 50} ${y + wave2}`}
              stroke={a}
              strokeWidth={0.8 + (i % 4) * 0.3}
              opacity={0.06 + (i % 3) * 0.03}
            />
          );
        })}
        {/* Vertical structure lines */}
        {Array.from({ length: 10 }).map((_, i) => {
          const x = 132 * i;
          const sway = Math.sin(i * 0.7) * 50;
          return (
            <path key={`v${i}`}
              d={`M${x + sway} -50 Q${x - sway + 30} ${H * 0.33}, ${x + sway - 20} ${H * 0.66} T${x - sway} ${H + 50}`}
              stroke={a}
              strokeWidth={0.5}
              opacity={0.04 + (i % 3) * 0.02}
            />
          );
        })}
      </svg>

      {/* ═══ BG: Concentric anatomy rings ═══ */}
      <div style={{
        position: 'absolute', top: 200, left: '50%', transform: 'translateX(-50%)',
        width: 1000, height: 1000,
        borderRadius: '50%',
        border: `1.5px solid ${a}`,
        opacity: 0.07,
        boxShadow: `0 0 80px ${a}15, inset 0 0 80px ${a}08`,
      }} />
      <div style={{
        position: 'absolute', top: 320, left: '50%', transform: 'translateX(-50%)',
        width: 760, height: 760,
        borderRadius: '50%',
        border: `1px solid ${a}`,
        opacity: 0.04,
      }} />
      <div style={{
        position: 'absolute', top: 440, left: '50%', transform: 'translateX(-50%)',
        width: 520, height: 520,
        borderRadius: '50%',
        border: `0.5px solid ${a}`,
        opacity: 0.03,
      }} />

      {/* ═══ BG: Scatter particles ═══ */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
        viewBox={`0 0 ${W} ${H}`} xmlns="http://www.w3.org/2000/svg">
        {Array.from({ length: 60 }).map((_, i) => (
          <circle key={i}
            cx={60 + (i * 293 + i * i * 7) % (W - 120)}
            cy={50 + (i * 487 + i * i * 3) % (H - 100)}
            r={1 + (i % 4) * 0.8}
            fill={a}
            opacity={0.08 + (i % 5) * 0.04}
          />
        ))}
      </svg>

      {/* ═══ BG: Noise texture ═══ */}
      <div style={{
        position: 'absolute', inset: 0, opacity: 0.5, mixBlendMode: 'overlay' as const,
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 512 512' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.06'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
      }} />

      {/* ═══ BG: Edge accents ═══ */}
      {/* Top */}
      <div style={{
        position: 'absolute', top: 0, left: '5%', right: '5%', height: 2,
        background: `linear-gradient(90deg, transparent, ${a}50, transparent)`,
      }} />
      {/* Sides */}
      <div style={{
        position: 'absolute', top: '5%', bottom: '5%', left: 0, width: 1,
        background: `linear-gradient(180deg, transparent 0%, ${a}18 30%, ${a}10 70%, transparent 100%)`,
      }} />
      <div style={{
        position: 'absolute', top: '5%', bottom: '5%', right: 0, width: 1,
        background: `linear-gradient(180deg, transparent 0%, ${a}18 30%, ${a}10 70%, transparent 100%)`,
      }} />

      {/* ═══ COPY ═══ */}
      <div style={{
        position: 'absolute', top: COPY_TOP, left: 0, right: 0,
        textAlign: 'center', zIndex: 2, padding: '0 70px',
      }}>
        <div style={{
          fontSize: isJa ? 100 : 104,
          fontWeight: 900, color: '#FFF',
          lineHeight: 1.05,
          letterSpacing: isJa ? 8 : -3,
          fontFeatureSettings: "'palt' 1",
          textShadow: `0 0 80px ${a}25, 0 0 160px ${a}10, 0 4px 20px rgba(0,0,0,0.6)`,
        }}>
          {lines.map((l, i) => <div key={i}>{l}</div>)}
        </div>

        <div style={{
          fontSize: 26, fontWeight: 400,
          color: `${a}60`,
          marginTop: 22, letterSpacing: isJa ? 3 : 1,
          fontFeatureSettings: "'palt' 1",
          textShadow: `0 0 40px ${a}15`,
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
              background: `${a}08`,
              border: `1px solid ${a}18`,
              borderRadius: 100,
              color: c.desc ? 'rgba(255,255,255,0.35)' : `${a}80`,
              fontSize: 15, fontWeight: c.desc ? 400 : 700,
              letterSpacing: 0.5,
              boxShadow: `0 0 20px ${a}06`,
            }}>
              {c.desc
                ? <><strong style={{ color: `${a}BB`, fontWeight: 700 }}>{c.label}</strong> {c.desc}</>
                : c.label}
            </span>
          ))}
        </div>
      </div>

      {/* ═══ PHONE ═══ */}
      <div style={{
        position: 'absolute', top: PHONE_TOP, left: PHONE_X, width: PHONE_W, zIndex: 1,
      }}>
        {/* Phone underglow */}
        <div style={{
          position: 'absolute', top: -50, left: -100, right: -100, bottom: -50,
          background: `radial-gradient(ellipse 70% 50%, ${a}10 0%, transparent 60%)`,
          filter: 'blur(30px)',
          pointerEvents: 'none',
        }} />

        {/* Top reflection arc */}
        <div style={{
          position: 'absolute', top: -20, left: '10%', right: '10%', height: 40,
          background: `radial-gradient(ellipse, ${a}18 0%, transparent 70%)`,
          filter: 'blur(15px)',
          pointerEvents: 'none',
        }} />

        <div style={{
          position: 'relative', borderRadius: 56, padding: 11,
          background: 'linear-gradient(155deg, #606062 0%, #3A3A3C 10%, #1C1C1E 50%, #3A3A3C 90%, #606062 100%)',
          boxShadow: `
            0 40px 80px rgba(0,0,0,0.9),
            0 0 0 0.5px rgba(255,255,255,0.12),
            0 20px 60px ${a}08,
            inset 0 0.5px 0 rgba(255,255,255,0.2),
            inset 0 -0.5px 0 rgba(255,255,255,0.06)
          `,
        }}>
          {/* Buttons */}
          <div style={{ position: 'absolute', top: 195, right: -2, width: 3, height: 75,
            background: 'linear-gradient(180deg, #707072, #3A3A3C, #707072)', borderRadius: '0 1.5px 1.5px 0' }} />
          <div style={{ position: 'absolute', top: 165, left: -2, width: 3, height: 38,
            background: 'linear-gradient(180deg, #707072, #3A3A3C, #707072)', borderRadius: '1.5px 0 0 1.5px' }} />
          <div style={{ position: 'absolute', top: 215, left: -2, width: 3, height: 38,
            background: 'linear-gradient(180deg, #707072, #3A3A3C, #707072)', borderRadius: '1.5px 0 0 1.5px' }} />

          <div style={{
            borderRadius: 45, overflow: 'hidden', background: '#000', position: 'relative',
          }}>
            <div style={{
              position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
              width: 120, height: 28, background: '#000', borderRadius: 14, zIndex: 10,
            }} />
            <div style={{
              position: 'absolute', inset: 0, borderRadius: 45,
              boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.1)',
              pointerEvents: 'none', zIndex: 8,
            }} />
            <div style={{
              position: 'absolute', top: 0, left: 0, right: 0, height: 150,
              background: 'linear-gradient(180deg, rgba(255,255,255,0.025) 0%, transparent 100%)',
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
                  border: `1.5px dashed ${a}15`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <span style={{ fontSize: 18, color: a, opacity: 0.15 }}>+</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ═══ BOTTOM FADE ═══ */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 500,
        background: 'linear-gradient(transparent 0%, #030504 65%)',
        pointerEvents: 'none', zIndex: 3,
      }} />

      {/* Bottom brand bar */}
      <div style={{
        position: 'absolute', bottom: 45, left: '25%', right: '25%', height: 2,
        background: `linear-gradient(90deg, transparent, ${a}35, transparent)`,
        zIndex: 4, borderRadius: 1,
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
        padding: '12px 20px', borderBottom: '1px solid #151515',
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

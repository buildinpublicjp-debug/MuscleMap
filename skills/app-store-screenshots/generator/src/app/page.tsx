'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const W = 1320;
const H = 2868;
const COPY_TOP = 80;
const PHONE_TOP = 428;
const PHONE_W = 1200;
const PHONE_X = (W - PHONE_W) / 2;

function CompositeSlide({ shot, lang, imageDataUrl, slideRef }: { shot: ShotDef; lang: Lang; imageDataUrl: string | null; slideRef?: React.RefObject<HTMLDivElement | null>; }) {
  const copy = shot.copy[lang]; const isJa = lang === 'ja' || lang === 'zh' || lang === 'ko'; const lines = copy.headline.split('\n'); const a = shot.accent;
  return (<div ref={slideRef} style={{ width: W, height: H, background: '#020303', position: 'relative', overflow: 'hidden', fontFamily: isJa ? "'Noto Sans JP', 'Hiragino Sans', sans-serif" : "'Inter', 'SF Pro Display', -apple-system, sans-serif" }}>
    <div style={{ position: 'absolute', inset: 0, background: `linear-gradient(175deg, #081410 0%, #030504 30%, #061008 60%, #020303 100%)` }} />
    <div style={{ position: 'absolute', top: -200, left: '50%', transform: 'translateX(-50%)', width: 1800, height: 1400, background: `radial-gradient(ellipse 65% 45%, ${a}44 0%, ${a}22 30%, ${a}0C 55%, transparent 70%)`, filter: 'blur(80px)' }} />
    <div style={{ position: 'absolute', bottom: -100, left: '50%', transform: 'translateX(-50%)', width: 1200, height: 600, background: `radial-gradient(ellipse, ${a}20 0%, ${a}08 40%, transparent 70%)`, filter: 'blur(60px)' }} />
    <div style={{ position: 'absolute', top: '30%', left: -200, width: 500, height: 800, background: `radial-gradient(circle, ${a}10 0%, transparent 60%)`, filter: 'blur(40px)' }} />
    <div style={{ position: 'absolute', top: '50%', right: -200, width: 500, height: 800, background: `radial-gradient(circle, ${a}0C 0%, transparent 60%)`, filter: 'blur(40px)' }} />
    <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} viewBox={`0 0 ${W} ${H}`} fill="none" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
      {Array.from({ length: 35 }).map((_, i) => { const y = 82 * i; const w1 = Math.sin(i * 0.4) * 80; const w2 = Math.cos(i * 0.6) * 60; return (<path key={`h${i}`} d={`M-80 ${y + w1} Q${W * 0.25} ${y + w2 + 40}, ${W * 0.5} ${y - w1 + 20} T${W + 80} ${y + w2}`} stroke={a} strokeWidth={0.6 + (i % 5) * 0.4} opacity={0.12 + (i % 4) * 0.05} />); })}
      {Array.from({ length: 12 }).map((_, i) => { const x = 110 * i; const s = Math.sin(i * 0.8) * 60; return (<path key={`v${i}`} d={`M${x + s} -80 Q${x - s + 40} ${H * 0.3}, ${x + s - 30} ${H * 0.6} T${x - s + 10} ${H + 80}`} stroke={a} strokeWidth={0.4 + (i % 3) * 0.3} opacity={0.06 + (i % 3) * 0.04} />); })}
    </svg>
    <div style={{ position: 'absolute', top: 150, left: '50%', transform: 'translateX(-50%)', width: 1100, height: 1100, borderRadius: '50%', border: `2px solid ${a}`, opacity: 0.12, boxShadow: `0 0 100px ${a}20, inset 0 0 60px ${a}0A` }} />
    <div style={{ position: 'absolute', top: 290, left: '50%', transform: 'translateX(-50%)', width: 820, height: 820, borderRadius: '50%', border: `1.5px solid ${a}`, opacity: 0.07 }} />
    <div style={{ position: 'absolute', top: 430, left: '50%', transform: 'translateX(-50%)', width: 540, height: 540, borderRadius: '50%', border: `1px solid ${a}`, opacity: 0.04 }} />
    <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} viewBox={`0 0 ${W} ${H}`} xmlns="http://www.w3.org/2000/svg">
      {Array.from({ length: 80 }).map((_, i) => (<circle key={i} cx={50 + (i * 293 + i * i * 7) % (W - 100)} cy={40 + (i * 487 + i * i * 3) % (H - 80)} r={0.8 + (i % 5) * 0.6} fill={a} opacity={0.15 + (i % 4) * 0.08} />))}
    </svg>
    <div style={{ position: 'absolute', inset: 0, opacity: 0.6, mixBlendMode: 'overlay' as const, backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 512 512' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.08'/%3E%3C/svg%3E")`, backgroundRepeat: 'repeat' }} />
    <div style={{ position: 'absolute', top: 0, left: '5%', right: '5%', height: 2, background: `linear-gradient(90deg, transparent, ${a}60, transparent)` }} />
    <div style={{ position: 'absolute', top: '5%', bottom: '5%', left: 0, width: 1, background: `linear-gradient(180deg, transparent, ${a}25, ${a}15, transparent)` }} />
    <div style={{ position: 'absolute', top: '5%', bottom: '5%', right: 0, width: 1, background: `linear-gradient(180deg, transparent, ${a}25, ${a}15, transparent)` }} />
    <div style={{ position: 'absolute', top: COPY_TOP, left: 0, right: 0, textAlign: 'center', zIndex: 2, padding: '0 60px' }}>
      <div style={{ fontSize: isJa ? 100 : 104, fontWeight: 900, color: '#FFF', lineHeight: 1.05, letterSpacing: isJa ? 8 : -3, fontFeatureSettings: "'palt' 1", textShadow: `0 0 60px ${a}30, 0 0 120px ${a}15, 0 4px 20px rgba(0,0,0,0.7)` }}>
        {lines.map((l, i) => <div key={i}>{l}</div>)}
      </div>
      <div style={{ fontSize: 26, fontWeight: 400, color: `${a}65`, marginTop: 16, letterSpacing: isJa ? 3 : 1, fontFeatureSettings: "'palt' 1", textShadow: `0 0 30px ${a}20` }}>{copy.sub}</div>
      <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 16, flexWrap: 'wrap' as const }}>
        {copy.chips.map((c, i) => (<span key={i} style={{ padding: '5px 14px', background: `${a}0C`, border: `1px solid ${a}20`, borderRadius: 100, color: c.desc ? 'rgba(255,255,255,0.4)' : `${a}90`, fontSize: 15, fontWeight: c.desc ? 400 : 700, boxShadow: `0 0 15px ${a}08` }}>{c.desc ? <><strong style={{ color: `${a}CC`, fontWeight: 700 }}>{c.label}</strong> {c.desc}</> : c.label}</span>))}
      </div>
    </div>
    <div style={{ position: 'absolute', top: PHONE_TOP, left: PHONE_X, width: PHONE_W, zIndex: 1 }}>
      <div style={{ position: 'absolute', top: -60, left: -120, right: -120, bottom: -60, background: `radial-gradient(ellipse 60% 40%, ${a}15 0%, transparent 60%)`, filter: 'blur(40px)' }} />
      <div style={{ position: 'absolute', top: -15, left: '8%', right: '8%', height: 30, background: `radial-gradient(ellipse, ${a}25 0%, transparent 70%)`, filter: 'blur(12px)' }} />
      <div style={{ position: 'relative', borderRadius: 62, padding: 12, background: 'linear-gradient(155deg, #606062 0%, #3A3A3C 10%, #1C1C1E 50%, #3A3A3C 90%, #606062 100%)', boxShadow: `0 40px 80px rgba(0,0,0,0.9), 0 0 0 0.5px rgba(255,255,255,0.12), 0 20px 60px ${a}0A, inset 0 0.5px 0 rgba(255,255,255,0.2), inset 0 -0.5px 0 rgba(255,255,255,0.06)` }}>
        <div style={{ position: 'absolute', top: 215, right: -2.5, width: 3, height: 85, background: 'linear-gradient(180deg, #707072, #3A3A3C, #707072)', borderRadius: '0 1.5px 1.5px 0' }} />
        <div style={{ position: 'absolute', top: 180, left: -2.5, width: 3, height: 42, background: 'linear-gradient(180deg, #707072, #3A3A3C, #707072)', borderRadius: '1.5px 0 0 1.5px' }} />
        <div style={{ position: 'absolute', top: 235, left: -2.5, width: 3, height: 42, background: 'linear-gradient(180deg, #707072, #3A3A3C, #707072)', borderRadius: '1.5px 0 0 1.5px' }} />
        <div style={{ borderRadius: 50, overflow: 'hidden', background: '#000', position: 'relative' }}>
          <div style={{ position: 'absolute', top: 12, left: '50%', transform: 'translateX(-50%)', width: 140, height: 32, background: '#000', borderRadius: 16, zIndex: 10 }} />
          <div style={{ position: 'absolute', inset: 0, borderRadius: 50, boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.1)', pointerEvents: 'none', zIndex: 8 }} />
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 160, background: 'linear-gradient(180deg, rgba(255,255,255,0.03) 0%, transparent 100%)', pointerEvents: 'none', zIndex: 5 }} />
          {imageDataUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={imageDataUrl} alt="" style={{ width: '100%', display: 'block' }} />
          ) : (
            <div style={{ width: '100%', aspectRatio: '1179/2556', background: '#080808', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ width: 50, height: 50, borderRadius: 13, border: `1.5px dashed ${a}18`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span style={{ fontSize: 20, color: a, opacity: 0.2 }}>+</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 200, background: 'linear-gradient(transparent 0%, #02030480 100%)', pointerEvents: 'none', zIndex: 3 }} />
    <div style={{ position: 'absolute', bottom: 40, left: '20%', right: '20%', height: 2, background: `linear-gradient(90deg, transparent, ${a}40, transparent)`, zIndex: 4, borderRadius: 1 }} />
  </div>);
}

export default function Page() {
  const [lang, setLang] = useState<Lang>('ja');
  const [images, setImages] = useState<Record<number, string>>({});
  // Export refs: point to hidden full-size CompositeSlides (off-screen)
  const exportRefs = useRef<Record<number, HTMLDivElement | null>>({});
  const [exporting, setExporting] = useState(false);
  const LANGS: Lang[] = ['ja', 'en', 'zh', 'ko', 'es', 'de', 'fr'];
  const S = 380 / W;
  const setImg = useCallback((id: number, d: string) => setImages(p => ({ ...p, [id]: d })), []);
  const pick = useCallback((id: number) => { const i = document.createElement('input'); i.type = 'file'; i.accept = 'image/*'; i.onchange = (e) => { const f = (e.target as HTMLInputElement).files?.[0]; if (!f) return; const r = new FileReader(); r.onload = () => setImg(id, r.result as string); r.readAsDataURL(f); }; i.click(); }, [setImg]);
  const drop = useCallback((id: number, e: DragEvent) => { e.preventDefault(); const f = e.dataTransfer.files[0]; if (!f?.type.startsWith('image/')) return; const r = new FileReader(); r.onload = () => setImg(id, r.result as string); r.readAsDataURL(f); }, [setImg]);

  // Export uses the hidden full-size ref, not the scaled preview
  const exp1 = useCallback(async (id: number) => {
    const el = exportRefs.current[id];
    if (!el) return;
    const u = await toPng(el, { width: W, height: H, pixelRatio: 1 });
    Object.assign(document.createElement('a'), { download: `shot${id}_${lang}.png`, href: u }).click();
  }, [lang]);

  const expAll = useCallback(async () => { setExporting(true); for (const s of SHOTS) { if (!images[s.id]) continue; await exp1(s.id); await new Promise(r => setTimeout(r, 500)); } setExporting(false); }, [images, exp1]);
  const n = Object.keys(images).length;
  return (
    <div style={{ background: '#060606', minHeight: '100vh', color: '#fff' }}>
      {/* Hidden full-size slides for export (off-screen) */}
      <div style={{ position: 'absolute', left: -99999, top: 0, pointerEvents: 'none' }} aria-hidden="true">
        {SHOTS.map(shot => (
          <CompositeSlide
            key={`export-${shot.id}`}
            shot={shot}
            lang={lang}
            imageDataUrl={images[shot.id] || null}
            slideRef={{ set current(el) { exportRefs.current[shot.id] = el; }, get current() { return exportRefs.current[shot.id] || null; } }}
          />
        ))}
      </div>

      <div style={{ padding: '12px 20px', borderBottom: '1px solid #151515', display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'sticky', top: 0, background: 'rgba(6,6,6,0.92)', backdropFilter: 'blur(16px)', zIndex: 50 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ fontSize: 13, fontWeight: 700, color: '#555', letterSpacing: 2, textTransform: 'uppercase' }}>Screenshots</span>
          <div style={{ width: 1, height: 14, background: '#1a1a1a' }} />
          <div style={{ display: 'flex', gap: 1 }}>
            {LANGS.map(l => (<button key={l} onClick={() => setLang(l)} style={{ padding: '3px 9px', background: lang === l ? '#00E676' : 'transparent', color: lang === l ? '#000' : '#444', border: 'none', borderRadius: 3, cursor: 'pointer', fontWeight: 700, fontSize: 10, textTransform: 'uppercase' }}>{l}</button>))}
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 10, color: '#2a2a2a' }}>{n}/6</span>
          <button onClick={expAll} disabled={!n || exporting} style={{ padding: '7px 20px', background: !n ? '#0d0d0d' : '#00E676', color: !n ? '#2a2a2a' : '#000', border: 'none', borderRadius: 5, cursor: !n ? 'not-allowed' : 'pointer', fontWeight: 800, fontSize: 11 }}>{exporting ? '...' : 'Export All'}</button>
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, padding: '12px 8px' }}>
        {SHOTS.map(shot => (
          <div key={shot.id}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4, padding: '0 4px' }}>
              <span style={{ fontSize: 10, color: '#3a3a3a', fontWeight: 600 }}>{shot.id}. {shot.copy[lang].headline.split('\n')[0]}</span>
              <div style={{ display: 'flex', gap: 3 }}>
                {images[shot.id] && (<button onClick={() => pick(shot.id)} style={{ padding: '2px 7px', background: 'transparent', color: '#333', border: '1px solid #1a1a1a', borderRadius: 2, cursor: 'pointer', fontSize: 9 }}>↻</button>)}
                <button onClick={() => exp1(shot.id)} disabled={!images[shot.id]} style={{ padding: '2px 7px', background: images[shot.id] ? '#00E676' : '#0a0a0a', color: images[shot.id] ? '#000' : '#1a1a1a', border: 'none', borderRadius: 2, cursor: images[shot.id] ? 'pointer' : 'not-allowed', fontSize: 9, fontWeight: 700 }}>↓</button>
              </div>
            </div>
            <div onDragOver={e => e.preventDefault()} onDrop={e => drop(shot.id, e)} onClick={() => { if (!images[shot.id]) pick(shot.id); }} style={{ width: W * S, height: H * S, overflow: 'hidden', borderRadius: 6, border: images[shot.id] ? '1px solid #181818' : '1px dashed #1f1f1f', cursor: images[shot.id] ? 'default' : 'pointer' }}>
              {/* Preview only — no ref needed, just visual */}
              <div style={{ transform: `scale(${S})`, transformOrigin: 'top left' }}>
                <CompositeSlide shot={shot} lang={lang} imageDataUrl={images[shot.id] || null} />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

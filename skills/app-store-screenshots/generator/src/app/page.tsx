'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const CANVAS_W = 1320;
const CANVAS_H = 2868;
const PHONE_W = 1080;
const COPY_PAD_TOP = 56;
const COPY_PAD_X = 56;
const DEVICE_GAP = 12;
const FADE_H = 280;

// ─── Drop Zone ────────────────────────────────────────────
function DropZone({
  shotId,
  onDrop,
  hasImage,
}: {
  shotId: number;
  onDrop: (dataUrl: string) => void;
  hasImage: boolean;
}) {
  const [over, setOver] = useState(false);

  const handle = useCallback(
    (e: DragEvent) => {
      e.preventDefault();
      e.stopPropagation();
      if (e.type === 'dragover' || e.type === 'dragenter') setOver(true);
      if (e.type === 'dragleave') setOver(false);
      if (e.type === 'drop') {
        setOver(false);
        const file = e.dataTransfer.files[0];
        if (!file || !file.type.startsWith('image/')) return;
        const reader = new FileReader();
        reader.onload = () => onDrop(reader.result as string);
        reader.readAsDataURL(file);
      }
    },
    [onDrop]
  );

  const handleClick = useCallback(() => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = () => onDrop(reader.result as string);
      reader.readAsDataURL(file);
    };
    input.click();
  }, [onDrop]);

  return (
    <div
      onDragOver={handle}
      onDragEnter={handle}
      onDragLeave={handle}
      onDrop={handle}
      onClick={handleClick}
      style={{
        width: 120,
        height: 80,
        borderRadius: 8,
        border: over
          ? '2px solid #00E676'
          : hasImage
          ? '2px solid #333'
          : '2px dashed #555',
        background: over ? '#00E67615' : hasImage ? '#1a1a1a' : '#0d0d0d',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        fontSize: 11,
        color: hasImage ? '#00E676' : '#666',
        transition: 'all 0.15s',
        flexShrink: 0,
      }}
    >
      {hasImage ? '✓ Shot ' + shotId : 'Drop here'}
    </div>
  );
}

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
        background: 'linear-gradient(180deg, #0A0A0A 0%, #0D0D0D 40%, #0A1A0F 100%)',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: isJa
          ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
          : "'Inter', 'SF Pro Display', sans-serif",
      }}
    >
      {/* Glow */}
      <div
        style={{
          position: 'absolute',
          top: -200,
          left: '50%',
          transform: 'translateX(-50%)',
          width: 1000,
          height: 1000,
          background: `radial-gradient(circle, ${shot.accent}18 0%, transparent 50%)`,
          pointerEvents: 'none',
        }}
      />

      {/* Grid */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage:
            'linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px)',
          backgroundSize: '64px 64px',
          pointerEvents: 'none',
        }}
      />

      {/* Copy */}
      <div
        style={{
          paddingTop: COPY_PAD_TOP,
          paddingLeft: COPY_PAD_X,
          paddingRight: COPY_PAD_X,
          textAlign: 'center',
          position: 'relative',
          zIndex: 2,
        }}
      >
        <div
          style={{
            fontSize: isJa ? 76 : 78,
            fontWeight: 900,
            color: '#FFF',
            lineHeight: 1.12,
            letterSpacing: isJa ? 3 : -1.5,
          }}
        >
          {lines.map((l, i) => (
            <div key={i}>{l}</div>
          ))}
        </div>
        <div
          style={{
            fontSize: 24,
            fontWeight: 500,
            color: `${shot.accent}88`,
            marginTop: 10,
            letterSpacing: isJa ? 1.5 : 0.3,
          }}
        >
          {copy.sub}
        </div>
        <div
          style={{
            display: 'flex',
            gap: 10,
            justifyContent: 'center',
            marginTop: 14,
            flexWrap: 'wrap' as const,
          }}
        >
          {copy.chips.map((c, i) => (
            <span
              key={i}
              style={{
                padding: '5px 14px',
                background: `${shot.accent}0A`,
                border: `1px solid ${shot.accent}20`,
                borderRadius: 30,
                color: c.desc ? 'rgba(255,255,255,0.55)' : `${shot.accent}BB`,
                fontSize: 16,
                fontWeight: c.desc ? 500 : 700,
              }}
            >
              {c.desc ? (
                <>
                  <strong style={{ color: shot.accent, fontWeight: 900 }}>
                    {c.label}
                  </strong>{' '}
                  {c.desc}
                </>
              ) : (
                c.label
              )}
            </span>
          ))}
        </div>
      </div>

      {/* Device */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'center',
          paddingTop: DEVICE_GAP,
          position: 'relative',
          zIndex: 1,
        }}
      >
        <div style={{ width: PHONE_W, position: 'relative' }}>
          <div
            className="iphone-body"
            style={{
              boxShadow: `0 50px 100px rgba(0,0,0,0.9), 0 0 0 1px rgba(255,255,255,0.04), 0 4px 60px ${shot.accent}10, inset 0 1px 0 rgba(255,255,255,0.06)`,
            }}
          >
            <div className="btn-power" />
            <div className="btn-vol-up" />
            <div className="btn-vol-down" />
            <div className="iphone-screen">
              <div className="dynamic-island" />
              {imageDataUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={imageDataUrl}
                  alt={`Shot ${shot.id}`}
                  style={{ width: '100%', display: 'block' }}
                />
              ) : (
                <div
                  style={{
                    width: '100%',
                    aspectRatio: '1179/2556',
                    background: 'linear-gradient(180deg,#1a1a1a,#0d0d0d)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'rgba(255,255,255,0.12)',
                    fontSize: 26,
                  }}
                >
                  Drop screenshot here
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Fade */}
      <div
        style={{
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          height: FADE_H,
          background: 'linear-gradient(transparent, #0A0A0A 85%)',
          pointerEvents: 'none',
          zIndex: 3,
        }}
      />
    </div>
  );
}

// ─── Export ────────────────────────────────────────────────
function ExportBtn({
  slideRef,
  shotId,
  lang,
  disabled,
}: {
  slideRef: React.RefObject<HTMLDivElement | null>;
  shotId: number;
  lang: Lang;
  disabled: boolean;
}) {
  const [busy, setBusy] = useState(false);

  const go = useCallback(async () => {
    if (!slideRef.current) return;
    setBusy(true);
    try {
      const url = await toPng(slideRef.current, {
        width: 1320,
        height: 2868,
        pixelRatio: 1,
      });
      const a = document.createElement('a');
      a.download = `shot${shotId}_${lang}_6.9.png`;
      a.href = url;
      a.click();
    } catch (e) {
      console.error(e);
    }
    setBusy(false);
  }, [slideRef, shotId, lang]);

  return (
    <button
      onClick={go}
      disabled={busy || disabled}
      style={{
        padding: '6px 14px',
        background: busy || disabled ? '#222' : '#00E676',
        color: busy || disabled ? '#555' : '#000',
        border: 'none',
        borderRadius: 6,
        cursor: busy || disabled ? 'not-allowed' : 'pointer',
        fontWeight: 700,
        fontSize: 12,
      }}
    >
      {busy ? '...' : 'Export'}
    </button>
  );
}

// ─── Page ─────────────────────────────────────────────────
export default function Page() {
  const [lang, setLang] = useState<Lang>('ja');
  const [images, setImages] = useState<Record<number, string>>({});
  const refs = useRef<Record<number, HTMLDivElement | null>>({});
  const [exporting, setExporting] = useState(false);

  const LANGS: Lang[] = ['ja', 'en', 'zh', 'ko', 'es', 'de', 'fr'];
  const SCALE = 280 / CANVAS_W;

  const setImage = useCallback((id: number, dataUrl: string) => {
    setImages((prev) => ({ ...prev, [id]: dataUrl }));
  }, []);

  const exportAll = useCallback(async () => {
    setExporting(true);
    for (const shot of SHOTS) {
      const el = refs.current[shot.id];
      if (!el || !images[shot.id]) continue;
      try {
        const url = await toPng(el, { width: 1320, height: 2868, pixelRatio: 1 });
        const a = document.createElement('a');
        a.download = `shot${shot.id}_${lang}_6.9.png`;
        a.href = url;
        a.click();
        await new Promise((r) => setTimeout(r, 600));
      } catch (e) {
        console.error(e);
      }
    }
    setExporting(false);
  }, [images, lang]);

  const loaded = Object.keys(images).length;

  return (
    <div style={{ background: '#0a0a0a', minHeight: '100vh', color: '#fff' }}>
      {/* Header */}
      <div
        style={{
          padding: '24px 32px',
          borderBottom: '1px solid #222',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          position: 'sticky',
          top: 0,
          background: '#0a0a0a',
          zIndex: 50,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          <h1 style={{ fontSize: 18, fontWeight: 800, margin: 0 }}>
            MuscleMap Screenshots
          </h1>
          <div style={{ display: 'flex', gap: 4 }}>
            {LANGS.map((l) => (
              <button
                key={l}
                onClick={() => setLang(l)}
                style={{
                  padding: '4px 10px',
                  background: lang === l ? '#00E676' : '#1a1a1a',
                  color: lang === l ? '#000' : '#888',
                  border: 'none',
                  borderRadius: 4,
                  cursor: 'pointer',
                  fontWeight: 700,
                  fontSize: 11,
                  textTransform: 'uppercase',
                }}
              >
                {l}
              </button>
            ))}
          </div>
          <span style={{ fontSize: 12, color: '#555' }}>
            {loaded}/6 loaded
          </span>
        </div>

        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          {/* Drop zones row */}
          <div style={{ display: 'flex', gap: 6 }}>
            {SHOTS.map((s) => (
              <DropZone
                key={s.id}
                shotId={s.id}
                hasImage={!!images[s.id]}
                onDrop={(url) => setImage(s.id, url)}
              />
            ))}
          </div>
          <button
            onClick={exportAll}
            disabled={loaded === 0 || exporting}
            style={{
              padding: '10px 20px',
              background: loaded === 0 || exporting ? '#222' : '#00E676',
              color: loaded === 0 || exporting ? '#555' : '#000',
              border: 'none',
              borderRadius: 8,
              cursor: loaded === 0 || exporting ? 'not-allowed' : 'pointer',
              fontWeight: 800,
              fontSize: 13,
            }}
          >
            {exporting ? 'Exporting...' : `Export All (${loaded})`}
          </button>
        </div>
      </div>

      {/* Shots Grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(6, 1fr)',
          gap: 16,
          padding: '24px 16px',
        }}
      >
        {SHOTS.map((shot) => (
          <div key={shot.id}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 8,
              }}
            >
              <span style={{ fontSize: 11, color: '#666' }}>
                {shot.id}. {shot.copy[lang].headline.split('\n')[0]}
              </span>
              <ExportBtn
                slideRef={{ current: refs.current[shot.id] || null }}
                shotId={shot.id}
                lang={lang}
                disabled={!images[shot.id]}
              />
            </div>

            {/* Preview */}
            <div
              onDragOver={(e) => { e.preventDefault(); e.stopPropagation(); }}
              onDrop={(e) => {
                e.preventDefault();
                e.stopPropagation();
                const file = e.dataTransfer.files[0];
                if (!file || !file.type.startsWith('image/')) return;
                const reader = new FileReader();
                reader.onload = () => setImage(shot.id, reader.result as string);
                reader.readAsDataURL(file);
              }}
              style={{
                width: CANVAS_W * SCALE,
                height: CANVAS_H * SCALE,
                overflow: 'hidden',
                borderRadius: 8,
                border: images[shot.id] ? '1px solid #333' : '1px dashed #444',
                cursor: 'pointer',
              }}
              onClick={() => {
                if (images[shot.id]) return;
                const input = document.createElement('input');
                input.type = 'file';
                input.accept = 'image/*';
                input.onchange = (ev) => {
                  const file = (ev.target as HTMLInputElement).files?.[0];
                  if (!file) return;
                  const reader = new FileReader();
                  reader.onload = () => setImage(shot.id, reader.result as string);
                  reader.readAsDataURL(file);
                };
                input.click();
              }}
            >
              <div
                style={{
                  transform: `scale(${SCALE})`,
                  transformOrigin: 'top left',
                }}
              >
                <CompositeSlide
                  shot={shot}
                  lang={lang}
                  imageDataUrl={images[shot.id] || null}
                  slideRef={{
                    set current(el: HTMLDivElement | null) {
                      refs.current[shot.id] = el;
                    },
                    get current() {
                      return refs.current[shot.id] || null;
                    },
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

'use client';

import { DragEvent, Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const SIZES = [
  { label: '6.5" alt', w: 1242, h: 2688 },
] as const;

const W = 1242;
const H = 2688;
const PHONE_W = 980;
const PHONE_TOP = 468;
const PHONE_X = (W - PHONE_W) / 2;
const FRAME_BEZEL = 7;
const FRAME_R = 58;
const SCREEN_R = 52;

const LANGS: Lang[] = ['ja', 'en', 'zh', 'ko', 'es', 'de', 'fr'];
const LOCALIZED_SCREENSHOT_LANGS = new Set<Lang>(['ja', 'en']);
const DEFAULT_PREVIEW_WIDTH = 278;
const MIN_PREVIEW_WIDTH = 210;
const MAX_PREVIEW_WIDTH = 340;
const CUSTOM_IMAGE_DB = 'musclemap-screenshot-generator';
const CUSTOM_IMAGE_STORE = 'custom-images';

type StoredImageRecord = {
  id: number;
  dataUrl: string;
};

function requestToPromise<T>(request: IDBRequest<T>) {
  return new Promise<T>((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function transactionDone(transaction: IDBTransaction) {
  return new Promise<void>((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  });
}

function openCustomImageDb() {
  return new Promise<IDBDatabase>((resolve, reject) => {
    const request = indexedDB.open(CUSTOM_IMAGE_DB, 1);

    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(CUSTOM_IMAGE_STORE)) {
        db.createObjectStore(CUSTOM_IMAGE_STORE, { keyPath: 'id' });
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function readStoredImages() {
  if (typeof indexedDB === 'undefined') return {};

  const db = await openCustomImageDb();
  try {
    const transaction = db.transaction(CUSTOM_IMAGE_STORE, 'readonly');
    const records = await requestToPromise<StoredImageRecord[]>(
      transaction.objectStore(CUSTOM_IMAGE_STORE).getAll(),
    );

    return records.reduce<Record<number, string>>((acc, record) => {
      acc[record.id] = record.dataUrl;
      return acc;
    }, {});
  } finally {
    db.close();
  }
}

async function writeStoredImages(images: Record<number, string>) {
  if (typeof indexedDB === 'undefined') return;

  const db = await openCustomImageDb();
  try {
    const transaction = db.transaction(CUSTOM_IMAGE_STORE, 'readwrite');
    const store = transaction.objectStore(CUSTOM_IMAGE_STORE);
    store.clear();
    Object.entries(images).forEach(([id, dataUrl]) => {
      store.put({ id: Number(id), dataUrl });
    });
    await transactionDone(transaction);
  } finally {
    db.close();
  }
}

function screenshotPath(lang: Lang, file: string) {
  if (LOCALIZED_SCREENSHOT_LANGS.has(lang)) {
    return `/screenshots/${lang}/${file}`;
  }

  return `/screenshots/${file}`;
}

function localFont(lang: Lang) {
  return lang === 'ja' || lang === 'zh' || lang === 'ko'
    ? "'Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', sans-serif"
    : "'Inter', 'SF Pro Display', -apple-system, BlinkMacSystemFont, sans-serif";
}

function ScreenImage({
  dataUrl,
  file,
  lang,
}: {
  dataUrl: string | null;
  file: string;
  lang: Lang;
}) {
  return (
    <div
      style={{
        width: '100%',
        aspectRatio: '1179/2556',
        backgroundColor: '#070807',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {dataUrl ? (
        <img
          src={dataUrl}
          alt=""
          style={{
            display: 'block',
            width: '100%',
            height: '100%',
            objectFit: 'cover',
          }}
        />
      ) : (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: `url(${screenshotPath(lang, file)})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backgroundRepeat: 'no-repeat',
          }}
        />
      )}
    </div>
  );
}

function PhoneFrame({
  shot,
  imageDataUrl,
  lang,
}: {
  shot: ShotDef;
  imageDataUrl: string | null;
  lang: Lang;
}) {
  const a = shot.accent;
  return (
    <div style={{ position: 'relative', width: PHONE_W }}>
      <div
        style={{
          position: 'absolute',
          left: -62,
          right: -62,
          bottom: -72,
          height: 220,
          background:
            'radial-gradient(ellipse, rgba(4, 14, 10, 0.38), rgba(4, 14, 10, 0.16) 42%, transparent 74%)',
          filter: 'blur(24px)',
        }}
      />
      <div
        style={{
          position: 'relative',
          borderRadius: FRAME_R,
          padding: FRAME_BEZEL,
          background:
            'linear-gradient(145deg, #6E7175 0%, #242628 12%, #050606 48%, #1F2224 84%, #7D8084 100%)',
          boxShadow:
            '0 78px 150px rgba(4, 12, 9, 0.30), 0 30px 62px rgba(4, 12, 9, 0.26), 0 0 0 0.5px rgba(255,255,255,0.30), inset 0 1px 0 rgba(255,255,255,0.26), inset 0 -1px 0 rgba(0,0,0,0.55)',
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 52,
            right: 52,
            height: 1,
            background:
              'linear-gradient(90deg, transparent, rgba(255,255,255,0.32), transparent)',
          }}
        />
        <div
          style={{
            position: 'absolute',
            top: 350,
            right: -3,
            width: 4,
            height: 88,
            borderRadius: '0 2px 2px 0',
            background: 'linear-gradient(180deg, #696B6E, #2C2E31, #67696C)',
          }}
        />
        <div
          style={{
            position: 'absolute',
            top: 250,
            left: -3,
            width: 4,
            height: 48,
            borderRadius: '2px 0 0 2px',
            background: 'linear-gradient(180deg, #696B6E, #2C2E31, #67696C)',
          }}
        />
        <div
          style={{
            position: 'absolute',
            top: 330,
            left: -3,
            width: 4,
            height: 58,
            borderRadius: '2px 0 0 2px',
            background: 'linear-gradient(180deg, #696B6E, #2C2E31, #67696C)',
          }}
        />
        <div
          style={{
            borderRadius: SCREEN_R,
            overflow: 'hidden',
            position: 'relative',
            background: '#000',
          }}
        >
          <div
            style={{
              position: 'absolute',
              inset: 0,
              borderRadius: SCREEN_R,
              boxShadow: `inset 0 0 0 0.5px rgba(255,255,255,0.10), inset 0 0 70px ${a}06`,
              pointerEvents: 'none',
              zIndex: 10,
            }}
          />
          <ScreenImage dataUrl={imageDataUrl} file={shot.file} lang={lang} />
        </div>
      </div>
    </div>
  );
}

export default function Page() {
  return (
    <Suspense
      fallback={
        <div
          style={{
            minHeight: '100vh',
            display: 'grid',
            placeItems: 'center',
            background: '#ECEFEA',
            color: '#526058',
            fontSize: 13,
            fontWeight: 900,
          }}
        >
          Loading screenshots...
        </div>
      }
    >
      <ScreenshotGenerator />
    </Suspense>
  );
}

function SlideBackground({ shot }: { shot: ShotDef }) {
  const accent = shot.accent;
  const palettes = {
    green: {
      base: 'linear-gradient(180deg, #FBFCFA 0%, #F0F8F2 35%, #DDEDE4 100%)',
      aura: `${accent}26`,
      wash: 'rgba(7,28,18,0.08)',
      shadow: 'rgba(3, 28, 16, 0.14)',
    },
    mint: {
      base: 'linear-gradient(180deg, #FBFCFA 0%, #F2F9F5 36%, #E4F0E9 100%)',
      aura: `${accent}20`,
      wash: 'rgba(7,24,16,0.06)',
      shadow: 'rgba(3, 28, 16, 0.11)',
    },
    blue: {
      base: 'linear-gradient(180deg, #FBFCFA 0%, #F1F8FA 34%, #DCECF1 100%)',
      aura: `${accent}24`,
      wash: 'rgba(2,31,44,0.075)',
      shadow: 'rgba(0, 34, 54, 0.14)',
    },
    dark: {
      base: 'linear-gradient(180deg, #FAFCFA 0%, #EFF8F2 32%, #D5E8DD 100%)',
      aura: `${accent}2B`,
      wash: 'rgba(3,24,14,0.10)',
      shadow: 'rgba(0, 24, 13, 0.18)',
    },
  } as const;
  const palette = palettes[shot.tone];
  const motions = [
    { x: -240, y: 1030, rotate: -13, width: 1160, height: 410, opacity: 0.34 },
    { x: 370, y: 1140, rotate: 14, width: 1120, height: 390, opacity: 0.42 },
    { x: -170, y: 1260, rotate: -8, width: 1040, height: 330, opacity: 0.28 },
    { x: 430, y: 1000, rotate: 12, width: 1080, height: 410, opacity: 0.4 },
    { x: -240, y: 1180, rotate: -12, width: 1180, height: 360, opacity: 0.32 },
    { x: 300, y: 1220, rotate: 11, width: 1120, height: 370, opacity: 0.34 },
  ];
  const motion = motions[(shot.id - 1) % motions.length];

  return (
    <>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: palette.base,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 0,
          height: 1080,
          background: `linear-gradient(180deg, ${palette.aura} 0%, ${accent}12 36%, transparent 78%)`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: motion.x,
          top: motion.y,
          width: motion.width,
          height: motion.height,
          borderRadius: 999,
          background:
            `linear-gradient(90deg, ${accent}00 0%, ${accent}34 35%, rgba(255,255,255,0.42) 58%, ${accent}18 100%)`,
          transform: `rotate(${motion.rotate}deg)`,
          opacity: motion.opacity,
          filter: 'blur(2px)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: shot.id === 4 ? -120 : -240,
          top: shot.id === 4 ? 430 : 960,
          width: 1660,
          height: shot.id === 4 ? 120 : 84,
          borderRadius: 999,
          background:
            'linear-gradient(90deg, transparent, rgba(255,255,255,0.72), transparent)',
          transform: `rotate(${shot.id % 2 === 0 ? -44 : -36}deg)`,
          opacity: shot.id === 1 || shot.id === 4 ? 0.62 : 0.38,
          filter: 'blur(1px)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          right: -460,
          top: shot.id === 2 ? 980 : 1220,
          width: 1420,
          height: 58,
          borderRadius: 999,
          background:
            `linear-gradient(90deg, transparent, ${accent}28, rgba(255,255,255,0.52), transparent)`,
          transform: `rotate(${shot.id % 2 === 0 ? -28 : -22}deg)`,
          opacity: 0.44,
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: shot.id % 2 === 0 ? 330 : 440,
          left: shot.id % 2 === 0 ? -300 : 700,
          width: 940,
          height: 940,
          borderRadius: '50%',
          background: `radial-gradient(circle, ${accent}24 0%, ${accent}10 38%, transparent 70%)`,
          filter: 'blur(14px)',
          opacity: shot.tone === 'dark' ? 1 : 0.84,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 560,
          height: 1700,
          background:
            `linear-gradient(180deg, transparent 0%, ${palette.wash} 30%, transparent 100%)`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: shot.id % 2 === 0 ? 0 : 'auto',
          right: shot.id % 2 === 0 ? 'auto' : 0,
          top: 900,
          width: 390,
          height: 1260,
          background:
            `linear-gradient(${shot.id % 2 === 0 ? 90 : 270}deg, ${palette.shadow}, transparent)`,
          opacity: 0.34,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: 720,
          background:
            `linear-gradient(180deg, transparent 0%, ${palette.wash} 100%)`,
        }}
      />
    </>
  );
}

function SlideCopy({ shot, lang }: { shot: ShotDef; lang: Lang }) {
  const copy = shot.copy[lang];
  const isCjk = lang === 'ja' || lang === 'zh' || lang === 'ko';
  const lines = getHeadlineLines(shot, lang, copy.headline);
  const headlineSize = isCjk ? 94 : 92;
  const headlineBoostSize = isCjk ? 116 : 112;
  const headlineTracking = isCjk ? 0 : -1;
  const lineBoxHeight = lang === 'ja' ? 122 : isCjk ? 106 : 100;
  const subMarginTop = lang === 'ja' ? 42 : 18;
  const copyTop = lang === 'ja' ? 24 : 86;

  return (
    <div
      style={{
        position: 'absolute',
        left: 88,
        right: 88,
        top: copyTop,
        zIndex: 2,
        textAlign: 'center',
      }}
    >
      <div
        style={{
          color: '#111714',
          fontWeight: 950,
          lineHeight: 1,
          letterSpacing: headlineTracking,
          fontFeatureSettings: "'palt' 1",
          textWrap: 'balance' as const,
        }}
      >
        {lines.map((line, lineIndex) => (
          <div
            key={`${shot.id}-${lineIndex}`}
            style={{
              whiteSpace: 'nowrap',
              height: lineBoxHeight,
            }}
          >
            {line.map((segment, segmentIndex) => (
              <span
                key={`${segment.text}-${segmentIndex}`}
                style={{
                  display: 'inline-block',
                  fontSize: segment.strong ? headlineBoostSize : headlineSize,
                  lineHeight: 1,
                }}
              >
                {segment.text}
              </span>
            ))}
          </div>
        ))}
      </div>

      <div
        style={{
          margin: `${subMarginTop}px auto 0`,
          maxWidth: 1080,
          color: '#34413A',
          fontSize: lang === 'ja' ? 50 : isCjk ? 54 : 50,
          fontWeight: 850,
          lineHeight: 1.16,
          letterSpacing: 0,
          textShadow: '0 1px 0 rgba(255,255,255,0.68)',
          textWrap: 'balance' as const,
        }}
      >
        {copy.sub}
      </div>
    </div>
  );
}

function getHeadlineLines(shot: ShotDef, lang: Lang, headline: string) {
  if (lang !== 'ja') {
    return headline
      .split('\n')
      .map((line, index) => [{ text: line, strong: index === 0 }]);
  }

  const ja: Record<number, { text: string; strong: boolean }[][]> = {
    1: [
      [{ text: '今日の狙い', strong: true }],
      [{ text: '一目でわかる。', strong: false }],
    ],
    2: [
      [
        { text: '記録', strong: true },
        { text: 'は一瞬。', strong: false },
      ],
      [
        { text: '回復', strong: true },
        { text: 'まで自動。', strong: false },
      ],
    ],
    3: [
      [
        { text: '開けばすぐ、', strong: true },
      ],
      [
        { text: 'やることが決まる。', strong: false },
      ],
    ],
    4: [
      [
        { text: '迷わず選んで、', strong: true },
      ],
      [
        { text: 'すぐ開始。', strong: false },
      ],
    ],
    5: [
      [
        { text: '92種目。', strong: true },
      ],
      [
        { text: 'フォームも確認。', strong: false },
      ],
    ],
    6: [
      [
        { text: '部位ごとの変化', strong: true },
      ],
      [
        { text: '深く追える。', strong: false },
      ],
    ],
    7: [
      [{ text: '迷ったフォームは、', strong: true }],
      [{ text: 'すぐ動画。', strong: false }],
    ],
    8: [
      [{ text: '成果を一枚で、', strong: true }],
      [{ text: 'きれいに共有。', strong: false }],
    ],
    9: [
      [{ text: '鍛えた部位が、', strong: true }],
      [{ text: 'ひと目で残る。', strong: false }],
    ],
  };

  return ja[shot.id] || headline
    .split('\n')
    .map((line) => [{ text: line, strong: false }]);
}

function normalizeLang(requested: string | null): Lang {
  return requested && LANGS.includes(requested as Lang) ? (requested as Lang) : 'ja';
}

function CompositeSlide({
  shot,
  lang,
  imageDataUrl,
  slideRef,
}: {
  shot: ShotDef;
  lang: Lang;
  imageDataUrl: string | null;
  slideRef?: (element: HTMLDivElement | null) => void;
}) {
  const jaPhoneScale = lang === 'ja' ? 1.045 : 1;
  const jaPhoneOffsetY = lang === 'ja' ? -58 : 0;

  return (
    <div
      ref={slideRef}
      style={{
        width: W,
        height: H,
        position: 'relative',
        overflow: 'hidden',
        fontFamily: localFont(lang),
      }}
    >
      <SlideBackground shot={shot} />
      <SlideCopy shot={shot} lang={lang} />
      <div
        style={{
          position: 'absolute',
          top: PHONE_TOP + shot.phoneOffsetY + jaPhoneOffsetY,
          left: PHONE_X,
          width: PHONE_W,
          zIndex: 3,
          transform: `scale(${shot.phoneScale * jaPhoneScale})`,
          transformOrigin: 'top center',
        }}
      >
        <PhoneFrame shot={shot} imageDataUrl={imageDataUrl} lang={lang} />
      </div>
    </div>
  );
}

function ScreenshotGenerator() {
  const searchParams = useSearchParams();
  const lang = normalizeLang(searchParams.get('lang'));
  const previewModeFromUrl = searchParams.get('mode') !== 'edit';
  const [images, setImages] = useState<Record<number, string>>({});
  const [imagesLoaded, setImagesLoaded] = useState(false);
  const slideRefs = useRef<Record<number, HTMLDivElement | null>>({});
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const fileStartIdRef = useRef(1);
  const [exporting, setExporting] = useState(false);
  const [previewModeOverride, setPreviewModeOverride] = useState<boolean | null>(null);
  const previewMode = previewModeOverride ?? previewModeFromUrl;
  const [draggingId, setDraggingId] = useState<number | null>(null);
  const [previewWidth, setPreviewWidth] = useState(DEFAULT_PREVIEW_WIDTH);
  const S = previewWidth / W;

  const selectedSize = SIZES[0];
  const imageCount = Object.keys(images).length;
  const isSafari =
    typeof navigator !== 'undefined' &&
    /^((?!chrome|android).)*safari/i.test(navigator.userAgent);

  useEffect(() => {
    let cancelled = false;

    readStoredImages()
      .then((storedImages) => {
        if (!cancelled) {
          setImages(storedImages);
        }
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) {
          setImagesLoaded(true);
        }
      });

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!imagesLoaded) return;
    void writeStoredImages(images).catch(() => {});
  }, [images, imagesLoaded]);

  const readImageFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/') && !/\.(png|jpe?g|webp)$/i.test(file.name)) {
      return Promise.resolve<string | null>(null);
    }

    return new Promise<string | null>((resolve) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = () => resolve(null);
      reader.readAsDataURL(file);
    });
  }, []);

  const loadFiles = useCallback(
    async (startId: number, files: FileList | File[]) => {
      const imageFiles = Array.from(files).filter(
        (file) => file.type.startsWith('image/') || /\.(png|jpe?g|webp)$/i.test(file.name),
      );
      if (!imageFiles.length) return;

      const nextImages: Record<number, string> = {};
      for (let index = 0; index < imageFiles.length; index += 1) {
        const id = startId + index;
        if (id > SHOTS.length) break;
        const dataUrl = await readImageFile(imageFiles[index]);
        if (dataUrl) nextImages[id] = dataUrl;
      }

      setImages((prev) => {
        const merged = { ...prev, ...nextImages };
        void writeStoredImages(merged).catch(() => {});
        return merged;
      });
      setPreviewModeOverride(false);
    },
    [readImageFile],
  );

  const pick = useCallback(
    (id: number) => {
      const input = fileInputRef.current;
      if (!input) return;
      fileStartIdRef.current = id;
      input.value = '';
      input.click();
    },
    [],
  );

  const drop = useCallback(
    (id: number, event: DragEvent) => {
      event.preventDefault();
      setDraggingId(null);
      if (!event.dataTransfer.files.length) return;
      void loadFiles(id, event.dataTransfer.files);
    },
    [loadFiles],
  );

  const exportOne = useCallback(
    async (id: number) => {
      const el = slideRefs.current[id];
      if (!el) return;
      const size = selectedSize;
      const opts = {
        width: size.w,
        height: size.h,
        pixelRatio: 1,
        cacheBust: true,
        backgroundColor: '#FBFCF9',
        style: {
          transform: `scale(${size.w / W}, ${size.h / H})`,
          transformOrigin: 'top left',
        },
      };
      await toPng(el, opts).catch(() => {});
      const dataUrl = await toPng(el, opts);
      Object.assign(document.createElement('a'), {
        download: `musclemap_shot${id}_${lang}_${size.w}x${size.h}.png`,
        href: dataUrl,
      }).click();
    },
    [lang, selectedSize],
  );

  const exportAll = useCallback(async () => {
    setExporting(true);
    for (const shot of SHOTS) {
      await exportOne(shot.id);
      await new Promise((resolve) => setTimeout(resolve, 260));
    }
    setExporting(false);
  }, [exportOne]);

  const gridStyle = useMemo(
    () => ({
      display: 'grid',
      gridTemplateColumns: `repeat(${SHOTS.length}, ${previewWidth}px)`,
      gap: 20,
      padding: '18px 30px 42px',
      overflowX: 'auto' as const,
      alignItems: 'start',
      scrollSnapType: 'x proximity' as const,
      WebkitOverflowScrolling: 'touch' as const,
    }),
    [previewWidth],
  );

  return (
    <div
      style={{
        background: '#ECEFEA',
        minHeight: '100vh',
        color: '#111714',
      }}
    >
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        onChange={(event) => {
          const files = event.currentTarget.files;
          if (!files?.length) return;
          void loadFiles(fileStartIdRef.current, files);
        }}
        style={{ display: 'none' }}
      />

      {isSafari && (
        <div
          style={{
            padding: '10px 20px',
            background: '#FFF4DB',
            color: '#7A5200',
            fontSize: 13,
            textAlign: 'center',
            fontWeight: 700,
          }}
        >
          Safari では書き出しが失敗する場合があります。Chrome で開いてください。
        </div>
      )}

      <div
        style={{
          padding: '12px 20px',
          borderBottom: '1px solid rgba(17, 23, 20, 0.08)',
          display: 'flex',
          alignItems: 'center',
          gap: 16,
          flexWrap: 'wrap',
          position: 'sticky',
          top: 0,
          background: 'rgba(251, 252, 249, 0.94)',
          backdropFilter: 'blur(16px)',
          zIndex: 50,
        }}
      >
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 2,
            minWidth: 190,
          }}
        >
          <div
            style={{
              fontSize: 13,
              fontWeight: 950,
              letterSpacing: 1.4,
              textTransform: 'uppercase',
            }}
          >
            MuscleMap Screenshots
          </div>
          <div style={{ color: '#68756E', fontSize: 11, fontWeight: 800 }}>
            {SHOTS.length} shots · {selectedSize.w}x{selectedSize.h}
          </div>
        </div>

        <div
          aria-label="Language"
          style={{
            display: 'flex',
            gap: 4,
            padding: 3,
            border: '1px solid rgba(17, 23, 20, 0.08)',
            borderRadius: 999,
            background: '#FFFFFF',
          }}
        >
          {LANGS.map((item) => (
            <a
              key={item}
              href={`?v=aligned-copy&lang=${item}`}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                minWidth: 36,
                padding: '7px 10px',
                background: lang === item ? '#111714' : 'transparent',
                color: lang === item ? '#FFFFFF' : '#526058',
                borderRadius: 999,
                cursor: 'pointer',
                fontWeight: 950,
                fontSize: 11,
                lineHeight: 1,
                textDecoration: 'none',
                textTransform: 'uppercase',
              }}
            >
              {item}
            </a>
          ))}
        </div>

        <label
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: '7px 12px',
            background: '#FFFFFF',
            border: '1px solid rgba(17, 23, 20, 0.08)',
            borderRadius: 999,
            color: '#526058',
            fontSize: 11,
            fontWeight: 900,
            whiteSpace: 'nowrap',
          }}
        >
          Preview
          <input
            type="range"
            min={MIN_PREVIEW_WIDTH}
            max={MAX_PREVIEW_WIDTH}
            value={previewWidth}
            onChange={(event) => setPreviewWidth(Number(event.target.value))}
            style={{
              width: 112,
              accentColor: '#00C77B',
              cursor: 'pointer',
            }}
          />
          <span style={{ color: '#111714', minWidth: 44, textAlign: 'right' }}>
            {previewWidth}px
          </span>
        </label>

        <a
          href={`?v=aligned-copy&lang=${lang}&mode=${previewMode ? 'edit' : 'preview'}`}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '9px 15px',
            background: previewMode ? '#111714' : '#FFFFFF',
            color: previewMode ? '#FFFFFF' : '#526058',
            border: '1px solid rgba(17, 23, 20, 0.08)',
            borderRadius: 999,
            cursor: 'pointer',
            fontWeight: 950,
            fontSize: 11,
            lineHeight: 1,
            textDecoration: 'none',
          }}
        >
          {previewMode ? 'Edit Screens' : 'Preview'}
        </a>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            marginLeft: 'auto',
          }}
        >
          <span style={{ fontSize: 12, color: '#68756E', fontWeight: 850 }}>
            {imageCount}/{SHOTS.length} custom
          </span>
          <button
            type="button"
            onClick={exportAll}
            disabled={exporting}
            style={{
              padding: '10px 22px',
              background: exporting ? '#CAD2CC' : '#111714',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: 999,
              cursor: exporting ? 'wait' : 'pointer',
              fontWeight: 950,
              fontSize: 12,
              boxShadow: exporting ? 'none' : '0 10px 24px rgba(17,23,20,0.14)',
            }}
          >
            {exporting ? 'Exporting...' : `Export All`}
          </button>
        </div>
      </div>

      <div style={gridStyle}>
        {SHOTS.map((shot) => (
          <div key={shot.id} style={{ width: previewWidth, scrollSnapAlign: 'start' }}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                gap: 8,
                minHeight: 30,
                marginBottom: 8,
                padding: '0 3px',
              }}
            >
              <span
                title={shot.copy[lang].headline.replace('\n', ' ')}
                style={{
                  fontSize: 12,
                  color: '#526058',
                  fontWeight: 900,
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  display: 'block',
                  minWidth: 0,
                }}
              >
                {String(shot.id).padStart(2, '0')} · {shot.nav}
              </span>
              {previewMode ? (
                <span
                  style={{
                    flex: '0 0 auto',
                    padding: '4px 8px',
                    borderRadius: 999,
                    background: '#FFFFFF',
                    color: '#68756E',
                    border: '1px solid rgba(17, 23, 20, 0.08)',
                    fontSize: 10,
                    fontWeight: 950,
                    textTransform: 'uppercase',
                  }}
                >
                  {lang}
                </span>
              ) : (
                <div style={{ display: 'flex', gap: 5, flex: '0 0 auto' }}>
                  <button
                    type="button"
                    onClick={() => pick(shot.id)}
                    style={{
                      padding: '5px 9px',
                      background: '#FFFFFF',
                      color: '#526058',
                      border: '1px solid rgba(17, 23, 20, 0.08)',
                      borderRadius: 999,
                      cursor: 'pointer',
                      fontSize: 10,
                      fontWeight: 900,
                    }}
                  >
                    Replace
                  </button>
                  <button
                    type="button"
                    onClick={() => exportOne(shot.id)}
                    style={{
                      padding: '5px 9px',
                      background: '#00C77B',
                      color: '#062018',
                      border: 'none',
                      borderRadius: 999,
                      cursor: 'pointer',
                      fontSize: 10,
                      fontWeight: 950,
                    }}
                  >
                    Export
                  </button>
                </div>
              )}
            </div>

            <div
              onDragOver={(event) => event.preventDefault()}
              onDragEnter={(event) => {
                event.preventDefault();
                setDraggingId(shot.id);
              }}
              onDragLeave={() => setDraggingId((value) => (value === shot.id ? null : value))}
              onDrop={(event) => drop(shot.id, event)}
              onClick={() => {
                if (!previewMode) pick(shot.id);
              }}
              style={{
                width: previewWidth,
                height: H * S,
                overflow: 'hidden',
                borderRadius: 12,
                border: images[shot.id]
                  ? '1px solid rgba(0, 199, 123, 0.42)'
                  : '1px solid rgba(17, 23, 20, 0.08)',
                background: '#FBFCF9',
                boxShadow: '0 24px 58px rgba(17, 23, 20, 0.11)',
                cursor: previewMode ? 'default' : 'pointer',
                position: 'relative',
              }}
            >
              <div style={{ transform: `scale(${S})`, transformOrigin: 'top left' }}>
                <CompositeSlide
                  shot={shot}
                  lang={lang}
                  imageDataUrl={images[shot.id] || null}
                  slideRef={(element) => {
                    slideRefs.current[shot.id] = element;
                  }}
                />
              </div>
              {(!previewMode || draggingId === shot.id || images[shot.id]) && (
                <div
                  style={{
                    position: 'absolute',
                    inset: 0,
                    borderRadius: 12,
                    border: draggingId === shot.id
                      ? '2px solid rgba(0, 199, 123, 0.95)'
                      : '2px solid transparent',
                    background: draggingId === shot.id
                      ? 'rgba(0, 199, 123, 0.12)'
                      : 'transparent',
                    pointerEvents: 'none',
                  }}
                >
                  {!previewMode && (
                    <div
                      style={{
                        position: 'absolute',
                        left: 10,
                        right: 10,
                        bottom: 10,
                        padding: '8px 10px',
                        borderRadius: 999,
                        background: images[shot.id]
                          ? 'rgba(0, 199, 123, 0.90)'
                          : 'rgba(17, 23, 20, 0.86)',
                        color: images[shot.id] ? '#062018' : '#FFFFFF',
                        fontSize: 10,
                        fontWeight: 950,
                        textAlign: 'center',
                        boxShadow: '0 8px 22px rgba(0,0,0,0.18)',
                      }}
                    >
                      {images[shot.id]
                        ? 'Custom image set'
                        : 'Drop screenshot here / click to choose'}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

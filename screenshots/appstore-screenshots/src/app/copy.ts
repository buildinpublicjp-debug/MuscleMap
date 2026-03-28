// MuscleMap App Store Screenshot Copy — 7 Languages
// Each slide: headline (max 2 lines), sub (1 line), accent color, chips

export type Locale = 'ja' | 'en' | 'de' | 'fr' | 'es' | 'pt' | 'ko';

export interface SlideCopy {
  headline: string;
  sub: string;
  chips: { label: string; desc?: string }[];
}

export interface SlideDefinition {
  id: number;
  accent: string;
  screenFile: string;
  nav: string; // CC向け: どの画面をキャプチャするか
  copy: Record<Locale, SlideCopy>;
}

export const SLIDES: SlideDefinition[] = [
  {
    id: 1,
    accent: '#00FFB3',
    screenFile: 'shot1_screen.png',
    nav: 'ホーム画面（回復マップ前面、色が付いた状態）',
    copy: {
      ja: {
        headline: '昨日の筋トレ、\n今どこに残ってる？',
        sub: '21部位の回復をリアルタイム表示',
        chips: [
          { label: '21', desc: '部位' },
          { label: '92', desc: '種目' },
          { label: 'EMG', desc: 'ベース' },
        ],
      },
      en: {
        headline: 'Your muscles\nremember yesterday.',
        sub: 'Real-time recovery across 21 muscle groups',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: '92', desc: 'exercises' },
          { label: 'EMG', desc: 'based' },
        ],
      },
      de: {
        headline: 'Deine Muskeln\nerinnern sich.',
        sub: 'Echtzeit-Erholung für 21 Muskelgruppen',
        chips: [
          { label: '21', desc: 'Muskeln' },
          { label: '92', desc: 'Übungen' },
        ],
      },
      fr: {
        headline: 'Vos muscles\nse souviennent.',
        sub: 'Récupération en temps réel de 21 groupes',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: '92', desc: 'exercices' },
        ],
      },
      es: {
        headline: 'Tus músculos\nrecuerdan ayer.',
        sub: 'Recuperación en tiempo real de 21 grupos',
        chips: [
          { label: '21', desc: 'músculos' },
          { label: '92', desc: 'ejercicios' },
        ],
      },
      pt: {
        headline: 'Seus músculos\nlembram de ontem.',
        sub: 'Recuperação em tempo real de 21 grupos',
        chips: [
          { label: '21', desc: 'músculos' },
          { label: '92', desc: 'exercícios' },
        ],
      },
      ko: {
        headline: '어제 운동한 근육,\n지금 어디에 남아있을까?',
        sub: '21개 부위 실시간 회복 추적',
        chips: [
          { label: '21', desc: '부위' },
          { label: '92', desc: '종목' },
        ],
      },
    },
  },
  {
    id: 2,
    accent: '#00D4FF',
    screenFile: 'shot2_screen.png',
    nav: '種目ライブラリ（2列GIFグリッド表示）',
    copy: {
      ja: {
        headline: '見て覚える、\n92種目',
        sub: '全種目アニメーションGIF付き',
        chips: [
          { label: '92', desc: '種目' },
          { label: 'GIF', desc: '対応' },
        ],
      },
      en: {
        headline: 'See the motion,\nnot just the name.',
        sub: 'Animated GIFs for all 92 exercises',
        chips: [
          { label: '92', desc: 'exercises' },
          { label: 'GIF', desc: 'powered' },
        ],
      },
      de: {
        headline: 'Sieh die Bewegung,\nnicht nur den Namen.',
        sub: 'Animierte GIFs für alle 92 Übungen',
        chips: [
          { label: '92', desc: 'Übungen' },
          { label: 'GIF', desc: 'animiert' },
        ],
      },
      fr: {
        headline: 'Voir le mouvement,\npas juste le nom.',
        sub: 'GIFs animés pour les 92 exercices',
        chips: [
          { label: '92', desc: 'exercices' },
          { label: 'GIF', desc: 'animés' },
        ],
      },
      es: {
        headline: 'Ver el movimiento,\nno solo el nombre.',
        sub: 'GIFs animados para los 92 ejercicios',
        chips: [
          { label: '92', desc: 'ejercicios' },
          { label: 'GIF', desc: 'animados' },
        ],
      },
      pt: {
        headline: 'Veja o movimento,\nnão só o nome.',
        sub: 'GIFs animados para todos os 92 exercícios',
        chips: [
          { label: '92', desc: 'exercícios' },
          { label: 'GIF', desc: 'animados' },
        ],
      },
      ko: {
        headline: '이름이 아닌\n동작으로 배우세요.',
        sub: '92개 운동 전체 애니메이션 GIF',
        chips: [
          { label: '92', desc: '종목' },
          { label: 'GIF', desc: '지원' },
        ],
      },
    },
  },
  {
    id: 3,
    accent: '#00FFB3',
    screenFile: 'shot3_screen.png',
    nav: 'ホーム画面（TodayActionCard + Day切替タブ表示）',
    copy: {
      ja: {
        headline: '今日やるべき種目、\n自動で',
        sub: '目標×頻度×場所 → あなた専用ルーティン',
        chips: [
          { label: '目標' },
          { label: '頻度' },
          { label: '場所' },
        ],
      },
      en: {
        headline: 'Never wonder\nwhat to train.',
        sub: 'Goals × frequency × location → your split',
        chips: [
          { label: 'Goals' },
          { label: 'Frequency' },
          { label: 'Location' },
        ],
      },
      de: {
        headline: 'Nie mehr fragen,\nwas trainiert wird.',
        sub: 'Ziele × Häufigkeit × Ort → dein Split',
        chips: [
          { label: 'Ziele' },
          { label: 'Frequenz' },
          { label: 'Ort' },
        ],
      },
      fr: {
        headline: 'Plus besoin\nde réfléchir.',
        sub: 'Objectifs × fréquence × lieu → votre split',
        chips: [
          { label: 'Objectifs' },
          { label: 'Fréquence' },
          { label: 'Lieu' },
        ],
      },
      es: {
        headline: 'Nunca más dudes\nqué entrenar.',
        sub: 'Objetivos × frecuencia × lugar → tu rutina',
        chips: [
          { label: 'Objetivos' },
          { label: 'Frecuencia' },
          { label: 'Lugar' },
        ],
      },
      pt: {
        headline: 'Nunca mais pense\no que treinar.',
        sub: 'Objetivos × frequência × local → sua rotina',
        chips: [
          { label: 'Objetivos' },
          { label: 'Frequência' },
          { label: 'Local' },
        ],
      },
      ko: {
        headline: '오늘 뭘 할지\n더 이상 고민하지 마세요.',
        sub: '목표 × 빈도 × 장소 → 맞춤 루틴',
        chips: [
          { label: '목표' },
          { label: '빈도' },
          { label: '장소' },
        ],
      },
    },
  },
  {
    id: 4,
    accent: '#FFD700',
    screenFile: 'shot4_screen.png',
    nav: 'ワークアウト完了画面（PR祝福 + 筋肉マップハイライト）',
    copy: {
      ja: {
        headline: '自己ベスト、\n見逃さない',
        sub: 'PR更新をリアルタイムで祝福',
        chips: [{ label: 'NEW PR!' }],
      },
      en: {
        headline: 'Every PR,\ncelebrated.',
        sub: 'Real-time personal record detection',
        chips: [{ label: 'NEW PR!' }],
      },
      de: {
        headline: 'Jeder PR\nwird gefeiert.',
        sub: 'Echtzeit-Erkennung persönlicher Rekorde',
        chips: [{ label: 'NEUER PR!' }],
      },
      fr: {
        headline: 'Chaque record\ncélébré.',
        sub: 'Détection en temps réel des records',
        chips: [{ label: 'NOUVEAU PR!' }],
      },
      es: {
        headline: 'Cada récord,\ncelebrado.',
        sub: 'Detección de récords en tiempo real',
        chips: [{ label: '¡NUEVO PR!' }],
      },
      pt: {
        headline: 'Cada recorde,\ncelebrado.',
        sub: 'Detecção de recordes em tempo real',
        chips: [{ label: 'NOVO PR!' }],
      },
      ko: {
        headline: '모든 자기 기록,\n놓치지 않습니다.',
        sub: '실시간 개인 기록 감지',
        chips: [{ label: 'NEW PR!' }],
      },
    },
  },
  {
    id: 5,
    accent: '#00D4FF',
    screenFile: 'shot5_screen.png',
    nav: 'Strength Mapタブ（筋肉の太さグレード表示）',
    copy: {
      ja: {
        headline: 'どこに効くか、\n数値で見る',
        sub: 'S〜Dグレードで全身を評価',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      en: {
        headline: 'See your strength\nin grades.',
        sub: 'S-to-D grading across your whole body',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      de: {
        headline: 'Deine Stärke\nin Noten.',
        sub: 'S-bis-D-Bewertung für den ganzen Körper',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      fr: {
        headline: 'Votre force\nen notes.',
        sub: 'Notation S à D sur tout le corps',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      es: {
        headline: 'Tu fuerza\nen grados.',
        sub: 'Clasificación S a D en todo el cuerpo',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      pt: {
        headline: 'Sua força\nem notas.',
        sub: 'Classificação S a D por todo o corpo',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      ko: {
        headline: '내 근력,\n등급으로 확인.',
        sub: 'S~D 등급으로 전신 평가',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
    },
  },
  {
    id: 6,
    accent: '#00FFB3',
    screenFile: 'shot6_screen.png',
    nav: 'ワークアウト完了画面（筋肉マップハイライト + シェアCTA）',
    copy: {
      ja: {
        headline: '今日、\nここを鍛えた',
        sub: 'ワークアウト完了で刺激部位を自動記録',
        chips: [
          { label: 'マップ' },
          { label: 'シェア' },
        ],
      },
      en: {
        headline: 'Today,\nyou hit these.',
        sub: 'Auto-log stimulated muscles on completion',
        chips: [
          { label: 'Map' },
          { label: 'Share' },
        ],
      },
      de: {
        headline: 'Heute hast du\ndiese trainiert.',
        sub: 'Automatische Aufzeichnung nach dem Training',
        chips: [
          { label: 'Karte' },
          { label: 'Teilen' },
        ],
      },
      fr: {
        headline: "Aujourd'hui,\nvous avez ciblé.",
        sub: 'Enregistrement auto des muscles stimulés',
        chips: [
          { label: 'Carte' },
          { label: 'Partager' },
        ],
      },
      es: {
        headline: 'Hoy\ntrabajaste estos.',
        sub: 'Registro automático de músculos estimulados',
        chips: [
          { label: 'Mapa' },
          { label: 'Compartir' },
        ],
      },
      pt: {
        headline: 'Hoje você\ntrabalhou estes.',
        sub: 'Registro automático dos músculos estimulados',
        chips: [
          { label: 'Mapa' },
          { label: 'Compartilhar' },
        ],
      },
      ko: {
        headline: '오늘\n이곳을 단련했습니다.',
        sub: '운동 완료 시 자극 부위 자동 기록',
        chips: [
          { label: '맵' },
          { label: '공유' },
        ],
      },
    },
  },
];

// Export sizes for Apple App Store
export const EXPORT_SIZES = [
  { name: '6.9"', width: 1320, height: 2868 },
  { name: '6.7"', width: 1290, height: 2796 },
  { name: '6.5"', width: 1284, height: 2778 },
  { name: '6.1"', width: 1179, height: 2556 },
] as const;

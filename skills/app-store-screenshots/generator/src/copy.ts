// MuscleMap App Store Screenshot Copy — 7 Languages
// Each shot: headline (2 lines max), sub (1 line), accent color, stat chips

export type Lang = 'ja' | 'en' | 'zh' | 'ko' | 'es' | 'de' | 'fr';

export interface ShotCopy {
  headline: string;
  sub: string;
  chips: { label: string; desc?: string }[];
}

export interface ShotDef {
  id: number;
  file: string;
  accent: string;
  nav: string;
  copy: Record<Lang, ShotCopy>;
}

export const SHOTS: ShotDef[] = [
  {
    id: 1,
    file: 'shot1_screen.png',
    accent: '#00FFB3',
    nav: 'Home — Recovery Map (front, colored)',
    copy: {
      ja: {
        headline: '昨日の筋トレ、\n今どこに残ってる？',
        sub: '21部位の回復をリアルタイム表示',
        chips: [
          { label: '21', desc: '筋肉' },
          { label: '92', desc: '種目' },
          { label: 'EMG', desc: 'ベース' },
        ],
      },
      en: {
        headline: 'Your muscles\nlight up.',
        sub: '21 muscles × real-time recovery map',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: '92', desc: 'exercises' },
          { label: 'EMG', desc: 'based' },
        ],
      },
      zh: {
        headline: '昨天练的肌肉，\n现在恢复了吗？',
        sub: '21个部位 × 实时恢复地图',
        chips: [
          { label: '21', desc: '肌肉' },
          { label: '92', desc: '动作' },
          { label: 'EMG', desc: '数据' },
        ],
      },
      ko: {
        headline: '어제 운동한 근육,\n지금 어디까지 회복됐을까?',
        sub: '21개 부위 × 실시간 회복 맵',
        chips: [
          { label: '21', desc: '근육' },
          { label: '92', desc: '종목' },
          { label: 'EMG', desc: '기반' },
        ],
      },
      es: {
        headline: 'Tus músculos\nse iluminan.',
        sub: '21 músculos × mapa de recuperación',
        chips: [
          { label: '21', desc: 'músculos' },
          { label: '92', desc: 'ejercicios' },
          { label: 'EMG', desc: 'basado' },
        ],
      },
      de: {
        headline: 'Deine Muskeln\nleuchten auf.',
        sub: '21 Muskeln × Echtzeit-Erholungskarte',
        chips: [
          { label: '21', desc: 'Muskeln' },
          { label: '92', desc: 'Übungen' },
          { label: 'EMG', desc: 'basiert' },
        ],
      },
      fr: {
        headline: 'Vos muscles\ns\'illuminent.',
        sub: '21 muscles × carte de récupération',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: '92', desc: 'exercices' },
          { label: 'EMG', desc: 'basé' },
        ],
      },
    },
  },
  {
    id: 2,
    file: 'shot2_screen.png',
    accent: '#00FFB3',
    nav: 'Workout Completion (muscle map highlight)',
    copy: {
      ja: {
        headline: '今日、ここを鍛えた',
        sub: 'ワークアウト完了で刺激部位を自動記録',
        chips: [{ label: 'PR', desc: '検出' }, { label: 'Share', desc: '' }],
      },
      en: {
        headline: 'Today, you hit\nthese muscles.',
        sub: 'Auto-records stimulated muscles on completion',
        chips: [{ label: 'PR', desc: 'detect' }, { label: 'Share', desc: '' }],
      },
      zh: {
        headline: '今天，这些肌肉\n被训练了',
        sub: '完成训练自动记录刺激部位',
        chips: [{ label: 'PR', desc: '检测' }, { label: '分享', desc: '' }],
      },
      ko: {
        headline: '오늘, 이 근육을\n단련했다',
        sub: '운동 완료 시 자극 부위 자동 기록',
        chips: [{ label: 'PR', desc: '감지' }, { label: '공유', desc: '' }],
      },
      es: {
        headline: 'Hoy entrenaste\nestos músculos.',
        sub: 'Registro automático al completar',
        chips: [{ label: 'PR', desc: 'detectar' }, { label: 'Compartir', desc: '' }],
      },
      de: {
        headline: 'Heute hast du\ndiese Muskeln trainiert.',
        sub: 'Automatische Aufzeichnung nach dem Training',
        chips: [{ label: 'PR', desc: 'erkennen' }, { label: 'Teilen', desc: '' }],
      },
      fr: {
        headline: 'Aujourd\'hui, tu as\ntravaillé ces muscles.',
        sub: 'Enregistrement auto à la fin',
        chips: [{ label: 'PR', desc: 'détection' }, { label: 'Partager', desc: '' }],
      },
    },
  },
  {
    id: 3,
    file: 'shot3_screen.png',
    accent: '#00FFB3',
    nav: 'Home — Day tabs (routine)',
    copy: {
      ja: {
        headline: '今日やるべき種目、\n自動で',
        sub: '目標×頻度×場所 → あなた専用Day分割',
        chips: [
          { label: '目標' },
          { label: '頻度' },
          { label: '場所' },
          { label: '経験' },
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
      zh: {
        headline: '今天练什么，\n自动安排',
        sub: '目标×频率×场所 → 你的专属计划',
        chips: [{ label: '目标' }, { label: '频率' }, { label: '场所' }],
      },
      ko: {
        headline: '오늘 뭘 해야 할지,\n자동으로',
        sub: '목표×빈도×장소 → 나만의 분할',
        chips: [{ label: '목표' }, { label: '빈도' }, { label: '장소' }],
      },
      es: {
        headline: 'Nunca te preguntes\nqué entrenar.',
        sub: 'Objetivos × frecuencia × lugar → tu rutina',
        chips: [{ label: 'Objetivos' }, { label: 'Frecuencia' }, { label: 'Lugar' }],
      },
      de: {
        headline: 'Nie mehr fragen:\nWas trainiere ich?',
        sub: 'Ziele × Häufigkeit × Ort → dein Split',
        chips: [{ label: 'Ziele' }, { label: 'Häufigkeit' }, { label: 'Ort' }],
      },
      fr: {
        headline: 'Plus besoin de\nse demander quoi faire.',
        sub: 'Objectifs × fréquence × lieu → votre split',
        chips: [{ label: 'Objectifs' }, { label: 'Fréquence' }, { label: 'Lieu' }],
      },
    },
  },
  {
    id: 4,
    file: 'shot4_screen.png',
    accent: '#00D4FF',
    nav: 'Exercise Library (grid + GIF)',
    copy: {
      ja: {
        headline: '92種目、全部動く',
        sub: '全種目アニメーションGIF対応',
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
      zh: {
        headline: '92个动作，\n全部有动图',
        sub: '全部动作配有GIF动画',
        chips: [{ label: '92', desc: '动作' }, { label: 'GIF', desc: '支持' }],
      },
      ko: {
        headline: '92개 종목,\n전부 움직인다',
        sub: '모든 종목 GIF 애니메이션 지원',
        chips: [{ label: '92', desc: '종목' }, { label: 'GIF', desc: '지원' }],
      },
      es: {
        headline: 'Ve el movimiento,\nno solo el nombre.',
        sub: 'GIFs animados para 92 ejercicios',
        chips: [{ label: '92', desc: 'ejercicios' }, { label: 'GIF', desc: '' }],
      },
      de: {
        headline: 'Sieh die Bewegung,\nnicht nur den Namen.',
        sub: 'Animierte GIFs für alle 92 Übungen',
        chips: [{ label: '92', desc: 'Übungen' }, { label: 'GIF', desc: '' }],
      },
      fr: {
        headline: 'Voyez le mouvement,\npas juste le nom.',
        sub: 'GIFs animés pour les 92 exercices',
        chips: [{ label: '92', desc: 'exercices' }, { label: 'GIF', desc: '' }],
      },
    },
  },
  {
    id: 5,
    file: 'shot5_screen.png',
    accent: '#FFD700',
    nav: 'PR Celebration (workout completion)',
    copy: {
      ja: {
        headline: '前回を超えろ',
        sub: 'PR更新をリアルタイムで祝福',
        chips: [{ label: 'NEW PR!' }],
      },
      en: {
        headline: 'Break your\npersonal record.',
        sub: 'Real-time PR detection & celebration',
        chips: [{ label: 'NEW PR!' }],
      },
      zh: {
        headline: '打破你的\n个人纪录',
        sub: '实时检测并庆祝PR',
        chips: [{ label: 'NEW PR!' }],
      },
      ko: {
        headline: '지난번을\n넘어서라',
        sub: '실시간 PR 감지 및 축하',
        chips: [{ label: 'NEW PR!' }],
      },
      es: {
        headline: 'Supera tu\nrécord personal.',
        sub: 'Detección y celebración de PR en tiempo real',
        chips: [{ label: 'NEW PR!' }],
      },
      de: {
        headline: 'Brich deinen\npersönlichen Rekord.',
        sub: 'Echtzeit-PR-Erkennung & Feier',
        chips: [{ label: 'NEW PR!' }],
      },
      fr: {
        headline: 'Dépasse ton\nrecord personnel.',
        sub: 'Détection et célébration PR en temps réel',
        chips: [{ label: 'NEW PR!' }],
      },
    },
  },
  {
    id: 6,
    file: 'shot6_screen.png',
    accent: '#00D4FF',
    nav: 'Strength Map (thickness grading)',
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
        headline: 'See your strength\nin thickness.',
        sub: 'S-to-D grading across your body',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      zh: {
        headline: '哪里有效，\n用数据看',
        sub: 'S到D等级评估全身',
        chips: [{ label: 'S' }, { label: 'A' }, { label: 'B' }, { label: 'C' }, { label: 'D' }],
      },
      ko: {
        headline: '어디에 효과가 있는지\n수치로 확인',
        sub: 'S~D 등급으로 전신 평가',
        chips: [{ label: 'S' }, { label: 'A' }, { label: 'B' }, { label: 'C' }, { label: 'D' }],
      },
      es: {
        headline: 'Ve tu fuerza\nen grosor.',
        sub: 'Calificación S a D en todo el cuerpo',
        chips: [{ label: 'S' }, { label: 'A' }, { label: 'B' }, { label: 'C' }, { label: 'D' }],
      },
      de: {
        headline: 'Sieh deine Stärke\nin Dicke.',
        sub: 'S-bis-D-Bewertung für den ganzen Körper',
        chips: [{ label: 'S' }, { label: 'A' }, { label: 'B' }, { label: 'C' }, { label: 'D' }],
      },
      fr: {
        headline: 'Voyez votre force\nen épaisseur.',
        sub: 'Notation S à D sur tout le corps',
        chips: [{ label: 'S' }, { label: 'A' }, { label: 'B' }, { label: 'C' }, { label: 'D' }],
      },
    },
  },
];

// Export sizes for App Store
export const EXPORT_SIZES = [
  { name: '6.9"', width: 1320, height: 2868 },
  { name: '6.5"', width: 1284, height: 2778 },
  { name: '6.3"', width: 1206, height: 2622 },
  { name: '6.1"', width: 1125, height: 2436 },
] as const;

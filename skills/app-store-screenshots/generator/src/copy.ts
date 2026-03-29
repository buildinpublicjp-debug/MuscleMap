// MuscleMap App Store Screenshot Copy — Redesigned
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
    accent: '#00E676',
    nav: 'Recovery Map — Hero',
    copy: {
      ja: {
        headline: '筋肉が、見える。',
        sub: '21部位の回復状態をリアルタイム表示',
        chips: [
          { label: '21', desc: '部位' },
          { label: 'リアルタイム' },
          { label: 'EMG', desc: 'ベース' },
        ],
      },
      en: {
        headline: 'See your muscles.\nLive.',
        sub: '21 muscles. Real-time recovery.',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: 'Real-time' },
          { label: 'EMG', desc: 'based' },
        ],
      },
      zh: {
        headline: '肌肉，看得见。',
        sub: '21个部位实时恢复状态',
        chips: [
          { label: '21', desc: '部位' },
          { label: '实时' },
          { label: 'EMG', desc: '数据' },
        ],
      },
      ko: {
        headline: '근육이 보인다.',
        sub: '21개 부위 실시간 회복 상태',
        chips: [
          { label: '21', desc: '부위' },
          { label: '실시간' },
          { label: 'EMG', desc: '기반' },
        ],
      },
      es: {
        headline: 'Tus músculos,\nvisibles.',
        sub: '21 músculos en tiempo real',
        chips: [
          { label: '21', desc: 'músculos' },
          { label: 'Tiempo real' },
          { label: 'EMG', desc: 'basado' },
        ],
      },
      de: {
        headline: 'Deine Muskeln.\nSichtbar.',
        sub: '21 Muskeln in Echtzeit',
        chips: [
          { label: '21', desc: 'Muskeln' },
          { label: 'Echtzeit' },
          { label: 'EMG', desc: 'basiert' },
        ],
      },
      fr: {
        headline: 'Vos muscles,\nvisibles.',
        sub: '21 muscles en temps réel',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: 'Temps réel' },
          { label: 'EMG', desc: 'basé' },
        ],
      },
    },
  },
  {
    id: 2,
    file: 'shot2_screen.png',
    accent: '#00E676',
    nav: 'Today Action — Auto Plan',
    copy: {
      ja: {
        headline: '今日やるべき種目、\n自動で。',
        sub: '目標×頻度×場所 → あなた専用メニュー',
        chips: [
          { label: '目標' },
          { label: '頻度' },
          { label: '場所' },
          { label: '自動生成' },
        ],
      },
      en: {
        headline: 'Your daily plan.\nAutomatic.',
        sub: 'Goal × Frequency × Location → Your menu',
        chips: [
          { label: 'Goals' },
          { label: 'Frequency' },
          { label: 'Location' },
          { label: 'Auto' },
        ],
      },
      zh: {
        headline: '今天练什么，\n自动安排。',
        sub: '目标×频率×场所 → 你的专属计划',
        chips: [
          { label: '目标' },
          { label: '频率' },
          { label: '场所' },
          { label: '自动' },
        ],
      },
      ko: {
        headline: '오늘 뭘 해야 할지,\n자동으로.',
        sub: '목표×빈도×장소 → 나만의 메뉴',
        chips: [
          { label: '목표' },
          { label: '빈도' },
          { label: '장소' },
          { label: '자동' },
        ],
      },
      es: {
        headline: 'Tu plan diario.\nAutomático.',
        sub: 'Objetivos × frecuencia × lugar → tu rutina',
        chips: [
          { label: 'Objetivos' },
          { label: 'Frecuencia' },
          { label: 'Lugar' },
          { label: 'Auto' },
        ],
      },
      de: {
        headline: 'Dein Tagesplan.\nAutomatisch.',
        sub: 'Ziele × Häufigkeit × Ort → dein Menü',
        chips: [
          { label: 'Ziele' },
          { label: 'Häufigkeit' },
          { label: 'Ort' },
          { label: 'Auto' },
        ],
      },
      fr: {
        headline: 'Votre plan du jour.\nAutomatique.',
        sub: 'Objectifs × fréquence × lieu → votre menu',
        chips: [
          { label: 'Objectifs' },
          { label: 'Fréquence' },
          { label: 'Lieu' },
          { label: 'Auto' },
        ],
      },
    },
  },
  {
    id: 3,
    file: 'shot3_screen.png',
    accent: '#00D4FF',
    nav: 'Exercise Library (92 GIFs)',
    copy: {
      ja: {
        headline: '92種目、全部動く。',
        sub: '正しいフォームをGIFで確認',
        chips: [
          { label: '92', desc: '種目' },
          { label: 'GIF', desc: '対応' },
          { label: 'EMG', desc: '刺激度' },
        ],
      },
      en: {
        headline: '92 exercises.\nAll animated.',
        sub: 'Check form with animated GIFs',
        chips: [
          { label: '92', desc: 'exercises' },
          { label: 'GIF', desc: 'powered' },
          { label: 'EMG', desc: 'mapped' },
        ],
      },
      zh: {
        headline: '92个动作，\n全部有动图。',
        sub: '用GIF确认正确姿势',
        chips: [
          { label: '92', desc: '动作' },
          { label: 'GIF', desc: '支持' },
          { label: 'EMG', desc: '数据' },
        ],
      },
      ko: {
        headline: '92개 종목,\n전부 움직인다.',
        sub: 'GIF로 올바른 폼 확인',
        chips: [
          { label: '92', desc: '종목' },
          { label: 'GIF', desc: '지원' },
          { label: 'EMG', desc: '기반' },
        ],
      },
      es: {
        headline: '92 ejercicios.\nTodos animados.',
        sub: 'Verifica tu forma con GIFs animados',
        chips: [
          { label: '92', desc: 'ejercicios' },
          { label: 'GIF', desc: '' },
          { label: 'EMG', desc: '' },
        ],
      },
      de: {
        headline: '92 Übungen.\nAlle animiert.',
        sub: 'Technik mit animierten GIFs prüfen',
        chips: [
          { label: '92', desc: 'Übungen' },
          { label: 'GIF', desc: '' },
          { label: 'EMG', desc: '' },
        ],
      },
      fr: {
        headline: '92 exercices.\nTous animés.',
        sub: 'Vérifiez votre forme avec des GIFs',
        chips: [
          { label: '92', desc: 'exercices' },
          { label: 'GIF', desc: '' },
          { label: 'EMG', desc: '' },
        ],
      },
    },
  },
  {
    id: 4,
    file: 'shot4_screen.png',
    accent: '#FFD700',
    nav: 'PR Celebration',
    copy: {
      ja: {
        headline: '自己ベスト、祝う。',
        sub: 'PR更新を自動検出 → 紙吹雪で祝福',
        chips: [{ label: '🏆 NEW PR!' }],
      },
      en: {
        headline: 'Celebrate\nevery PR.',
        sub: 'Auto-detect PRs → Celebrate with confetti',
        chips: [{ label: '🏆 NEW PR!' }],
      },
      zh: {
        headline: '最佳纪录，\n值得庆祝。',
        sub: '自动检测PR → 撒花庆祝',
        chips: [{ label: '🏆 NEW PR!' }],
      },
      ko: {
        headline: '자기 최고 기록,\n축하하자.',
        sub: 'PR 자동 감지 → 축하 이펙트',
        chips: [{ label: '🏆 NEW PR!' }],
      },
      es: {
        headline: 'Celebra cada\nrécord personal.',
        sub: 'Detección automática de PR → Confeti',
        chips: [{ label: '🏆 NEW PR!' }],
      },
      de: {
        headline: 'Feiere jeden\npersönlichen Rekord.',
        sub: 'PR automatisch erkennen → Konfetti',
        chips: [{ label: '🏆 NEW PR!' }],
      },
      fr: {
        headline: 'Célèbre chaque\nrecord personnel.',
        sub: 'Détection auto des PR → Confettis',
        chips: [{ label: '🏆 NEW PR!' }],
      },
    },
  },
  {
    id: 5,
    file: 'shot5_screen.png',
    accent: '#00E676',
    nav: 'History — Growth Tracking',
    copy: {
      ja: {
        headline: '成長が、\nグラフで見える。',
        sub: '週間ボリューム推移 + 先週比',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
      en: {
        headline: 'Watch yourself\ngrow.',
        sub: 'Weekly volume trends + comparison',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
      zh: {
        headline: '成长，\n一目了然。',
        sub: '周训练量趋势 + 对比',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
      ko: {
        headline: '성장을\n그래프로 확인.',
        sub: '주간 볼륨 추이 + 전주 대비',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
      es: {
        headline: 'Mira cómo\ncreces.',
        sub: 'Tendencias de volumen semanal + comparación',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
      de: {
        headline: 'Sieh deinen\nFortschritt.',
        sub: 'Wöchentliche Volumentrends + Vergleich',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
      fr: {
        headline: 'Regardez votre\nprogression.',
        sub: 'Tendances hebdomadaires + comparaison',
        chips: [
          { label: '30.5k', desc: 'kg' },
          { label: '↑ 12%' },
          { label: '🔥 8w' },
        ],
      },
    },
  },
  {
    id: 6,
    file: 'shot6_screen.png',
    accent: '#00D4FF',
    nav: 'Strength Map — Grades',
    copy: {
      ja: {
        headline: 'どこが強い？\n数値で見る。',
        sub: '筋力レベルを太さで可視化 — S〜Dランク',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      en: {
        headline: 'Know your\nstrengths.',
        sub: 'Strength levels visualized — S to D rank',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      zh: {
        headline: '哪里更强？\n数据说话。',
        sub: '肌力等级可视化 — S到D等级',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      ko: {
        headline: '어디가 강한가?\n수치로 확인.',
        sub: '근력 레벨 시각화 — S~D 등급',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      es: {
        headline: '¿Dónde eres\nfuerte?',
        sub: 'Niveles de fuerza — rango S a D',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      de: {
        headline: 'Wo bist du\nstark?',
        sub: 'Stärkelevel visualisiert — S bis D',
        chips: [
          { label: 'S' },
          { label: 'A' },
          { label: 'B' },
          { label: 'C' },
          { label: 'D' },
        ],
      },
      fr: {
        headline: 'Où êtes-vous\nfort ?',
        sub: 'Niveaux de force — rang S à D',
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
];

// Export sizes for App Store
export const EXPORT_SIZES = [
  { name: '6.9"', width: 1320, height: 2868 },
] as const;

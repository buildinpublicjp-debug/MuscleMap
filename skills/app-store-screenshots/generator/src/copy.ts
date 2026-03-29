// MuscleMap App Store Screenshot Copy — v2
// Design philosophy: benefit-driven, readable at thumbnail size
// Story arc: Hook → Benefit → Depth → Core Action → Insight → Transformation
//
// Changes from v1:
// - Headlines shortened & punchier (max 2 lines, ~8 chars/line for JA)
// - Subs simplified to one short benefit phrase
// - Chips reduced to 2-3 max, data-heavy
// - Shot 4: PR Celebration → Workout Recording (matches actual screen)
// - Shot 5: Growth Chart → Muscle Detail (matches RecoveryDetailView)
// - Shot 6: Strength Map (deleted) → Progress Photo (Pro feature)

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
  // ─── SHOT 1: Recovery Map — HOOK ───
  // "What is this app?" → You can SEE your muscles
  {
    id: 1,
    file: 'shot1_screen.png',
    accent: '#00E676',
    nav: 'Recovery Map — Hero',
    copy: {
      ja: {
        headline: '筋肉が、見える。',
        sub: '21部位の回復をリアルタイムで',
        chips: [
          { label: '21', desc: '部位' },
          { label: 'リアルタイム' },
        ],
      },
      en: {
        headline: 'See your\nmuscles.',
        sub: '21 muscles. Real-time recovery.',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: 'Real-time' },
        ],
      },
      zh: {
        headline: '肌肉，\n看得见。',
        sub: '21个部位 实时恢复状态',
        chips: [
          { label: '21', desc: '部位' },
          { label: '实时' },
        ],
      },
      ko: {
        headline: '근육이\n보인다.',
        sub: '21개 부위 실시간 회복',
        chips: [
          { label: '21', desc: '부위' },
          { label: '실시간' },
        ],
      },
      es: {
        headline: 'Tus músculos,\nvisibles.',
        sub: '21 músculos en tiempo real',
        chips: [
          { label: '21', desc: 'músculos' },
          { label: 'Tiempo real' },
        ],
      },
      de: {
        headline: 'Deine Muskeln.\nSichtbar.',
        sub: '21 Muskeln in Echtzeit',
        chips: [
          { label: '21', desc: 'Muskeln' },
          { label: 'Echtzeit' },
        ],
      },
      fr: {
        headline: 'Vos muscles,\nvisibles.',
        sub: '21 muscles en temps réel',
        chips: [
          { label: '21', desc: 'muscles' },
          { label: 'Temps réel' },
        ],
      },
    },
  },

  // ─── SHOT 2: Today's Plan — BENEFIT ───
  // "What does it do for me?" → No more guessing what to train
  {
    id: 2,
    file: 'shot2_screen.png',
    accent: '#00E676',
    nav: 'Today Action — Auto Plan',
    copy: {
      ja: {
        headline: '迷わない。',
        sub: '回復×目標から今日の種目を自動提案',
        chips: [
          { label: '自動生成' },
          { label: '回復連動' },
        ],
      },
      en: {
        headline: "No more\nguessing.",
        sub: 'Recovery × Goals → Your daily plan',
        chips: [
          { label: 'Auto-plan' },
          { label: 'Recovery-linked' },
        ],
      },
      zh: {
        headline: '不再迷茫。',
        sub: '恢复×目标 → 今日计划',
        chips: [
          { label: '自动' },
          { label: '恢复联动' },
        ],
      },
      ko: {
        headline: '고민 끝.',
        sub: '회복×목표 → 오늘의 메뉴',
        chips: [
          { label: '자동 생성' },
          { label: '회복 연동' },
        ],
      },
      es: {
        headline: 'Sin dudas.',
        sub: 'Recuperación × Objetivos → Tu plan',
        chips: [
          { label: 'Auto' },
          { label: 'Recuperación' },
        ],
      },
      de: {
        headline: 'Kein Rätsel\nmehr.',
        sub: 'Erholung × Ziele → Dein Plan',
        chips: [
          { label: 'Automatisch' },
          { label: 'Erholung' },
        ],
      },
      fr: {
        headline: 'Fini les\ndoutes.',
        sub: 'Récupération × Objectifs → Votre plan',
        chips: [
          { label: 'Auto' },
          { label: 'Récupération' },
        ],
      },
    },
  },

  // ─── SHOT 3: Exercise Library — DEPTH ───
  // "How much content?" → 92 exercises, all with GIF form guides
  {
    id: 3,
    file: 'shot3_screen.png',
    accent: '#00D4FF',
    nav: 'Exercise Library (92 GIFs)',
    copy: {
      ja: {
        headline: '92種目。\n全部動く。',
        sub: 'GIFで正しいフォームを確認',
        chips: [
          { label: '92', desc: '種目' },
          { label: 'GIF' },
          { label: 'EMG', desc: '対応' },
        ],
      },
      en: {
        headline: '92 exercises.\nAll animated.',
        sub: 'Animated form guides for every move',
        chips: [
          { label: '92', desc: 'exercises' },
          { label: 'GIF' },
          { label: 'EMG', desc: 'mapped' },
        ],
      },
      zh: {
        headline: '92个动作。\n全部有动图。',
        sub: 'GIF动图确认正确姿势',
        chips: [
          { label: '92', desc: '动作' },
          { label: 'GIF' },
          { label: 'EMG', desc: '数据' },
        ],
      },
      ko: {
        headline: '92개 종목.\n전부 움직인다.',
        sub: 'GIF로 정확한 폼 확인',
        chips: [
          { label: '92', desc: '종목' },
          { label: 'GIF' },
          { label: 'EMG', desc: '기반' },
        ],
      },
      es: {
        headline: '92 ejercicios.\nTodos animados.',
        sub: 'Guías de forma animadas',
        chips: [
          { label: '92', desc: 'ejercicios' },
          { label: 'GIF' },
          { label: 'EMG' },
        ],
      },
      de: {
        headline: '92 Übungen.\nAlle animiert.',
        sub: 'Animierte Form-Guides',
        chips: [
          { label: '92', desc: 'Übungen' },
          { label: 'GIF' },
          { label: 'EMG' },
        ],
      },
      fr: {
        headline: '92 exercices.\nTous animés.',
        sub: "Guides de forme animés",
        chips: [
          { label: '92', desc: 'exercices' },
          { label: 'GIF' },
          { label: 'EMG' },
        ],
      },
    },
  },

  // ─── SHOT 4: Workout Recording — CORE ACTION ───
  // "How do I use it?" → Just log. PRs are detected automatically.
  // Accent: gold — the PR badge on screen ties it together
  {
    id: 4,
    file: 'shot4_screen.png',
    accent: '#FFD700',
    nav: 'Workout Recording + PR',
    copy: {
      ja: {
        headline: '記録する。\nあとは自動。',
        sub: 'PR更新も回復計算もおまかせ',
        chips: [
          { label: '🏆', desc: 'PR自動検出' },
          { label: '回復連動' },
        ],
      },
      en: {
        headline: 'Just log it.\nWe do the rest.',
        sub: 'Auto PR detection + recovery tracking',
        chips: [
          { label: '🏆', desc: 'Auto PR' },
          { label: 'Recovery sync' },
        ],
      },
      zh: {
        headline: '只管记录。\n剩下交给我。',
        sub: 'PR自动检测 + 恢复追踪',
        chips: [
          { label: '🏆', desc: '自动PR' },
          { label: '恢复联动' },
        ],
      },
      ko: {
        headline: '기록만 해.\n나머지는 자동.',
        sub: 'PR 자동 감지 + 회복 추적',
        chips: [
          { label: '🏆', desc: '자동 PR' },
          { label: '회복 연동' },
        ],
      },
      es: {
        headline: 'Solo registra.\nNosotros hacemos\nel resto.',
        sub: 'PR automático + seguimiento',
        chips: [
          { label: '🏆', desc: 'PR auto' },
          { label: 'Recuperación' },
        ],
      },
      de: {
        headline: 'Einfach loggen.\nWir machen\nden Rest.',
        sub: 'Auto-PR + Erholungs-Tracking',
        chips: [
          { label: '🏆', desc: 'Auto PR' },
          { label: 'Erholung' },
        ],
      },
      fr: {
        headline: 'Enregistrez.\nOn fait le reste.',
        sub: 'PR auto + suivi récupération',
        chips: [
          { label: '🏆', desc: 'PR auto' },
          { label: 'Récupération' },
        ],
      },
    },
  },

  // ─── SHOT 5: Muscle Detail — INSIGHT ───
  // "How deep does the data go?" → Per-muscle trends, recovery, history
  {
    id: 5,
    file: 'shot5_screen.png',
    accent: '#00D4FF',
    nav: 'Recovery Detail — Per Muscle',
    copy: {
      ja: {
        headline: '1部位ずつ、\n深く知る。',
        sub: '重量推移・回復・種目を一覧',
        chips: [
          { label: '重量推移' },
          { label: '回復状態' },
          { label: '種目履歴' },
        ],
      },
      en: {
        headline: 'Every muscle,\nin depth.',
        sub: 'Weight trends · Recovery · Exercise history',
        chips: [
          { label: 'Trends' },
          { label: 'Recovery' },
          { label: 'History' },
        ],
      },
      zh: {
        headline: '每块肌肉，\n深入了解。',
        sub: '重量趋势 · 恢复 · 训练记录',
        chips: [
          { label: '重量趋势' },
          { label: '恢复' },
          { label: '记录' },
        ],
      },
      ko: {
        headline: '1부위씩,\n깊이 알다.',
        sub: '중량 추이 · 회복 · 종목 이력',
        chips: [
          { label: '중량 추이' },
          { label: '회복' },
          { label: '이력' },
        ],
      },
      es: {
        headline: 'Cada músculo,\nen detalle.',
        sub: 'Tendencias · Recuperación · Historial',
        chips: [
          { label: 'Tendencias' },
          { label: 'Recuperación' },
          { label: 'Historial' },
        ],
      },
      de: {
        headline: 'Jeder Muskel.\nIm Detail.',
        sub: 'Trends · Erholung · Übungs-Historie',
        chips: [
          { label: 'Trends' },
          { label: 'Erholung' },
          { label: 'Historie' },
        ],
      },
      fr: {
        headline: 'Chaque muscle,\nen détail.',
        sub: 'Tendances · Récupération · Historique',
        chips: [
          { label: 'Tendances' },
          { label: 'Récupération' },
          { label: 'Historique' },
        ],
      },
    },
  },

  // ─── SHOT 6: Progress Photo — TRANSFORMATION ───
  // "What's the payoff?" → Capture your body's change over time
  // NEW: replaces deleted Strength Map
  {
    id: 6,
    file: 'shot6_screen.png',
    accent: '#B388FF',
    nav: 'Progress Photo — Transformation',
    copy: {
      ja: {
        headline: '変化を、残す。',
        sub: '定点撮影で体の変化を記録',
        chips: [
          { label: '定点撮影' },
          { label: '比較' },
        ],
      },
      en: {
        headline: 'Capture\nthe change.',
        sub: 'Track your transformation over time',
        chips: [
          { label: 'Progress' },
          { label: 'Compare' },
        ],
      },
      zh: {
        headline: '留住变化。',
        sub: '定点拍摄记录身体变化',
        chips: [
          { label: '定点拍摄' },
          { label: '对比' },
        ],
      },
      ko: {
        headline: '변화를\n남기다.',
        sub: '정점 촬영으로 변화 기록',
        chips: [
          { label: '정점 촬영' },
          { label: '비교' },
        ],
      },
      es: {
        headline: 'Captura\nel cambio.',
        sub: 'Registra tu transformación',
        chips: [
          { label: 'Progreso' },
          { label: 'Comparar' },
        ],
      },
      de: {
        headline: 'Halte die\nVeränderung fest.',
        sub: 'Deine Transformation dokumentieren',
        chips: [
          { label: 'Fortschritt' },
          { label: 'Vergleich' },
        ],
      },
      fr: {
        headline: 'Capturer\nle changement.',
        sub: 'Documentez votre transformation',
        chips: [
          { label: 'Progrès' },
          { label: 'Comparer' },
        ],
      },
    },
  },
];

// Export sizes for App Store
export const EXPORT_SIZES = [
  { name: '6.9"', width: 1320, height: 2868 },
] as const;

// MuscleMap App Store screenshot copy.
// Seven locales share the same nine-shot story so layout and exports stay predictable.

export type Lang = 'ja' | 'en' | 'zh' | 'ko' | 'es' | 'de' | 'fr';

export interface ShotCopy {
  eyebrow: string;
  headline: string;
  sub: string;
  chips: string[];
}

export interface ShotDef {
  id: number;
  file: string;
  accent: string;
  tone: 'green' | 'mint' | 'blue' | 'dark';
  phoneScale: number;
  phoneOffsetY: number;
  nav: string;
  copy: Record<Lang, ShotCopy>;
}

export const EXTRA_HEADLINE_OPTIONS = {
  youtube: {
    ja: [
      'YouTubeでフォームを、\nすぐ確認。',
      'フォームを、\nすぐ確認。',
      '迷ったら、\nその場で動画。',
    ],
  },
  share: {
    ja: [
      '今日のワークアウトを、\n共有。',
      '達成を、\n一枚に。',
      '成果を、\nシェア。',
    ],
  },
  conquest: {
    ja: [
      '全身、\nひとつずつ。',
      '鍛えた部位を、\n地図に。',
      '全身制覇への道。',
    ],
  },
} as const;

export const SHOTS: ShotDef[] = [
  {
    id: 1,
    file: 'shot1_screen.png',
    accent: '#00C77B',
    tone: 'green',
    phoneScale: 1.055,
    phoneOffsetY: -8,
    nav: 'Recovery Map',
    copy: {
      ja: {
        eyebrow: 'Recovery Map',
        headline: '今日の狙いが\n一目でわかる。',
        sub: '回復マップで迷わず決める。',
        chips: ['21部位', '回復状態', 'おすすめ'],
      },
      en: {
        eyebrow: 'Recovery Map',
        headline: 'Know what\nto train today.',
        sub: 'Check muscle recovery and your next move at a glance.',
        chips: ['21 muscles', 'Recovery', 'Next move'],
      },
      zh: {
        eyebrow: '恢复地图',
        headline: '今天练哪里，\n一眼就知道。',
        sub: '通过恢复地图快速确认推荐部位。',
        chips: ['21部位', '恢复状态', '推荐部位'],
      },
      ko: {
        eyebrow: '회복 맵',
        headline: '오늘 어디를\n운동할지 바로 보입니다.',
        sub: '회복 맵으로 추천 부위를 한눈에 확인하세요.',
        chips: ['21부위', '회복 상태', '추천 부위'],
      },
      es: {
        eyebrow: 'Mapa de recuperación',
        headline: 'Sabe qué entrenar\nhoy.',
        sub: 'Mira tu recuperación muscular y el siguiente paso.',
        chips: ['21 músculos', 'Recuperación', 'Siguiente'],
      },
      de: {
        eyebrow: 'Recovery Map',
        headline: 'Sieh sofort,\nwas heute dran ist.',
        sub: 'Muskel-Erholung und nächste Empfehlung auf einen Blick.',
        chips: ['21 Muskeln', 'Erholung', 'Empfehlung'],
      },
      fr: {
        eyebrow: 'Carte de récupération',
        headline: 'Sachez quoi\nentraîner aujourd’hui.',
        sub: 'Voyez la récupération et le prochain muscle à cibler.',
        chips: ['21 muscles', 'Récupération', 'À cibler'],
      },
    },
  },
  {
    id: 2,
    file: 'shot2_screen.png',
    accent: '#00B86B',
    tone: 'dark',
    phoneScale: 1.05,
    phoneOffsetY: 8,
    nav: 'Workout Logging',
    copy: {
      ja: {
        eyebrow: 'Workout Log',
        headline: '記録は一瞬。\n回復まで自動。',
        sub: 'セットもPRもまとめて管理。',
        chips: ['前回値', 'PR検出', '回復計算'],
      },
      en: {
        eyebrow: 'Workout Log',
        headline: 'Just log it.\nWe do the rest.',
        sub: 'Track weight, reps, and sets without slowing down.',
        chips: ['Last set', 'Auto PR', 'Recovery sync'],
      },
      zh: {
        eyebrow: '训练记录',
        headline: '只管记录。\n剩下自动完成。',
        sub: '快速记录重量、次数和组数。',
        chips: ['上次记录', '自动PR', '恢复计算'],
      },
      ko: {
        eyebrow: '운동 기록',
        headline: '기록만 하세요.\n나머지는 자동.',
        sub: '중량, 횟수, 세트를 빠르게 남깁니다.',
        chips: ['이전 기록', 'PR 감지', '회복 계산'],
      },
      es: {
        eyebrow: 'Registro',
        headline: 'Registra.\nLo demás es automático.',
        sub: 'Peso, repeticiones y series sin perder el ritmo.',
        chips: ['Última serie', 'PR auto', 'Recuperación'],
      },
      de: {
        eyebrow: 'Workout Log',
        headline: 'Eintragen.\nDer Rest läuft automatisch.',
        sub: 'Gewicht, Wiederholungen und Sätze schnell erfassen.',
        chips: ['Letzter Satz', 'Auto PR', 'Erholung'],
      },
      fr: {
        eyebrow: 'Journal',
        headline: 'Enregistrez.\nLe reste est automatique.',
        sub: 'Poids, répétitions et séries sans casser le rythme.',
        chips: ['Dernière série', 'PR auto', 'Récupération'],
      },
    },
  },
  {
    id: 3,
    file: 'shot3_screen.png',
    accent: '#00C77B',
    tone: 'mint',
    phoneScale: 1.055,
    phoneOffsetY: -2,
    nav: 'Home Dashboard',
    copy: {
      ja: {
        eyebrow: 'Dashboard',
        headline: '開けばすぐ、\nやることが決まる。',
        sub: '回復・成長・予定を一画面に。',
        chips: ['今日のメニュー', '回復状況', '週間ボリューム'],
      },
      en: {
        eyebrow: 'Dashboard',
        headline: 'Open the app.\nKnow the plan.',
        sub: "Today's workout, recovery, and progress in one view.",
        chips: ["Today's plan", 'Recovery', 'Volume'],
      },
      zh: {
        eyebrow: '仪表盘',
        headline: '打开应用，\n今天就决定了。',
        sub: '今日训练、恢复和成长集中在一屏。',
        chips: ['今日计划', '恢复状态', '训练量'],
      },
      ko: {
        eyebrow: '대시보드',
        headline: '앱을 열면\n오늘이 정해집니다.',
        sub: '오늘의 메뉴, 회복, 성장을 한 화면에.',
        chips: ['오늘 메뉴', '회복 상태', '볼륨'],
      },
      es: {
        eyebrow: 'Panel',
        headline: 'Abre la app.\nYa tienes plan.',
        sub: 'Rutina, recuperación y progreso en una sola vista.',
        chips: ['Plan diario', 'Recuperación', 'Volumen'],
      },
      de: {
        eyebrow: 'Dashboard',
        headline: 'App öffnen.\nPlan sehen.',
        sub: 'Training, Erholung und Fortschritt in einer Ansicht.',
        chips: ['Tagesplan', 'Erholung', 'Volumen'],
      },
      fr: {
        eyebrow: 'Tableau de bord',
        headline: 'Ouvrez l’app.\nVotre séance est prête.',
        sub: 'Séance, récupération et progrès sur un seul écran.',
        chips: ['Plan du jour', 'Récupération', 'Volume'],
      },
    },
  },
  {
    id: 4,
    file: 'shot4_screen.png',
    accent: '#00AEEF',
    tone: 'blue',
    phoneScale: 1.045,
    phoneOffsetY: 18,
    nav: 'Recommended Menu',
    copy: {
      ja: {
        eyebrow: 'Smart Menu',
        headline: '迷わず選んで、\nすぐ開始。',
        sub: '回復に合うメニューを提案。',
        chips: ['自動提案', 'Day分割', '回復連動'],
      },
      en: {
        eyebrow: 'Smart Menu',
        headline: 'No more guessing.\nPick and start.',
        sub: 'Get a workout menu matched to your recovery.',
        chips: ['Auto plan', 'Split days', 'Recovery-led'],
      },
      zh: {
        eyebrow: '智能菜单',
        headline: '不再纠结。\n选好就开始。',
        sub: '根据恢复状态推荐适合今天的菜单。',
        chips: ['自动推荐', '分化训练', '恢复联动'],
      },
      ko: {
        eyebrow: '스마트 메뉴',
        headline: '고민하지 말고\n선택만 하세요.',
        sub: '회복 상태에 맞는 오늘의 메뉴를 제안합니다.',
        chips: ['자동 제안', 'Day 분할', '회복 연동'],
      },
      es: {
        eyebrow: 'Menú inteligente',
        headline: 'Sin dudas.\nElige y empieza.',
        sub: 'Un menú de entrenamiento basado en tu recuperación.',
        chips: ['Auto plan', 'Divisiones', 'Recuperación'],
      },
      de: {
        eyebrow: 'Smart Menu',
        headline: 'Nicht raten.\nEinfach starten.',
        sub: 'Ein Trainingsmenü passend zu deiner Erholung.',
        chips: ['Auto-Plan', 'Split Days', 'Erholung'],
      },
      fr: {
        eyebrow: 'Menu intelligent',
        headline: 'Plus d’hésitation.\nChoisissez et lancez.',
        sub: 'Un menu adapté à votre récupération du jour.',
        chips: ['Plan auto', 'Split', 'Récupération'],
      },
    },
  },
  {
    id: 5,
    file: 'shot5_screen.png',
    accent: '#00AEEF',
    tone: 'blue',
    phoneScale: 1.035,
    phoneOffsetY: 8,
    nav: 'Exercise Library',
    copy: {
      ja: {
        eyebrow: 'Exercise Library',
        headline: '92種目。\nフォームも確認。',
        sub: '動きと効く部位をチェック。',
        chips: ['92種目', 'GIFフォーム', '部位フィルタ'],
      },
      en: {
        eyebrow: 'Exercise Library',
        headline: '92 exercises.\nAll animated.',
        sub: 'Check form and target muscles before every set.',
        chips: ['92 exercises', 'GIF form', 'Filters'],
      },
      zh: {
        eyebrow: '动作库',
        headline: '92个动作。\n全部有动图。',
        sub: '训练前确认姿势和目标肌肉。',
        chips: ['92动作', 'GIF姿势', '部位筛选'],
      },
      ko: {
        eyebrow: '종목 라이브러리',
        headline: '92개 종목.\n전부 움직입니다.',
        sub: '폼과 자극 부위를 GIF로 확인하세요.',
        chips: ['92종목', 'GIF 폼', '부위 필터'],
      },
      es: {
        eyebrow: 'Biblioteca',
        headline: '92 ejercicios.\nTodos animados.',
        sub: 'Revisa la forma y los músculos antes de cada serie.',
        chips: ['92 ejercicios', 'GIF', 'Filtros'],
      },
      de: {
        eyebrow: 'Übungsbibliothek',
        headline: '92 Übungen.\nAlle animiert.',
        sub: 'Form und Zielmuskeln vor jedem Satz prüfen.',
        chips: ['92 Übungen', 'GIF-Form', 'Filter'],
      },
      fr: {
        eyebrow: 'Bibliothèque',
        headline: '92 exercices.\nTous animés.',
        sub: 'Vérifiez le mouvement et les muscles ciblés.',
        chips: ['92 exercices', 'GIF', 'Filtres'],
      },
    },
  },
  {
    id: 6,
    file: 'shot6_screen.png',
    accent: '#00B86B',
    tone: 'green',
    phoneScale: 1.045,
    phoneOffsetY: 12,
    nav: 'Muscle Detail',
    copy: {
      ja: {
        eyebrow: 'Muscle Detail',
        headline: '部位ごとの変化を\n深く追える。',
        sub: '回復・推移・記録をまとめて確認。',
        chips: ['回復率', '重量推移', '種目履歴'],
      },
      en: {
        eyebrow: 'Muscle Detail',
        headline: 'Every muscle,\nin depth.',
        sub: 'Recovery, trends, and history for each muscle.',
        chips: ['Recovery', 'Trends', 'History'],
      },
      zh: {
        eyebrow: '肌肉详情',
        headline: '每个部位，\n都能深入追踪。',
        sub: '按肌肉查看恢复率、趋势和记录。',
        chips: ['恢复率', '重量趋势', '记录'],
      },
      ko: {
        eyebrow: '근육 상세',
        headline: '1부위씩,\n깊게 추적합니다.',
        sub: '부위별 회복률, 추이, 기록을 확인하세요.',
        chips: ['회복률', '중량 추이', '종목 이력'],
      },
      es: {
        eyebrow: 'Detalle muscular',
        headline: 'Cada músculo,\nen detalle.',
        sub: 'Recuperación, tendencias e historial por músculo.',
        chips: ['Recuperación', 'Tendencias', 'Historial'],
      },
      de: {
        eyebrow: 'Muskel-Detail',
        headline: 'Jeder Muskel.\nIm Detail.',
        sub: 'Erholung, Trends und Historie pro Muskel.',
        chips: ['Erholung', 'Trends', 'Historie'],
      },
      fr: {
        eyebrow: 'Détail musculaire',
        headline: 'Chaque muscle,\nen détail.',
        sub: 'Récupération, tendances et historique par muscle.',
        chips: ['Récupération', 'Tendances', 'Historique'],
      },
    },
  },
  {
    id: 7,
    file: 'shot6_screen.png',
    accent: '#00AEEF',
    tone: 'blue',
    phoneScale: 1.04,
    phoneOffsetY: 10,
    nav: 'YouTube Form',
    copy: {
      ja: {
        eyebrow: 'YouTube Form',
        headline: '迷ったフォームは、\nすぐ動画。',
        sub: '種目名でYouTube検索へ。',
        chips: ['フォーム確認', 'YouTube検索', '時短'],
      },
      en: {
        eyebrow: 'YouTube Form',
        headline: 'Check form\non YouTube.',
        sub: 'Jump to videos by exercise name.',
        chips: ['Form check', 'YouTube search', 'Fast'],
      },
      zh: {
        eyebrow: 'YouTube动作',
        headline: '马上确认\n动作姿势。',
        sub: '用动作名称跳转到视频搜索。',
        chips: ['姿势确认', 'YouTube搜索', '省时'],
      },
      ko: {
        eyebrow: 'YouTube 폼',
        headline: '폼을 바로\n확인하세요.',
        sub: '종목명으로 영상 검색에 바로 이동합니다.',
        chips: ['폼 확인', 'YouTube 검색', '빠르게'],
      },
      es: {
        eyebrow: 'Forma en YouTube',
        headline: 'Revisa la forma\nen YouTube.',
        sub: 'Salta a videos por nombre del ejercicio.',
        chips: ['Forma', 'YouTube', 'Rápido'],
      },
      de: {
        eyebrow: 'YouTube-Form',
        headline: 'Form direkt\nprüfen.',
        sub: 'Mit dem Übungsnamen zu Videos springen.',
        chips: ['Form', 'YouTube', 'Schnell'],
      },
      fr: {
        eyebrow: 'Forme YouTube',
        headline: 'Vérifiez le geste\nsur YouTube.',
        sub: 'Accédez aux vidéos par nom d’exercice.',
        chips: ['Forme', 'YouTube', 'Rapide'],
      },
    },
  },
  {
    id: 8,
    file: 'shot3_screen.png',
    accent: '#00C77B',
    tone: 'mint',
    phoneScale: 1.045,
    phoneOffsetY: 8,
    nav: 'Share Card',
    copy: {
      ja: {
        eyebrow: 'Share Card',
        headline: '成果を一枚で、\nきれいに共有。',
        sub: 'ワークアウトを一枚のカードに。',
        chips: ['共有', '達成記録', 'カード生成'],
      },
      en: {
        eyebrow: 'Share Card',
        headline: 'Share today’s\nworkout.',
        sub: 'Turn progress into one clean card.',
        chips: ['Share', 'Achievement', 'Card'],
      },
      zh: {
        eyebrow: '分享卡片',
        headline: '分享今天的\n训练成果。',
        sub: '把成果整理成一张卡片。',
        chips: ['分享', '成果', '卡片'],
      },
      ko: {
        eyebrow: '공유 카드',
        headline: '오늘의 운동을\n공유하세요.',
        sub: '성과를 하나의 카드로 남깁니다.',
        chips: ['공유', '성과', '카드'],
      },
      es: {
        eyebrow: 'Tarjeta para compartir',
        headline: 'Comparte tu\nentrenamiento.',
        sub: 'Convierte el progreso en una tarjeta.',
        chips: ['Compartir', 'Logro', 'Tarjeta'],
      },
      de: {
        eyebrow: 'Share Card',
        headline: 'Training heute\nteilen.',
        sub: 'Fortschritt als klare Karte speichern.',
        chips: ['Teilen', 'Erfolg', 'Karte'],
      },
      fr: {
        eyebrow: 'Carte de partage',
        headline: 'Partagez votre\nséance du jour.',
        sub: 'Transformez vos progrès en carte.',
        chips: ['Partager', 'Réussite', 'Carte'],
      },
    },
  },
  {
    id: 9,
    file: 'shot1_screen.png',
    accent: '#00B86B',
    tone: 'green',
    phoneScale: 1.045,
    phoneOffsetY: 12,
    nav: 'Body Conquest',
    copy: {
      ja: {
        eyebrow: 'Body Conquest',
        headline: '鍛えた部位が、\nひと目で残る。',
        sub: '鍛えた部位がひと目でわかる。',
        chips: ['全身進捗', '部位マップ', '継続'],
      },
      en: {
        eyebrow: 'Body Conquest',
        headline: 'One muscle\nat a time.',
        sub: 'Visualize your full-body progress.',
        chips: ['Full body', 'Muscle map', 'Progress'],
      },
      zh: {
        eyebrow: '全身进度',
        headline: '全身，\n一步一步完成。',
        sub: '可视化你的全身进度。',
        chips: ['全身', '肌肉地图', '进度'],
      },
      ko: {
        eyebrow: '전신 정복',
        headline: '전신을\n하나씩 채우세요.',
        sub: '진행 상황을 시각화합니다.',
        chips: ['전신', '근육 맵', '진행'],
      },
      es: {
        eyebrow: 'Cuerpo completo',
        headline: 'Todo el cuerpo,\npaso a paso.',
        sub: 'Visualiza tu progreso corporal.',
        chips: ['Cuerpo', 'Mapa', 'Progreso'],
      },
      de: {
        eyebrow: 'Body Conquest',
        headline: 'Den ganzen Körper,\nSchritt für Schritt.',
        sub: 'Mach deinen Fortschritt sichtbar.',
        chips: ['Ganzkörper', 'Muskelkarte', 'Fortschritt'],
      },
      fr: {
        eyebrow: 'Corps complet',
        headline: 'Tout le corps,\nétape par étape.',
        sub: 'Visualisez votre progression.',
        chips: ['Corps', 'Carte', 'Progression'],
      },
    },
  },
];

export type TitleCatalogEntry = {
  id: string;
  name: string;
  description: string;
  condition: string;
  fromGacha: boolean; // ガチャで獲得可能か
};

export const TITLE_CATALOG: readonly TitleCatalogEntry[] = [
  // ========== ガチャから獲得可能な称号 ==========
  {
    id: "title_beginner",
    name: "初心者",
    description: "悪魔的しりとりの世界へようこそ",
    condition: "ガチャで獲得",
    fromGacha: true,
  },
  {
    id: "title_demon_lover",
    name: "悪魔愛好家",
    description: "悪魔を愛する者",
    condition: "ガチャで獲得",
    fromGacha: true,
  },
  {
    id: "title_word_master",
    name: "言霊使い",
    description: "言葉に宿る力を操る者",
    condition: "ガチャで獲得",
    fromGacha: true,
  },

  // ========== 条件達成で獲得する称号 ==========
  // レート系
  {
    id: "title_rating_1500",
    name: "強者",
    description: "レート1500に到達した証",
    condition: "レートが1500になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_rating_2000",
    name: "圧倒的猛者",
    description: "レート2000に到達した証",
    condition: "レートが2000になった際に獲得",
    fromGacha: false,
  },

  // 連敗系
  {
    id: "title_lose_streak_3",
    name: "めげない強さ",
    description: "3連敗しても立ち上がる者",
    condition: "3連敗した際に獲得",
    fromGacha: false,
  },

  // 魂系
  {
    id: "title_soul_eater",
    name: "ソウルイーター",
    description: "魂を使い果たした者",
    condition: "魂が残り0になった際に獲得",
    fromGacha: false,
  },

  // ガチャ回数系
  {
    id: "title_gacha_3",
    name: "〜ビギナー召喚者〜",
    description: "ガチャを3回回した者",
    condition: "ガチャを回した回数が3回になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_gacha_10",
    name: "〜中堅召喚者〜",
    description: "ガチャを10回回した者",
    condition: "ガチャを回した回数が10回になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_gacha_50",
    name: "〜ベテラン召喚者〜",
    description: "ガチャを50回回した者",
    condition: "ガチャを回した回数が50回になった際に獲得",
    fromGacha: false,
  },

  // ログイン系
  {
    id: "title_login_7days",
    name: "ずっといるよ",
    description: "連続7日間ログインした者",
    condition: "連続7日間ログインした際に獲得",
    fromGacha: false,
  },

  // コイン系
  {
    id: "title_coins_20",
    name: "ちょっとお金持ち",
    description: "コインを20枚保有した者",
    condition: "保有コインが20枚になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_coins_50",
    name: "割とお金持ち",
    description: "コインを50枚保有した者",
    condition: "保有コインが50枚になった際に獲得",
    fromGacha: false,
  },

  // 連勝系
  {
    id: "title_win_streak_3",
    name: "3連勝者",
    description: "3連勝を達成した者",
    condition: "3連勝した際に獲得",
    fromGacha: false,
  },
  {
    id: "title_win_streak_5",
    name: "5連勝者",
    description: "5連勝を達成した者",
    condition: "5連勝した際に獲得",
    fromGacha: false,
  },
  {
    id: "title_win_streak_10",
    name: "10連勝者",
    description: "10連勝を達成した者",
    condition: "10連勝した際に獲得",
    fromGacha: false,
  },

  // 累計勝利系
  {
    id: "title_total_wins_10",
    name: "累計勝利10回クリア済み",
    description: "累計10回の勝利を達成した者",
    condition: "累計勝利数が10回になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_total_wins_20",
    name: "累計勝利20回クリア済み",
    description: "累計20回の勝利を達成した者",
    condition: "累計勝利数が20回になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_total_wins_30",
    name: "累計勝利30回クリア済み",
    description: "累計30回の勝利を達成した者",
    condition: "累計勝利数が30回になった際に獲得",
    fromGacha: false,
  },
  {
    id: "title_total_wins_50",
    name: "累計勝利50回クリア済み",
    description: "累計50回の勝利を達成した者",
    condition: "累計勝利数が50回になった際に獲得",
    fromGacha: false,
  },

  // AI対戦系
  {
    id: "title_ai_match_10",
    name: "累計AI対戦10回クリア済み",
    description: "AIと10回対戦した者",
    condition: "累計AI対戦数が10回になった際に獲得",
    fromGacha: false,
  },

  // 特殊勝利
  {
    id: "title_loose_transcender",
    name: "るーずを超越した者",
    description: "「ず」「る」「ー」全てを取られても勝利した者",
    condition: "相手に「ず、る、ー」全てを取られて勝利した際に獲得",
    fromGacha: false,
  },

  // コンプ率系
  {
    id: "title_completion_90",
    name: "我、不足なし",
    description: "全てのコンプ率が90%を超えた者",
    condition:
      "全てのコンプ率（アイコン・称号・メッセージ）が90%を超えた際に獲得",
    fromGacha: false,
  },

  // 勝率系
  {
    id: "title_win_rate_90",
    name: "天才",
    description: "過去30戦で勝率90%を超えた者",
    condition: "過去30戦の勝率が90%を超えた際に獲得",
    fromGacha: false,
  },
  {
    id: "title_win_rate_95",
    name: "神",
    description: "過去30戦で勝率95%を超えた者",
    condition: "過去30戦の勝率が95%を超えた際に獲得",
    fromGacha: false,
  },

  // プレミアム系
  {
    id: "title_premium_subscriber",
    name: "リアルに金持ち",
    description: "プレミアムプランに加入した者",
    condition: "プレミアムプランに加入した際に獲得",
    fromGacha: false,
  },
] as const;

export const TITLE_IDS: readonly string[] = TITLE_CATALOG.map((x) => x.id);
export const GACHA_TITLE_IDS: readonly string[] = TITLE_CATALOG.filter(
  (x) => x.fromGacha,
).map((x) => x.id);

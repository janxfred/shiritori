export type MessageCatalogEntry = {
  id: string;
  content: string;
  condition: string;
  rarity: number;
};

export const MESSAGE_CATALOG: readonly MessageCatalogEntry[] = [
  // デフォルトメッセージ
  {
    id: "msg_default_01",
    content: "よろしくお願いします",
    condition: "デフォルト",
    rarity: 1,
  },

  // ガチャで獲得可能なメッセージ
  {
    id: "msg_gacha_01",
    content: "君の敗因はただひとつ……僕が相手だった事です",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_02",
    content: "堕ちろ、そして巡れ",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_03",
    content: "てめーの敗因は……たったひとつだぜ……『てめーはおれを怒らせた』",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_04",
    content: "この世は残酷なんだ",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_05",
    content: "戦わなければ勝てない",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_06",
    content: "お前さぁ…疲れてんだよ",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_07",
    content: "勝ちたい…！勝ちたい！！！",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_08",
    content: "君のようなカンのいいガキは嫌いだよ",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_09",
    content: "この称号が目に入らぬか！",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_10",
    content: "あまり強い言葉を遣うなよ。弱く見えるぞ",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_11",
    content: "私の戦闘力は53万です",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_12",
    content: "誇れ お前は強い",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_13",
    content: "分を弁えろ 痴れ者が",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_14",
    content: "勝者だけが正義だ!!!!",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_15",
    content: "所詮この世は弱肉強食 強ければ生き弱ければ死ぬ",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_16",
    content: "私に倒されることは大災に遭ったのと同じだと思え",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_17",
    content: "計画通り",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_18",
    content: "貴様は詰んでいたのだ 初めから",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_19",
    content: "さあ 絶望してくれるなよ",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_20",
    content: "よろしい ならば戦争だ",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_21",
    content: "お前も悪魔にならないか？",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_22",
    content: "私の語彙からは逃げられんよ",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_23",
    content: "私が天に立つ",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_24",
    content: "お前たちはただ 黙って私に負けていればいいんだ",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_25",
    content: "1000引く7は？",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_26",
    content: "君が何を信じていようと勝手だが…事実は一つだ。君は負ける",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_27",
    content: "お前も神にならないか？",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_28",
    content: "お前は金持ちにならないのか？",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_29",
    content: "わが語彙に一片の悔いなし!!",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_30",
    content: "お前は今まで食ったパンの枚数を覚えているのか？",
    condition: "ガチャで獲得",
    rarity: 3,
  },
  {
    id: "msg_gacha_31",
    content: "狡猾にいこう、悪魔らしく。",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_32",
    content: "初めまして。そしてさようなら。",
    condition: "ガチャで獲得",
    rarity: 2,
  },
  {
    id: "msg_gacha_33",
    content: "悪魔風情が。",
    condition: "ガチャで獲得",
    rarity: 2,
  },
] as const;

export const MESSAGE_IDS: readonly string[] = MESSAGE_CATALOG.map((x) => x.id);

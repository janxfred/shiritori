import { DEFAULT_ICON_URL } from "./asset_url";

export type IconCatalogEntry = {
  id: string;
  imageUrl: string;
  rarity: number;
  staticFileName: string;
};

export const ICON_CATALOG: readonly IconCatalogEntry[] = [
  {
    id: "default_demon",
    imageUrl: DEFAULT_ICON_URL,
    rarity: 1,
    staticFileName: "default_demon.jpg",
  },
  {
    id: "demon_black_red",
    imageUrl: "/static/demon_black_red.png",
    rarity: 1,
    staticFileName: "demon_black_red.png",
  },
  {
    id: "demon_white_gold",
    imageUrl: "/static/demon_white_gold.png",
    rarity: 1,
    staticFileName: "demon_white_gold.png",
  },
  {
    id: "demon_white_green",
    imageUrl: "/static/demon_white_green.png",
    rarity: 1,
    staticFileName: "demon_white_green.png",
  },
  {
    id: "demon_white_blue",
    imageUrl: "/static/demon_white_blue.png",
    rarity: 1,
    staticFileName: "demon_white_blue.png",
  },
  {
    id: "demon_white_gray_horn",
    imageUrl: "/static/demon_white_gray_horn.png",
    rarity: 1,
    staticFileName: "demon_white_gray_horn.png",
  },
] as const;

export const ICON_IDS: readonly string[] = ICON_CATALOG.map((x) => x.id);
export const STATIC_ICON_FILE_NAMES: readonly string[] = ICON_CATALOG.map(
  (x) => x.staticFileName
);

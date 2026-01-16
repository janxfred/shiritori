export const DEFAULT_ICON_URL = "/static/default_demon.jpg";

export function normalizeIconImageUrl(imageUrl: string): string {
  if (imageUrl.startsWith("https://example.com/")) {
    return DEFAULT_ICON_URL;
  }
  return imageUrl;
}

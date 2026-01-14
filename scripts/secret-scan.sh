#!/usr/bin/env bash
set -euo pipefail

# Fail if google-services.json is tracked
if git ls-files | grep -qE '(^|/)google-services\.json$'; then
  echo "ERROR: google-services.json が Git で追跡されています。" >&2
  echo "       このリポジトリでは google-services.json はコミット禁止です。" >&2
  exit 1
fi

# Fail if likely Google API key is present in tracked files
matches="$(git grep -n -I -E 'AIzaSy[0-9A-Za-z_\-]{30,}' || true)"
if [[ -n "$matches" ]]; then
  echo "ERROR: リポジトリ内に Google API キーらしき文字列（AIzaSy...）が検出されました。" >&2
  echo "$matches" >&2
  exit 1
fi

echo "OK: 既知パターンの機密は検出されませんでした。"

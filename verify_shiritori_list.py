#!/usr/bin/env python3
import json

# 修正後のファイルを読み込み
with open('shiritori_list.json', 'r', encoding='utf-8') as f:
    words = json.load(f)

# 不適切な語句が残っていないかチェック
problematic = []
brands = ['ぐーぐる', 'あまぞん', 'いんすたぐらむ', 'あっぷる', 'まくどなるど']
for brand in brands:
    if brand in words:
        problematic.append(brand)

if problematic:
    print(f'警告: 以下の不適切な語句が残っています: {problematic}')
else:
    print('✓ 主要な不適切語句は全て削除されています')

# 追加した語句が含まれているか確認
added = ['かんがるー', 'ゆり', 'ぎょうざ', 'しゅうまい']
missing = []
for word in added:
    if word not in words:
        missing.append(word)

if missing:
    print(f'警告: 以下の追加予定語句が見つかりません: {missing}')
else:
    print('✓ 追加した語句が全て含まれています')

print(f'\n最終統計:')
print(f'  総語数: {len(words):,} 語')
print(f'  重複: {len(words) - len(set(words))} 語')
print(f'  ソート済み: {"はい" if words == sorted(words) else "いいえ"}')

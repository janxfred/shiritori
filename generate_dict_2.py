import json
import jaconv
import re
from sudachipy import Dictionary
from wordfreq import top_n_list

def generate_shiritori_by_lookup():
    # 1. Sudachiの準備
    # Dictionaryを直接生成。lookupはここから呼び出す
    dic = Dictionary(dict="core") 
    
    # 日本語の頻出上位5万語をターゲットにする（これだけで十分な語彙になります）
    TARGET_WORDS = top_n_list('ja', 50000)
    
    # 除外条件
    EXCLUDED_SUB_POS = {'人名', '代名詞', '数詞', '非自立', '形状詞可能', '副詞可能'}
    hiragana_re = re.compile(r'^[ぁ-んー]{1,13}$')

    word_candidates = {}

    print(f"頻出語 {len(TARGET_WORDS)} 件をSudachiで検証中...")

    for surface in TARGET_WORDS:
        # --- ここがポイント: 辞書から直接引く ---
        # lookupは単語の全エントリをリストで返します
        results = dic.lookup(surface)
        if not results: continue

        # 最も一般的なエントリ（通常は最初）を採用
        word_info = results[0]
        pos = word_info.part_of_speech()

        # A. 品詞フィルタ
        if pos[0] != '名詞': continue
        if pos[1] == '固有名詞' and pos[2] == '人名': continue
        if any(sub in pos for sub in EXCLUDED_SUB_POS): continue

        # B. 読みとルールの適用
        reading = jaconv.kata2hira(word_info.reading_form())
        if not hiragana_re.match(reading): continue
        if reading.endswith('ん') or reading.endswith('ー'): continue

        # C. 登録（読みをキーにして表記揺れを排除）
        if reading not in word_candidates:
            word_candidates[reading] = reading

    # 保存
    final_list = sorted(list(word_candidates.values()))
    with open('shiritori_list.json', 'w', encoding='utf-8') as f:
        json.dump(final_list, f, ensure_ascii=False, indent=2)

    print(f"完了: {len(final_list)}件を抽出しました。")

if __name__ == "__main__":
    generate_shiritori_by_lookup()
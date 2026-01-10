import json
import jaconv
import re
import sqlite3
import os
from jamdict import Jamdict

def generate_demon_shiritori_dict():
    jam = Jamdict()
    db_path = jam.jmdict.path
    
    if not os.path.exists(db_path):
        print("辞書データを準備中...")
        jam.lookup('しりとり')
        db_path = jam.jmdict.path
    
    print(f"辞書ソース(SQLite)に接続: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # カラム名を 'value' から 'text' に修正
    query = """
    SELECT DISTINCT k.text, g.text
    FROM Kana k
    JOIN Sense s ON k.entry_id = s.entry_id
    JOIN pos sp ON s.id = sp.sense_id
    JOIN SenseGloss g ON s.id = g.sense_id
    WHERE sp.text = 'n' 
       OR (sp.text = 'n-pr' AND (g.text LIKE '%place%' OR g.text LIKE '%station%' OR g.text LIKE '%building%' OR g.text LIKE '%city%'))
    """

    print("MySQL用データの抽出を開始...")
    try:
        cursor.execute(query)
        rows = cursor.fetchall()
    except sqlite3.OperationalError as e:
        print(f"クエリ実行エラー: {e}")
        conn.close()
        return

    word_list = []
    seen_words = set()
    hiragana_re = re.compile(r'^[ぁ-んー]+$')

    for kana_text, gloss in rows:
        word = jaconv.kata2hira(kana_text)
        
        # 基本ルール: ひらがなのみ [cite: 23]
        if not hiragana_re.match(word): continue
        # ルールA: 「ん」で終わる単語は除外 
        if word.endswith('ん'): continue 
            
        if word not in seen_words:
            word_list.append({"word": word})
            seen_words.add(word)

    conn.close()

    # プロジェクトのルートに出力
    output_path = '../dictionary.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(word_list, f, ensure_ascii=False, indent=2)
    
    print(f"成功: {len(word_list)}件の名詞を {output_path} に生成しました。")

if __name__ == "__main__":
    generate_demon_shiritori_dict()
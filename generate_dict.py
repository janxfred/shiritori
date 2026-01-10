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

    # idseq で Entry, Kana, Sense を結合
    # 名詞系の品詞を抽出（固有名詞は人名を除く地名・建物のみ許可）
    query = """
    SELECT DISTINCT k.text
    FROM Kana k
    JOIN Sense s ON k.idseq = s.idseq
    JOIN pos p ON s.ID = p.sid
    WHERE p.text = 'noun (common) (futsuumeishi)'
       OR p.text = 'noun or participle which takes the aux. verb suru'
       OR p.text = 'noun, used as a prefix'
       OR p.text = 'noun, used as a suffix'
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

    for (kana_text,) in rows:
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
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, 'dictionary.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(word_list, f, ensure_ascii=False, indent=2)
    
    print(f"成功: {len(word_list)}件の名詞を {output_path} に生成しました。")

if __name__ == "__main__":
    generate_demon_shiritori_dict()
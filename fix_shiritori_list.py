#!/usr/bin/env python3
"""
しりとりリストの修正スクリプト
不適切な語句を削除し、適切な一般名詞を追加する
"""
import json
import re

# 削除すべき語句のパターン
# 商品名・企業名
BRAND_NAMES = {
    "あっぷる",  # Apple製品・ブランド名として認識される可能性
    "あっぷるぱい",  # アップルパイは一般名詞だが、Appleとの混同を避ける
    "ぐーぐる", "あまぞん", "いんすたぐらむ", "ふぇいすぶっく",
    "まいくろそふと", "やふー", "らいん", "ついったー", "ゆーちゅーぶ",
    "ぐりこ", "といざらす", "まくどなるど", "すたーばっくす",
    "ぞぞ",  # ZOZOは企業名
    "さふぁり",  # Safari（ブラウザ名）
    "えくせる",  # Excel（ソフトウェア名）
    "わーど",  # Word（ソフトウェア名として認識されやすい）
    "おふぃす",  # Office（ソフトウェア名として認識されやすい）
    "こかこーら", "ぺぷし", "けんたっきー",  # 飲食ブランド
    "びっぐろーぶ",  # BIGLOBE（企業名）
}

# 人名・キャラクター名（明らかな固有名詞）
PERSON_NAMES = {
    "そんごくう",  # 孫悟空は架空の人物
    "あとむ",  # アトムは固有キャラ名（鉄腕アトム）
    "ぴのきお",  # ピノキオは固有キャラ名
}

# 地名でもマニアック過ぎるもの（一般的な都道府県名や有名都市は残す）
OBSCURE_PLACES = {
    "あぐい",  # 愛知県の小さな町
    "あぐり",  # マイナーな地名
    "いなしき",  # 茨城県の市（認知度が低い）
    "あざみの",  # あざみ野（固有の駅名・地名）
    "いさはや",  # 諫早（知名度が限定的）
    "びばりーひるず",  # Beverly Hills（外国の固有地名）
    "あきるの",  # 秋留野（東京の市だが知名度が低い）
}

# 略語・専門用語・IT用語
ABBREVIATIONS = {
    "あいでぃあ",  # idea（英語）
    "あいてむ",  # item（英語）
    "あいでんてぃてぃ",  # identity（専門用語）
    "あうぇい",  # away（英語）
    "あうとそーしんぐ",  # outsourcing（ビジネス専門用語）
    "あくせす",  # access（IT用語として専門的）
    "あぷり",  # アプリ（略語）
    "あるごりずむ",  # algorithm（専門用語）
}

# 動詞（しりとりには名詞が適切）
VERBS = {
    "あるく",  # 歩く
    # 「いく」は除外（幾という名詞もある）
}

# 不自然な外来語・カタカナ語・固有地名・複合語
UNNATURAL_KATAKANA = {
    # "あいしんぐ"は許可する
    # "あうとどあ"は許可する
    # "あうとれっと"は許可する
    "あとらんた",  # Atlanta（固有地名）
    "あとらんてぃす",  # Atlantis（伝説の地名）
    "あむすてるだむ",  # Amsterdam（固有地名）
    "あれくさんどりあ",  # Alexandria（固有地名）
    "あぬびす",  # アヌビス（エジプト神話の神）
    # "あしゅら"は許可する
    # "あぽろ"は許可する
    # "あづち"は許可する．義務教育で，時代の名前は習う．
}

# 略語・専門用語・IT用語
ABBREVIATIONS = {
    # "あいでぃあ"は許可する
    # "あいてむ"は許可する
    # "あいでんてぃてぃ"は許可する
    "あうぇい"
    # "あうとそーしんぐ"は許可する
    # "あくせす"は許可する
    # "あぷり"は許可する
    # "あるごりずむ"は許可する
}

# 動詞（しりとりには名詞が適切）
VERBS = {
    "あるく",  # 歩く
    # 「いく」は除外（幾という名詞もある）
}

# 不自然な外来語・カタカナ語・固有地名
UNNATURAL_KATAKANA = {
    "あとらんた",  # Atlanta（固有地名）
    "あとらんてぃす",  # Atlantis（伝説の地名）
    "あむすてるだむ",  # Amsterdam（固有地名）
    "あれくさんどりあ",  # Alexandria（固有地名）
}

# 追加すべき一般的な名詞（既存リストに無い場合のみ追加）
COMMON_NOUNS_TO_ADD = [
    # 基本的な動物
    "うさぎ",
    "おおかみ",
    "かえる",
    "きつね",
    "くま",
    "さる",
    "しか",
    "たぬき",
    "ねこ",
    "ねずみ",
    "ひつじ",
    "ぶた",
    "やぎ",
    "わに",
    "とら",
    "ぞう",
    "かば",
    "さい",
    "しまうま",
    "ちーたー",
    "ごりら",
    "ぱんだ",
    "こあら",
    "かんがるー",
    "らっこ",
    "あざらし",  # 既存確認必要
    "いるか",  # 既存確認必要
    
    # 基本的な鳥類
    "からす",
    "すずめ",
    "つばめ",
    "はと",
    "わし",
    "たか",
    "ふくろう",
    "つる",
    "こうのとり",
    
    # 基本的な海の生物
    "たこ",
    "いか",  # 既存確認必要
    "えび",
    "かに",
    "ひとで",
    "くらげ",
    "さめ",
    "まぐろ",
    "さけ",
    "さば",
    
    # 基本的な昆虫
    "かぶとむし",
    "くわがた",
    "ちょう",
    "とんぼ",
    "ばった",
    "かまきり",
    "せみ",
    "ほたる",
    "てんとうむし",
    
    # 基本的な植物・花
    "きく",
    "すみれ",
    "たんぽぽ",
    "ばら",
    "ひまわり",
    "ゆり",
    "さくら",
    "つつじ",
    "あじさい",  # 既存確認必要
    "こすもす",
    "ちゅーりっぷ",
    
    # 基本的な樹木
    "まつ",
    "すぎ",
    "けやき",
    "くすのき",
    "いちょう",  # 既存確認必要
    "もみじ",
    
    # 基本的な野菜
    "きゃべつ",
    "はくさい",
    "にんじん",
    "たまねぎ",
    "じゃがいも",
    "とまと",
    "きゅうり",
    "なす",
    "ほうれんそう",
    "ねぎ",
    "かぼちゃ",
    "れたす",
    "ぶろっこりー",
    
    # 基本的な果物
    "りんご",
    "ばなな",
    "ぶどう",
    "いちご",  # 既存確認必要
    "すいか",
    "もも",
    "なし",
    "かき",
    "さくらんぼ",
    "ぱいなっぷる",
    "まんごー",
    "きうい",
    
    # 基本的な食べ物
    "おにぎり",
    "かれー",
    "すし",
    "てんぷら",
    "そば",
    "やきそば",
    "おこのみやき",
    "たこやき",
    "ぎょうざ",
    "しゅうまい",
    "はんばーぐ",
    "おむれつ",
    "さらだ",
    "すーぷ",
    "さんどいっち",
    "ぴざ",  # 既存確認必要
    "すぱげってぃ",
    "しちゅー",
    
    # 基本的な飲み物
    "みず",
    "おちゃ",
    "こーひー",
    "こーら",
    "じゅーす",
    "みるく",
    
    # 基本的な日用品
    "かがみ",
    "かさ",
    "くし",
    "たおる",
    "はし",
    "ふで",
    "ほうき",
    "ばけつ",
    "はぶらし",
    "はみがきこ",
    "しゃんぷー",
    "りんす",
    "てぃっしゅ",
    
    # 基本的な文房具
    "えんぴつ",
    "けしごむ",  # 既存確認必要
    "のーと",
    "ふでばこ",
    "はさみ",
    "のり",
    "ほっちきす",
    "えのぐ",
    
    # 基本的な衣類
    "ようふく",
    "しゃつ",
    "ずぼん",
    "すかーと",
    "せーたー",
    "こーと",
    "じゃけっと",
    "くつ",
    "くつした",
    "ぼうし",
    "てぶくろ",
    "まふらー",
    
    # 基本的な自然・気象
    "かみなり",
    "くも",
    "たいよう",  # 既存確認必要
    "つき",
    "ほし",
    "やま",
    "かわ",
    "うみ",
    "みずうみ",
    "もり",
    "そら",
    "つち",
    "いし",
    "すな",
    "こおり",
    "ゆき",
    "あめ",  # 既存確認必要
    "かぜ",
    "にじ",
    "くもり",
    "はれ",
    
    # 基本的な身体部位
    "からだ",
    "あたま",  # 既存確認必要
    "かお",
    "め",
    "はな",  # 既存確認必要
    "みみ",
    "くち",
    "は",
    "した",
    "くび",
    "かた",
    "うで",
    "て",  # 既存確認必要
    "ゆび",
    "つめ",
    "むね",
    "おなか",
    "せなか",
    "こし",
    "あし",  # 既存確認必要
    "ひざ",
    
    # 基本的な場所・建物
    "いえ",  # 既存確認必要
    "へや",
    "まど",
    "どあ",
    "やね",
    "にわ",
    "がっこう",
    "きょうしつ",
    "えき",
    "くうこう",
    "ぎんこう",
    "ゆうびんきょく",
    "こうばん",
    "しょうぼうしょ",
    "すーぱー",
    "こんびに",
    "かふぇ",
    "ほてる",
    
    # 基本的な乗り物
    "じどうしゃ",
    "でんしゃ",
    "ばす",
    "たくしー",
    "じてんしゃ",
    "おーとばい",
    "ひこうき",
    "へりこぷたー",
    "ふね",
    "ふぇりー",
    "ろけっと",
    
    # 基本的な色
    "いろ",  # 既存確認必要
    "あか",  # 既存確認必要
    "あお",  # 既存確認必要
    "みどり",
    "しろ",
    "くろ",
    "ちゃいろ",
    "おれんじ",
    "むらさき",
    "ぴんく",
    
    # 基本的な時間・季節
    "あさ",  # 既存確認必要
    "ひる",  # 既存確認必要
    "ゆうがた",
    "よる",
    "はる",
    "なつ",
    "あき",  # 既存確認必要
    "ふゆ",
    
    # 基本的な家族
    "かぞく",
    "ちち",
    "はは",
    "あに",  # 既存確認必要
    "あね",  # 既存確認必要
    "おとうと",
    "いもうと",  # 既存確認必要
    "そふ",
    "そぼ",
    "おじ",
    "おば",
    "まご",
    
    # 基本的な数字・単位
    "かず",
    "ばんごう",
    "めーとる",
    "きろ",
    "ぐらむ",
    "りっとる",
    
    # 基本的な感情・状態
    "きもち",
    "こころ",
    "あい",  # 既存確認必要
    "ゆめ",
    "きぼう",
    "しあわせ",
    "かなしみ",
    "いかり",
    "よろこび",
    "おどろき",
    
    # 基本的な概念
    "ばしょ",
    "なまえ",
    "かたち",
    "おおきさ",
    "おもさ",
    "ながさ",
    "ひろさ",
    "たかさ",
]

def load_shiritori_list(filepath):
    """しりとりリストを読み込む"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_shiritori_list(filepath, word_list):
    """しりとりリストを保存する"""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(word_list, f, ensure_ascii=False, indent=2)

def should_remove(word):
    """語句を削除すべきかどうか判定"""
    if word in BRAND_NAMES:
        return True, "商品名・企業名"
    if word in PERSON_NAMES:
        return True, "人名・キャラクター名"
    if word in OBSCURE_PLACES:
        return True, "マニアックな地名"
    if word in ABBREVIATIONS:
        return True, "略語"
    if word in VERBS:
        return True, "動詞"
    if word in UNNATURAL_KATAKANA:
        return True, "不自然な外来語"
    
    return False, None

def fix_shiritori_list(input_file, output_file):
    """しりとりリストを修正"""
    print(f"読み込み中: {input_file}")
    word_list = load_shiritori_list(input_file)
    print(f"元のリスト: {len(word_list)} 語")
    
    # 重複チェック
    from collections import Counter
    counter = Counter(word_list)
    duplicates = {word: count for word, count in counter.items() if count > 1}
    if duplicates:
        print(f"\n重複を検出: {len(duplicates)} 種類、{sum(count - 1 for count in duplicates.values())} 個の重複")
        for word, count in sorted(duplicates.items())[:10]:
            print(f"  {word}: {count}回")
        if len(duplicates) > 10:
            print(f"  ... 他 {len(duplicates) - 10} 件")
    
    # 削除する語句のログ
    removed_words = []
    
    # フィルタリング（重複も除去）
    seen = set()
    filtered_list = []
    for word in word_list:
        # 重複チェック
        if word in seen:
            removed_words.append((word, "重複"))
            continue
        seen.add(word)
        
        # 不適切な語句チェック
        should_rm, reason = should_remove(word)
        if should_rm:
            removed_words.append((word, reason))
            print(f"削除: {word} ({reason})")
        else:
            filtered_list.append(word)
    
    print(f"\n削除した語句: {len(removed_words)} 語")
    
    # 追加する語句
    added_words = []
    for word in COMMON_NOUNS_TO_ADD:
        if word not in filtered_list:
            filtered_list.append(word)
            added_words.append(word)
            print(f"追加: {word}")
    
    print(f"\n追加した語句: {len(added_words)} 語")
    
    # ソート（ひらがな順）
    filtered_list.sort()
    
    print(f"修正後のリスト: {len(filtered_list)} 語")
    
    # 保存
    save_shiritori_list(output_file, filtered_list)
    print(f"\n保存完了: {output_file}")
    
    # サマリー
    print("\n=== 修正サマリー ===")
    print(f"元の語句数: {len(word_list)}")
    print(f"削除: {len(removed_words)}")
    print(f"  - 重複: {sum(1 for _, r in removed_words if r == '重複')}")
    print(f"  - 不適切: {sum(1 for _, r in removed_words if r != '重複')}")
    print(f"追加: {len(added_words)}")
    print(f"最終: {len(filtered_list)}")
    
    return filtered_list, removed_words, added_words

if __name__ == "__main__":
    input_file = "shiritori_list.json"
    output_file = "shiritori_list_fixed.json"
    
    fix_shiritori_list(input_file, output_file)

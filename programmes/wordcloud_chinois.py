import os
import re
from wordcloud import WordCloud
import matplotlib.pyplot as plt

input_file = "pals/resultats_chinois_pals.tsv"
output_dir = "wordcloud"
output_image = os.path.join(output_dir, "nuage_chinois.png")
font_path = "/System/Library/Fonts/STHeiti Light.ttc"

STOPWORDS = {"的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "个", "这", "那", "之", "与", "于", "及", "而", "以", "等", "为", "从", "自", "向", "往", "被", "把", "让", "给", "所", "者", "并", "且", "更", "而", "又", "也", "已", "再", "就", "但", "却", "因", "故", "由于", "所以", "如果", "虽然", "但是", "然而", "比如", "例如", "及其",

    "这个", "那个", "这些", "那些", "这样", "那样", "怎样", "怎么", "什么", "哪里", "哪个", "哪些", "其", "自己", "别人", "大家", "各位", "左右", "这种", "某种", "有些", "有些", "甚至", "不仅", "不但", "即使", "即便",

    "非常", "十分", "极其", "特别", "相当", "稍微", "有点", "几乎", "全部", "所有", "一切", "已经", "能够", "通过", "进行", "作为", "目前", "此时", "因此", "因此", "从而", "确实", "确实", "其实", "似乎", "所谓", "既然", "虽然", "确实", "确确实实", "容易", "突然", "依然", "依然", "一直", "曾经", "正在", "已经",

    "出现", "存在", "产生", "进行", "关于", "对于", "由于", "针对", "采用", "提供", "导致", "说明", "具有", "如下", "如下", "如图", "如图", "显示", "表明", "上述", "如下", "如图", "部分", "很多", "许多", "不少", "一点", "一些","为什么","有关","二十","有关"
}

def is_clean_chinese(text):

    if len(text) < 2:
        return False
    if not re.match(r'^[\u4e00-\u9fa5]+$', text):
        return False
    if text in STOPWORDS:
        return False
    return True

print(f"Nettoyage et lecture de : {input_file}")

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

word_scores = {}

try:
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        header_idx = -1
        for i, line in enumerate(lines):
            if "token" in line and "specificity" in line:
                header_idx = i
                break

        if header_idx != -1:
            for line in lines[header_idx + 1:]:
                parts = line.strip().split('\t')
                if len(parts) >= 6:
                    token = parts[0]
                    # 应用我们的强力清洗逻辑
                    if is_clean_chinese(token):
                        try:
                            score = float(parts[5])
                            if score > 0:
                                word_scores[token] = score
                        except ValueError:
                            continue

    if word_scores:
        print(f"Génération du nuage épuré : {output_image}")
        wc = WordCloud(
            font_path=font_path,
            width=1200, height=800,
            background_color='white',
            max_words=80,
            colormap='Dark2'
        ).generate_from_frequencies(word_scores)

        wc.to_file(output_image)
        print("Succès ! Le nuage est propre.")

        plt.figure(figsize=(12, 8))
        plt.imshow(wc, interpolation='bilinear')
        plt.axis("off")
        plt.show()
    else:
        print("Erreur : Aucun mot significatif n'a survécu au filtrage.")

except Exception as e:
    print(f"Erreur : {e}")

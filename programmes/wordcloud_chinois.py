import os
import re
from wordcloud import WordCloud
import matplotlib.pyplot as plt

input_file = "pals/resultats_chinois_pals.tsv"
output_dir = "wordcloud"
output_image = os.path.join(output_dir, "nuage_chinois.png")
font_path = "/System/Library/Fonts/STHeiti Light.ttc"

STOPWORDS = {"这个", "这种", "没有", "其实", "为什么", "怎么", "就是",
    "既然", "似乎", "所谓", "虽然", "确实", "可以", "容易", "这种", "这个"}

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

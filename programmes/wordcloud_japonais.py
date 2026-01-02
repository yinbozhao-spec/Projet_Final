import os
import glob
import re
from bs4 import BeautifulSoup
from wordcloud import WordCloud
import MeCab
import numpy as np
from PIL import Image

CONC_DIR = "concordance"

files = glob.glob(os.path.join(CONC_DIR, "*.html"))

if not files:
    print("Aucun fichier de concordance trouvé")
    exit(1)

texts = []

for file in files:
    with open(file, encoding="utf-8") as f:
        soup = BeautifulSoup(f, "html.parser")

        text = soup.get_text(separator=" ")

        text = re.sub(r"\s+", " ", text)
        text = re.sub(r"[0-9a-zA-Z]", "", text)  # enlever romaji / chiffres
        texts.append(text)

full_text = " ".join(texts)

tagger = MeCab.Tagger("-Owakati")
wakati_text = tagger.parse(full_text)

stopwords = {
     "さん","鬼", "おに", "オニ", "oni", "Oni", "ONI"
    'の', 'に', 'は', 'を', 'が', 'と', 'で', 'も', 'から', 'まで', 'へ', 'や',
    'より', 'か', 'ね', 'よ', 'な', 'だ', 'です', 'ます', 'た', 'て', 'い',
    'する', 'ある', 'いる', 'なる', 'れる', 'られる', 'せる', 'させる',
    'こと', 'もの', 'ため', 'よう', 'そう', 'ところ', 'これ', 'それ', 'あれ',
    'この', 'その', 'あの', 'ここ', 'そこ', 'あそこ', 'どこ', 'だれ', 'なに', 'など', 'たち', 'まし'
}

filtered_words = [
    w for w in wakati_text.split()
    if w not in stopwords and len(w) > 1
]

final_text = " ".join(filtered_words)
mask = np.array(Image.open("oni_mask.png"))
mask = 255 - mask

wc = WordCloud(
    font_path="NotoSansCJK-Bold.ttc",
    background_color="black",
    mask=mask,
    width=2000,
    height=2000,
    max_words=500,
    contour_width=2,
    contour_color="black"
)
wc.generate(final_text)
wc.to_file("wordcloud_oni.png")

print("Nuage de mots généré : wordcloud_oni.png")

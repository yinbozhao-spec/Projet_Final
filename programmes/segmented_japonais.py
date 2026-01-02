import MeCab
import os
import re

STOPWORDS = {
   'の', 'に', 'は', 'を', 'が', 'と', 'で', 'も', 'から', 'まで', 'へ', 'や',
    'より', 'か', 'ね', 'よ', 'な', 'だ', 'です', 'た', 'て', 'い',
    'する', 'ある', 'いる', 'なる', 'れる', 'られる', 'せる', 'させる',
    'こと', 'もの', 'ため', 'よう', 'そう', 'ところ', 'これ', 'それ', 'あれ',
    'この', 'その', 'あの', 'ここ', 'そこ', 'あそこ', 'どこ', 'だれ', 'なに', 'など', 'オニ', 'し', 'さ'
}

tagger = MeCab.Tagger()
tagger.parse("")  # bug MeCab

INPUT_DIR = "dumps-text"
OUTPUT_DIR = "dumps-segmented"

os.makedirs(OUTPUT_DIR, exist_ok=True)

print("Segmentation japonaise (format cooccurrents.py)")

for filename in sorted(os.listdir(INPUT_DIR)):
    if not filename.endswith(".txt"):
        continue

    in_path = os.path.join(INPUT_DIR, filename)
    out_path = os.path.join(OUTPUT_DIR, filename.replace(".txt", "_seg.txt"))

    print(f"→ {filename}")

    with open(in_path, encoding="utf-8", errors="ignore") as fin, \
         open(out_path, "w", encoding="utf-8") as fout:

        for line in fin:
            line = line.strip()

            
            if not line:
                fout.write("\n")
                continue

            node = tagger.parseToNode(line)

            while node:
                surface = node.surface
                features = node.feature.split(",")

                pos = features[0]

                
                if pos in {"名詞", "動詞", "形容詞"}:
                    if surface and surface not in STOPWORDS:
                        fout.write(surface + "\n")

                node = node.next

            
            fout.write("\n")

print("Terminé : corpus prêt pour cooccurrents.py")


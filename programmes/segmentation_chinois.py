import thulac
import sys
import os

STOPWORDS = {
    "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个",
    "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看",
    "这", "那", "个", "与", "等", "及", "而", "及", "它", "之", "于", "之"
}

print("Chargement du modèle THULAC...")
thu = thulac.thulac(seg_only=True)

def segment_file(input_path, output_path):
    try:
        with open(input_path, 'r', encoding='utf-8', errors='ignore') as f, \
             open(output_path, 'w', encoding='utf-8') as out:
            for line in f:
                line = line.strip()
                if line:
                    segmented_line = thu.cut(line, text=True)
                    words = segmented_line.split()

                    filtered_words = [w for w in words if w not in STOPWORDS and len(w) > 0]

                    if filtered_words:
                        out.write("\n".join(filtered_words) + "\n\n")
    except Exception as e:
        print(f"Erreur sur {input_path}: {e}")

input_dir = "./dumps-text/"
output_dir = "./dumps-segmented/"

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

print("Début de la segmentation (avec filtrage des stopwords)...")
files = [f for f in os.listdir(input_dir) if f.endswith(".txt")]

for i, filename in enumerate(files, 1):
    input_path = os.path.join(input_dir, filename)

    file_id = filename.replace("chinois_", "").replace(".txt", "")
    new_filename = f"chinois_segmented_{file_id}.txt"

    output_path = os.path.join(output_dir, new_filename)

    print(f"[{i}/{len(files)}] {filename} -> {new_filename}")
    segment_file(input_path, output_path)

print("\nSegmentation terminée avec succès !")

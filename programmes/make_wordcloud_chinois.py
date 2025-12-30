import os
from wordcloud import WordCloud
import matplotlib.pyplot as plt

# 1. Configuration des fichiers
file_path = "resultats_pals.tsv"
output_image = "nuage_de_mots_chinois.png"
# Chemin de la police (Mac)
font = "/System/Library/Fonts/STHeiti Light.ttc"

print(f"Lecture des résultats depuis {file_path}...")

word_scores = {}

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        # On lit toutes les lignes
        lines = f.readlines()

        # On cherche la ligne qui contient les titres des colonnes
        start_index = -1
        for i, line in enumerate(lines):
            if "token" in line and "specificity" in line:
                start_index = i
                break

        if start_index == -1:
            print("Erreur : Impossible de trouver la ligne d'en-tête dans le fichier TSV.")
        else:
            # On parcourt les lignes APRÈS l'en-tête
            for line in lines[start_index + 1:]:
                parts = line.strip().split('\t')
                # Une ligne de données valide doit avoir au moins 6 colonnes
                if len(parts) >= 6:
                    token = parts[0]
                    try:
                        # La spécificité est dans la 6ème colonne (indice 5)
                        score = float(parts[5])
                        # On ne garde que les scores positifs et significatifs
                        if score > 0:
                            word_scores[token] = score
                    except ValueError:
                        continue

    if not word_scores:
        print("Erreur : Aucune donnée de spécificité trouvée.")
    else:
        # 2. Générer le nuage de mots
        print(f"Génération du nuage avec {len(word_scores)} mots...")
        wc = WordCloud(
            font_path=font,
            width=1000,
            height=700,
            background_color='white',
            max_words=100
        ).generate_from_frequencies(word_scores)

        # 3. Sauvegarder
        wc.to_file(output_image)
        print(f"Succès ! Le nuage de mots est enregistré : {output_image}")

        # 4. Affichage rapide
        plt.figure(figsize=(10, 7))
        plt.imshow(wc, interpolation='bilinear')
        plt.axis("off")
        plt.show()

except Exception as e:
    print(f"Une erreur est survenue : {e}")

import thulac
import sys
import os

# 1. Initialisation du segmenteur (uniquement segmentation, sans POS-tagging)
print("Chargement du modèle THULAC, veuillez patienter...")
thu = thulac.thulac(seg_only=True)

def segment_file(input_path, output_path):
    """
    Lit le texte brut, effectue la segmentation et convertit au format vertical pour PALS.
    """
    try:
        # Utilisation de errors='ignore' pour éviter les plantages dus aux caractères mal encodés
        with open(input_path, 'r', encoding='utf-8', errors='ignore') as f, \
             open(output_path, 'w', encoding='utf-8') as out:
            for line in f:
                line = line.strip()
                if line:
                    # Segmentation avec THULAC
                    segmented_line = thu.cut(line, text=True)
                    # Découpage de la ligne en liste de mots
                    words = segmented_line.split()
                    if words:
                        # Un mot par ligne, suivi d'un saut de ligne après chaque phrase/paragraphe
                        out.write("\n".join(words) + "\n\n")
    except Exception as e:
        print(f"Erreur lors du traitement du fichier {input_path}: {e}")

# 2. Configuration des répertoires d'entrée et de sortie
input_dir = "./dumps-text/"
output_dir = "./dumps-segmented/"

# Création du répertoire de sortie s'il n'existe pas
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print(f"Répertoire créé : {output_dir}")

# 3. Traitement par lot de tous les fichiers
print("Début de la segmentation...")
files = [f for f in os.listdir(input_dir) if f.endswith(".txt")]

for i, filename in enumerate(files, 1):
    input_path = os.path.join(input_dir, filename)
    output_path = os.path.join(output_dir, filename)

    # Affichage de la progression dans le terminal
    print(f"[{i}/{len(files)}] Traitement de : {filename}")
    segment_file(input_path, output_path)

print("\nFélicitations ! La segmentation est terminée avec succès.")
print(f"Les résultats sont enregistrés dans : {output_dir}")

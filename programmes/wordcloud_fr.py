import os
import glob
import numpy as np
from PIL import Image
from wordcloud import WordCloud

# --- CONFIGURATION ---
# Parcourir tous les fichiers texte dans dumps-text et ses sous-dossiers
FOLDER_PATH = "dumps-text/**/*.txt"
MASK_FILE = "mask.png"
OUTPUT_FILE = "wordcloud_fr_final.png"

# --- 1. LISTE DES MOTS À EXCLURE (STOPWORDS) ---
frenche_stopwords = {
    # Mots courants
    "le", "la", "les", "un", "une", "des", "de", "du", "et", "en", "dans",
    "que", "qui", "pour", "par", "avec", "sur", "au", "aux", "ce", "ces", "cette",
    "il", "elle", "ils", "elles", "nous", "vous", "je", "tu", "on",
    "ne", "pas", "plus", "ou", "se", "sa", "son", "ses", "leur", "leurs",
    "a", "est", "sont", "être", "avoir", "faire", "comme", "mais", "si", "tout",
    "aussi", "très", "bien", "sans", "sous", "dont", "après", "avant", "car", "ni",
    "votre", "notre", "nos", "vos", "y", "été", "étée", "étés", "étées",
    # Mots techniques / web
    "https", "http", "www", "com", "org", "fr", "net", "html", "php",
    "web", "site", "page", "accueil", "menu", "aller", "contenu", "recherche",
    "cliquez", "ici", "naviguer", "navigation", "copyright", "droits", "réservés",
    "cookies", "politique", "confidentialité", "contact", "mentions", "légales",
    "wiki", "wikipedia", "article", "modifier", "code", "source", "lire",
    # Mot clé à exclure
    "fantôme", "fantomes", "fantômes", "fantome"
}

# --- 2. RÉCUPÉRER TOUS LES FICHIERS TEXTE ---
files = glob.glob(FOLDER_PATH, recursive=True)

if not files:
    print(f"ERREUR : Aucun fichier trouvé dans {FOLDER_PATH}")
    print("Vérifie que dumps-text contient des fichiers texte.")
    exit(1)

print(f"Lecture de {len(files)} fichiers textes...")

full_text = ""
for filename in files:
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
            full_text += content + " "
    except Exception as e:
        print(f"Erreur de lecture sur {filename}: {e}")

# --- 3. CHARGEMENT DU MASQUE ---
if not os.path.exists(MASK_FILE):
    print(f"Fichier masque {MASK_FILE} introuvable.")
    exit(1)

# Charger l'image
original_mask = np.array(Image.open(MASK_FILE))

# Si l'image est en couleur (RGB), on la met en gris
if len(original_mask.shape) == 3:
    original_mask = np.mean(original_mask, axis=2)

mask = original_mask.copy()

# 1. On nettoie d'abord (gris clair -> blanc, gris foncé -> noir)
mask[mask > 200] = 255
mask[mask < 255] = 0

# 2. L'INVERSION MAGIQUE (Comme ton camarade)
# Si ta forme est blanche sur fond noir, décommente la ligne suivante :
mask = 255 - mask

# --- 4. CONFIGURATION DU NUAGE (Mise à jour pour ressembler au modèle) ---
print("Génération du nuage de mots en cours...")

wc = WordCloud(
    background_color="black",    # Fond noir comme sur le modèle
    mask=mask,
    stopwords=frenche_stopwords,
    width=2000,
    height=2000,
    max_words=200,
    contour_width=0,             # Pas de contour, c'est plus joli sur fond noir
    # contour_color="white",     # (Si tu veux un contour, mets-le en blanc)
    colormap="viridis"           # Couleurs flashy sur fond noir
)

wc.generate(full_text)
wc.to_file(OUTPUT_FILE)
print(f"Terminé ! Image enregistrée sous : {OUTPUT_FILE}")

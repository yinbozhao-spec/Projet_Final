#!/bin/bash

# Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 URLs/URLS_chinois.txt"
    exit 1
fi

URL_FILE=$1

# 1. Définition et création des répertoires
DIR_ASP="./aspirations"
DIR_DUMP="./dumps-text"
DIR_CONTEXT="./contextes"
DIR_CONCORD="./concordances"
DIR_BIGRAM="./bigrammes"
DIR_TABLEAUX="./tableaux"

mkdir -p "$DIR_ASP" "$DIR_DUMP" "$DIR_CONTEXT" "$DIR_CONCORD" "$DIR_BIGRAM" "$DIR_TABLEAUX"

OUTPUT_HTML="$DIR_TABLEAUX/chinois.html"
MOT="鬼"

# 2. Initialisation du fichier HTML (En-tête)
cat > "$OUTPUT_HTML" <<EOF
<html>
<head>
    <meta charset="UTF-8">
    <title>Tableau Récapitulatif - $MOT</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <style>
        .keyword { color: red; font-weight: bold; }
        .stat-box { background-color: #f5f5f5; padding: 2px 5px; border-radius: 3px; }
        .table-container { margin-top: 20px; }
    </style>
</head>
<body>
<section class="section">
    <h1 class="title has-text-centered">Corpus Chinois : « $MOT »</h1>
    <div class="table-container">
    <table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth">
    <thead>
        <tr style="background-color: #3273dc; color: white;">
            <th>ID</th>
            <th>URL</th>
            <th>Code HTTP</th>
            <th>Encodage</th>
            <th>Occurrences</th>
            <th>Source</th>
            <th>Dump</th>
            <th>Contextes</th>
            <th>Concordances</th>
        </tr>
    </thead>
    <tbody>
EOF

# 3. Traitement des URLs
ID=1
while IFS= read -r URL || [[ -n "$URL" ]]; do
    [[ -z "$URL" ]] && continue
    echo "Traitement ID $ID : $URL"

    # Définition des noms de fichiers
    ASP_FILE="chinois_$ID.html"
    DUMP_FILE="chinois_$ID.txt"
    CONTEXT_FILE="context_chinois_$ID.txt"
    CONCORD_FILE="concord_chinois_$ID.html"
    BIGRAM_FILE="bigram_chinois_$ID.txt"

    # Téléchargement de la page
    HTTP_CODE=$(curl -L -s -o "$DIR_ASP/$ASP_FILE" -w "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" "$URL")

    # Détection de l'encodage
    if [ -f "$DIR_ASP/$ASP_FILE" ]; then
        ENCODING=$(file -I "$DIR_ASP/$ASP_FILE" | cut -d "=" -f 2 | tr '[:lower:]' '[:upper:]' | xargs)
    else
        ENCODING="N/A"
    fi

    # Si le téléchargement a réussi
    if [ "$HTTP_CODE" -eq 200 ]; then
        # Extraction du texte propre
        lynx -dump -nolist -display_charset=utf-8 "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null

        # A. Comptage des occurrences
        NB_OCC=$(grep -o "$MOT" "$DIR_DUMP/$DUMP_FILE" | wc -l)

        # B. EXTRACTION DES CONTEXTES (La partie qui manquait)
        # On extrait le mot avec 2 lignes avant et après
        grep -C 2 "$MOT" "$DIR_DUMP/$DUMP_FILE" > "$DIR_CONTEXT/$CONTEXT_FILE"

        # C. Analyse des Bigrammes
        grep -oE "$MOT." "$DIR_DUMP/$DUMP_FILE" | sort | uniq -c | sort -nr > "$DIR_BIGRAM/$BIGRAM_FILE"

        # D. Génération de la Concordance HTML
        echo "<html><head><meta charset='utf-8'></head><body><table border='1' width='100%'>" > "$DIR_CONCORD/$CONCORD_FILE"
        grep "$MOT" "$DIR_DUMP/$DUMP_FILE" | while read -r line; do
            # Remplacement pour surlignage
            line_html=$(echo "$line" | LC_ALL=C sed "s/$MOT/<span style='color:red;font-weight:bold;'>$MOT<\/span>/g")
            echo "<tr><td style='padding:5px;'>$line_html</td></tr>" >> "$DIR_CONCORD/$CONCORD_FILE"
        done
        echo "</table></body></html>" >> "$DIR_CONCORD/$CONCORD_FILE"
    else
        NB_OCC=0
        echo "Échec" > "$DIR_DUMP/$DUMP_FILE"
        echo "N/A" > "$DIR_CONTEXT/$CONTEXT_FILE"
        echo "" > "$DIR_BIGRAM/$BIGRAM_FILE"
    fi

    # 4. Ajout de la ligne au tableau HTML
    echo "<tr>
        <td>$ID</td>
        <td><small><a href=\"$URL\" target=\"_blank\">Lien</a></small></td>
        <td class=\"$( [ "$HTTP_CODE" -eq 200 ] && echo 'has-text-success' || echo 'has-text-danger' )\"><b>$HTTP_CODE</b></td>
        <td>$ENCODING</td>
        <td><span class=\"stat-box\">$NB_OCC</span></td>
        <td><a href=\"../aspirations/$ASP_FILE\">Source</a></td>
        <td><a href=\"../dumps-text/$DUMP_FILE\">Texte</a></td>
        <td><a href=\"../contextes/$CONTEXT_FILE\">Contextes</a></td>
        <td><a href=\"../concordances/$CONCORD_FILE\">Consulter</a></td>
    </tr>" >> "$OUTPUT_HTML"

    ((ID++))
done < "$URL_FILE"

# 5. Fermeture du fichier HTML
cat >> "$OUTPUT_HTML" <<EOF
    </tbody>
    </table>
    </div>
</section>
<footer class="footer">
  <div class="content has-text-centered">
    <p>Projet de Traitement Automatique des Langues - Master TAL</p>
  </div>
</footer>
</body>
</html>
EOF

echo "Succès ! Le tableau a été généré : $OUTPUT_HTML"
echo "Les fichiers de contexte se trouvent dans : $DIR_CONTEXT"

#!/bin/bash

# Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 URLs/fr.txt"
    exit 1
fi

URL_FILE=$1

# Dossiers de sortie
DIR_ASP="./aspirations"
DIR_DUMP="./dumps-text"
DIR_CONTEXT="./contextes"
DIR_CONCORD="./concordances"
DIR_BIGRAM="./bigrammes"
DIR_TABLEAUX="./tableaux"

mkdir -p "$DIR_ASP" "$DIR_DUMP" "$DIR_CONTEXT" "$DIR_CONCORD" "$DIR_BIGRAM" "$DIR_TABLEAUX"

# Fichier HTML de sortie
OUTPUT_HTML="$DIR_TABLEAUX/francais.html"

# Mot cible pour le contexte
MOT="fantôme"

# Début du tableau HTML
cat > "$OUTPUT_HTML" <<EOF
<html>
<head>
    <meta charset="UTF-8">
    <title>Tableau Récapitulatif - $MOT</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <style>
        .keyword { color: red; font-weight: bold; }
        .stat-box { background-color: #f5f5f5; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
<section class="section">
    <h1 class="title has-text-centered">Corpus Français : « $MOT »</h1>
    <table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth">
    <thead>
        <tr style="background-color: #3273dc; color: white;">
            <th>ID</th>
            <th>URL</th>
            <th>Code HTTP</th>
            <th>Encodage</th>
            <th>Occurrences</th>
            <th>HTML</th>
            <th>Dump</th>
            <th>Bigrammes</th>
            <th>Concordances</th>
        </tr>
    </thead>
    <tbody>
EOF

ID=1
while IFS= read -r URL || [[ -n "$URL" ]]; do
    [[ -z "$URL" ]] && continue
    echo "Traitement ID $ID : $URL"

    ASP_FILE="fr_$ID.html"
    DUMP_FILE="fr_$ID.txt"
    CONTEXT_FILE="context_fr_$ID.txt"
    CONCORD_FILE="concord_fr_$ID.html"
    BIGRAM_FILE="bigram_fr_$ID.txt"

    HTTP_CODE=$(curl -L -s -o "$DIR_ASP/$ASP_FILE" -w "%{http_code}" -A "Mozilla/5.0" "$URL")

    if [ -f "$DIR_ASP/$ASP_FILE" ]; then
        ENCODING=$(file -I "$DIR_ASP/$ASP_FILE" | cut -d "=" -f 2 | tr '[:lower:]' '[:upper:]' | xargs)
    else
        ENCODING="N/A"
    fi

    if [ "$HTTP_CODE" -eq 200 ]; then
        lynx -dump -nolist -display_charset=utf-8 "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null

        NB_OCC=$(grep -o "$MOT" "$DIR_DUMP/$DUMP_FILE" | wc -l)

        grep -oE "$MOT." "$DIR_DUMP/$DUMP_FILE" | sort | uniq -c | sort -nr > "$DIR_BIGRAM/$BIGRAM_FILE"

        # Concordancier HTML
        echo "<html><head><meta charset='utf-8'></head><body><table border='1' width='100%'>" > "$DIR_CONCORD/$CONCORD_FILE"
        grep "$MOT" "$DIR_DUMP/$DUMP_FILE" | while read -r line; do
            line_html=$(echo "$line" | LC_ALL=C sed "s/$MOT/<span class='keyword'>$MOT<\/span>/g")
            echo "<tr><td style='padding:5px;'>$line_html</td></tr>" >> "$DIR_CONCORD/$CONCORD_FILE"
        done
        echo "</table></body></html>" >> "$DIR_CONCORD/$CONCORD_FILE"
    else
        NB_OCC=0
        echo "Échec du téléchargement" > "$DIR_DUMP/$DUMP_FILE"
        echo "" > "$DIR_BIGRAM/$BIGRAM_FILE"
    fi

    # Ajouter la ligne dans le tableau HTML
    echo "<tr>
        <td>$ID</td>
        <td><small><a href=\"$URL\" target=\"_blank\">Lien</a></small></td>
        <td class=\"$( [ "$HTTP_CODE" -eq 200 ] && echo 'has-text-success' || echo 'has-text-danger' )\"><b>$HTTP_CODE</b></td>
        <td>$ENCODING</td>
        <td><span class=\"stat-box\">$NB_OCC</span></td>
        <td><a href=\"../aspirations/$ASP_FILE\">Source</a></td>
        <td><a href=\"../dumps-text/$DUMP_FILE\">Texte</a></td>
        <td><a href=\"../bigrammes/$BIGRAM_FILE\">Bigrams</a></td>
        <td><a href=\"../concordances/$CONCORD_FILE\">Consulter</a></td>
    </tr>" >> "$OUTPUT_HTML"

    ((ID++))
done < "$URL_FILE"

# Fin du tableau HTML
cat >> "$OUTPUT_HTML" <<EOF
    </tbody>
    </table>
</section>
</body>
</html>
EOF

echo "Succès ! Votre tableau est ici : $OUTPUT_HTML"
echo "Les bigrammes sont dans : $DIR_BIGRAM"

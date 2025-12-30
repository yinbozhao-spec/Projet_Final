#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 URLs/URLS_chinois.txt"
    exit 1
fi

URL_FILE=$1

DIR_ASP="./aspirations"
DIR_DUMP="./dumps-text"
DIR_CONCORD="./concordances"
DIR_BIGRAM="./bigrammes"
DIR_TABLEAUX="./tableaux"

mkdir -p "$DIR_ASP" "$DIR_DUMP" "$DIR_CONCORD" "$DIR_BIGRAM" "$DIR_TABLEAUX"

OUTPUT_HTML="$DIR_TABLEAUX/chinois.html"
MOT="鬼"

cat > "$OUTPUT_HTML" <<EOF
<html>
<head>
    <meta charset="UTF-8">
    <title>Tableau Récapitulatif - $MOT</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
</head>
<body>
<section class="section">
    <h1 class="title has-text-centered">Corpus Chinois : « $MOT »</h1>
    <div class="table-container">
    <table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth">
    <thead>
        <tr style="background-color: #3273dc; color: white;">
            <th>n°</th>
            <th>URL</th>
            <th>code</th>
            <th>encodage</th>
            <th>nombre d’occurrences</th>
            <th>page HTML brute</th>
            <th>dump textuel</th>
            <th>concordancier HTML</th>
            <th>bigrammes</th>
        </tr>
    </thead>
    <tbody>
EOF

ID=1
while IFS= read -r URL || [[ -n "$URL" ]]; do
    [[ -z "$URL" ]] && continue
    echo "Traitement ID $ID : $URL"

    ASP_FILE="chinois_$ID.html"
    DUMP_FILE="chinois_$ID.txt"
    CONCORD_FILE="concord_chinois_$ID.html"
    BIGRAM_FILE="bigram_chinois_$ID.txt"

    HTTP_CODE=$(curl -L -s -o "$DIR_ASP/$ASP_FILE" -w "%{http_code}" -A "Mozilla/5.0" "$URL")

    ENCODING=$(file -I "$DIR_ASP/$ASP_FILE" | cut -d "=" -f 2 | tr '[:lower:]' '[:upper:]' | xargs)

    if [ "$HTTP_CODE" -eq 200 ]; then
        lynx -dump -nolist -display_charset=utf-8 "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null

        NB_OCC=$(grep -o "$MOT" "$DIR_DUMP/$DUMP_FILE" | wc -l)

        grep -oE "$MOT." "$DIR_DUMP/$DUMP_FILE" | sort | uniq -c | sort -nr > "$DIR_BIGRAM/$BIGRAM_FILE"

        echo "<html><head><meta charset='utf-8'></head><body><table border='1' width='100%'>" > "$DIR_CONCORD/$CONCORD_FILE"
        grep "$MOT" "$DIR_DUMP/$DUMP_FILE" | while read -r line; do
            line_colored=$(echo "$line" | LC_ALL=C sed "s/$MOT/<span style='color:red;font-weight:bold;'>$MOT<\/span>/g")
            echo "<tr><td style='padding:5px;'>$line_colored</td></tr>" >> "$DIR_CONCORD/$CONCORD_FILE"
        done
        echo "</table></body></html>" >> "$DIR_CONCORD/$CONCORD_FILE"
    else
        NB_OCC=0
        echo "Échec de récupération" > "$DIR_DUMP/$DUMP_FILE"
        echo "" > "$DIR_BIGRAM/$BIGRAM_FILE"
    fi

    echo "<tr>
        <td>$ID</td>
        <td><small><a href=\"$URL\" target=\"_blank\">Lien</a></small></td>
        <td>$HTTP_CODE</td>
        <td>$ENCODING</td>
        <td>$NB_OCC</td>
        <td><a href=\"../aspirations/$ASP_FILE\">HTML</a></td>
        <td><a href=\"../dumps-text/$DUMP_FILE\">TXT</a></td>
        <td><a href=\"../concordances/$CONCORD_FILE\">Consulter</a></td>
        <td><a href=\"../bigrammes/$BIGRAM_FILE\">Analyse</a></td>
    </tr>" >> "$OUTPUT_HTML"

    ((ID++))
done < "$URL_FILE"

cat >> "$OUTPUT_HTML" <<EOF
    </tbody>
    </table>
    </div>
</section>
</body>
</html>
EOF

echo "Succès ! Le tableau a été généré sans erreur : $OUTPUT_HTML"

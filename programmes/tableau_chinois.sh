#!/bin/bash

# Vérifie le nombre d'arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 URLs/URLs_chinois.txt"
    exit 1
fi

URL_FILE=$1

# Dossiers de sortie
DIR_ASP="./aspirations"
DIR_DUMP="./dumps-text"
DIR_CONCORD="./concordances"
DIR_BIGRAM="./bigrammes"
DIR_TABLEAUX="./tableaux"

mkdir -p "$DIR_ASP" "$DIR_DUMP" "$DIR_CONCORD" "$DIR_BIGRAM" "$DIR_TABLEAUX"

OUTPUT_HTML="$DIR_TABLEAUX/chinois.html"
MOT="鬼"

# Début du fichier HTML
cat > "$OUTPUT_HTML" <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Corpus chinois – mot étudié : $MOT</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
  <style>
    body { background-color: #f5f7fa; }
    .table-container { max-height: 75vh; overflow-y: auto; }
    table { font-size: 0.9rem; }
    thead th { position: sticky; top: 0; background-color: #3273dc; color: white; z-index: 2; text-align: center; }
    td, th { vertical-align: middle; text-align: center; word-break: break-all; }
    td.url { text-align: left; }
    td.count { font-weight: bold; color: #d0021b; }
    a { font-weight: 500; }
  </style>
</head>
<body>
<section class="section">
  <div class="container">
    <h1 class="title has-text-centered">Corpus chinois – mot étudié : <span class="has-text-danger">$MOT</span></h1>
    <div class="table-container">
      <table class="table is-bordered is-striped is-hoverable is-fullwidth">
        <thead>
          <tr>
            <th>Numero</th><th>URL</th><th>HTTP</th><th>Encodage</th><th>Occurrences</th>
            <th>HTML</th><th>TXT</th><th>Bigrammes</th><th>Concordances</th>
          </tr>
        </thead>
        <tbody>
EOF

ID=1
while IFS= read -r URL || [[ -n "$URL" ]]; do
    [[ -z "$URL" ]] && continue
    echo "Traitement $ID : $URL"

    ASP_FILE="chinois_$ID.html"
    DUMP_FILE="chinois_$ID.txt"
    CONCORD_FILE="concord_chinois_$ID.html"
    BIGRAM_FILE="bigram_chinois_$ID.txt"

    # Téléchargement HTML et récupération du code HTTP
    HTTP_CODE=$(curl -L -s -o "$DIR_ASP/$ASP_FILE" -w "%{http_code}" "$URL")

    if [[ "$HTTP_CODE" == "200" ]]; then
        encodage=$(file -b --mime-encoding "$DIR_ASP/$ASP_FILE" | tr '[:lower:]' '[:upper:]')

        # Conversion en UTF-8 si nécessaire
        if [[ "$encodage" == "UTF-8" || "$encodage" == "US-ASCII" ]]; then
            lynx -dump -nolist -display_charset=utf-8 "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
        else
            lynx -dump -nolist "$DIR_ASP/$ASP_FILE" | iconv -f "$encodage" -t UTF-8//IGNORE > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
        fi

        # Nombre d'occurrences
        NB_OCC=$(grep -o "$MOT" "$DIR_DUMP/$DUMP_FILE" | wc -l)

        # Bigrammes
        grep -oE "$MOT." "$DIR_DUMP/$DUMP_FILE" | sort | uniq -c | sort -nr > "$DIR_BIGRAM/$BIGRAM_FILE"

        # Concordances HTML
        echo "<html><head><meta charset='utf-8'></head><body><table border='1'>" > "$DIR_CONCORD/$CONCORD_FILE"
        grep "$MOT" "$DIR_DUMP/$DUMP_FILE" | while read -r line; do
            line_colored=$(echo "$line" | sed "s/$MOT/<span style='color:red;font-weight:bold;'>$MOT<\/span>/g")
            echo "<tr><td style='padding:5px;'>$line_colored</td></tr>" >> "$DIR_CONCORD/$CONCORD_FILE"
        done
        echo "</table></body></html>" >> "$DIR_CONCORD/$CONCORD_FILE"

    else
        NB_OCC=0
        encodage="N/A"
        echo "Aspiration Failed" > "$DIR_DUMP/$DUMP_FILE"
    fi

    # Ajout de la ligne dans le tableau principal
    echo "<tr>
        <td>$ID</td>
        <td class='url'><a href='$URL' target='_blank'>$URL</a></td>
        <td>$HTTP_CODE</td>
        <td>$encodage</td>
        <td class='count'>$NB_OCC</td>
        <td><a href='../$DIR_ASP/$ASP_FILE'>HTML</a></td>
        <td><a href='../$DIR_DUMP/$DUMP_FILE'>TXT</a></td>
        <td><a href='../$DIR_BIGRAM/$BIGRAM_FILE'>Bigrammes</a></td>
        <td><a href='../$DIR_CONCORD/$CONCORD_FILE'>Concord.</a></td>
    </tr>" >> "$OUTPUT_HTML"

    ((ID++))
done < "$URL_FILE"

# Fin du fichier HTML
cat >> "$OUTPUT_HTML" <<EOF
        </tbody>
      </table>
    </div>
</div>
</section>
</body>
</html>
EOF

echo "Analyse terminée → $OUTPUT_HTML"

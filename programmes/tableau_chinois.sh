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
            <th>n°</th><th>URL</th><th>code</th><th>encodage</th><th>occurrences</th>
            <th>HTML</th><th>TXT</th><th>Concordance</th><th>Bigrammes</th>
        </tr>
    </thead>
    <tbody>
EOF

ID=1
while IFS= read -r URL || [[ -n "$URL" ]]; do
    [[ -z "$URL" ]] && continue
    echo "Processing ID $ID: $URL"

    ASP_FILE="chinois_$ID.html"
    DUMP_FILE="chinois_$ID.txt"
    CONCORD_FILE="concord_chinois_$ID.html"
    BIGRAM_FILE="bigram_chinois_$ID.txt"

    HTTP_CODE=$(curl -L -s -o "$DIR_ASP/$ASP_FILE" -w "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36" "$URL")

    if [[ "$HTTP_CODE" == "200" ]]; then
        encodage=$(file -b --mime-encoding "$DIR_ASP/$ASP_FILE" | tr '[:lower:]' '[:upper:]')

        if [[ "$encodage" == "UTF-8" || "$encodage" == "US-ASCII" ]]; then
            lynx -dump -nolist -display_charset=utf-8 "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
        else
            VERIFENCODAGEDANSICONV=$(iconv -l | egrep -io "$encodage" | sort -u | head -n 1)
            if [[ "$VERIFENCODAGEDANSICONV" != "" ]]; then
                lynx -dump -nolist "$DIR_ASP/$ASP_FILE" | iconv -f "$encodage" -t UTF-8//IGNORE > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
            else
                CHARSET_PAGE=$(egrep -oi "charset=[^\"'>]*" "$DIR_ASP/$ASP_FILE" | head -n 1 | cut -d= -f2 | tr -d " \"'" | tr '[:lower:]' '[:upper:]')
                if [[ "$CHARSET_PAGE" != "" ]]; then
                    VERIFENCODAGEDANSICONV_PAGE=$(iconv -l | egrep -io "$CHARSET_PAGE" | sort -u | head -n 1)
                    if [[ "$VERIFENCODAGEDANSICONV_PAGE" != "" ]]; then
                        lynx -dump -nolist "$DIR_ASP/$ASP_FILE" | iconv -f "$CHARSET_PAGE" -t UTF-8//IGNORE > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
                    else
                        lynx -dump -nolist "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
                    fi
                else
                    lynx -dump -nolist "$DIR_ASP/$ASP_FILE" > "$DIR_DUMP/$DUMP_FILE" 2>/dev/null
                fi
            fi
        fi

        python3 -c "
import sys
p = '$DIR_DUMP/$DUMP_FILE'
try:
    with open(p, 'rb') as f: content = f.read()
    t = content.decode('utf-8', errors='ignore')
    if 'æ' in t and 'ç' in t:
        t = t.encode('latin-1').decode('utf-8')
    with open(p, 'w', encoding='utf-8') as f: f.write(t)
except: pass
"

        NB_OCC=$(grep -o "$MOT" "$DIR_DUMP/$DUMP_FILE" | wc -l)
        grep -oE "$MOT." "$DIR_DUMP/$DUMP_FILE" | sort | uniq -c | sort -nr > "$DIR_BIGRAM/$BIGRAM_FILE"

        echo "<html><head><meta charset='utf-8'></head><body><table border='1' width='100%'>" > "$DIR_CONCORD/$CONCORD_FILE"
        LC_ALL=en_US.UTF-8 grep "$MOT" "$DIR_DUMP/$DUMP_FILE" | while read -r line; do
            line_colored=$(echo "$line" | sed "s/$MOT/<span style='color:red;font-weight:bold;'>$MOT<\/span>/g")
            echo "<tr><td style='padding:5px;'>$line_colored</td></tr>" >> "$DIR_CONCORD/$CONCORD_FILE"
        done
        echo "</table></body></html>" >> "$DIR_CONCORD/$CONCORD_FILE"
    else
        NB_OCC=0
        encodage="N/A"
        echo "Aspiration Failed" > "$DIR_DUMP/$DUMP_FILE"
    fi

    echo "<tr>
        <td>$ID</td>
        <td><small><a href=\"$URL\" target=\"_blank\">Lien</a></small></td>
        <td>$HTTP_CODE</td>
        <td>$encodage</td>
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

echo "Process completed: $OUTPUT_HTML"

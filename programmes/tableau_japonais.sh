
export LC_ALL=C.UTF-8

if [ $# -ne 2 ]; then
    echo "Ce programme demande deux arguments (le fichier contenant les URLs et le fichier HTML de sortie)" #vérifie qu'il y a bien les deux arguments demandés
    exit 1
fi

OCC=0
FICHIER_URLS=$1
HTML_FILE=$2

cat > "$HTML_FILE" << EOF
<html>
    <head>
    <meta charset="UTF-8">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css">
            <title>Résultats d’analyse des URLs</title>
        <style>
            body {font-family: Arial, sans-serif; margin: 15px;}
            table {border-collapse: collapse; width: 100%;}
            th, td {border: 1px solid #ddd; padding: 8px;}
            th {background-color: #f8f8f8;}
            tr:nth-child(even) {background-color: #fafafa;}
            .kw {color:red;font-weight:bold;}
        </style>
    </head>
    <body>
        <h1>Résultats d’analyse des URLs</h1>
        <table>
            <tr>
                <th>#</th><th>URL</th><th>Code HTTP</th><th>Encodage</th>
                <th>Nombre total d'occurences</th>
                <th>HTML brut</th><th>Dump textuel</th>
                <th>Contextes</th><th>Concordancier</th>
                <th>Bigrammes</th>
            </tr>
EOF




mkdir -p aspirations dumps-text concordances contextes bigrammes




while read -r line; do
    [ -z "$line" ] && continue

    if ! echo "$line" | grep -qE "^https?://"; then
        echo "URL ignorée : $line"
        continue
    fi
    #compter chaque ligne
    OCC=$((OCC + 1))
    #trouver le code HTTP
    CODE=$(curl -s -o tmp.txt -w "%{http_code}" "$line")

    if [ "$CODE" -eq 200 ]; then #vérifie que le code HTTP est bien 200 pour la suite du programme

        RAW_HTML="aspirations/raw_japonais_${OCC}.html"
        VIEW_HTML="aspirations/view_japonais_${OCC}.html"

        curl -s -A "Mozilla/5.0" "$line" -o "$RAW_HTML"

        {
            echo "<html><head><meta charset='UTF-8'><title>Aspirations</title></head><body><pre>" #petit html pour afficher un peu mieux la page
            sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' "$RAW_HTML"
            echo "</pre></body></html>"
        } > "$VIEW_HTML"

        HTML_CELL="<a href=\"$VIEW_HTML\">Aperçu</a>"


        DUMP_FILE="dumps-text/dumps_japonais_${OCC}.txt"
        DUMP_CELL="<a href=\"$DUMP_FILE\">Dumps</a>"

        lynx -dump -nolist "$RAW_HTML" > "$DUMP_FILE"


        BIGRAM_FILE="bigrammes/bigrammes_japonais_${OCC}.txt"
        tr '[:space:]' '\n' < "$DUMP_FILE" > temp.txt

        PREV=""
        > "$BIGRAM_FILE"

        while read -r MOT; do
            if [ -n "$PREV" ]; then
            echo "$PREV $MOT" >> "$BIGRAM_FILE"
            fi
            PREV="$MOT"
        done < temp.txt

        grep -Ei '(鬼|oni|おに)' "$BIGRAM_FILE" > bigrammes_tmp.txt
        mv bigrammes_tmp.txt "$BIGRAM_FILE"


        BIGRAM_CELL="<a href=\"$BIGRAM_FILE\">Bigrammes</a>"

        rm -f temp.txt


        CONTEXT_FILE="contextes/context_japonais_${OCC}.txt"
        grep -o -P ".{0,15}(鬼|oni|おに).{0,15}" "$DUMP_FILE" \
            | sed 's/[[:space:]]\+/ /g' \
            > "$CONTEXT_FILE"

        CTX_CELL="<a href=\"$CONTEXT_FILE\">Contextes</a>"


        CONC_FILE="concordances/concord_japonais_${OCC}.html"
        CONC_CELL="<a href=\"$CONC_FILE\">Concordances</a>"

            { #html un peu plus joli pour le concordancier
                echo "<html>"
                echo "<head>"
                echo "<meta charset='UTF-8'>"
                echo "<title>Concordances</title>"
                echo "<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css'>"
                echo "<style>
                body { padding: 30px; }
                .kw { color: red; font-weight: bold; }
                .context-box {
                    border-bottom: 1px solid #ddd;
                    padding: 10px 0;
                    font-family: monospace;
                }
                </style>"
                echo "</head>"
                echo "<body>"
                echo "<section class='section'>"
                echo "<h1 class='title'>Concordances</h1>"
                echo "<h2 class='subtitle'>$line</h2>"
                echo "<a href='javascript:history.back()'>← Retour</a>"
                echo "<hr>"

            while read -r context; do
                SURLIGNE=$(echo "$context" | sed -E 's/(鬼|oni|おに)/<span class="kw">\1<\/span>/g')
                echo "<div class='context-box'>$SURLIGNE</div>"
            done < "$CONTEXT_FILE"

                echo "</section>"
                echo "</body></html>"
            } > "$CONC_FILE"
    else
        DUMP_CELL="vide"
        CTX_CELL="vide"
        CONC_CELL="vide"
        BIGRAM_CELL="vide"
        HTML_CELL="vide" #vide si code http =/ 200
    fi



    lynx -dump -stdin -nolist < tmp.txt > aspiration.txt

     #plusieurs façons de compter le caractère oni et ses écritures (j'ai fait ça au cas où j'ai besoin de ces données séparemment)
    NB_KANJI=$(grep -o "鬼" aspiration.txt | wc -l)
    NB_HIRA=$(grep -Po '(?<![ぁ-ゖ])おに(?![ぁ-ゖ])' aspiration.txt | wc -l)
    NB_KATA=$(grep -Po '(?<![ァ-ヶ])オニ(?![ァ-ヶ])' aspiration.txt | wc -l)
    NB_ROMA=$(grep -Poi '(?<![a-z])oni(?![a-z])' aspiration.txt | wc -l)
    NB_TOTAL=$((NB_KANJI + NB_HIRA + NB_ROMA + NB_KATA))

    rm -f tmp.txt aspiration.txt

cat >> "$HTML_FILE" << EOF
            <tr>
                <td>$OCC</td>
                <td><a href="$line">$line</a></td>
                <td>$CODE</td>
                <td>UTF-8</td>
                <td>$NB_TOTAL</td>
                <td>$HTML_CELL</td>
                <td>$DUMP_CELL</td>
                <td>$CTX_CELL</td>
                <td>$CONC_CELL</td>
                <td>$BIGRAM_CELL</td>
            </tr>
EOF

done < "$FICHIER_URLS"

cat >> "$HTML_FILE" << EOF
        </table>
    </body>
</html>
EOF



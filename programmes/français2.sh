#!/bin/bash

# ====================================================================
# SCRIPT FINAL - SPÉCIAL MAC (ADAPTÉ A TES DOSSIERS)
# ====================================================================

# 1. VÉRIFICATION
if [ $# -eq 0 ]; then
    echo "Erreur : Il manque le fichier d'URLs !"
    echo "Usage : ./français2.sh ../URLs/fr.txt"
    exit 1
fi

FICHIER_URLS="$1"
basename=$(basename "$FICHIER_URLS" .txt)
FICHIER_TABLEAU="../tableaux/tableau-$basename.html"

# On crée les dossiers (au niveau de la racine PPE1-2526)
mkdir -p ../aspirations ../dumps-text ../contextes ../tableaux

# 2. EN-TÊTE HTML
echo "<html>
<head>
    <meta charset=\"UTF-8\">
    <title>Tableau FR - Fantôme</title>
    <style>
        table { border-collapse: collapse; width: 100%; font-family: sans-serif; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even){background-color: #f2f2f2;}
        th { background-color: #04AA6D; color: white; }
        .mot-cle { color: red; font-weight: bold; background-color: yellow; }
        .error { background-color: #ffcccc; }
    </style>
</head>
<body>
<h1 align=\"center\">Tableau de suivi : Mot 'Fantôme'</h1>
<table align=\"center\">
<tr>
    <th>N°</th>
    <th>Code</th>
    <th>URL</th>
    <th>Encodage</th>
    <th>Aspiration</th>
    <th>Dump</th>
    <th>Nb</th>
    <th>Contexte</th>
</tr>" > "$FICHIER_TABLEAU"

line_num=0

# 3. BOUCLE
while read -r URL; do
    ((line_num++))
    echo "Traitement URL n°$line_num..."

    fichier_html="../aspirations/$basename-$line_num.html"
    fichier_dump="../dumps-text/$basename-$line_num.txt"
    fichier_contexte="../contextes/$basename-$line_num.txt"

    # --- A : ASPIRATION ---
    code_http=$(curl -s -I -L -w "%{http_code}" -o /dev/null "$URL")
    
    if [ "$code_http" -eq 200 ]; then
        
        # Téléchargement
        curl -s -L -o "$fichier_html" "$URL"
        encodage=$(file -b --mime-encoding "$fichier_html")

        # --- B : DUMP (Version Mac Textutil) ---
        # C'est ici que ça corrige tes "zéros" !
        textutil -convert txt "$fichier_html" -output "$fichier_dump" -encoding UTF-8

        # --- C : COMPTE ET CONTEXTE ---
        compte=$(grep -c -i "fantôme" "$fichier_dump")
        
        # Contexte (3 lignes)
        grep -i -C 1 "fantôme" "$fichier_dump" > "$fichier_contexte"
        
        # Nettoyage pour affichage HTML
        contexte_safe=$(cat "$fichier_contexte" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        contexte_final=$(echo "$contexte_safe" | sed 's/fantôme/<span class="mot-cle">fantôme<\/span>/Ig' | sed 's/Fantôme/<span class="mot-cle">Fantôme<\/span>/Ig')

        # --- D : ÉCRITURE ---
        echo "<tr>
            <td>$line_num</td>
            <td>$code_http</td>
            <td><a href=\"$URL\" target=\"_blank\">Lien</a></td>
            <td>$encodage</td>
            <td><a href=\"$fichier_html\">HTML</a></td>
            <td><a href=\"$fichier_dump\">Txt</a></td>
            <td>$compte</td>
            <td>$contexte_final</td>
        </tr>" >> "$FICHIER_TABLEAU"
    else
        echo "<tr class=\"error\"><td>$line_num</td><td>$code_http</td><td><a href=\"$URL\">$URL</a></td><td>-</td><td>-</td><td>-</td><td>-</td><td>Erreur</td></tr>" >> "$FICHIER_TABLEAU"
    fi

done < "$FICHIER_URLS"

echo "</table></body></html>" >> "$FICHIER_TABLEAU"
echo "TERMINÉ ! Regarde dans le dossier tableaux."
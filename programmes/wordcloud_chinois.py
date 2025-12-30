import os
import re
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from wordcloud import WordCloud
import matplotlib.pyplot as plt

input_file = "pals/resultats_chinois_pals.tsv"
output_dir = "wordcloud"
output_image = os.path.join(output_dir, "nuage_chinois_forme_gui.png")
font_path = "/System/Library/Fonts/STHeiti Light.ttc"

STOPWORDS = {"的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "个", "这", "那", "之", "与", "于", "及", "而", "以", "等", "为", "从", "自", "向", "往", "被", "把", "让", "给", "所", "者", "并", "且", "更", "又", "已", "再", "但", "却", "因", "故", "由于", "所以", "如果", "虽然", "但是", "然而", "比如", "例如", "及其", "这个", "那个", "这些", "那些", "这样", "那样", "怎样", "怎么", "什么", "哪里", "哪个", "哪些", "其", "自己", "别人", "大家", "各位", "左右", "这种", "某种", "有些", "甚至", "不仅", "不但", "即使", "即便", "非常", "十分", "极其", "特别", "相当", "稍微", "有点", "几乎", "全部", "所有", "一切", "已经", "能够", "通过", "进行", "作为", "目前", "此时", "因此", "从而", "确实", "其实", "似乎", "所谓", "既然", "容易", "突然", "依然", "一直", "曾经", "正在", "出现", "存在", "产生", "关于", "对于", "针对", "采用", "提供", "导致", "说明", "具有", "如下", "如图", "显示", "表明", "上述", "部分", "很多", "许多", "不少", "一点", "一些", "为什么", "有关", "二十", "可以", "早已", "为什", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "?", "_", "“", "”", "、", "。", "《", "》", "！", "，", "：", "；", "？"}

def est_chinois_propre(texte):
    if len(texte) < 2:
        return False
    if not re.match(r'^[\u4e00-\u9fa5]+$', texte):
        return False
    if texte in STOPWORDS:
        return False
    return True

def creer_masque_texte(caractere, chemin_police, taille=(2000, 2000)):
    # Création du masque comme une image chargée (fond noir, texte blanc)
    img_masque = Image.new("L", taille, 0)
    dessin = ImageDraw.Draw(img_masque)
    try:
        taille_police = int(taille[0] * 0.8)
        police = ImageFont.truetype(chemin_police, taille_police)
        boite = dessin.textbbox((0, 0), caractere, font=police)
        largeur, hauteur = boite[2] - boite[0], boite[3] - boite[1]
        dessin.text(((taille[0]-largeur)//2, (taille[1]-hauteur)//2 - boite[1]), caractere, font=police, fill=255)

        # Application de la transformation exacte de ton camarade
        mask = np.array(img_masque)
        mask = 255 - mask
        return mask
    except:
        return None

scores_mots = {}

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

try:
    with open(input_file, 'r', encoding='utf-8') as f:
        lignes = f.readlines()
        index_entete = -1
        for i, ligne in enumerate(lignes):
            if "token" in ligne and "specificity" in ligne:
                index_entete = i
                break

        if index_entete != -1:
            for ligne in lignes[index_entete + 1:]:
                elements = ligne.strip().split('\t')
                if len(elements) >= 6:
                    token = elements[0]
                    if est_chinois_propre(token):
                        try:
                            score = float(elements[5])
                            if score > 0:
                                scores_mots[token] = score
                        except:
                            continue

    if scores_mots:
        mask = creer_masque_texte("鬼", font_path)

        # Utilisation des paramètres exacts de ton camarade
        wc = WordCloud(
            font_path=font_path,
            background_color="black",
            mask=mask,
            width=2000,
            height=2000,
            max_words=500,
            contour_width=2,
            contour_color="black"
        ).generate_from_frequencies(scores_mots)

        wc.to_file(output_image)

        plt.figure(figsize=(10, 10))
        plt.imshow(wc, interpolation='bilinear')
        plt.axis("off")
        plt.show()
    else:
        print("Erreur : Aucun mot valide.")

except Exception as e:
    print(f"Erreur : {e}")

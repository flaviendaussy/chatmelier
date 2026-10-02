#!/usr/bin/env python3
"""Fabrique les cartes du banc d'essai (V2.3 · K3), avec leur référence exacte.

Aucune photo de carte réelle n'était disponible (02/10). Chaque carte est dessinée à partir
des mêmes données que sa référence : la vérité est exacte par construction. Puis la page
est dégradée comme une photo prise à table : perspective, rotation, ombre, flou, grain,
compression. Les vins sont réels, les prix plausibles.

    python3 tool/banc_ia/fabriquer_cartes.py ~/chatmelier-banc

Écrit <dossier>/cartes/<nom>/page1.jpg (page2.jpg…) et reference.json, au format attendu
par banc.py : {"mode": "carte" | "ardoise", "vins": [{"nom", "producteur", "millesime",
"prix", "prix_verre"}]}. Une carte sans prix a des prix nuls. Rejouable : même graine,
mêmes images.
"""
import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

POLICES = {
    'lato': '/usr/share/fonts/truetype/lato/Lato-Regular.ttf',
    'lato_gras': '/usr/share/fonts/truetype/lato/Lato-Bold.ttf',
    'serif': '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
    'palatino_it': '/usr/share/fonts/opentype/urw-base35/P052-Italic.otf',
    'bookman': '/usr/share/fonts/opentype/urw-base35/URWBookman-Light.otf',
    'gothic': '/usr/share/fonts/opentype/urw-base35/URWGothic-Book.otf',
    'liberation_serif': '/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf',
    'etroite': '/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Regular.ttf',
}


def v(nom, prod, mill, prix=None, verre=None):
    return {'nom': nom, 'producteur': prod, 'millesime': mill, 'prix': prix, 'prix_verre': verre}


# Les cartes : des lieux, des langues, des devises et des mises en page différentes.
CARTES = [
    {
        'nom': 'bistrot_paris', 'titre': 'Le Petit Zinc', 'sous_titre': 'Notre cave', 'devise': '€',
        'police': 'serif', 'format': 'fr', 'colonne_verre': True, 'pages': [[
            ('Blancs', [v('Muscadet Sèvre et Maine sur lie', 'Domaine de la Pépière', 2023, 29, 6),
                        v('Sancerre', 'Domaine Vacheron', 2023, 48, 10),
                        v('Chablis 1er Cru Vaillons', 'Domaine Christian Moreau', 2022, 62),
                        v('Meursault', 'Domaine Roulot', 2020, 145)]),
            ('Rouges', [v('Fleurie', 'Domaine Jules Desjourneys', 2022, 52),
                        v('Morgon Côte du Py', 'Jean Foillard', 2022, 45, 9),
                        v('Saumur-Champigny', 'Domaine des Roches Neuves', 2022, 38, 8),
                        v('Crozes-Hermitage', 'Alain Graillot', 2021, 49),
                        v('Madiran', 'Château Montus', 2018, 55),
                        v('Pauillac', 'Château Pichon Baron', 2016, 190)]),
            ('Bulles', [v('Champagne Brut 1er Cru', 'Pierre Gimonnet', None, 72, 13)]),
        ]],
    },
    {
        'nom': 'brasserie_longue', 'titre': 'Brasserie Lutetia', 'sous_titre': 'La carte des vins', 'devise': '€',
        'police': 'liberation_serif', 'format': 'fr', 'colonne_verre': False, 'pages': [
            [('Champagnes', [v('Brut Réserve', 'Charles Heidsieck', None, 95),
                             v('Grande Cuvée', 'Krug', None, 390),
                             v('Blanc de Blancs', 'Ruinart', None, 140)]),
             ('Loire', [v('Vouvray Le Haut-Lieu Sec', 'Domaine Huet', 2021, 58),
                        v('Savennières Clos du Papillon', 'Domaine du Closel', 2020, 64),
                        v('Chinon Les Varennes du Grand Clos', 'Charles Joguet', 2019, 59),
                        v('Pouilly-Fumé Pur Sang', 'Didier Dagueneau', 2020, 135)]),
             ('Bourgogne blanc', [v('Puligny-Montrachet', 'Domaine Leflaive', 2020, 210),
                                  v('Saint-Aubin 1er Cru En Remilly', 'Domaine Hubert Lamy', 2021, 98),
                                  v('Mâcon-Pierreclos', 'Domaine Guffens-Heynen', 2022, 54),
                                  v('Chablis Grand Cru Les Clos', 'Domaine William Fèvre', 2019, 180)]),
             ('Alsace', [v('Riesling Grand Cru Schlossberg', 'Domaine Weinbach', 2020, 89),
                         v('Gewurztraminer', 'Domaine Zind-Humbrecht', 2021, 66)])],
            [('Bourgogne rouge', [v('Gevrey-Chambertin Les Platières', 'Philippe Leclerc', 2021, 115),
                                  v('Chambolle-Musigny', 'Domaine Ghislaine Barthod', 2020, 160),
                                  v('Pommard 1er Cru Les Rugiens', 'Domaine de Courcel', 2019, 175),
                                  v('Bourgogne Hautes-Côtes de Nuits', 'Domaine Jayer-Gilles', 2021, 72)]),
             ('Rhône', [v('Côte-Rôtie La Landonne', 'E. Guigal', 2017, 690),
                        v('Hermitage', 'Jean-Louis Chave', 2018, 650),
                        v('Châteauneuf-du-Pape', 'Château de Beaucastel', 2019, 120),
                        v('Cornas', 'Auguste Clape', 2019, 135)]),
             ('Bordeaux', [v('Saint-Julien', 'Château Léoville Las Cases', 2012, 420),
                           v('Pessac-Léognan', 'Domaine de Chevalier', 2016, 145),
                           v('Pomerol', 'Château La Conseillante', 2015, 260),
                           v('Margaux', 'Château Palmer', 2014, 480)]),
             ('Sud', [v('Bandol', 'Domaine Tempier', 2019, 78),
                      v('Minervois La Livinière', 'Château Maris', 2020, 48),
                      v('Faugères', 'Domaine Léon Barral', 2019, 69)])],
        ],
    },
    {
        'nom': 'ecosse_kitchin', 'titre': 'THE KITCHIN', 'sous_titre': 'Wine List', 'devise': '£',
        'police': 'gothic', 'format': 'en', 'colonne_verre': False, 'pages': [[
            ('Red Wines', [v('Barolo', 'Vietti', 2019, 95),
                           v('Rioja Reserva', 'La Rioja Alta', 2016, 60),
                           v('Pinot Noir', 'Felton Road', 2021, 72),
                           v('Bin 28 Kalimna Shiraz', 'Penfolds', 2019, 58),
                           v('Malbec', 'Catena Zapata', 2020, 44)]),
            ('White Wines', [v('Sancerre', 'Vacheron', 2022, 42),
                             v('Chablis 1er Cru', 'William Fèvre', 2021, 58),
                             v('Riesling Kabinett', 'Dr. Loosen', 2022, 40),
                             v('Rías Baixas Albariño', 'Pazo de Señorans', 2023, 46)]),
            ('Sparkling', [v('Special Cuvée', 'Bollinger', None, 110)]),
        ]],
    },
    {
        'nom': 'tapas_madrid', 'titre': 'Taberna La Bodeguilla', 'sous_titre': 'Vinos', 'devise': '€',
        'police': 'bookman', 'format': 'es', 'colonne_verre': True, 'pages': [[
            ('Tintos', [v('Rioja Gran Reserva 904', 'La Rioja Alta', 2015, 85),
                        v('Ribera del Duero Crianza', 'Pesquera', 2019, 45, 7),
                        v('Priorat Camins del Priorat', 'Álvaro Palacios', 2021, 39, 6),
                        v('Bierzo Pétalos', 'Descendientes de J. Palacios', 2021, 34, 5.5),
                        v('Toro Románico', 'Teso La Monja', 2020, 29)]),
            ('Blancos', [v('Rías Baixas Albariño', 'Pazo de Señorans', 2023, 32, 5),
                         v('Rueda Verdejo', 'José Pariente', 2023, 24, 4),
                         v('Valdeorras Godello', 'Rafael Palacios As Sortes', 2021, 68)]),
            ('Rosados y espumosos', [v('Navarra Rosado', 'Chivite Las Fincas', 2023, 26, 4.5),
                                     v('Cava Reserva de la Familia', 'Juvé & Camps', 2019, 38)]),
        ]],
    },
    {
        'nom': 'enoteca_roma', 'titre': 'Enoteca Il Goccetto', 'sous_titre': 'Carta dei vini', 'devise': '€',
        'police': 'palatino_it', 'format': 'it', 'colonne_verre': False, 'pages': [[
            ('Rossi', [v('Barolo Cannubi', 'Brezza', 2018, 92),
                       v('Brunello di Montalcino', 'Biondi-Santi', 2016, 240),
                       v('Chianti Classico Riserva', 'Fèlsina Rancia', 2019, 58),
                       v('Etna Rosso', 'Tenuta delle Terre Nere', 2021, 39),
                       v('Montepulciano d\'Abruzzo', 'Valentini', 2017, 160)]),
            ('Bianchi', [v('Soave Classico', 'Pieropan', 2022, 32),
                         v('Fiano di Avellino', 'Ciro Picariello', 2021, 36),
                         v('Verdicchio dei Castelli di Jesi', 'Bucci Villa Bucci', 2020, 48)]),
            ('Bollicine', [v('Franciacorta Brut', 'Ca\' del Bosco', None, 64)]),
        ]],
    },
    {
        'nom': 'salon_sans_prix', 'titre': 'Salon Premium', 'sous_titre': 'Sélection de vins offerte', 'devise': '',
        'police': 'lato', 'format': 'fr', 'colonne_verre': False, 'pages': [[
            ('Blancs', [v('Chablis', 'Domaine Laroche', 2022),
                        v('Côtes de Gascogne', 'Domaine Tariquet', 2023)]),
            ('Rouges', [v('Saint-Émilion Grand Cru', 'Château Fombrauge', 2018),
                        v('Côtes du Rhône', 'E. Guigal', 2021)]),
            ('Champagne', [v('Brut Impérial', 'Moët & Chandon', None)]),
        ]],
    },
    {
        'nom': 'ardoise_craie', 'titre': 'LE COMPTOIR DU CANAL', 'sous_titre': 'Les vins au verre (12 cl)',
        'devise': '€', 'police': 'lato', 'format': 'fr', 'mode': 'ardoise', 'colonne_verre': False, 'pages': [[
            ('Bulles', [v('Champagne Brut 1er Cru', 'Pierre Gimonnet', None, verre=13)]),
            ('Blancs', [v('Muscadet Sèvre et Maine sur lie', 'Domaine de l\'Écu', 2023, verre=6),
                        v('Chablis', 'William Fèvre', 2022, verre=9),
                        v('Sancerre', 'Domaine Vacheron', 2023, verre=10)]),
            ('Rosé', [v('Bandol rosé', 'Domaine Tempier', 2023, verre=9)]),
            ('Rouges', [v('Saumur-Champigny', 'Roches Neuves', 2022, verre=8),
                        v('Morgon Côte du Py', 'Jean Foillard', 2022, verre=9),
                        v('Côtes du Rhône', 'Gramenon', 2021, verre=8),
                        v('Madiran', 'Château Montus', 2018, verre=11)]),
        ]],
    },
    {
        'nom': 'ardoise_italique', 'titre': 'Cave à manger Le Vercingétorix', 'sous_titre': 'Ardoise du jour, au verre',
        'devise': '€', 'police': 'palatino_it', 'format': 'fr', 'mode': 'ardoise', 'colonne_verre': False, 'pages': [[
            ('Les blancs', [v('L\'Étoile Chardonnay', 'Domaine de Montbourgeau', 2020, verre=8),
                            v('Alsace Riesling', 'Domaine Ostertag', 2022, verre=7.5),
                            v('Saint-Véran', 'Domaine des Deux Roches', 2022, verre=7)]),
            ('Les rouges', [v('Beaujolais-Villages', 'Domaine Dupeuble', 2023, verre=5.5),
                            v('Cahors', 'Clos Triguedina', 2019, verre=7),
                            v('Corbières', 'Domaine Ledogar', 2021, verre=6.5),
                            v('Saint-Joseph', 'Domaine Coursodon', 2021, verre=9.5)]),
        ]],
    },
    {
        'nom': 'deux_colonnes_dense', 'titre': 'Restaurant Le Grand Véfour', 'sous_titre': 'Sélection du sommelier',
        'devise': '€', 'police': 'etroite', 'format': 'fr', 'colonnes': 2, 'colonne_verre': False, 'pages': [[
            ('Bourgogne', [v('Corton-Charlemagne Grand Cru', 'Bonneau du Martray', 2018, 310),
                           v('Vosne-Romanée', 'Domaine Méo-Camuzet', 2019, 240),
                           v('Volnay 1er Cru Clos des Chênes', 'Domaine Lafarge', 2017, 190),
                           v('Marsannay', 'Domaine Bruno Clair', 2020, 75),
                           v('Rully 1er Cru', 'Domaine Vincent Dureuil-Janthial', 2021, 82),
                           v('Givry', 'Domaine Joblot', 2020, 68)]),
            ('Bordeaux', [v('Saint-Estèphe', 'Château Montrose', 2014, 290),
                          v('Graves', 'Château de Chantegrive', 2019, 52),
                          v('Fronsac', 'Château Fontenil', 2016, 64),
                          v('Sauternes', 'Château Suduiraut', 2015, 95)]),
            ('Loire & Jura', [v('Savennières Roche aux Moines', 'Domaine aux Moines', 2019, 88),
                              v('Bourgueil', 'Domaine de la Butte', 2020, 46),
                              v('Arbois Vin Jaune', 'Domaine Tissot', 2015, 120),
                              v('Côtes du Jura Chardonnay', 'Domaine Labet', 2020, 72)]),
            ('Rhône & Provence', [v('Condrieu', 'Domaine Georges Vernay Coteau de Vernon', 2021, 160),
                                  v('Saint-Péray', 'Domaine Alain Voge', 2021, 58),
                                  v('Gigondas', 'Domaine Santa Duc', 2019, 66),
                                  v('Palette', 'Château Simone', 2019, 98),
                                  v('Bellet', 'Clos Saint-Vincent', 2021, 74),
                                  v('Cassis', 'Clos Sainte Magdeleine', 2022, 56)]),
        ]],
    },
    {
        'nom': 'formule_magnums', 'titre': 'Chez Germaine', 'sous_titre': 'Vins — bouteille 75 cl', 'devise': '€',
        'police': 'serif', 'format': 'fr', 'colonne_verre': True, 'pages': [[
            ('Effervescents', [v('Crémant de Loire', 'Langlois-Château', None, 32, 6),
                               v('Champagne Blanc de Blancs Initial', 'Jacques Selosse', None, 260)]),
            ('Blancs', [v('Picpoul de Pinet', 'Domaine Félines Jourdan', 2023, 26, 5),
                        v('Côtes Catalanes Les Calcinaires', 'Domaine Gauby', 2022, 44),
                        v('Bouzeron', 'Domaine A. et P. de Villaine', 2021, 39, 7)]),
            ('Rouges', [v('Côtes du Rhône', 'Domaine de la Janasse', 2022, 29, 5.5),
                        v('Marcillac', 'Domaine du Cros', 2022, 27),
                        v('Irouléguy', 'Domaine Arretxea', 2019, 46),
                        v('Pic Saint-Loup', 'Domaine de l\'Hortus', 2020, 38, 7)]),
        ]],
    },
]


def police(nom, taille):
    return ImageFont.truetype(POLICES[nom], taille)


def prix_texte(prix, devise, langue):
    if prix is None:
        return ''
    nombre = f'{prix:g}'.replace('.', ',') if langue != 'en' else f'{prix:g}'
    return f'{devise}{nombre}' if devise == '£' else f'{nombre} {devise}'


def libelle(w, fmt):
    m = '' if w['millesime'] is None else f" {w['millesime']}"
    if fmt == 'en':
        return f"{w['nom']}, {w['producteur']}{m}"
    if fmt == 'es':
        return f"{w['producteur']} · {w['nom']}{m}"
    if fmt == 'it':
        return f"{w['nom']}{m} — {w['producteur']}"
    return f"{w['nom']}{m}, {w['producteur']}"


def dessiner_page(carte, sections, numero, total):
    """La page propre, avant la photo."""
    ardoise = carte.get('mode') == 'ardoise'
    colonnes = carte.get('colonnes', 1)
    larg, haut = (1400 if colonnes == 2 else 1240), 1754
    fond, encre, accent = ((40, 46, 43), (236, 236, 228), (240, 214, 140)) if ardoise else \
        ((250, 247, 240), (35, 28, 28), (122, 28, 52))
    im = Image.new('RGB', (larg, haut), fond)
    d = ImageDraw.Draw(im)
    if ardoise:
        alea = random.Random(carte['nom'])
        for _ in range(12000):
            x, y = alea.randrange(larg), alea.randrange(haut)
            g = alea.randint(46, 64)
            d.point((x, y), fill=(g, g + 4, g + 1))
        d.rectangle([0, 0, larg - 1, haut - 1], outline=(118, 80, 46), width=36)
    taille = 28 if colonnes == 2 else 34
    t_titre, t_rub, t_ligne = police(carte['police'], 62), police(carte['police'], 40), police(carte['police'], taille)
    y = 90
    titre = carte['titre'] + (' (suite)' if numero > 1 else '')
    d.text((larg // 2, y), titre, font=t_titre, fill=accent, anchor='mt')
    y += 86
    d.text((larg // 2, y), carte['sous_titre'], font=t_rub, fill=encre, anchor='mt')
    y += 80
    if carte['colonne_verre']:
        entete = {'en': 'Glass   Bottle', 'es': 'Copa   Botella', 'it': 'Calice   Bottiglia'}.get(carte['format'], 'Verre   Bouteille')
        d.text((larg - 90, y), entete, font=police(carte['police'], 26), fill=encre, anchor='ra')
        y += 46
    largeur_col = (larg - 160) // colonnes
    debut_y = y
    # Deux colonnes : la première moitié des vins à gauche, le reste à droite, et le
    # producteur sur une seconde ligne, comme sur les cartes serrées.
    moitie = sum(len(ws) for _, ws in sections) / 2
    deja = 0
    col = 0
    t_prod = police(carte['police'], taille - 6)
    for rub, vins in sections:
        if colonnes == 2 and col == 0 and deja >= moitie:
            col, y = 1, debut_y
        deja += len(vins)
        x0 = 80 + col * (largeur_col + 40)
        x1 = x0 + largeur_col - (40 if colonnes == 2 else 10)
        d.text((x0, y), rub, font=t_rub, fill=accent)
        y += 60
        for w in vins:
            texte = libelle(w, carte['format'])
            verre_a_part = carte['colonne_verre'] and not ardoise
            place = (x1 - 190 - 110 if verre_a_part else x1 - 130) - (x0 + 22)
            # Une ligne trop longue pour sa place passe le producteur à la ligne, comme sur
            # les cartes serrées ; sans quoi elle chevaucherait les prix.
            deux_lignes = colonnes == 2 or d.textlength(texte, font=t_ligne) > place
            if deux_lignes:
                m = '' if w['millesime'] is None else f" {w['millesime']}"
                d.text((x0 + 22, y), f"{w['nom']}{m}", font=t_ligne, fill=encre)
                d.text((x0 + 40, y + taille + 4), w['producteur'], font=t_prod, fill=encre)
            else:
                d.text((x0 + 22, y), texte, font=t_ligne, fill=encre)
            if ardoise:
                d.text((x1, y), prix_texte(w['prix_verre'], carte['devise'], carte['format']), font=t_ligne, fill=encre, anchor='ra')
            else:
                if verre_a_part and w['prix_verre'] is not None:
                    d.text((x1 - 190, y), prix_texte(w['prix_verre'], carte['devise'], carte['format']), font=t_ligne, fill=encre, anchor='ra')
                d.text((x1, y), prix_texte(w['prix'], carte['devise'], carte['format']), font=t_ligne, fill=encre, anchor='ra')
            y += 2 * taille + 16 if deux_lignes else 50
        y += 24
    if total > 1:
        d.text((larg // 2, haut - 70), f'{numero} / {total}', font=police(carte['police'], 26), fill=encre, anchor='mt')
    return im


def perspective(points_dest, points_src):
    """Les huit coefficients de Image.PERSPECTIVE, par élimination de Gauss."""
    a, b = [], []
    for (x, y), (u, w) in zip(points_dest, points_src):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.append(u)
        a.append([0, 0, 0, x, y, 1, -w * x, -w * y]); b.append(w)
    n = 8
    m = [a[i] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(m[r][c]))
        m[c], m[p] = m[p], m[c]
        for r in range(n):
            if r != c and m[r][c]:
                f = m[r][c] / m[c][c]
                m[r] = [m[r][k] - f * m[c][k] for k in range(n + 1)]
    return [m[i][n] / m[i][i] for i in range(n)]


def photographier(page, alea):
    """La page posée sur une table, prise au téléphone."""
    larg, haut = page.size
    marge = 120
    table = Image.new('RGB', (larg + 2 * marge, haut + 2 * marge), (92, 64, 44))
    table.paste(page, (marge, marge))
    tl, th = table.size
    j = lambda: alea.uniform(0, 70)  # noqa: E731
    dest = [(0, 0), (tl, 0), (tl, th), (0, th)]
    src = [(j(), j()), (tl - j(), j()), (tl - j(), th - j()), (j(), th - j())]
    photo = table.transform((tl, th), Image.PERSPECTIVE, perspective(dest, src), Image.BICUBIC)
    photo = photo.rotate(alea.uniform(-3, 3), resample=Image.BICUBIC, fillcolor=(70, 50, 35))
    # Une ombre douce qui traverse la page, comme une main ou un verre.
    ombre = Image.new('L', photo.size, 0)
    od = ImageDraw.Draw(ombre)
    cx, cy = alea.randrange(photo.size[0]), alea.randrange(photo.size[1])
    od.ellipse([cx - 500, cy - 380, cx + 500, cy + 380], fill=alea.randint(40, 75))
    ombre = ombre.filter(ImageFilter.GaussianBlur(160))
    photo = Image.composite(Image.new('RGB', photo.size, (0, 0, 0)), photo, ombre)
    photo = photo.filter(ImageFilter.GaussianBlur(alea.uniform(0.5, 1.1)))
    grain = Image.effect_noise(photo.size, alea.uniform(6, 12)).convert('RGB')
    photo = Image.blend(photo, grain, 0.05)
    photo.thumbnail((1600, 1600))
    return photo


def main():
    if len(sys.argv) != 2:
        sys.exit('usage : fabriquer_cartes.py <dossier du banc>')
    dossier = Path(sys.argv[1]).expanduser() / 'cartes'
    for carte in CARTES:
        alea = random.Random(f'banc-{carte["nom"]}')
        cible = dossier / carte['nom']
        cible.mkdir(parents=True, exist_ok=True)
        for ancienne in cible.glob('page*.jpg'):
            ancienne.unlink()
        pages = carte['pages']
        for i, sections in enumerate(pages, start=1):
            photo = photographier(dessiner_page(carte, sections, i, len(pages)), alea)
            photo.save(cible / f'page{i}.jpg', quality=alea.randint(72, 86))
        vins = [w for sections in pages for _, ws in sections for w in ws]
        reference = {'mode': carte.get('mode', 'carte'), 'vins': vins}
        (cible / 'reference.json').write_text(json.dumps(reference, ensure_ascii=False, indent=1) + '\n')
        print(f'{carte["nom"]} : {len(pages)} page(s), {len(vins)} vins')


if __name__ == '__main__':
    main()

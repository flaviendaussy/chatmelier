import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

dest_dirs = [
    '/home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/app/assets/badges',
    '/home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/assets/assets/badges'
]

def create_badge(
    filename_base,
    tier,
    title_top,
    icon_symbol,
    subtitle_bottom,
    accent_color,
    bg_gradient_colors
):
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size // 2, size // 2
    r_outer = 240
    r_inner = 216

    # 1. Subtle drop shadow
    shadow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)
    shadow_draw.ellipse([cx - r_outer + 4, cy - r_outer + 8, cx + r_outer + 4, cy + r_outer + 8], fill=(0, 0, 0, 170))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(12))
    img.paste(shadow_img, (0, 0), shadow_img)

    # 2. Outer Metal Ring
    if tier == "diamond":
        ring_outer_c = (0, 229, 255, 255)
        ring_inner_c = (178, 255, 255, 255)
        ring_mid_c = (0, 150, 200, 255)
    elif tier == "gold":
        ring_outer_c = (212, 175, 55, 255)
        ring_inner_c = (255, 223, 115, 255)
        ring_mid_c = (160, 120, 20, 255)
    elif tier == "bronze":
        ring_outer_c = (205, 127, 50, 255)
        ring_inner_c = (240, 168, 96, 255)
        ring_mid_c = (140, 75, 25, 255)
    else:  # silver
        ring_outer_c = (192, 192, 192, 255)
        ring_inner_c = (240, 240, 240, 255)
        ring_mid_c = (120, 120, 120, 255)

    # Draw outer thick metallic ring
    for i in range(24):
        radius = r_outer - i
        t = i / 24.0
        r = int(ring_outer_c[0] * (1 - t) + ring_inner_c[0] * t)
        g = int(ring_outer_c[1] * (1 - t) + ring_inner_c[1] * t)
        b = int(ring_outer_c[2] * (1 - t) + ring_inner_c[2] * t)
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], outline=(r, g, b, 255), width=2)

    # Inner disc with radial gradient
    inner_disc = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    disc_draw = ImageDraw.Draw(inner_disc)
    c_start, c_end = bg_gradient_colors

    for r_curr in range(r_inner, 0, -1):
        ratio = r_curr / r_inner
        col = (
            int(c_start[0] * (1 - ratio) + c_end[0] * ratio),
            int(c_start[1] * (1 - ratio) + c_end[1] * ratio),
            int(c_start[2] * (1 - ratio) + c_end[2] * ratio),
            255
        )
        disc_draw.ellipse([cx - r_curr, cy - r_curr, cx + r_curr, cy + r_curr], fill=col)

    # Blend inner disc into main image
    img = Image.alpha_composite(img, inner_disc)
    draw = ImageDraw.Draw(img)

    # Draw inner filigree ring
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], outline=ring_inner_c, width=3)
    draw.ellipse([cx - r_inner + 8, cy - r_inner + 8, cx + r_inner - 8, cy + r_inner - 8], outline=ring_mid_c, width=1)

    # Decorative dots / rivets around the border
    dot_radius = r_inner - 4
    for angle in range(0, 360, 15):
        rad = math.radians(angle)
        dx = cx + dot_radius * math.cos(rad)
        dy = cy + dot_radius * math.sin(rad)
        draw.ellipse([dx - 2.5, dy - 2.5, dx + 2.5, dy + 2.5], fill=ring_inner_c)

    # Center Emblem Art
    # 1. Glowing central halo
    halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    halo_draw.ellipse([cx - 105, cy - 105, cx + 105, cy + 105], fill=(*accent_color[:3], 100))
    halo = halo.filter(ImageFilter.GaussianBlur(28))
    img = Image.alpha_composite(img, halo)
    draw = ImageDraw.Draw(img)

    # Load Fonts
    font_symbol = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 90)

    # Auto-scaling for title_top
    title_text = title_top.upper()
    title_size = 22
    while title_size > 14:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/lato/Lato-Bold.ttf", title_size)
        bbox = draw.textbbox((0, 0), title_text, font=font_title)
        if (bbox[2] - bbox[0]) <= 320:
            break
        title_size -= 1
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/lato/Lato-Bold.ttf", title_size)

    # Auto-scaling for subtitle_bottom
    sub_text = subtitle_bottom.upper()
    sub_size = 17
    while sub_size > 12:
        font_sub = ImageFont.truetype("/usr/share/fonts/truetype/lato/Lato-Bold.ttf", sub_size)
        bbox = draw.textbbox((0, 0), sub_text, font=font_sub)
        if (bbox[2] - bbox[0]) <= 260:
            break
        sub_size -= 1
    font_sub = ImageFont.truetype("/usr/share/fonts/truetype/lato/Lato-Bold.ttf", sub_size)

    # 2. Central symbol / graphic
    bbox = draw.textbbox((0, 0), icon_symbol, font=font_symbol)
    w_sym = bbox[2] - bbox[0]
    h_sym = bbox[3] - bbox[1]
    sym_x = cx - w_sym // 2
    sym_y = cy - h_sym // 2 - 14

    # Drop shadow on symbol
    draw.text((sym_x + 3, sym_y + 4), icon_symbol, font=font_symbol, fill=(0, 0, 0, 180))
    draw.text((sym_x, sym_y), icon_symbol, font=font_symbol, fill=(255, 255, 255, 255))

    # 3. Top Centered Header Banner
    top_box = draw.textbbox((0, 0), title_text, font=font_title)
    w_top = top_box[2] - top_box[0]
    draw.text((cx - w_top // 2 + 1, cy - 148 + 1), title_text, font=font_title, fill=(0, 0, 0, 220))
    draw.text((cx - w_top // 2, cy - 148), title_text, font=font_title, fill=ring_inner_c)

    # 4. Bottom Ribbon / Plaque
    sub_box = draw.textbbox((0, 0), sub_text, font=font_sub)
    w_sub = sub_box[2] - sub_box[0]

    ribbon_w = min(360, max(230, w_sub + 56))
    ribbon_h = 44
    rx1, ry1 = cx - ribbon_w // 2, cy + 120
    rx2, ry2 = cx + ribbon_w // 2, ry1 + ribbon_h

    # Ribbon shadow
    draw.rounded_rectangle([rx1 + 2, ry1 + 3, rx2 + 2, ry2 + 3], radius=10, fill=(0, 0, 0, 150))
    # Ribbon body
    draw.rounded_rectangle([rx1, ry1, rx2, ry2], radius=10, fill=(22, 18, 28, 245), outline=ring_inner_c, width=2)

    # Ribbon text
    draw.text((cx - w_sub // 2, ry1 + 11), sub_text, font=font_sub, fill=(255, 255, 255, 245))

    # Stars on sides of ribbon
    draw.text((rx1 + 10, ry1 + 10), "★", font=font_sub, fill=ring_inner_c)
    draw.text((rx2 - 24, ry1 + 10), "★", font=font_sub, fill=ring_inner_c)

    # Save to destination directories
    for d in dest_dirs:
        os.makedirs(d, exist_ok=True)
        out_png = os.path.join(d, f"{filename_base}.png")
        out_webp = os.path.join(d, f"{filename_base}.webp")
        img.save(out_png, "PNG")
        img.save(out_webp, "WEBP", quality=95)

    print(f"Generated {filename_base} (tier={tier})")

badges_to_generate = [
    # --- Milestones & Cellar ---
    ("milestone_bottles_500", "diamond", "500 Bouteilles", "🏛️", "Patrimoine", (0, 229, 255), ((25, 30, 55), (10, 12, 22))),
    ("milestone_bottles_1000", "diamond", "1000 Bouteilles", "👑", "Grande Réserve", (255, 215, 0), ((40, 20, 50), (12, 8, 20))),
    ("milestone_tastings_5", "bronze", "5 Dégustations", "🍷", "Première Goulée", (205, 127, 50), ((50, 25, 20), (20, 10, 10))),
    ("milestone_tastings_25", "silver", "25 Dégustations", "👃", "Palais Affûté", (192, 192, 192), ((35, 30, 40), (15, 12, 18))),
    ("milestone_tastings_50", "gold", "50 Dégustations", "📜", "Sommelier Amateur", (212, 175, 55), ((55, 35, 15), (20, 12, 8))),
    ("milestone_tastings_100", "diamond", "100 Dégustations", "🏆", "Grand Dégustateur", (0, 229, 255), ((20, 45, 60), (8, 18, 28))),
    ("milestone_tastings_250", "diamond", "250 Dégustations", "🔮", "Maître du Palais", (168, 85, 247), ((38, 18, 55), (15, 8, 25))),
    ("milestone_grand_cru_collection", "gold", "Grands Crus", "💎", "Collectionneur", (255, 215, 0), ((60, 20, 30), (22, 10, 14))),
    ("milestone_cellar_centurion", "diamond", "Vin de Garde", "⌛", "Cuvée Centenaire", (255, 215, 0), ((45, 15, 35), (18, 6, 15))),

    # --- Grapes ---
    ("grape_chenin", "gold", "Cépage Chenin", "🍯", "Alchimiste Chenin", (245, 158, 11), ((60, 45, 15), (22, 16, 6))),
    ("grape_gewurztraminer", "silver", "Gewurztraminer", "🌹", "Exotisme Épicé", (244, 114, 182), ((50, 20, 35), (20, 10, 16))),

    # --- Cocktails ---
    ("cocktail_master", "silver", "Cocktails", "🍹", "Maître Mixologue", (249, 115, 22), ((45, 25, 20), (18, 10, 8))),
    ("cocktail_expert", "gold", "Mixologie", "🧪", "Alchimiste Shaker", (212, 175, 55), ((50, 30, 15), (20, 12, 6))),
    ("cocktail_legend", "diamond", "Comptoir", "🌟", "Légende du Bar", (0, 229, 255), ((25, 30, 60), (10, 12, 28))),
    ("cocktail_pantry", "silver", "Réserve du Bar", "🧊", "Barman Prévoyant", (56, 189, 248), ((20, 35, 50), (10, 16, 24))),
    ("cocktail_diy_shaker", "bronze", "Système D", "🫙", "Shaker Maison", (205, 127, 50), ((45, 30, 20), (18, 12, 8))),
    ("cocktail_vintage_punch", "silver", "Convivialité", "🥣", "Punch Sommelier", (249, 115, 22), ((48, 25, 15), (20, 10, 6))),

    # --- Regions ---
    ("region_sud_ouest", "silver", "Terroir", "🦆", "Bastide Sud-Ouest", (217, 119, 6), ((50, 25, 20), (20, 10, 8))),
    ("region_languedoc_roussillon", "silver", "Méditerranée", "🌿", "Garrigue & Soleil", (16, 185, 129), ((20, 45, 30), (10, 20, 14))),
    ("region_corse", "silver", "Île de Beauté", "🏝️", "Vignoble Corse", (14, 165, 233), ((20, 35, 55), (10, 16, 26))),
    ("region_beaujolais", "silver", "Beaujolais", "🍇", "Les Dix Crus", (236, 72, 153), ((50, 15, 30), (22, 8, 15))),
    ("region_toscana", "silver", "Toscana", "🏛️", "Renaissance", (212, 175, 55), ((55, 30, 20), (22, 12, 8))),
    ("region_piemonte", "gold", "Piemonte", "👑", "Noblesse Piémont", (255, 215, 0), ((55, 15, 25), (24, 6, 12))),
    ("region_veneto", "silver", "Veneto", "🎭", "Sérénissime", (168, 85, 247), ((35, 20, 45), (15, 8, 20))),
    ("region_rioja", "silver", "La Rioja", "🍷", "Chêne & Rioja", (220, 38, 38), ((55, 18, 22), (24, 8, 10))),
    ("region_napa", "gold", "Napa Valley", "🌉", "Or Californien", (255, 215, 0), ((50, 35, 15), (22, 15, 6))),
    ("region_douro", "silver", "Portugal", "🇵🇹", "Terrasses du Douro", (220, 38, 38), ((45, 20, 20), (18, 8, 8))),

    # --- Looser ---
    ("looser_poussiere", "bronze", "Oubliettes", "🕸️", "Toiles d'Araignée", (156, 163, 175), ((35, 35, 35), (15, 15, 15))),

    # --- Savant / Knowledge ---
    ("savant_jefferson", "gold", "Ambassade", "📜", "Thomas Jefferson", (212, 175, 55), ((55, 35, 20), (22, 14, 8))),
    ("savant_vents", "silver", "Val du Rhône", "💨", "Maître du Mistral", (56, 189, 248), ((20, 35, 50), (10, 16, 24))),
    ("savant_sanguis_christi", "diamond", "In Vino Veritas", "✝️", "Sanguis Christi", (225, 29, 72), ((45, 10, 20), (18, 5, 8))),

    # --- New Features & App Highlights ---
    ("savant_flight_discovery", "silver", "Flight Scan", "🍷", "Flight 3 Verres", (236, 72, 153), ((45, 20, 35), (18, 8, 14))),
    ("savant_grand_flight", "gold", "Grand Flight", "🦅", "Maestro 5 Verres", (255, 215, 0), ((60, 30, 20), (25, 12, 8))),
    ("spirit_fill_vigilant", "bronze", "Jauge Flacon", "🥃", "Le Dernier Trait", (205, 127, 50), ((45, 25, 15), (18, 10, 6))),
    ("spirit_amaretto_italian", "silver", "Saronno", "🌰", "Dolce Vita Amaretto", (245, 158, 11), ((50, 30, 15), (20, 12, 6))),
    ("spirit_collection_prestige", "gold", "Cabinet", "🏺", "Cabinet Spiritueux", (212, 175, 55), ((55, 35, 18), (22, 14, 7))),
    ("savant_consensus_table_master", "gold", "Choisir en groupe", "👥", "Maître de Table", (16, 185, 129), ((25, 45, 35), (10, 20, 15))),
    ("savant_verticale_tasting", "gold", "Verticale", "⏳", "Voyage Temporel", (212, 175, 55), ((55, 25, 35), (22, 10, 15))),
    ("savant_blind_taste_master", "diamond", "Aveugle Parfait", "🎯", "Nez Absolu", (0, 229, 255), ((20, 30, 60), (8, 12, 28))),
    ("savant_accord_mets_vins_etoile", "gold", "Accord Sublime", "✨", "Harmonie Étoilée", (255, 215, 0), ((50, 30, 45), (20, 12, 20))),
]

for b in badges_to_generate:
    create_badge(*b)

print(f"\nAll {len(badges_to_generate)} badges successfully generated in PNG and WEBP formats!")

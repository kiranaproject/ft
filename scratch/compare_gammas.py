import os
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")

gammas = [0.55, 0.65, 0.72, 0.78, 0.85]
imgs = {}
for g in gammas:
    p = os.path.join(scratch_dir, f"gamma_{g}.png")
    imgs[g] = Image.open(p)

# We want to compare:
# 1. Close-up of "Next Theme" button (crop: [30, 42, 235, 84])
# 2. Close-up of Header label "Static Label (Non-Selectable)..." (crop: [30, 14, 470, 36])
# 3. Close-up of "Selectable Text: Click & drag..." (crop: [30, 246, 470, 272])
# 4. Zoomed-in 3x snippet of the word "Selectable" or "Next Theme"

# Let's inspect the crop sizes
btn_crop = (30, 42, 235, 84)     # w=205, h=42
lbl_crop = (30, 12, 470, 38)     # w=440, h=26
txt_crop = (30, 246, 470, 272)   # w=440, h=26
word_crop = (30, 246, 170, 272)  # "Selectable Text" w=140, h=26

# Compose a comprehensive comparison sheet
sheet_w = 1200
sheet_h = 1000
sheet = Image.new("RGB", (sheet_w, sheet_h), (24, 26, 32))
draw = ImageDraw.Draw(sheet)

try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    font_sec = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    font_lbl = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    font_big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
except Exception:
    font_title = font_sec = font_lbl = font_big = ImageFont.load_default()

draw.text((40, 20), "Floria Toolkit - Font Thickness / Gamma Tuning Comparison", fill=(255, 255, 255), font=font_title)
draw.text((40, 50), "Evaluation of FreeType/AGG rasterizer gamma curves from 0.55 (original heavy) to 0.85 (ultra-light)", fill=(160, 170, 190), font=font_lbl)

# Row of Button close-ups
y = 90
draw.text((40, y), "1. Button Text ('Next Theme') at 100% scale:", fill=(100, 200, 255), font=font_sec)
y += 30

for idx, g in enumerate(gammas):
    x = 40 + idx * 225
    cropped = imgs[g].crop(btn_crop)
    sheet.paste(cropped, (x, y))
    draw.rectangle([x-1, y-1, x + cropped.width, y + cropped.height], outline=(70, 75, 90), width=1)
    tag = f"gamma = {g}"
    if g == 0.55:
        tag += " (Original)"
    elif g == 0.72:
        tag += " (Refined)"
    draw.text((x, y + cropped.height + 6), tag, fill=(220, 220, 220), font=font_lbl)

y += 95
draw.text((40, y), "2. Text Widget ('Selectable Text: Click & drag...') at 100% scale:", fill=(100, 200, 255), font=font_sec)
y += 30

for idx, g in enumerate([0.55, 0.72, 0.78]):
    row_y = y + idx * 45
    cropped = imgs[g].crop(txt_crop)
    sheet.paste(cropped, (230, row_y))
    draw.rectangle([229, row_y-1, 230 + cropped.width, row_y + cropped.height], outline=(70, 75, 90), width=1)
    tag = f"gamma = {g:0.2f}"
    if g == 0.55:
        tag += " [Original: slightly thick/heavy]"
    elif g == 0.72:
        tag += " [Refined: crisp & natural]"
    elif g == 0.80:
        tag += " [Lighter: thin & delicate]"
    draw.text((40, row_y + 4), tag, fill=(200, 215, 235), font=font_lbl)

y += 165
draw.text((40, y), "3. 300% Pixel Zoom Comparison ('Selectable Text'):", fill=(100, 200, 255), font=font_sec)
y += 30

for idx, g in enumerate([0.55, 0.65, 0.72, 0.78, 0.85]):
    col_x = 40 + (idx % 2) * 560
    row_y = y + (idx // 2) * 115
    
    snippet = imgs[g].crop(word_crop)
    zoomed = snippet.resize((snippet.width * 3, snippet.height * 3), Image.NEAREST)
    # limit zoomed width to 520
    zoomed = zoomed.crop((0, 0, 520, zoomed.height))
    sheet.paste(zoomed, (col_x, row_y))
    draw.rectangle([col_x-1, row_y-1, col_x + zoomed.width, row_y + zoomed.height], outline=(70, 75, 90), width=1)
    
    lbl = f"Gamma {g}"
    if g == 0.55:
        lbl += " (Original - dark stem dilation)"
    elif g == 0.72:
        lbl += " (Crisp, perfectly balanced stems)"
    elif g == 0.85:
        lbl += " (Very thin, high contrast)"
    draw.text((col_x, row_y - 20), lbl, fill=(240, 240, 240), font=font_lbl)

out_file = os.path.join(artifact_dir, "font_gamma_comparison.png")
sheet.save(out_file)
print(f"Comparison sheet generated: {out_file}")

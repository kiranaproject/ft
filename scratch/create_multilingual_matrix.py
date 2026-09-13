import os
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"

p_light = os.path.join(artifact_dir, "multilingual_1_initial_light.png")
p_copied = os.path.join(artifact_dir, "multilingual_2_japanese_copied.png")
p_dark = os.path.join(artifact_dir, "multilingual_3_dark_mode.png")
p_nord = os.path.join(artifact_dir, "multilingual_4_nord_theme.png")

img_light = Image.open(p_light)
img_copied = Image.open(p_copied)
img_dark = Image.open(p_dark)
img_nord = Image.open(p_nord)

# Matrix canvas: 2x2 grid
col_w = img_light.width
row_h = img_light.height

pad_top = 80
pad_side = 40
pad_bottom = 40
gap_x = 30
gap_y = 45
header_h = 30

matrix_w = pad_side * 2 + col_w * 2 + gap_x
matrix_h = pad_top + 2 * (row_h + header_h + gap_y) + pad_bottom - gap_y

canvas = Image.new("RGB", (matrix_w, matrix_h), (20, 22, 28))
draw = ImageDraw.Draw(canvas)

try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
    font_sub = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    font_hdr = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
except Exception:
    font_title = font_sub = font_hdr = ImageFont.load_default()

draw.text((pad_side, 20), "Floria Toolkit — Multilingual & Internationalization Showcase Matrix", fill=(255, 255, 255), font=font_title)
draw.text((pad_side, 50), "Demonstrating Unicode UTF-8 text rendering across 14 languages & writing systems (C and Python APIs)", fill=(160, 175, 195), font=font_sub)

cells = [
    (0, 0, img_light, "1. Light Mode (Default Qt6 Theme) - 14 Languages Overview"),
    (0, 1, img_copied, "2. Interactive Selection & System Clipboard Copy (Japanese Selected)"),
    (1, 0, img_dark, "3. Dark Mode (Smooth Contrast & Crisp Gamma 0.75 Antialiasing)"),
    (1, 1, img_nord, "4. Theme Hot-swapping (Nord Dark Vector Palette)")
]

for r, c, img, label in cells:
    x = pad_side + c * (col_w + gap_x)
    y = pad_top + r * (row_h + header_h + gap_y)
    
    draw.text((x, y), label, fill=(100, 200, 255), font=font_hdr)
    y += header_h
    
    canvas.paste(img, (x, y))
    draw.rectangle([x - 1, y - 1, x + col_w, y + row_h], outline=(65, 70, 85), width=1)

out_file = os.path.join(artifact_dir, "multilingual_showcase_matrix.png")
canvas.save(out_file)
print(f"Generated multilingual matrix: {out_file} ({canvas.size})")

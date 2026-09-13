import subprocess
import time
import os
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
c_exec = "/home/afumi/Documents/projects/floria-toolkit/target/bin/c_example"

tested_gammas = [0.55, 0.65, 0.72, 0.75, 0.80]

def capture_modes_for_gamma(gamma_val):
    env = os.environ.copy()
    env["DISPLAY"] = ":0"
    env["FT_FONT_GAMMA"] = str(gamma_val)
    proc = subprocess.Popen([c_exec], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
    time.sleep(0.8)

    try:
        res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria"], 
                             capture_output=True, text=True, check=True, env=env)
        win_ids = res.stdout.strip().splitlines()
        win_id = int(win_ids[-1])

        # Capture Light Mode
        light_xwd = os.path.join(scratch_dir, f"gamma_{gamma_val}_light.xwd")
        light_png = os.path.join(scratch_dir, f"gamma_{gamma_val}_light.png")
        subprocess.run(["xwd", "-id", str(win_id), "-out", light_xwd, "-silent"], check=True, env=env)
        subprocess.run(["ffmpeg", "-y", "-i", light_xwd, "-update", "1", "-frames:v", "1", light_png],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        # Toggle Dark Mode (Click at 367, 63)
        subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "367", "63"], env=env)
        time.sleep(0.1)
        subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
        time.sleep(0.3)

        # Capture Dark Mode
        dark_xwd = os.path.join(scratch_dir, f"gamma_{gamma_val}_dark.xwd")
        dark_png = os.path.join(scratch_dir, f"gamma_{gamma_val}_dark.png")
        subprocess.run(["xwd", "-id", str(win_id), "-out", dark_xwd, "-silent"], check=True, env=env)
        subprocess.run(["ffmpeg", "-y", "-i", dark_xwd, "-update", "1", "-frames:v", "1", dark_png],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        print(f"Captured gamma {gamma_val}: Light & Dark")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=1.0)
        except Exception:
            proc.kill()
        time.sleep(0.3)

for g in tested_gammas:
    capture_modes_for_gamma(g)

# Build Comprehensive Matrix Graphic
sheet_w = 1260
sheet_h = 1120
sheet = Image.new("RGB", (sheet_w, sheet_h), (22, 24, 30))
draw = ImageDraw.Draw(sheet)

try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    font_sec = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    font_lbl = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    font_bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
except Exception:
    font_title = font_sec = font_lbl = font_bold = ImageFont.load_default()

draw.text((40, 20), "Floria Toolkit - Font Thickness / Stem Darkening Matrix", fill=(255, 255, 255), font=font_title)
draw.text((40, 50), "Comparing FreeType gamma values across Light and Dark theme modes (Default Qt6 style)", fill=(160, 175, 195), font=font_lbl)

# Section 1: Button text in Light & Dark Mode
# Crop of button: (30, 42, 235, 84)
btn_crop = (30, 42, 235, 84)

y = 85
draw.text((40, y), "1. Button Text ('Next Theme') - Light Mode vs Dark Mode (100% scale):", fill=(100, 200, 255), font=font_sec)
y += 30

for idx, g in enumerate(tested_gammas):
    x = 40 + idx * 240
    im_l = Image.open(os.path.join(scratch_dir, f"gamma_{g}_light.png")).crop(btn_crop)
    im_d = Image.open(os.path.join(scratch_dir, f"gamma_{g}_dark.png")).crop(btn_crop)
    
    sheet.paste(im_l, (x, y))
    draw.rectangle([x-1, y-1, x + im_l.width, y + im_l.height], outline=(65, 70, 85), width=1)
    
    sheet.paste(im_d, (x, y + 46))
    draw.rectangle([x-1, y + 45, x + im_d.width, y + 46 + im_d.height], outline=(65, 70, 85), width=1)
    
    status = ""
    if g == 0.55:
        status = "\n(Original: Too thick)"
    elif g == 0.72:
        status = "\n(Recommended: Crisp)"
    elif g == 0.75:
        status = "\n(Optimal Thin/Sharp)"
    elif g == 0.80:
        status = "\n(Delicate)"
        
    draw.text((x + 2, y + 96), f"γ = {g:0.2f}{status}", fill=(210, 220, 235), font=font_lbl)

# Section 2: Text Widget in Light & Dark Mode (440px wide)
txt_crop = (30, 246, 470, 272)

y += 150
draw.text((40, y), "2. Text Widget Sample ('Selectable Text: Click & drag to select me...'):", fill=(100, 200, 255), font=font_sec)
y += 30

display_gammas = [0.55, 0.70, 0.72, 0.75]
# Let's show gamma 0.55 vs 0.72 vs 0.75
comp_gammas = [
    (0.55, "Gamma 0.55 (Original: heavy dilation, letters feel dense & thick)"),
    (0.72, "Gamma 0.72 (Refined: natural desktop stroke weight, balanced anti-aliasing)"),
    (0.75, "Gamma 0.75 (Clean & Modern: slightly thinner, high legibility, crisp stems)"),
    (0.80, "Gamma 0.80 (Delicate: slim strokes, excellent on ultra-high DPI screens)")
]

for g, desc in comp_gammas:
    draw.text((40, y), desc, fill=(180, 210, 245), font=font_bold)
    y += 22
    
    im_l = Image.open(os.path.join(scratch_dir, f"gamma_{g}_light.png")).crop(txt_crop)
    im_d = Image.open(os.path.join(scratch_dir, f"gamma_{g}_dark.png")).crop(txt_crop)
    
    sheet.paste(im_l, (40, y))
    draw.rectangle([39, y-1, 40 + im_l.width, y + im_l.height], outline=(65, 70, 85), width=1)
    
    sheet.paste(im_d, (500, y))
    draw.rectangle([499, y-1, 500 + im_d.width, y + im_d.height], outline=(65, 70, 85), width=1)
    
    y += 36

# Section 3: 350% Zoomed comparison
y += 15
draw.text((40, y), "3. 350% Pixel Zoom - Glyph Anatomy Comparison ('Selectable'):", fill=(100, 200, 255), font=font_sec)
y += 30

word_crop = (30, 246, 150, 272) # "Selectable"
zoom_gammas = [(0.55, "Original (0.55)"), (0.72, "Refined (0.72)"), (0.75, "Optimal (0.75)"), (0.80, "Light (0.80)")]

for idx, (g, title) in enumerate(zoom_gammas):
    x = 40 + idx * 300
    im_l = Image.open(os.path.join(scratch_dir, f"gamma_{g}_light.png")).crop(word_crop)
    im_d = Image.open(os.path.join(scratch_dir, f"gamma_{g}_dark.png")).crop(word_crop)
    
    zoom_w = int(im_l.width * 2.35)
    zoom_h = int(im_l.height * 2.35)
    
    z_l = im_l.resize((zoom_w, zoom_h), Image.NEAREST)
    z_d = im_d.resize((zoom_w, zoom_h), Image.NEAREST)
    
    draw.text((x, y), title, fill=(230, 230, 230), font=font_bold)
    
    sheet.paste(z_l, (x, y + 22))
    draw.rectangle([x-1, y + 21, x + zoom_w, y + 22 + zoom_h], outline=(70, 75, 90), width=1)
    
    sheet.paste(z_d, (x, y + 22 + zoom_h + 8))
    draw.rectangle([x-1, y + 21 + zoom_h + 8, x + zoom_w, y + 22 + 2*zoom_h + 8], outline=(70, 75, 90), width=1)

out_file = os.path.join(artifact_dir, "font_rendering_improvement_matrix.png")
sheet.save(out_file)
print(f"Generated comprehensive matrix: {out_file}")

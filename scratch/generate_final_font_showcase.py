import subprocess
import time
import os
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
c_exec = "/home/afumi/Documents/projects/floria-toolkit/target/bin/c_example"

# 1. Run c_example with default gamma (0.75) and capture Light Mode and Dark Mode
env = os.environ.copy()
env["DISPLAY"] = ":0"
# Ensure FT_FONT_GAMMA is unset so default 0.75 is used
if "FT_FONT_GAMMA" in env:
    del env["FT_FONT_GAMMA"]

proc = subprocess.Popen([c_exec], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
time.sleep(0.8)

try:
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria"], 
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    win_id = int(win_ids[-1])

    # Light Mode
    p_light_xwd = os.path.join(scratch_dir, "font_default_light.xwd")
    p_light_png = os.path.join(artifact_dir, "font_showcase_light_075.png")
    subprocess.run(["xwd", "-id", str(win_id), "-out", p_light_xwd, "-silent"], check=True, env=env)
    subprocess.run(["ffmpeg", "-y", "-i", p_light_xwd, "-update", "1", "-frames:v", "1", p_light_png],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    # Toggle Dark Mode
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "367", "63"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)

    # Dark Mode
    p_dark_xwd = os.path.join(scratch_dir, "font_default_dark.xwd")
    p_dark_png = os.path.join(artifact_dir, "font_showcase_dark_075.png")
    subprocess.run(["xwd", "-id", str(win_id), "-out", p_dark_xwd, "-silent"], check=True, env=env)
    subprocess.run(["ffmpeg", "-y", "-i", p_dark_xwd, "-update", "1", "-frames:v", "1", p_dark_png],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
finally:
    proc.terminate()
    try:
        proc.wait(timeout=1.0)
    except Exception:
        proc.kill()
    time.sleep(0.3)

# 2. Build Before vs After Comparison Graphic
img_orig_light = Image.open(os.path.join(scratch_dir, "gamma_0.55_light.png"))
img_orig_dark = Image.open(os.path.join(scratch_dir, "gamma_0.55_dark.png"))
img_new_light = Image.open(p_light_png)
img_new_dark = Image.open(p_dark_png)

card_w = 1100
card_h = 760
card = Image.new("RGB", (card_w, card_h), (24, 26, 33))
draw = ImageDraw.Draw(card)

try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    font_sec = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    font_sub = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    font_bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
except Exception:
    font_title = font_sec = font_sub = font_bold = ImageFont.load_default()

draw.text((40, 22), "Floria Toolkit - Font Thickness Refinement (Before vs After)", fill=(255, 255, 255), font=font_title)
draw.text((40, 52), "Transitioned FreeType rasterizer gamma from 0.55 (heavy stem dilation) to 0.75 (clean, crisp, standard weight)", fill=(160, 175, 195), font=font_sub)

# Compare Light Mode UI
y = 90
draw.text((40, y), "Light Mode: Full Window Comparison (500x385)", fill=(100, 200, 255), font=font_sec)
y += 28

# Left: Before (0.55)
draw.text((40, y), "BEFORE: Default Gamma = 0.55 (Heavy, thick glyphs)", fill=(240, 120, 120), font=font_bold)
card.paste(img_orig_light, (40, y + 20))
draw.rectangle([39, y + 19, 40 + 500, y + 20 + 385], outline=(80, 85, 100), width=1)

# Right: After (0.75)
draw.text((560, y), "AFTER: Default Gamma = 0.75 (Refined, crisp, natural desktop weight)", fill=(110, 230, 150), font=font_bold)
card.paste(img_new_light, (560, y + 20))
draw.rectangle([559, y + 19, 560 + 500, y + 20 + 385], outline=(80, 85, 100), width=1)

# Close-up row at the bottom
y += 430
draw.text((40, y), "Magnified Glyph Stem Comparison (300% Zoom):", fill=(100, 200, 255), font=font_sec)
y += 25

word_crop = (30, 246, 170, 272) # "Selectable Text"
w_orig_l = img_orig_light.crop(word_crop)
w_orig_d = img_orig_dark.crop(word_crop)
w_new_l = img_new_light.crop(word_crop)
w_new_d = img_new_dark.crop(word_crop)

zoom_scale = 2.4
zw = int(w_orig_l.width * zoom_scale)
zh = int(w_orig_l.height * zoom_scale)

# Before Light & Dark
draw.text((40, y), "Before (γ = 0.55)", fill=(240, 130, 130), font=font_bold)
card.paste(w_orig_l.resize((zw, zh), Image.NEAREST), (40, y + 20))
card.paste(w_orig_d.resize((zw, zh), Image.NEAREST), (40, y + 20 + zh + 6))

# After Light & Dark
draw.text((560, y), "After (γ = 0.75)", fill=(120, 230, 160), font=font_bold)
card.paste(w_new_l.resize((zw, zh), Image.NEAREST), (560, y + 20))
card.paste(w_new_d.resize((zw, zh), Image.NEAREST), (560, y + 20 + zh + 6))

out_cmp = os.path.join(artifact_dir, "font_refinement_before_after.png")
card.save(out_cmp)
print(f"Generated before/after card: {out_cmp}")

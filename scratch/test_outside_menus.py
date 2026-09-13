import subprocess
import time
import os
import sys
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
os.makedirs(scratch_dir, exist_ok=True)

exec_path = "/home/afumi/Documents/projects/floria-toolkit/target/bin/outside_menu_demo"

env = os.environ.copy()
env["DISPLAY"] = ":0"

print(f"Launching {exec_path} on {env['DISPLAY']}...")
proc = subprocess.Popen([exec_path], env=env)
time.sleep(1.2)

snapshots = []

def capture_step(step_idx, step_name):
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria Toolkit - Menus Outside Window Demo"],
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    win_id = int(win_ids[-1])
    
    info = subprocess.run(["xwininfo", "-id", str(win_id)], capture_output=True, text=True, env=env)
    wx, wy, ww, wh = 0, 0, 480, 180
    for line in info.stdout.splitlines():
        if "Absolute upper-left X:" in line: wx = int(line.split(":")[-1])
        if "Absolute upper-left Y:" in line: wy = int(line.split(":")[-1])
        if "Width:" in line: ww = int(line.split(":")[-1])
        if "Height:" in line: wh = int(line.split(":")[-1])

    xwd_file = os.path.join(scratch_dir, f"outside_step{step_idx}_{step_name}.xwd")
    png_file = os.path.join(artifact_dir, f"outside_step{step_idx}_{step_name}.png")
    tmp_root_png = os.path.join(scratch_dir, f"tmp_outside_{step_idx}.png")
    
    subprocess.run(["xwd", "-root", "-out", xwd_file, "-silent"], check=True, env=env)
    subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", tmp_root_png],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    if os.path.exists(xwd_file):
        os.remove(xwd_file)
    
    full_img = Image.open(tmp_root_png)
    # Crop generous margin (160px right and 160px bottom) so menus extending outside are completely visible
    crop_box = (max(0, wx - 16), max(0, wy - 36), min(full_img.width, wx + ww + 160), min(full_img.height, wy + wh + 160))
    cropped = full_img.crop(crop_box)
    cropped.save(png_file)
    if os.path.exists(tmp_root_png):
        os.remove(tmp_root_png)

    print(f"Captured Outside Step {step_idx}: {step_name} -> {png_file}")
    snapshots.append((step_idx, step_name, png_file))
    return win_id

try:
    # 0. Initial compact window state
    win_id = capture_step(0, "initial_compact_window")

    # 1. Click "File" menu (x=25, y=14) -> Dropdown extends OUTSIDE bottom of window onto desktop!
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "25", "14"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(1, "file_menu_extends_below_window")

    # 2. Hover over "Recent Projects" (around y=138) to open cascading submenu outside
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "70", "138"], env=env)
    time.sleep(0.4)
    capture_step(2, "cascading_submenu_floating_outside")

    # 3. Dismiss menu by clicking inside window (x=240, y=90)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "240", "90"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.3)

    # 4. Right-click near the bottom-right corner of the window (x=380, y=140)
    # The context menu extends outside both the right and bottom window edges onto the desktop!
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "380", "140"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "3"], env=env)
    time.sleep(0.4)
    capture_step(3, "context_menu_extends_outside_bottom_right")

    # 5. Click "Toggle Dark Theme" in context menu (center of 2nd item, ~ y=46 inside context menu -> screen y ~ 140+46=186)
    # In window coordinates, x=430, y=186 (notice y=186 is already outside the 180px tall window!)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "430", "186"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(4, "dark_theme_toggled_via_outside_menu")

    # 6. Open File menu again in dark mode to verify dark floating menus extending outside
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "25", "14"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(5, "dark_file_menu_extends_outside")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except subprocess.TimeoutExpired:
        proc.kill()

print("[INFO] All outside-window menu steps captured!")

# Create Composite Matrix
cols = 3
rows = (len(snapshots) + cols - 1) // cols
thumb_w = 480
thumb_h = 320
pad = 16
header_h = 60
footer_h = 30

matrix_w = cols * thumb_w + (cols + 1) * pad
matrix_h = header_h + rows * thumb_h + (rows + 1) * pad + footer_h

matrix_img = Image.new("RGBA", (matrix_w, matrix_h), (22, 24, 29, 255))
draw = ImageDraw.Draw(matrix_img)

title_font = None
label_font = None
try:
    title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
    label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
except Exception:
    title_font = ImageFont.load_default()
    label_font = ImageFont.load_default()

draw.text((pad, 16), "Floria Toolkit - Menus Floating & Extending Outside Window Frame Onto Desktop", 
          fill=(255, 255, 255, 255), font=title_font)

for i, (step_idx, step_name, png_path) in enumerate(snapshots):
    r = i // cols
    c = i % cols
    x = pad + c * (thumb_w + pad)
    y = header_h + pad + r * (thumb_h + pad)
    
    if os.path.exists(png_path):
        img = Image.open(png_path).convert("RGBA")
        img.thumbnail((thumb_w, thumb_h - 26), Image.Resampling.LANCZOS)
        
        draw.rounded_rectangle([x - 2, y - 2, x + thumb_w + 2, y + thumb_h + 2], radius=6, fill=(35, 38, 46, 255), outline=(60, 65, 78, 255))
        matrix_img.paste(img, (x, y + 24), img)
        
        caption = f"Step {step_idx}: {step_name.replace('_', ' ').title()}"
        draw.text((x + 8, y + 4), caption, fill=(130, 180, 255, 255), font=label_font)

matrix_path = os.path.join(artifact_dir, "floria_menus_outside_window_matrix.png")
matrix_img.save(matrix_path)
print(f"[INFO] Generated Outside-Window Showcase Matrix -> {matrix_path}")

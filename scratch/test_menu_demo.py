import subprocess
import time
import os
import sys
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
os.makedirs(scratch_dir, exist_ok=True)

exec_path = "/home/afumi/Documents/projects/floria-toolkit/target/bin/example_menus"

env = os.environ.copy()
env["DISPLAY"] = ":0"

print(f"Launching {exec_path} on {env['DISPLAY']}...")
proc = subprocess.Popen([exec_path], env=env)
time.sleep(1.2)

snapshots = []

def capture_step(step_idx, step_name):
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria Toolkit - Window Main Menu & Pop-up Menu Demo"],
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    win_id = int(win_ids[-1])
    
    info = subprocess.run(["xwininfo", "-id", str(win_id)], capture_output=True, text=True, env=env)
    wx, wy, ww, wh = 0, 0, 800, 600
    for line in info.stdout.splitlines():
        if "Absolute upper-left X:" in line: wx = int(line.split(":")[-1])
        if "Absolute upper-left Y:" in line: wy = int(line.split(":")[-1])
        if "Width:" in line: ww = int(line.split(":")[-1])
        if "Height:" in line: wh = int(line.split(":")[-1])

    xwd_file = os.path.join(scratch_dir, f"menu_step{step_idx}_{step_name}.xwd")
    png_file = os.path.join(artifact_dir, f"menu_step{step_idx}_{step_name}.png")
    tmp_root_png = os.path.join(scratch_dir, f"tmp_root_{step_idx}.png")
    
    subprocess.run(["xwd", "-root", "-out", xwd_file, "-silent"], check=True, env=env)
    subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", tmp_root_png],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    if os.path.exists(xwd_file):
        os.remove(xwd_file)
    
    full_img = Image.open(tmp_root_png)
    crop_box = (max(0, wx - 12), max(0, wy - 36), min(full_img.width, wx + ww + 60), min(full_img.height, wy + wh + 60))
    cropped = full_img.crop(crop_box)
    cropped.save(png_file)
    if os.path.exists(tmp_root_png):
        os.remove(tmp_root_png)

    print(f"Captured Step {step_idx}: {step_name} -> {png_file}")
    snapshots.append((step_idx, step_name, png_file))
    return win_id

try:
    # 0. Initial state
    win_id = capture_step(0, "initial_state")

    # 1. Click "File" menu in the menu bar (File is around x=25, y=14)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "25", "14"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)
    capture_step(1, "file_menu_dropdown_opened")

    # 2. Hover over "Recent Files" (around y=138 inside File dropdown) to open cascading submenu
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "70", "138"], env=env)
    time.sleep(0.4)
    capture_step(2, "recent_files_cascading_submenu")

    # 3. Sweep mouse across to "Edit" menu (around x=65, y=14)
    # This verifies menu tracking across the menu bar while dropdown is active
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "65", "14"], env=env)
    time.sleep(0.4)
    capture_step(3, "edit_menu_switched_via_sweep")

    # 4. Sweep mouse to "View" menu (around x=110, y=14)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "110", "14"], env=env)
    time.sleep(0.4)
    capture_step(4, "view_menu_with_checkmarks")

    # 5. Click "Dark Mode" in the View menu (Dark mode item is 3rd item, around y=102)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "130", "102"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(5, "dark_mode_activated")

    # 6. Open View menu again in Dark Mode (x=110, y=14)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "110", "14"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.3)
    capture_step(6, "view_menu_in_dark_mode")

    # 7. Hover over "Color Themes" inside View menu in Dark Mode (around y=138)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "140", "138"], env=env)
    time.sleep(0.4)
    capture_step(7, "color_themes_cascading_in_dark_mode")

    # 8. Click "Nord Theme" inside the cascading themes submenu (Nord is 2nd item, around x=320, y=170)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "320", "170"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(8, "nord_theme_activated")

    # 9. Right-click inside the Container (x=200, y=250) -> Widget Context Menu
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "200", "250"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "3"], env=env)
    time.sleep(0.4)
    capture_step(9, "container_context_menu_opened")

    # 10. Click "Inspect Container Widget" (1st item in context menu, around x=250, y=265)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "250", "265"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(10, "container_inspect_action_executed")

    # 11. Right-click on window background (x=600, y=100) -> Window Context Menu
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "600", "100"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "3"], env=env)
    time.sleep(0.4)
    capture_step(11, "window_context_menu_opened")

    # 12. Click "Toggle Dark Mode" in window context menu (around x=650, y=170)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "650", "170"], env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.4)
    capture_step(12, "toggled_back_to_light_mode")

    # 13. Keyboard navigation test: Open "File" menu, press Down arrow twice, press Enter
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "25", "14"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "1"], env=env)
    time.sleep(0.3)
    # Down arrow -> "Open..."
    subprocess.run(["xdotool", "key", "--window", str(win_id), "Down"], env=env)
    time.sleep(0.2)
    # Down arrow -> "Save"
    subprocess.run(["xdotool", "key", "--window", str(win_id), "Down"], env=env)
    time.sleep(0.2)
    capture_step(13, "keyboard_nav_save_highlighted")

    # Press Enter
    subprocess.run(["xdotool", "key", "--window", str(win_id), "Return"], env=env)
    time.sleep(0.3)
    capture_step(14, "keyboard_nav_save_executed")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except subprocess.TimeoutExpired:
        proc.kill()

print("[INFO] All interactive menu steps captured successfully!")

# Generate Composite Showcase Matrix
cols = 3
rows = (len(snapshots) + cols - 1) // cols
thumb_w = 480
thumb_h = 360
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
    title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
except Exception:
    title_font = ImageFont.load_default()
    label_font = ImageFont.load_default()

draw.text((pad, 16), "Floria Toolkit (Ft) - Window Main Menu & Pop-up Context Menu Verification Matrix", 
          fill=(255, 255, 255, 255), font=title_font)

for i, (step_idx, step_name, png_path) in enumerate(snapshots):
    r = i // cols
    c = i % cols
    x = pad + c * (thumb_w + pad)
    y = header_h + pad + r * (thumb_h + pad)
    
    if os.path.exists(png_path):
        img = Image.open(png_path).convert("RGBA")
        img.thumbnail((thumb_w, thumb_h - 26), Image.Resampling.LANCZOS)
        
        # Plate backing
        draw.rounded_rectangle([x - 2, y - 2, x + thumb_w + 2, y + thumb_h + 2], radius=6, fill=(35, 38, 46, 255), outline=(60, 65, 78, 255))
        matrix_img.paste(img, (x, y + 24), img)
        
        caption = f"Step {step_idx}: {step_name.replace('_', ' ').title()}"
        draw.text((x + 8, y + 4), caption, fill=(130, 180, 255, 255), font=label_font)

matrix_path = os.path.join(artifact_dir, "floria_menu_showcase_matrix.png")
matrix_img.save(matrix_path)
print(f"[INFO] Generated Menu Showcase Matrix -> {matrix_path}")

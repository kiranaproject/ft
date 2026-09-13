import subprocess
import time
import os
import sys
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
os.makedirs(scratch_dir, exist_ok=True)

exec_path = "/home/afumi/Documents/projects/floria-toolkit/target/bin/widget_context_menus_demo"

env = os.environ.copy()
env["DISPLAY"] = ":0"

print(f"Launching {exec_path} on {env['DISPLAY']}...")
proc = subprocess.Popen([exec_path], env=env)
time.sleep(1.2)

snapshots = []

def get_window_id():
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria Toolkit - Default Widget Popup Menus Demo"],
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    return int(win_ids[-1])

def capture_step(step_idx, step_name):
    win_id = get_window_id()
    info = subprocess.run(["xwininfo", "-id", str(win_id)], capture_output=True, text=True, env=env)
    wx, wy, ww, wh = 0, 0, 640, 620
    for line in info.stdout.splitlines():
        if "Absolute upper-left X:" in line: wx = int(line.split(":")[-1])
        if "Absolute upper-left Y:" in line: wy = int(line.split(":")[-1])
        if "Width:" in line: ww = int(line.split(":")[-1])
        if "Height:" in line: wh = int(line.split(":")[-1])

    xwd_file = os.path.join(scratch_dir, f"ctx_step{step_idx}_{step_name}.xwd")
    png_file = os.path.join(artifact_dir, f"ctx_step{step_idx}_{step_name}.png")
    tmp_root_png = os.path.join(scratch_dir, f"tmp_root_ctx_{step_idx}.png")
    
    subprocess.run(["xwd", "-root", "-out", xwd_file, "-silent"], check=True, env=env)
    subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", tmp_root_png],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    if os.path.exists(xwd_file):
        os.remove(xwd_file)
    
    full_img = Image.open(tmp_root_png)
    crop_box = (max(0, wx - 10), max(0, wy - 32), min(full_img.width, wx + ww + 180), min(full_img.height, wy + wh + 60))
    cropped = full_img.crop(crop_box)
    cropped.save(png_file)
    if os.path.exists(tmp_root_png):
        os.remove(tmp_root_png)

    print(f"Captured Step {step_idx}: {step_name} -> {png_file}")
    snapshots.append((step_idx, step_name, png_file))
    return win_id, wx, wy

try:
    # Step 0: Initial state
    win_id, wx, wy = capture_step(0, "initial_state")

    # Step 1: Right-click on Selectable Text (TFtText) without selection
    # txt_selectable is at (30, 46, 580, 28)
    print("Step 1: Right click on selectable text...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 60), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(1, "selectable_text_menu_unselected")

    # Step 2: Select All in Selectable Text
    # The menu item "Select All" is the first item (~16px below popup top)
    print("Step 2: Click Select All in context menu...")
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 75), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    # Right-click again on the selected text to show Copy enabled
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 60), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(2, "selectable_text_menu_selected_copy_enabled")

    # Dismiss menu
    subprocess.run(["xdotool", "key", "Escape"], check=True, env=env)
    time.sleep(0.3)

    # Step 3: Right-click on Non-Selectable Text (bubbles up to window context menu)
    # txt_non_selectable is at (30, 110, 580, 28)
    print("Step 3: Right click on non-selectable text...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 120), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(3, "non_selectable_text_bubbles_to_window_menu")

    # Dismiss menu
    subprocess.run(["xdotool", "key", "Escape"], check=True, env=env)
    time.sleep(0.3)

    # Step 4: Right-click on Editable Entry (TFtEntry) without selection
    # entry_editable is at (30, 174, 580, 36)
    print("Step 4: Right click on editable entry (unselected)...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 190), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(4, "editable_entry_menu_unselected")

    # Step 5: Click Select All in Editable Entry context menu
    print("Step 5: Click Select All in editable entry...")
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 205), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    # Right-click again on selected entry
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 190), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(5, "editable_entry_menu_selected_cut_copy_del_enabled")

    # Dismiss menu
    subprocess.run(["xdotool", "key", "Escape"], check=True, env=env)
    time.sleep(0.3)

    # Step 6: Right-click on Read-Only Entry (TFtEntry, ReadOnly = 1) without selection
    # entry_readonly is at (30, 246, 580, 36)
    print("Step 6: Right click on read-only entry...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 260), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(6, "readonly_entry_menu_cut_paste_del_greyed_out")

    # Step 7: Click Select All on Read-Only Entry
    print("Step 7: Click Select All on read-only entry...")
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 275), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    # Right-click again on selected read-only entry: Copy is enabled, Cut/Paste/Del still greyed out!
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 260), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(7, "readonly_entry_selected_copy_enabled_cut_paste_del_greyed")

    # Dismiss menu
    subprocess.run(["xdotool", "key", "Escape"], check=True, env=env)
    time.sleep(0.3)

    # Step 8: Right-click on Editable TextArea (TFtTextArea) without selection
    # ta_editable is at (30, 318, 580, 90)
    print("Step 8: Right click on editable textarea (unselected)...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 345), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(8, "editable_textarea_menu_unselected")

    # Step 9: Click Select All in Editable TextArea context menu
    print("Step 9: Click Select All in editable textarea...")
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 360), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    # Right-click again on selected textarea
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 345), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(9, "editable_textarea_selected_all_enabled")

    # Dismiss menu
    subprocess.run(["xdotool", "key", "Escape"], check=True, env=env)
    time.sleep(0.3)

    # Step 10: Right-click on Read-Only TextArea (TFtTextArea, ReadOnly = 1)
    # ta_readonly is at (30, 444, 580, 90)
    print("Step 10: Right click on read-only textarea...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 470), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(10, "readonly_textarea_menu_cut_paste_del_greyed")

    # Step 11: Click Select All on Read-Only TextArea
    print("Step 11: Click Select All on read-only textarea...")
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 485), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    # Right-click again on selected read-only textarea
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 470), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(11, "readonly_textarea_selected_copy_enabled_cut_paste_del_greyed")

    # Dismiss menu
    subprocess.run(["xdotool", "key", "Escape"], check=True, env=env)
    time.sleep(0.3)

    # Step 12: Test Cut, Paste and Delete actions on editable entry
    # Focus entry_editable, select all, right click, click Cut
    print("Step 12: Testing Cut action on editable entry...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 190), "click", "1"], check=True, env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "key", "ctrl+a"], check=True, env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "click", "3"], check=True, env=env)
    time.sleep(0.4)
    # In popup menu: Select All (y~15), Sep, Cut (y~55)
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 245), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    capture_step(12, "entry_cut_executed_text_cleared")

    # Step 13: Test Paste action on editable entry
    print("Step 13: Testing Paste action on editable entry...")
    subprocess.run(["xdotool", "mousemove", str(wx + 100), str(wy + 190), "click", "3"], check=True, env=env)
    time.sleep(0.4)
    # In popup menu: Select All (y~15), Sep, Cut (y~55), Copy (y~83), Paste (y~111)
    subprocess.run(["xdotool", "mousemove", str(wx + 150), str(wy + 301), "click", "1"], check=True, env=env)
    time.sleep(0.4)
    capture_step(13, "entry_paste_executed_text_restored")

    print(f"[SUCCESS] All {len(snapshots)} verification steps captured successfully!")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except subprocess.TimeoutExpired:
        proc.kill()

# Now build a verification matrix image
print("Generating comprehensive verification matrix...")
cols = 2
rows = (len(snapshots) + cols - 1) // cols
cell_w = 680
cell_h = 660

matrix_img = Image.new("RGB", (cols * cell_w, rows * cell_h), (26, 27, 38))
draw = ImageDraw.Draw(matrix_img)

for i, (step_idx, step_name, img_path) in enumerate(snapshots):
    r = i // cols
    c = i % cols
    px = c * cell_w
    py = r * cell_h
    
    # Title bar for cell
    draw.rectangle([px, py, px + cell_w, py + 30], fill=(40, 44, 58))
    draw.text((px + 10, py + 8), f"Step {step_idx}: {step_name}", fill=(240, 240, 245))
    
    step_img = Image.open(img_path)
    # Thumbnail fit
    step_img.thumbnail((cell_w - 20, cell_h - 45))
    matrix_img.paste(step_img, (px + 10, py + 35))

matrix_path = os.path.join(artifact_dir, "floria_widget_context_menus_matrix.png")
matrix_img.save(matrix_path)
print(f"Matrix saved to {matrix_path}")

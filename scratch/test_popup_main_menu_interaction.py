import subprocess
import time
import os
import sys
from PIL import Image

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

    xwd_file = os.path.join(scratch_dir, f"fix_step{step_idx}_{step_name}.xwd")
    png_file = os.path.join(artifact_dir, f"fix_step{step_idx}_{step_name}.png")
    tmp_root_png = os.path.join(scratch_dir, f"tmp_root_fix_{step_idx}.png")
    
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

    # 1. Right click on the main window (x=240, y=240) to open context popup menu
    print("Step 1: Right-clicking in window to open popup menu...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "240", "240", "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(1, "popup_menu_opened")

    # 2. Click on Main Menu bar "File" (x=25, y=14)
    print("Step 2: Clicking Main Menu 'File' while popup menu is open...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "25", "14", "click", "1"], check=True, env=env)
    time.sleep(0.5)
    capture_step(2, "clicked_file_menu_popup_dismissed")

    # 3. Click on Main Menu bar "Edit" (x=68, y=14)
    print("Step 3: Clicking Main Menu 'Edit' while File menu is open...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "68", "14", "click", "1"], check=True, env=env)
    time.sleep(0.5)
    capture_step(3, "clicked_edit_menu_file_dismissed")

    # 4. Click on Main Menu bar "Edit" again (toggle close)
    print("Step 4: Clicking 'Edit' again to toggle close...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "68", "14", "click", "1"], check=True, env=env)
    time.sleep(0.5)
    capture_step(4, "clicked_edit_again_toggle_closed")

    # 5. Right click to open popup menu again
    print("Step 5: Right-clicking in window to open popup menu again...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "320", "260", "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step(5, "popup_menu_reopened")

    # 6. Click on empty space of Main Menu bar (x=500, y=14)
    print("Step 6: Clicking empty area of Main Menu bar...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "500", "14", "click", "1"], check=True, env=env)
    time.sleep(0.5)
    capture_step(6, "clicked_empty_main_menu_area_dismissed")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except:
        proc.kill()
    print("Demo terminated.")

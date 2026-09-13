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

def capture_region(filename):
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

    xwd_file = os.path.join(scratch_dir, f"{filename}.xwd")
    png_file = os.path.join(artifact_dir, f"{filename}.png")
    tmp_root_png = os.path.join(scratch_dir, f"tmp_{filename}.png")
    
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

    print(f"Captured: {png_file}")
    return win_id

try:
    # 0. Initial window
    win_id = capture_region("stuck_bug_0_initial")

    # 1. Right click on entry at (200, 190) to open entry context menu
    print("1. Opening popup context menu at (200, 190)...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "200", "190", "click", "3"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_1_context_menu_open")

    # 2. SUDDENLY click Main Menu 'File' at (25, 14)
    print("2. SUDDENLY clicking Main Menu 'File' while context menu is open...")
    # We move directly to File and click
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "25", "14", "click", "1"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_2_file_menu_opened_context_dismissed")

    # 3. SUDDENLY right click on window at (350, 350) while File menu is open
    print("3. SUDDENLY right-clicking window at (350, 350) while File menu is open...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "350", "350", "click", "3"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_3_window_context_menu_file_dismissed")

    # 4. SUDDENLY click Main Menu 'View' at (140, 14)
    print("4. SUDDENLY clicking Main Menu 'View' while context menu is open...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "140", "14", "click", "1"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_4_view_menu_opened_context_dismissed")

    # 5. SUDDENLY click empty space on Main Menu at (600, 14)
    print("5. SUDDENLY clicking empty area on Main Menu while View menu is open...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "600", "14", "click", "1"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_5_empty_main_menu_area_all_dismissed")

    # 6. Re-open context menu
    print("6. Re-opening popup context menu...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "250", "250", "click", "3"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_6_context_menu_reopened")

    # 7. Click empty area on Main Menu at (600, 14) from context menu
    print("7. Clicking empty area on Main Menu to dismiss context menu...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "600", "14", "click", "1"], check=True, env=env)
    time.sleep(0.4)
    capture_region("stuck_bug_7_empty_main_menu_dismissed_context_menu")

    print("All interaction tests completed successfully!")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except:
        proc.kill()

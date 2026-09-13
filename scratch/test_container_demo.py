import subprocess
import time
import os
import sys
from PIL import Image, ImageDraw, ImageFont

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
os.makedirs(scratch_dir, exist_ok=True)

exec_path = "/home/afumi/Documents/projects/floria-toolkit/target/bin/example_containers"

env = os.environ.copy()
env["DISPLAY"] = ":0"

print(f"Launching {exec_path} on {env['DISPLAY']}...")
proc = subprocess.Popen([exec_path], env=env)
time.sleep(1.0)

snapshots = []

def capture_step(step_idx, step_name):
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria Toolkit - Reusable Container"],
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    win_id = int(win_ids[-1])
    
    xwd_file = os.path.join(scratch_dir, f"container_step{step_idx}_{step_name}.xwd")
    png_file = os.path.join(artifact_dir, f"container_step{step_idx}_{step_name}.png")
    
    subprocess.run(["xwd", "-id", str(win_id), "-out", xwd_file, "-silent"], check=True, env=env)
    subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", png_file],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    if os.path.exists(xwd_file):
        os.remove(xwd_file)
    print(f"Captured Step {step_idx}: {step_name} -> {png_file}")
    snapshots.append((step_idx, step_name, png_file))
    return win_id

try:
    # 0. Initial state
    win_id = capture_step(0, "initial_state")

    # 1. Scroll Container 1 (Form Box) down
    # Move over Container 1 (x=180, y=200 relative to window) and send wheel down (button 5)
    for _ in range(5):
        subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "180", "200"], env=env)
        subprocess.run(["xdotool", "click", "--window", str(win_id), "5"], env=env)
        time.sleep(0.05)
    time.sleep(0.3)
    capture_step(1, "container1_scrolled_down")

    # 2. Click "Save Profile" inside Container 1
    # Check where "Save Profile" has scrolled. Originally at y=370, container client starts at y=82+6=88.
    # We scrolled ~150px down, so Save Profile is now visible around y=280..300 in the window!
    # Let's click "Save Profile" button: relative X=50 inside cont1, relative Y=386 -> window y ~280
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "80", "280"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)
    capture_step(2, "container1_button_clicked")

    # 3. Scroll Container 2 (ListView) down
    # Move over Container 2 (x=500, y=200 relative to window) and send wheel down
    for _ in range(6):
        subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "500", "200"], env=env)
        subprocess.run(["xdotool", "click", "--window", str(win_id), "5"], env=env)
        time.sleep(0.05)
    time.sleep(0.3)
    capture_step(3, "container2_listview_scrolled")

    # 4. Click "Inspect" button in Container 2 on scrolled row
    # In Container 2, Inspect button is around x=660, y=220
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "660", "220"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)
    capture_step(4, "container2_inspect_clicked")

    # 5. Toggle Frame of Container 1
    # "Toggle Frame" button is at x=420, y=460
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "420", "460"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)
    capture_step(5, "container1_frame_toggled")

    # 6. Cycle Theme to Nord
    # "Switch Theme" button is at x=550, y=460
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "550", "460"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)
    capture_step(6, "theme_nord")

    # 7. Toggle Dark Mode
    # "Toggle Dark" button is at x=670, y=460
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "670", "460"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)
    capture_step(7, "dark_mode")

    # 8. Scroll Container 1 back up
    for _ in range(7):
        subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "180", "200"], env=env)
        subprocess.run(["xdotool", "click", "--window", str(win_id), "4"], env=env) # wheel up
        time.sleep(0.05)
    time.sleep(0.2)
    # Focus and type into Username entry (around x=100, y=145 in win)
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "100", "145"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "key", "--window", str(win_id), "ctrl+a"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "type", "--window", str(win_id), "lazarus_power"], env=env)
    time.sleep(0.3)
    capture_step(8, "entry_edited_in_dark")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=1.0)
    except Exception:
        proc.kill()
    time.sleep(0.3)

# Build Comprehensive Matrix Image
cols = 3
rows = (len(snapshots) + cols - 1) // cols
cell_w = 760 // 2 + 60
cell_h = 580 // 2 + 70

canvas_w = cols * cell_w + 40
canvas_h = rows * cell_h + 100

sheet = Image.new("RGB", (canvas_w, canvas_h), (24, 26, 32))
draw = ImageDraw.Draw(sheet)

try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    font_cell = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
except Exception:
    font_title = ImageFont.load_default()
    font_cell = ImageFont.load_default()

draw.text((25, 20), "Floria Toolkit - TFtContainer (Reusable Scrolled Container Box) Verification Matrix", fill=(240, 243, 246), font=font_title)
draw.text((25, 48), "Demonstrates smooth child scrolling, inner scissor clipping, frame styling, relative layout, and theme integration", fill=(140, 150, 165), font=font_cell)

for idx, (step_num, step_name, img_path) in enumerate(snapshots):
    r = idx // cols
    c = idx % cols
    x = 25 + c * cell_w
    y = 80 + r * cell_h
    
    label = f"Step {step_num}: {step_name.replace('_', ' ').title()}"
    draw.text((x, y), label, fill=(130, 200, 255), font=font_cell)
    
    if os.path.exists(img_path):
        with Image.open(img_path) as im:
            thumb = im.resize((cell_w - 20, cell_h - 40), Image.Resampling.LANCZOS)
            sheet.paste(thumb, (x, y + 24))

matrix_path = os.path.join(artifact_dir, "floria_container_showcase_matrix.png")
sheet.save(matrix_path)
print(f"Matrix saved to {matrix_path}")

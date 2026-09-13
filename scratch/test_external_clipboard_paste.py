import subprocess
import time
import os
import sys
import threading
from Xlib import X, display, Xatom
from Xlib.protocol import event
from PIL import Image

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
os.makedirs(scratch_dir, exist_ok=True)

exec_path = "/home/afumi/Documents/projects/floria-toolkit/target/bin/widget_context_menus_demo"

env = os.environ.copy()
env["DISPLAY"] = ":0"

# External clipboard provider running in a background thread
EXTERNAL_TEXT = "Text copied from an external application!"
stop_provider = False

def external_clipboard_server():
    d = display.Display(":0")
    root = d.screen().root
    win = root.create_window(0, 0, 1, 1, 0, d.screen().root_depth)
    clip_atom = d.intern_atom('CLIPBOARD')
    utf8_atom = d.intern_atom('UTF8_STRING')
    targets_atom = d.intern_atom('TARGETS')
    string_atom = Xatom.STRING

    win.set_selection_owner(clip_atom, X.CurrentTime)
    d.sync()
    print(f"[ExternalApp] Claimed CLIPBOARD ownership (win id: {win.id})")

    while not stop_provider:
        while d.pending_events() > 0:
            ev = d.next_event()
            if ev.type == X.SelectionRequest:
                print(f"[ExternalApp] Received SelectionRequest: target={ev.target}, property={ev.property}")
                if ev.target == targets_atom:
                    t_list = [targets_atom, utf8_atom, string_atom]
                    ev.requestor.change_property(ev.property, Xatom.ATOM, 32, t_list)
                    resp = event.SelectionNotify(
                        time=ev.time,
                        requestor=ev.requestor,
                        selection=ev.selection,
                        target=ev.target,
                        property=ev.property
                    )
                    ev.requestor.send_event(resp)
                    d.sync()
                    print("[ExternalApp] Responded to TARGETS request")
                elif ev.target in (utf8_atom, string_atom):
                    data = EXTERNAL_TEXT.encode('utf-8')
                    ev.requestor.change_property(ev.property, ev.target, 8, data)
                    resp = event.SelectionNotify(
                        time=ev.time,
                        requestor=ev.requestor,
                        selection=ev.selection,
                        target=ev.target,
                        property=ev.property
                    )
                    ev.requestor.send_event(resp)
                    d.sync()
                    print(f"[ExternalApp] Responded to text conversion request: '{EXTERNAL_TEXT}'")
        time.sleep(0.02)

    win.destroy()
    d.close()

srv_thread = threading.Thread(target=external_clipboard_server, daemon=True)
srv_thread.start()
time.sleep(0.5)

print(f"Launching {exec_path}...")
proc = subprocess.Popen([exec_path], env=env)
time.sleep(1.2)

def get_window_id():
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria Toolkit - Default Widget Popup Menus Demo"],
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    return int(win_ids[-1])

def capture_step(step_name):
    win_id = get_window_id()
    info = subprocess.run(["xwininfo", "-id", str(win_id)], capture_output=True, text=True, env=env)
    wx, wy, ww, wh = 0, 0, 640, 620
    for line in info.stdout.splitlines():
        if "Absolute upper-left X:" in line: wx = int(line.split(":")[-1])
        if "Absolute upper-left Y:" in line: wy = int(line.split(":")[-1])
        if "Width:" in line: ww = int(line.split(":")[-1])
        if "Height:" in line: wh = int(line.split(":")[-1])

    xwd_file = os.path.join(scratch_dir, f"ext_paste_{step_name}.xwd")
    png_file = os.path.join(artifact_dir, f"ext_paste_{step_name}.png")
    tmp_root_png = os.path.join(scratch_dir, f"tmp_root_ext_{step_name}.png")
    
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

    print(f"Captured: {step_name} -> {png_file}")
    return win_id, wx, wy

try:
    win_id, wx, wy = capture_step("1_initial")

    # Step 1: Right-click on editable entry.
    # Note: text in clipboard comes from external app!
    print("Right-clicking editable entry...")
    subprocess.run(["xdotool", "mousemove", str(wx + 200), str(wy + 190), "click", "3"], check=True, env=env)
    time.sleep(0.5)
    capture_step("2_context_menu_with_paste_enabled")

    # Step 2: Click "Select All" to replace text
    subprocess.run(["xdotool", "mousemove", str(wx + 250), str(wy + 205), "click", "1"], check=True, env=env)
    time.sleep(0.3)

    # Step 3: Press Ctrl+V (Paste) in the editable entry
    print("Pressing Ctrl+V to paste external clipboard text...")
    subprocess.run(["xdotool", "key", "ctrl+v"], check=True, env=env)
    time.sleep(0.5)
    capture_step("3_pasted_into_entry")

    # Step 4: Focus editable textarea and paste via Ctrl+V
    print("Focusing textarea and pasting external clipboard text...")
    subprocess.run(["xdotool", "mousemove", str(wx + 200), str(wy + 345), "click", "1"], check=True, env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "key", "ctrl+a"], check=True, env=env)
    time.sleep(0.2)
    subprocess.run(["xdotool", "key", "ctrl+v"], check=True, env=env)
    time.sleep(0.5)
    capture_step("4_pasted_into_textarea")

    print("[SUCCESS] All external clipboard paste tests completed successfully!")

finally:
    stop_provider = True
    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except subprocess.TimeoutExpired:
        proc.kill()

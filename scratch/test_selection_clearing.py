import subprocess
import time
import os
from PIL import Image

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
c_exec = "/home/afumi/Documents/projects/floria-toolkit/target/bin/c_example"
multi_exec = "/home/afumi/Documents/projects/floria-toolkit/target/bin/multilingual_example"

env = os.environ.copy()
env["DISPLAY"] = ":0"

print("Starting selection test...")

# Launch c_example
proc1 = subprocess.Popen([c_exec], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
time.sleep(1.0)

try:
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Widgets & Text"], 
                         capture_output=True, text=True, check=True, env=env)
    win1_id = int(res.stdout.strip().splitlines()[-1])
    print(f"c_example Win ID: {win1_id}")

    def capture_win(wid, name):
        xwd_file = os.path.join(scratch_dir, f"{name}.xwd")
        png_file = os.path.join(artifact_dir, f"{name}.png")
        subprocess.run(["xwd", "-id", str(wid), "-out", xwd_file, "-silent"], check=True, env=env)
        subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", png_file],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"Captured: {png_file}")
        return png_file

    # Step 1: Drag-select text in Widget 1 (Y ≈ 259, from X=40 to X=200)
    print("Step 1: Selecting text in Widget 1...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "40", "259"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "mousedown", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "200", "259"], env=env)
    time.sleep(0.15)
    subprocess.run(["xdotool", "mouseup", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.3)

    p1 = capture_win(win1_id, "selection_step1_widget1_selected")

    # Step 2: Now select text in Widget 2 (Clipboard label at Y ≈ 337, from X=240 to X=320)
    print("Step 2: Selecting text in Widget 2 (should unselect Widget 1)...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "240", "337"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "mousedown", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "340", "337"], env=env)
    time.sleep(0.15)
    subprocess.run(["xdotool", "mouseup", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.3)

    p2 = capture_win(win1_id, "selection_step2_widget2_selected")

    # Step 3: Click on empty background (X=15, Y=15)
    print("Step 3: Clicking on empty window background (should unselect all)...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "15", "15"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.3)

    p3 = capture_win(win1_id, "selection_step3_background_cleared")

    # Step 4: Re-select text in Widget 1
    print("Step 4: Re-selecting text in Widget 1 before launching second app...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "40", "259"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "mousedown", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "mousemove", "--window", str(win1_id), "220", "259"], env=env)
    time.sleep(0.15)
    subprocess.run(["xdotool", "mouseup", "--window", str(win1_id), "1"], env=env)
    time.sleep(0.3)

    p4_before = capture_win(win1_id, "selection_step4_win1_selected")

    # Step 5: Launch second application (multilingual_example)
    print("Step 5: Launching second application...")
    proc2 = subprocess.Popen([multi_exec], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
    time.sleep(1.0)

    try:
        res2 = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Multilingual"], 
                              capture_output=True, text=True, check=True, env=env)
        win2_id = int(res2.stdout.strip().splitlines()[-1])
        print(f"multilingual Win ID: {win2_id}")

        # Select text in Window 2 (e.g. click "Select" on Japanese, or drag in Window 2)
        print("Selecting text in Window 2...")
        subprocess.run(["xdotool", "mousemove", "--window", str(win2_id), "785", "150"], env=env)
        time.sleep(0.1)
        subprocess.run(["xdotool", "click", "--window", str(win2_id), "1"], env=env)
        time.sleep(0.4)

        # Capture Window 1: it MUST be unselected now!
        p5_win1_cleared = capture_win(win1_id, "selection_step5_win1_unselected_by_ext_app")
        p5_win2_selected = capture_win(win2_id, "selection_step5_win2_now_selected")

    finally:
        proc2.terminate()
        try:
            proc2.wait(timeout=1.0)
        except Exception:
            proc2.kill()

finally:
    proc1.terminate()
    try:
        proc1.wait(timeout=1.0)
    except Exception:
        proc1.kill()

print("All selection clearing tests finished!")

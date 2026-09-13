import subprocess
import time
import os

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
c_bin = "/home/afumi/Documents/projects/floria-toolkit/target/bin/multilingual_example"

env = os.environ.copy()
env["DISPLAY"] = ":0"

print("1. Launching C multilingual example...")
proc = subprocess.Popen([c_bin], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
time.sleep(1.0)

try:
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Multilingual"], 
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    win_id = int(win_ids[-1])
    print(f"Window ID: {win_id}")

    def capture(name):
        xwd_file = os.path.join(artifact_dir, "scratch", f"{name}.xwd")
        png_file = os.path.join(artifact_dir, f"{name}.png")
        subprocess.run(["xwd", "-id", str(win_id), "-out", xwd_file, "-silent"], check=True, env=env)
        subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", png_file],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"Captured: {png_file}")
        return png_file

    # Capture 1: Initial Light Mode
    p1 = capture("multilingual_1_initial_light")

    # Click Japanese "Select" button:
    # Column 2 starts at X=430. Japanese row is row 0 of column 2 (Y=142). Button is at X=430+315=745, Y=140.
    print("Clicking Japanese Select button...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "770", "150"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.2)

    # Click "Copy Active Phrase" (X=420, Y=84)
    print("Clicking Copy button...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "420", "84"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.2)

    # Capture 2: Japanese loaded and copied
    p2 = capture("multilingual_2_japanese_copied")

    # Toggle Dark Mode (Switch is at X=240, Y=84)
    print("Toggling Dark Mode...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "240", "84"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)

    # Capture 3: Dark Mode
    p3 = capture("multilingual_3_dark_mode")

    # Click Next Theme (X=90, Y=84)
    print("Cycling Theme (Nord)...")
    subprocess.run(["xdotool", "mousemove", "--window", str(win_id), "90", "84"], env=env)
    time.sleep(0.1)
    subprocess.run(["xdotool", "click", "--window", str(win_id), "1"], env=env)
    time.sleep(0.3)

    # Capture 4: Nord Theme
    p4 = capture("multilingual_4_nord_theme")

finally:
    proc.terminate()
    try:
        proc.wait(timeout=1.0)
    except Exception:
        proc.kill()
    time.sleep(0.3)

print("2. Testing Python multilingual example launch...")
py_proc = subprocess.Popen(["python3", "examples/python/multilingual.py"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
time.sleep(1.0)
try:
    res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Python"], 
                         capture_output=True, text=True, check=True, env=env)
    win_ids = res.stdout.strip().splitlines()
    win_id = int(win_ids[-1])
    print(f"Python Window ID: {win_id}")
    p_py = capture("multilingual_5_python_host")
finally:
    py_proc.terminate()
    try:
        py_proc.wait(timeout=1.0)
    except Exception:
        py_proc.kill()

print("All tests and captures completed successfully!")

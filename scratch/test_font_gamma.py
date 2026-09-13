import subprocess
import time
import os
from PIL import Image

artifact_dir = "/home/afumi/.gemini/antigravity-cli/brain/975c8ef3-e22c-4d09-b28d-309845524761"
scratch_dir = os.path.join(artifact_dir, "scratch")
c_exec = "/home/afumi/Documents/projects/floria-toolkit/target/bin/c_example"

def capture_gamma(gamma_val):
    env = os.environ.copy()
    env["DISPLAY"] = ":0"
    env["FT_FONT_GAMMA"] = str(gamma_val)
    proc = subprocess.Popen([c_exec], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
    time.sleep(0.8)

    try:
        res = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "Floria"], 
                             capture_output=True, text=True, check=True, env=env)
        win_ids = res.stdout.strip().splitlines()
        win_id = int(win_ids[-1])
        xwd_file = os.path.join(scratch_dir, f"gamma_{gamma_val}.xwd")
        png_file = os.path.join(scratch_dir, f"gamma_{gamma_val}.png")
        subprocess.run(["xwd", "-id", str(win_id), "-out", xwd_file, "-silent"], check=True, env=env)
        subprocess.run(["ffmpeg", "-y", "-i", xwd_file, "-update", "1", "-frames:v", "1", png_file],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"Captured gamma {gamma_val}: {png_file}")
        return png_file
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=1.0)
        except Exception:
            proc.kill()
        time.sleep(0.3)

gammas = [0.55, 0.65, 0.72, 0.78, 0.85]
for g in gammas:
    capture_gamma(g)
print("All gamma captures complete.")

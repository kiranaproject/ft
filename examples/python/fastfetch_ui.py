#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Fastfetch Desktop Inspector (Python Example)
A modern desktop system information dashboard inspired by fastfetch / neofetch.
Demonstrates:
  - System hardware & OS discovery (CPU, GPU, RAM, Disk, Uptime, DE, WM, Shell)
  - Distro ASCII art logo with custom colors
  - Progress bars for live RAM, Swap, and Disk utilization
  - Indeterminate activity bar powered by the optimized partial blit engine
  - Live Refresh, Dark Mode toggle, and Theme switching (Default, Nord, Dracula, Gruvbox)
"""

import ctypes
import datetime
import os
import platform
import re
import shutil
import subprocess
import sys
import time

# ---------------------------------------------------------------------------
# 1. Locate and load libft.so
# ---------------------------------------------------------------------------
LIB_SEARCH_PATHS = [
    os.path.abspath(os.path.join(os.path.dirname(__file__), "../../target/bin/libft.so")),
    os.path.abspath(os.path.join(os.path.dirname(__file__), "../../target/libft.so")),
    "/usr/local/lib/libft.so",
]

lib_path = None
for p in LIB_SEARCH_PATHS:
    if os.path.exists(p):
        lib_path = p
        break

if not lib_path:
    print("Error: libft.so not found. Please build the toolkit first (lazbuild src/main/pascal/ft.lpi).")
    sys.exit(1)

ft = ctypes.CDLL(lib_path)

# Callback types
CLICK_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)
COMBO_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_int32, ctypes.c_char_p, ctypes.c_void_p)

# Keep global references to prevent garbage collection
g_callbacks = []

def to_bytes(s):
    """Safely convert string to UTF-8 bytes for ctypes."""
    if isinstance(s, str):
        return s.encode("utf-8")
    return s

# Core Lifecycle
ft.ft_init.argtypes = []
ft.ft_init.restype = None

ft.ft_main_loop.argtypes = []
ft.ft_main_loop.restype = None

ft.ft_quit.argtypes = []
ft.ft_quit.restype = None

# Window Management
ft.ft_window_create.argtypes = [ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_window_create.restype = ctypes.c_void_p

ft.ft_widget_show.argtypes = [ctypes.c_void_p]
ft.ft_widget_show.restype = None

# Containers
ft.ft_container_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_container_create.restype = ctypes.c_void_p

ft.ft_container_set_draw_frame.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_container_set_draw_frame.restype = None

ft.ft_container_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_container_set_corner_radius.restype = None

ft.ft_container_set_padding.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
ft.ft_container_set_padding.restype = None

ft.ft_container_set_scrollbar_mode.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_container_set_scrollbar_mode.restype = None

# Labels / Text
ft.ft_text_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_text_create.restype = ctypes.c_void_p

ft.ft_text_set_text.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_text_set_text.restype = None

ft.ft_text_set_color.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double, ctypes.c_double]
ft.ft_text_set_color.restype = None

ft.ft_widget_set_font.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_font.restype = None

# Buttons
ft.ft_button_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_button_create.restype = ctypes.c_void_p

ft.ft_button_on_click.argtypes = [ctypes.c_void_p, CLICK_CB, ctypes.c_void_p]
ft.ft_button_on_click.restype = None

ft.ft_button_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_button_set_corner_radius.restype = None

# ComboBox
ft.ft_combobox_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_combobox_create.restype = ctypes.c_void_p

ft.ft_combobox_add_item.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_combobox_add_item.restype = ctypes.c_int32

ft.ft_combobox_set_selected.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_combobox_set_selected.restype = None

ft.ft_combobox_on_change.argtypes = [ctypes.c_void_p, COMBO_CB, ctypes.c_void_p]
ft.ft_combobox_on_change.restype = None

# ProgressBar
ft.ft_progressbar_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_progressbar_create.restype = ctypes.c_void_p

ft.ft_progressbar_set_range.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
ft.ft_progressbar_set_range.restype = None

ft.ft_progressbar_set_value.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_progressbar_set_value.restype = None

ft.ft_progressbar_set_show_text.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_progressbar_set_show_text.restype = None

ft.ft_progressbar_set_text_format.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_progressbar_set_text_format.restype = None

ft.ft_progressbar_set_indeterminate.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_progressbar_set_indeterminate.restype = None

ft.ft_progressbar_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_progressbar_set_corner_radius.restype = None

# Themes & Styling
ft.ft_theme_set.argtypes = [ctypes.c_char_p]
ft.ft_theme_set.restype = ctypes.c_int32

ft.ft_theme_get.argtypes = []
ft.ft_theme_get.restype = ctypes.c_char_p

ft.ft_theme_set_dark_mode.argtypes = [ctypes.c_int32]
ft.ft_theme_set_dark_mode.restype = None

ft.ft_theme_get_dark_mode.argtypes = []
ft.ft_theme_get_dark_mode.restype = ctypes.c_int32


# ---------------------------------------------------------------------------
# 2. System Information Collectors
# ---------------------------------------------------------------------------

def get_os_release():
    info = {}
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    info[k] = v.strip('"')
    return info

def get_host_name():
    for p in ["/sys/class/dmi/id/product_name", "/sys/devices/virtual/dmi/id/product_name"]:
        if os.path.exists(p):
            try:
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    v = f.read().strip()
                    if v:
                        return v
            except Exception:
                pass
    return platform.node()

def get_kernel():
    return f"{platform.system()} {platform.release()}"

def get_uptime_str():
    if os.path.exists("/proc/uptime"):
        try:
            with open("/proc/uptime", "r", encoding="utf-8", errors="ignore") as f:
                secs = float(f.readline().split()[0])
                days = int(secs // 86400)
                hours = int((secs % 86400) // 3600)
                mins = int((secs % 3600) // 60)
                if days > 0:
                    return f"{days}d {hours}h {mins}m"
                return f"{hours}h {mins}m"
        except Exception:
            pass
    return "Unknown"

def get_packages():
    # Try dpkg
    try:
        out = subprocess.check_output(["dpkg-query", "-f", ".\n", "-W"], stderr=subprocess.DEVNULL)
        return f"{len(out.splitlines())} (dpkg)"
    except Exception:
        pass
    # Try rpm
    try:
        out = subprocess.check_output(["rpm", "-qa"], stderr=subprocess.DEVNULL)
        return f"{len(out.splitlines())} (rpm)"
    except Exception:
        pass
    # Try pacman
    try:
        out = subprocess.check_output(["pacman", "-Qq"], stderr=subprocess.DEVNULL)
        return f"{len(out.splitlines())} (pacman)"
    except Exception:
        pass
    return "N/A"

def get_shell():
    sh = os.environ.get("SHELL", "/bin/bash")
    sh_name = os.path.basename(sh)
    try:
        out = subprocess.check_output([sh, "--version"], stderr=subprocess.DEVNULL).decode().splitlines()[0]
        words = out.split()
        if len(words) >= 4 and "version" in words[2].lower():
            return f"{sh_name} {words[3]}"
        return f"{sh_name} ({words[-1]})"
    except Exception:
        return sh_name

def get_desktop_env():
    de = os.environ.get("XDG_CURRENT_DESKTOP") or os.environ.get("DESKTOP_SESSION") or "Unknown"
    wm_type = os.environ.get("XDG_SESSION_TYPE", "x11")
    return de, wm_type

def get_window_manager():
    # Check common WMs
    wms = ["marco", "mutter", "kwin", "xfwm4", "i3", "openbox", "bspwm", "sway", "wayfire"]
    for wm in wms:
        try:
            subprocess.check_output(["pidof", wm], stderr=subprocess.DEVNULL)
            return wm.capitalize()
        except Exception:
            pass
    return "X11 WM"

def get_cpu():
    model = "Unknown CPU"
    cores = os.cpu_count() or 1
    if os.path.exists("/proc/cpuinfo"):
        try:
            with open("/proc/cpuinfo", "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if "model name" in line:
                        model = line.split(":", 1)[1].strip()
                        break
        except Exception:
            pass
    # Clean up model string
    model = re.sub(r"\s+", " ", model)
    return model, cores

def get_gpu():
    try:
        out = subprocess.check_output(["lspci"], stderr=subprocess.DEVNULL).decode()
        for line in out.splitlines():
            if "VGA" in line or "3D" in line or "Display" in line:
                parts = line.split(":", 2)
                if len(parts) >= 3:
                    gpu = parts[2].strip()
                    gpu = re.sub(r"\(rev [0-9a-fA-F]+\)", "", gpu).strip()
                    return gpu
    except Exception:
        pass
    return "Integrated Graphics"

def get_resolution():
    try:
        out = subprocess.check_output(["xrandr"], stderr=subprocess.DEVNULL).decode()
        for line in out.splitlines():
            if "*" in line:
                return line.strip().split()[0]
    except Exception:
        pass
    return "1920x1080"

def get_memory():
    mem = {}
    if os.path.exists("/proc/meminfo"):
        try:
            with open("/proc/meminfo", "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    parts = line.split(":")
                    if len(parts) == 2:
                        k = parts[0].strip()
                        v = parts[1].strip().split()[0]
                        mem[k] = int(v)
        except Exception:
            pass
    total = mem.get("MemTotal", 1024 * 1024) / (1024 * 1024)
    avail = mem.get("MemAvailable", 0) / (1024 * 1024)
    used = max(0.0, total - avail)
    pct = (used / total * 100.0) if total > 0 else 0.0

    swap_total = mem.get("SwapTotal", 0) / (1024 * 1024)
    swap_free = mem.get("SwapFree", 0) / (1024 * 1024)
    swap_used = max(0.0, swap_total - swap_free)
    swap_pct = (swap_used / swap_total * 100.0) if swap_total > 0 else 0.0

    return total, used, pct, swap_total, swap_used, swap_pct

def get_disk():
    try:
        total, used, free = shutil.disk_usage("/")
        tot_gib = total / (1024**3)
        used_gib = used / (1024**3)
        pct = (used_gib / tot_gib * 100.0) if tot_gib > 0 else 0.0
        return tot_gib, used_gib, pct
    except Exception:
        return 100.0, 50.0, 50.0


# ---------------------------------------------------------------------------
# 3. Distro ASCII Logos & Theme Colors
# ---------------------------------------------------------------------------

UBUNTU_ASCII = [
    r"         _          ",
    r"     ---(_)         ",
    r" _/  ---  \         ",
    r"(_) |   |           ",
    r"  \  --- _/         ",
    r"     ---(_)         ",
]

DEBIAN_ASCII = [
    r"       _____        ",
    r"      /  __ \       ",
    r"     |  /    |      ",
    r"     |  \___-       ",
    r"      -_            ",
    r"        --_         ",
]

ARCH_ASCII = [
    r"          /\        ",
    r"         /  \       ",
    r"        /\   \      ",
    r"       /      \     ",
    r"      /   ,,   \    ",
    r"     /   |  |  -\   ",
    r"    /_-''    ''-_\  ",
]

FEDORA_ASCII = [
    r"           ,'''''.  ",
    r"          |   ,.  | ",
    r"          |  |  '_' ",
    r"       ,--'  |___   ",
    r"      |        |    ",
    r"      |   .---'     ",
    r"       '--'         ",
]

LINUX_ASCII = [
    r"         .---.      ",
    r"        | o_o |     ",
    r"        | :_/ |     ",
    r"       //   \ \     ",
    r"      (|     | )    ",
    r"     /'\_   _/`\    ",
    r"     \___)=(___/    ",
]

def pick_distro_ascii_and_color(distro_id):
    d = distro_id.lower()
    if "ubuntu" in d:
        return UBUNTU_ASCII, (0.95, 0.45, 0.12)  # Ubuntu Orange
    elif "debian" in d:
        return DEBIAN_ASCII, (0.85, 0.15, 0.30)  # Debian Red
    elif "arch" in d:
        return ARCH_ASCII, (0.18, 0.65, 0.88)    # Arch Cyan
    elif "fedora" in d:
        return FEDORA_ASCII, (0.20, 0.45, 0.85)  # Fedora Blue
    elif "mint" in d:
        return UBUNTU_ASCII, (0.40, 0.80, 0.45)  # Mint Green
    else:
        return LINUX_ASCII, (0.92, 0.75, 0.20)   # Tux Gold


# ---------------------------------------------------------------------------
# 4. Main Application GUI Setup
# ---------------------------------------------------------------------------

def main():
    ft.ft_init()

    # Collect initial system info
    os_info = get_os_release()
    distro_name = os_info.get("PRETTY_NAME", platform.system())
    distro_id = os_info.get("ID", "linux")
    user_str = os.environ.get("USER", "user")
    host_str = platform.node()
    user_at_host = f"{user_str}@{host_str}"
    hardware_model = get_host_name()
    kernel_str = get_kernel()
    arch_str = f"{platform.machine()} (64-bit)"
    shell_str = get_shell()
    packages_str = get_packages()
    de_str, session_str = get_desktop_env()
    wm_str = get_window_manager()
    cpu_model, cpu_cores = get_cpu()
    gpu_model = get_gpu()
    res_str = get_resolution()

    # Create Main Window
    win_w = 960
    win_h = 700
    win = ft.ft_window_create(win_w, win_h, b"Floria Toolkit - Fastfetch Desktop Inspector")
    if not win:
        print("Error: Failed to create Floria Toolkit window.")
        sys.exit(1)

    # -----------------------------------------------------------------------
    # Top Header Bar
    # -----------------------------------------------------------------------
    hdr_title = ft.ft_text_create(win, 20, 16, 360, 24, b"Fastfetch Desktop Inspector")
    ft.ft_widget_set_font(hdr_title, b"Inter-Bold-15")

    hdr_subtitle = ft.ft_text_create(win, 20, 40, 360, 18, b"System Hardware & Desktop Dashboard")
    ft.ft_widget_set_font(hdr_subtitle, b"Inter-Regular-11")

    # Controls in Header (Theme dropdown, Dark Mode toggle, Refresh button)
    cb_theme = ft.ft_combobox_create(win, 500, 20, 140, 30)
    ft.ft_combobox_add_item(cb_theme, b"Default Theme")
    ft.ft_combobox_add_item(cb_theme, b"Nord Theme")
    ft.ft_combobox_add_item(cb_theme, b"Dracula Theme")
    ft.ft_combobox_add_item(cb_theme, b"Gruvbox Theme")
    ft.ft_combobox_set_selected(cb_theme, 0)

    btn_dark = ft.ft_button_create(win, 650, 20, 135, 30, b"Dark Mode")
    ft.ft_button_set_corner_radius(btn_dark, 5.0)

    btn_refresh = ft.ft_button_create(win, 795, 20, 145, 30, b"Refresh Stats")
    ft.ft_button_set_corner_radius(btn_refresh, 5.0)

    # -----------------------------------------------------------------------
    # Left Column (Distro Card, ANSI Palette, Activity Indicator)
    # -----------------------------------------------------------------------
    col_left_x = 20
    col_left_w = 310

    # Card 1: Distro Logo & Identity
    card_distro = ft.ft_container_create(win, col_left_x, 68, col_left_w, 326)
    ft.ft_container_set_draw_frame(card_distro, 1)
    ft.ft_container_set_corner_radius(card_distro, 8.0)
    ft.ft_container_set_padding(card_distro, 16.0, 16.0)

    # ASCII Logo
    ascii_lines, (logo_r, logo_g, logo_b) = pick_distro_ascii_and_color(distro_id)
    cur_y = 0
    for line in ascii_lines:
        lbl_line = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 16, line.encode("utf-8"))
        ft.ft_widget_set_font(lbl_line, b"Monospace-Bold-11")
        ft.ft_text_set_color(lbl_line, logo_r, logo_g, logo_b)
        cur_y += 16

    cur_y += 6
    # User@Host banner
    lbl_user_host = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 20, user_at_host.encode("utf-8"))
    ft.ft_widget_set_font(lbl_user_host, b"Inter-Bold-13")
    ft.ft_text_set_color(lbl_user_host, logo_r, logo_g, logo_b)
    cur_y += 20

    lbl_sep = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 12, b"----------------------------------------")
    ft.ft_widget_set_font(lbl_sep, b"Monospace-Regular-10")
    cur_y += 14

    # Distro summary fields
    lbl_d_os = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 18, f"OS: {distro_name}".encode("utf-8"))
    ft.ft_widget_set_font(lbl_d_os, b"Inter-Medium-11")
    cur_y += 18

    lbl_d_host = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 18, f"Host: {hardware_model}".encode("utf-8"))
    ft.ft_widget_set_font(lbl_d_host, b"Inter-Regular-11")
    cur_y += 18

    lbl_d_kernel = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 18, f"Kernel: {kernel_str}".encode("utf-8"))
    ft.ft_widget_set_font(lbl_d_kernel, b"Inter-Regular-11")
    cur_y += 18

    lbl_d_uptime = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 18, f"Uptime: {get_uptime_str()}".encode("utf-8"))
    ft.ft_widget_set_font(lbl_d_uptime, b"Inter-Regular-11")
    cur_y += 18

    lbl_d_pkgs = ft.ft_text_create(card_distro, 0, cur_y, col_left_w - 32, 18, f"Packages: {packages_str}".encode("utf-8"))
    ft.ft_widget_set_font(lbl_d_pkgs, b"Inter-Regular-11")

    # Card 2: Terminal Color Palette Swatches (Classic fastfetch signature)
    card_palette = ft.ft_container_create(win, col_left_x, 404, col_left_w, 114)
    ft.ft_container_set_draw_frame(card_palette, 1)
    ft.ft_container_set_corner_radius(card_palette, 8.0)
    ft.ft_container_set_padding(card_palette, 14.0, 12.0)

    lbl_pal_title = ft.ft_text_create(card_palette, 0, 0, col_left_w - 28, 18, b"Terminal ANSI Palette")
    ft.ft_widget_set_font(lbl_pal_title, b"Inter-Bold-11")

    # ANSI Colors
    ansi_standard = [
        ("●", 0.18, 0.20, 0.25),  # Black / Dark Grey
        ("●", 0.90, 0.30, 0.30),  # Red
        ("●", 0.30, 0.80, 0.40),  # Green
        ("●", 0.95, 0.75, 0.20),  # Yellow
        ("●", 0.30, 0.55, 0.95),  # Blue
        ("●", 0.85, 0.40, 0.85),  # Magenta
        ("●", 0.25, 0.80, 0.85),  # Cyan
        ("●", 0.85, 0.88, 0.92),  # White
    ]
    ansi_bright = [
        ("●", 0.38, 0.42, 0.50),  # Bright Black
        ("●", 1.00, 0.45, 0.45),  # Bright Red
        ("●", 0.45, 0.95, 0.55),  # Bright Green
        ("●", 1.00, 0.88, 0.35),  # Bright Yellow
        ("●", 0.45, 0.70, 1.00),  # Bright Blue
        ("●", 0.95, 0.55, 0.95),  # Bright Magenta
        ("●", 0.40, 0.92, 0.95),  # Bright Cyan
        ("●", 1.00, 1.00, 1.00),  # Bright White
    ]

    for i, (sym, cr, cg, cb) in enumerate(ansi_standard):
        c_lbl = ft.ft_text_create(card_palette, i * 32, 28, 28, 22, sym.encode("utf-8"))
        ft.ft_widget_set_font(c_lbl, b"Inter-Bold-16")
        ft.ft_text_set_color(c_lbl, cr, cg, cb)

    for i, (sym, cr, cg, cb) in enumerate(ansi_bright):
        c_lbl = ft.ft_text_create(card_palette, i * 32, 54, 28, 22, sym.encode("utf-8"))
        ft.ft_widget_set_font(c_lbl, b"Inter-Bold-16")
        ft.ft_text_set_color(c_lbl, cr, cg, cb)

    # Card 3: Live Background Activity Heartbeat
    card_pulse = ft.ft_container_create(win, col_left_x, 528, col_left_w, 110)
    ft.ft_container_set_draw_frame(card_pulse, 1)
    ft.ft_container_set_corner_radius(card_pulse, 8.0)
    ft.ft_container_set_padding(card_pulse, 14.0, 12.0)

    lbl_pulse_head = ft.ft_text_create(card_pulse, 0, 0, col_left_w - 28, 18, b"Engine Heartbeat (Smooth 30 FPS)")
    ft.ft_widget_set_font(lbl_pulse_head, b"Inter-Bold-11")

    pb_pulse = ft.ft_progressbar_create(card_pulse, 0, 24, col_left_w - 28, 14, 0)
    ft.ft_progressbar_set_indeterminate(pb_pulse, 1)
    ft.ft_progressbar_set_corner_radius(pb_pulse, 4.0)

    lbl_pulse_note1 = ft.ft_text_create(card_pulse, 0, 46, col_left_w - 28, 16, b"Partial blit scissor engine active")
    ft.ft_widget_set_font(lbl_pulse_note1, b"Inter-Regular-10")

    lbl_pulse_note2 = ft.ft_text_create(card_pulse, 0, 64, col_left_w - 28, 16, b"Ambient idle usage: < 2% CPU")
    ft.ft_widget_set_font(lbl_pulse_note2, b"Inter-Regular-10")

    # -----------------------------------------------------------------------
    # Right Column (Hardware Specs, Environment, Live Resource Meters)
    # -----------------------------------------------------------------------
    col_right_x = 342
    col_right_w = 598

    # Card 1: Hardware Specifications
    card_hw = ft.ft_container_create(win, col_right_x, 68, col_right_w, 168)
    ft.ft_container_set_draw_frame(card_hw, 1)
    ft.ft_container_set_corner_radius(card_hw, 8.0)
    ft.ft_container_set_padding(card_hw, 16.0, 14.0)

    lbl_hw_head = ft.ft_text_create(card_hw, 0, 0, col_right_w - 32, 20, b"Hardware Specifications")
    ft.ft_widget_set_font(lbl_hw_head, b"Inter-Bold-13")

    ft.ft_text_create(card_hw, 0, 28, 125, 18, b"CPU Model:")
    lbl_hw_cpu = ft.ft_text_create(card_hw, 130, 28, col_right_w - 162, 18, f"{cpu_model} ({cpu_cores} cores)".encode("utf-8"))
    ft.ft_widget_set_font(lbl_hw_cpu, b"Inter-Medium-11")

    ft.ft_text_create(card_hw, 0, 50, 125, 18, b"GPU Controller:")
    lbl_hw_gpu = ft.ft_text_create(card_hw, 130, 50, col_right_w - 162, 18, gpu_model.encode("utf-8"))
    ft.ft_widget_set_font(lbl_hw_gpu, b"Inter-Medium-11")

    ft.ft_text_create(card_hw, 0, 72, 125, 18, b"Resolution:")
    lbl_hw_res = ft.ft_text_create(card_hw, 130, 72, col_right_w - 162, 18, f"{res_str} (Standard DPI)".encode("utf-8"))
    ft.ft_widget_set_font(lbl_hw_res, b"Inter-Medium-11")

    ft.ft_text_create(card_hw, 0, 94, 125, 18, b"Architecture:")
    lbl_hw_arch = ft.ft_text_create(card_hw, 130, 94, col_right_w - 162, 18, arch_str.encode("utf-8"))
    ft.ft_widget_set_font(lbl_hw_arch, b"Inter-Medium-11")

    ft.ft_text_create(card_hw, 0, 116, 125, 18, b"Host Machine:")
    lbl_hw_host = ft.ft_text_create(card_hw, 130, 116, col_right_w - 162, 18, f"{hardware_model} ({host_str})".encode("utf-8"))
    ft.ft_widget_set_font(lbl_hw_host, b"Inter-Medium-11")

    # Card 2: Desktop & Software Environment
    card_sw = ft.ft_container_create(win, col_right_x, 246, col_right_w, 148)
    ft.ft_container_set_draw_frame(card_sw, 1)
    ft.ft_container_set_corner_radius(card_sw, 8.0)
    ft.ft_container_set_padding(card_sw, 16.0, 14.0)

    lbl_sw_head = ft.ft_text_create(card_sw, 0, 0, col_right_w - 32, 20, b"Desktop & Software Environment")
    ft.ft_widget_set_font(lbl_sw_head, b"Inter-Bold-13")

    ft.ft_text_create(card_sw, 0, 28, 170, 18, b"Desktop (DE):")
    lbl_sw_de = ft.ft_text_create(card_sw, 175, 28, col_right_w - 207, 18, f"{de_str} ({session_str})".encode("utf-8"))
    ft.ft_widget_set_font(lbl_sw_de, b"Inter-Medium-11")

    ft.ft_text_create(card_sw, 0, 50, 170, 18, b"Window Manager (WM):")
    lbl_sw_wm = ft.ft_text_create(card_sw, 175, 50, col_right_w - 207, 18, wm_str.encode("utf-8"))
    ft.ft_widget_set_font(lbl_sw_wm, b"Inter-Medium-11")

    ft.ft_text_create(card_sw, 0, 72, 170, 18, b"Default Shell:")
    lbl_sw_sh = ft.ft_text_create(card_sw, 175, 72, col_right_w - 207, 18, shell_str.encode("utf-8"))
    ft.ft_widget_set_font(lbl_sw_sh, b"Inter-Medium-11")

    ft.ft_text_create(card_sw, 0, 94, 170, 18, b"Package Count:")
    lbl_sw_pkg = ft.ft_text_create(card_sw, 175, 94, col_right_w - 207, 18, packages_str.encode("utf-8"))
    ft.ft_widget_set_font(lbl_sw_pkg, b"Inter-Medium-11")

    # Card 3: Live Resource Monitors (RAM, Swap, Disk)
    card_res = ft.ft_container_create(win, col_right_x, 404, col_right_w, 234)
    ft.ft_container_set_draw_frame(card_res, 1)
    ft.ft_container_set_corner_radius(card_res, 8.0)
    ft.ft_container_set_padding(card_res, 16.0, 14.0)

    lbl_res_head = ft.ft_text_create(card_res, 0, 0, col_right_w - 32, 20, b"Live Resource Monitors")
    ft.ft_widget_set_font(lbl_res_head, b"Inter-Bold-13")

    # Memory (RAM)
    mem_tot, mem_used, mem_pct, swap_tot, swap_used, swap_pct = get_memory()
    lbl_ram = ft.ft_text_create(card_res, 0, 26, col_right_w - 32, 18, f"Memory (RAM): {mem_used:.2f} GiB / {mem_tot:.2f} GiB ({mem_pct:.1f}%)".encode("utf-8"))
    ft.ft_widget_set_font(lbl_ram, b"Inter-Medium-11")

    pb_ram = ft.ft_progressbar_create(card_res, 0, 48, col_right_w - 32, 18, 0)
    ft.ft_progressbar_set_range(pb_ram, ctypes.c_double(0.0), ctypes.c_double(100.0))
    ft.ft_progressbar_set_value(pb_ram, ctypes.c_double(mem_pct))
    ft.ft_progressbar_set_show_text(pb_ram, 1)
    ft.ft_progressbar_set_corner_radius(pb_ram, 5.0)

    # Swap
    lbl_swap = ft.ft_text_create(card_res, 0, 76, col_right_w - 32, 18, f"Swap Space: {swap_used:.2f} GiB / {swap_tot:.2f} GiB ({swap_pct:.1f}%)".encode("utf-8"))
    ft.ft_widget_set_font(lbl_swap, b"Inter-Medium-11")

    pb_swap = ft.ft_progressbar_create(card_res, 0, 98, col_right_w - 32, 18, 0)
    ft.ft_progressbar_set_range(pb_swap, ctypes.c_double(0.0), ctypes.c_double(100.0))
    ft.ft_progressbar_set_value(pb_swap, ctypes.c_double(swap_pct))
    ft.ft_progressbar_set_show_text(pb_swap, 1)
    ft.ft_progressbar_set_corner_radius(pb_swap, 5.0)

    # Disk (/)
    disk_tot, disk_used, disk_pct = get_disk()
    lbl_disk = ft.ft_text_create(card_res, 0, 126, col_right_w - 32, 18, f"Root Storage (/): {disk_used:.1f} GiB / {disk_tot:.1f} GiB ({disk_pct:.1f}%)".encode("utf-8"))
    ft.ft_widget_set_font(lbl_disk, b"Inter-Medium-11")

    pb_disk = ft.ft_progressbar_create(card_res, 0, 148, col_right_w - 32, 18, 0)
    ft.ft_progressbar_set_range(pb_disk, ctypes.c_double(0.0), ctypes.c_double(100.0))
    ft.ft_progressbar_set_value(pb_disk, ctypes.c_double(disk_pct))
    ft.ft_progressbar_set_show_text(pb_disk, 1)
    ft.ft_progressbar_set_corner_radius(pb_disk, 5.0)

    # -----------------------------------------------------------------------
    # Bottom Status Bar
    # -----------------------------------------------------------------------
    try:
        load1, load5, load15 = os.getloadavg()
        load_str = f"Load: {load1:.2f}, {load5:.2f}, {load15:.2f}"
    except Exception:
        load_str = "Load: N/A"

    now_str = datetime.datetime.now().strftime("%H:%M:%S")
    status_bar = ft.ft_text_create(win, 20, 652, 920, 22, f"System Ready • {load_str} • Refreshed at {now_str}".encode("utf-8"))
    ft.ft_widget_set_font(status_bar, b"Inter-Regular-10")

    # -----------------------------------------------------------------------
    # Callbacks & Interactive Logic
    # -----------------------------------------------------------------------

    def do_refresh():
        # Re-read memory
        m_tot, m_used, m_pct, s_tot, s_used, s_pct = get_memory()
        ft.ft_text_set_text(lbl_ram, f"Memory (RAM): {m_used:.2f} GiB / {m_tot:.2f} GiB ({m_pct:.1f}%)".encode("utf-8"))
        ft.ft_progressbar_set_value(pb_ram, ctypes.c_double(m_pct))

        ft.ft_text_set_text(lbl_swap, f"Swap Space: {s_used:.2f} GiB / {s_tot:.2f} GiB ({s_pct:.1f}%)".encode("utf-8"))
        ft.ft_progressbar_set_value(pb_swap, ctypes.c_double(s_pct))

        # Re-read disk
        d_tot, d_used, d_pct = get_disk()
        ft.ft_text_set_text(lbl_disk, f"Root Storage (/): {d_used:.1f} GiB / {d_tot:.1f} GiB ({d_pct:.1f}%)".encode("utf-8"))
        ft.ft_progressbar_set_value(pb_disk, ctypes.c_double(d_pct))

        # Re-read uptime
        ft.ft_text_set_text(lbl_d_uptime, f"Uptime: {get_uptime_str()}".encode("utf-8"))

        # Update status bar
        try:
            l1, l5, l15 = os.getloadavg()
            l_str = f"Load: {l1:.2f}, {l5:.2f}, {l15:.2f}"
        except Exception:
            l_str = "Load: N/A"
        n_str = datetime.datetime.now().strftime("%H:%M:%S")
        ft.ft_text_set_text(status_bar, f"Stats Updated • {l_str} • Refreshed at {n_str}".encode("utf-8"))

    def on_refresh_click(widget, user_data):
        do_refresh()

    cb_refresh_fn = CLICK_CB(on_refresh_click)
    g_callbacks.append(cb_refresh_fn)
    ft.ft_button_on_click(btn_refresh, cb_refresh_fn, None)

    def on_dark_click(widget, user_data):
        is_dark = ft.ft_theme_get_dark_mode()
        new_dark = 0 if is_dark else 1
        ft.ft_theme_set_dark_mode(new_dark)
        # Re-apply theme to window
        cur_theme = ft.ft_theme_get()
        if cur_theme:
            ft.ft_theme_set(cur_theme)

    cb_dark_fn = CLICK_CB(on_dark_click)
    g_callbacks.append(cb_dark_fn)
    ft.ft_button_on_click(btn_dark, cb_dark_fn, None)

    def on_theme_change(widget, selected_index, text, user_data):
        if text:
            t = text.decode("utf-8") if isinstance(text, bytes) else str(text)
            if "Default" in t:
                ft.ft_theme_set(b"default")
            elif "Nord" in t:
                ft.ft_theme_set(b"nord")
            elif "Dracula" in t:
                ft.ft_theme_set(b"dracula")
            elif "Gruvbox" in t:
                ft.ft_theme_set(b"gruvbox")

    cb_theme_fn = COMBO_CB(on_theme_change)
    g_callbacks.append(cb_theme_fn)
    ft.ft_combobox_on_change(cb_theme, cb_theme_fn, None)

    # Show window & enter main loop
    ft.ft_widget_show(win)
    print(f"[Fastfetch UI] Running for {user_at_host} on {distro_name}...")
    ft.ft_main_loop()
    ft.ft_quit()

if __name__ == "__main__":
    main()

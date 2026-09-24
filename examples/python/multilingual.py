#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Multilingual & Internationalization Showcase (Python)
Demonstrates UTF-8 text rendering, font management, and interactive text selection
across multiple world scripts (Latin, Cyrillic, Greek, CJK, Thai, Indic, Arabic, Hebrew).
"""

import ctypes
import os
import sys

# Locate and load libft.so
LIB_SEARCH_PATHS = [
    os.path.abspath(os.path.join(os.path.dirname(__file__), "../../target/libft.so")),
    "/usr/local/lib/libft.so",
]

lib_path = None
for p in LIB_SEARCH_PATHS:
    if os.path.exists(p):
        lib_path = p
        break

if not lib_path:
    print("Error: Could not find libft.so. Please compile the library first.")
    sys.exit(1)

ft = ctypes.CDLL(lib_path)

# Signatures
CLICK_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)
TOGGLE_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_int32, ctypes.c_void_p)

ft.ft_init.argtypes = []
ft.ft_init.restype = None

ft.ft_main_loop.argtypes = []
ft.ft_main_loop.restype = None

ft.ft_window_create.argtypes = [ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_window_create.restype = ctypes.c_void_p

ft.ft_widget_show.argtypes = [ctypes.c_void_p]
ft.ft_widget_show.restype = None

ft.ft_button_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_button_create.restype = ctypes.c_void_p

ft.ft_button_on_click.argtypes = [ctypes.c_void_p, CLICK_CB, ctypes.c_void_p]
ft.ft_button_on_click.restype = None

ft.ft_switch_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_switch_create.restype = ctypes.c_void_p

ft.ft_switch_set_checked.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_switch_set_checked.restype = None

ft.ft_switch_on_toggle.argtypes = [ctypes.c_void_p, TOGGLE_CB, ctypes.c_void_p]
ft.ft_switch_on_toggle.restype = None

ft.ft_text_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_text_create.restype = ctypes.c_void_p

ft.ft_text_set_text.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_text_set_text.restype = None

ft.ft_text_set_selectable.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_text_set_selectable.restype = None

ft.ft_text_select_all.argtypes = [ctypes.c_void_p]
ft.ft_text_select_all.restype = None

ft.ft_text_copy.argtypes = [ctypes.c_void_p]
ft.ft_text_copy.restype = ctypes.c_int32

ft.ft_clipboard_get_text.argtypes = []
ft.ft_clipboard_get_text.restype = ctypes.c_char_p

ft.ft_theme_set.argtypes = [ctypes.c_char_p]
ft.ft_theme_set.restype = ctypes.c_int32

ft.ft_theme_get.argtypes = []
ft.ft_theme_get.restype = ctypes.c_char_p

ft.ft_theme_set_dark_mode.argtypes = [ctypes.c_int32]
ft.ft_theme_set_dark_mode.restype = None

ft.ft_theme_get_dark_mode.argtypes = []
ft.ft_theme_get_dark_mode.restype = ctypes.c_int32

ft.ft_widget_set_font.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_font.restype = None

ft.ft_system_font_get.argtypes = []
ft.ft_system_font_get.restype = ctypes.c_char_p

ft.ft_font_gamma_get.argtypes = []
ft.ft_font_gamma_get.restype = ctypes.c_double

ft.ft_screen_dpi_get.argtypes = []
ft.ft_screen_dpi_get.restype = ctypes.c_double

# Multilingual Samples
SAMPLES = [
    # European & Mediterranean
    ("English", "Welcome to Floria Toolkit!", "Ubuntu-11"),
    ("Spanish", "¡Hola! Bienvenidos a Floria Toolkit", "Ubuntu-11"),
    ("French", "Bonjour, bienvenue sur Floria Toolkit", "Ubuntu-11"),
    ("German", "Schöne Grüße & Herzlich Willkommen!", "Ubuntu-11"),
    ("Russian (Русский)", "Привет, мир! Добро пожаловать в Floria", "Ubuntu-11"),
    ("Greek (Ελληνικά)", "Γειά σου κόσμε! Καλώς ήρθατε στο Floria", "Ubuntu-11"),

    # East Asian (CJK)
    ("Japanese (Nihongo)", "こんにちは、世界！Floriaへようこそ", "Noto Sans CJK JP-11"),
    ("Chinese Simp (简体中文)", "你好，世界！欢迎使用 Floria Toolkit", "Noto Sans CJK SC-11"),
    ("Chinese Trad (繁體中文)", "你好，世界！歡迎使用 Floria Toolkit", "Noto Sans CJK TC-11"),
    ("Korean (한국어)", "안녕하세요, 세계! Floria에 오신 것을 환영합니다", "Noto Sans CJK KR-11"),

    # South/SE Asian, Arabic & Hebrew
    ("Thai (Phasa Thai)", "สวัสดีชาวโลก! ยินดีต้อนรับสู่ Floria", "Noto Sans Thai-11"),
    ("Hindi (Hindī)", "नमस्ते दुनिया! Floria Toolkit में स्वागत है", "Noto Sans Devanagari-11"),
    ("Arabic (Al-Arabiyyah)", "مرحباً بالعالم! أهلاً بكم في Floria", "Noto Sans Arabic-11"),
    ("Hebrew (Ivrit)", "שלום עולם! ברוכים הבאים ל-Floria", "Noto Sans Hebrew-11"),
]

THEMES = ["default", "nord", "dracula", "gruvbox", "gtk2", "classic"]
current_theme_idx = 0

s_banner_text = None
s_lbl_clipboard = None

def on_theme_cycle(widget, user_data):
    global current_theme_idx
    current_theme_idx = (current_theme_idx + 1) % len(THEMES)
    ft.ft_theme_set(THEMES[current_theme_idx].encode("utf-8"))
    print(f"[Python Multilingual] Theme: {ft.ft_theme_get().decode('utf-8')}")

def on_dark_mode_toggle(widget, checked, user_data):
    ft.ft_theme_set_dark_mode(checked)
    print(f"[Python Multilingual] Dark Mode: {'ON' if checked else 'OFF'}")

def on_copy_active(widget, user_data):
    global s_banner_text, s_lbl_clipboard
    if s_banner_text:
        ft.ft_text_copy(s_banner_text)
        clip = ft.ft_clipboard_get_text()
        text_str = clip.decode('utf-8', errors='replace') if clip else "(empty)"
        if s_lbl_clipboard:
            ft.ft_text_set_text(s_lbl_clipboard, f"Clipboard: {text_str}".encode('utf-8'))
        print(f"[Python Multilingual] Copied: '{text_str}'")

def make_sample_callback(phrase, font_name):
    def cb(widget, user_data):
        global s_banner_text
        if s_banner_text:
            ft.ft_text_set_text(s_banner_text, phrase.encode("utf-8"))
            if font_name:
                ft.ft_widget_set_font(s_banner_text, font_name.encode("utf-8"))
            ft.ft_text_select_all(s_banner_text)
            print(f"[Python Multilingual] Loaded phrase: {phrase}")
    return CLICK_CB(cb)

# Keep callback references alive to prevent GC
callbacks = []

def main():
    global s_banner_text, s_lbl_clipboard

    ft.ft_init()
    sys_font = ft.ft_system_font_get().decode("utf-8")
    dpi = ft.ft_screen_dpi_get()
    gamma = ft.ft_font_gamma_get()
    print(f"[Python Multilingual] System Font: {sys_font} | DPI: {dpi:.1f} | Gamma: {gamma:.2f}")

    win = ft.ft_window_create(880, 640, "Floria Toolkit (Python) — Multilingual Showcase".encode("utf-8"))

    # Headers
    title = ft.ft_text_create(win, 24, 12, 832, 26, "Floria Toolkit — Internationalization & Unicode Typography".encode("utf-8"))
    ft.ft_text_set_selectable(title, 0)

    sub = ft.ft_text_create(win, 24, 38, 832, 20, "Full UTF-8 support across Latin, Cyrillic, Greek, CJK, Thai, Indic & BiDi/RTL scripts.".encode("utf-8"))
    ft.ft_text_set_selectable(sub, 0)

    # Top Controls
    cb_theme = CLICK_CB(on_theme_cycle)
    callbacks.append(cb_theme)
    btn_theme = ft.ft_button_create(win, 24, 66, 140, 36, "Next Theme".encode("utf-8"))
    ft.ft_button_on_click(btn_theme, cb_theme, None)

    cb_dark = TOGGLE_CB(on_dark_mode_toggle)
    callbacks.append(cb_dark)
    sw_dark = ft.ft_switch_create(win, 180, 71, 140, 26, "Dark Mode".encode("utf-8"))
    ft.ft_switch_set_checked(sw_dark, ft.ft_theme_get_dark_mode())
    ft.ft_switch_on_toggle(sw_dark, cb_dark, None)

    cb_copy = CLICK_CB(on_copy_active)
    callbacks.append(cb_copy)
    btn_copy = ft.ft_button_create(win, 335, 66, 170, 36, "Copy Active Phrase".encode("utf-8"))
    ft.ft_button_on_click(btn_copy, cb_copy, None)

    s_lbl_clipboard = ft.ft_text_create(win, 520, 72, 335, 24, "Clipboard: (empty)".encode("utf-8"))
    ft.ft_text_set_selectable(s_lbl_clipboard, 1)

    # Column Headers
    c1 = ft.ft_text_create(win, 24, 115, 400, 22, "1. European & Mediterranean Scripts:".encode("utf-8"))
    ft.ft_text_set_selectable(c1, 0)

    c2 = ft.ft_text_create(win, 450, 115, 400, 22, "2. Asian & Global Writing Systems:".encode("utf-8"))
    ft.ft_text_set_selectable(c2, 0)

    # Language Rows
    start_y = 142
    row_h = 52

    for i, (label, phrase, font_name) in enumerate(SAMPLES):
        is_col2 = (i >= 6)
        col_x = 450 if is_col2 else 24
        row_idx = (i - 6) if is_col2 else i
        cur_y = start_y + row_idx * row_h

        lbl_w = ft.ft_text_create(win, col_x, cur_y, 260, 18, f"{label}:".encode("utf-8"))
        ft.ft_text_set_selectable(lbl_w, 0)

        cb_sample = make_sample_callback(phrase, font_name)
        callbacks.append(cb_sample)
        btn_sel = ft.ft_button_create(win, col_x + 335, cur_y - 2, 65, 22, "Select".encode("utf-8"))
        ft.ft_button_on_click(btn_sel, cb_sample, None)

        txt_w = ft.ft_text_create(win, col_x, cur_y + 20, 400, 26, phrase.encode("utf-8"))
        ft.ft_text_set_selectable(txt_w, 1)
        if font_name:
            ft.ft_widget_set_font(txt_w, font_name.encode("utf-8"))

    # Bottom Banner
    banner_lbl = ft.ft_text_create(win, 24, 564, 832, 20, 
                                   "Interactive UTF-8 Text Selection Banner (Click 'Select' above or drag & double-click below):".encode("utf-8"))
    ft.ft_text_set_selectable(banner_lbl, 0)

    s_banner_text = ft.ft_text_create(win, 24, 588, 832, 34, 
                                      "こんにちは、世界！欢迎使用 Floria Toolkit (Click & drag to select any part)".encode("utf-8"))
    ft.ft_text_set_selectable(s_banner_text, 1)
    ft.ft_widget_set_font(s_banner_text, "Noto Sans CJK JP-13".encode("utf-8"))

    ft.ft_widget_show(win)
    print("[Python Multilingual] Running main loop...")
    ft.ft_main_loop()

if __name__ == "__main__":
    main()

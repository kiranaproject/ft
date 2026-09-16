#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Ubuntu Terminal Per-Pixel Background Transparency Demo
Demonstrates:
  1. Per-pixel 32-bit ARGB TrueColor Visual on X11.
  2. Translucent window background (showing desktop wallpaper / windows underneath).
  3. 100% Solid, crisp widgets inside (text, buttons, tabs, sliders, container cards).
  4. Real-time background opacity adjustment via slider and quick presets.
  5. Dynamic background tint switching (Ubuntu Aubergine, Obsidian Slate, Deep Navy, Console Green).
"""

import ctypes
import os
import sys

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
    print("Error: libft.so not found. Please build the toolkit first (lazbuild src/main/pascal/ft.lpi).")
    sys.exit(1)

ft = ctypes.CDLL(lib_path)

# Callback signatures
CLICK_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)
SLIDER_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_double, ctypes.c_void_p)

g_callbacks = []

def to_bytes(s):
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

# Window & Widgets
ft.ft_window_create.argtypes = [ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_window_create.restype = ctypes.c_void_p
ft.ft_window_set_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_window_set_opacity.restype = None
ft.ft_window_get_opacity.argtypes = [ctypes.c_void_p]
ft.ft_window_get_opacity.restype = ctypes.c_double
ft.ft_window_set_background_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_window_set_background_opacity.restype = None
ft.ft_window_get_background_opacity.argtypes = [ctypes.c_void_p]
ft.ft_window_get_background_opacity.restype = ctypes.c_double

ft.ft_widget_show.argtypes = [ctypes.c_void_p]
ft.ft_widget_show.restype = None
ft.ft_widget_set_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_widget_set_opacity.restype = None
ft.ft_widget_set_style.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_style.restype = None

ft.ft_text_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_text_create.restype = ctypes.c_void_p
ft.ft_text_set_text.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_text_set_text.restype = None

ft.ft_button_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_button_create.restype = ctypes.c_void_p
ft.ft_button_on_click.argtypes = [ctypes.c_void_p, CLICK_CB, ctypes.c_void_p]
ft.ft_button_on_click.restype = None
ft.ft_button_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_button_set_corner_radius.restype = None

ft.ft_slider_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_slider_create.restype = ctypes.c_void_p
ft.ft_slider_set_range.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
ft.ft_slider_set_range.restype = None
ft.ft_slider_set_value.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_slider_set_value.restype = None
ft.ft_slider_on_change.argtypes = [ctypes.c_void_p, SLIDER_CB, ctypes.c_void_p]
ft.ft_slider_on_change.restype = None

ft.ft_container_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_container_create.restype = ctypes.c_void_p
ft.ft_container_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_container_set_corner_radius.restype = None
ft.ft_container_set_draw_frame.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_container_set_draw_frame.restype = None
ft.ft_container_set_padding.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
ft.ft_container_set_padding.restype = None
ft.ft_container_set_scrollbar_mode.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_container_set_scrollbar_mode.restype = None

# Theme & CSS
ft.ft_theme_set_dark_mode.argtypes = [ctypes.c_int32]
ft.ft_theme_set_dark_mode.restype = None

def main():
    ft.ft_init()
    ft.ft_theme_set_dark_mode(1)

    win_w = 880
    win_h = 630
    win = ft.ft_window_create(win_w, win_h, to_bytes("afumi@ubuntu: ~/projects/floria-toolkit"))

    # Initial Ubuntu aubergine background tint and 80% background opacity
    current_tint = "#2c001e"
    ft.ft_widget_set_style(win, to_bytes(f"background-color: {current_tint};"))
    ft.ft_window_set_background_opacity(win, 0.80)

    # -------------------------------------------------------------
    # 1. Authentic Top Tab / Header Bar (Solid Opaque Controls)
    # -------------------------------------------------------------
    tab_bar = ft.ft_container_create(win, 0, 0, win_w, 42)
    ft.ft_container_set_padding(tab_bar, 0.0, 0.0)
    ft.ft_container_set_scrollbar_mode(tab_bar, 0)
    ft.ft_widget_set_style(tab_bar, to_bytes("background: #190314; border-bottom: 1px solid #4a1540;"))
    ft.ft_container_set_draw_frame(tab_bar, 1)

    # Active Tab (Ubuntu Orange accent indicator)
    tab1 = ft.ft_button_create(tab_bar, 10, 6, 225, 30, to_bytes("afumi@ubuntu: ~"))
    ft.ft_widget_set_style(tab1, to_bytes(
        "background: #3c0f32; color: #ffffff; font-size: 11px; font-weight: bold; border-top: 2px solid #e95420;"
    ))
    ft.ft_button_set_corner_radius(tab1, 4.0)

    # Inactive Tab 2
    tab2 = ft.ft_button_create(tab_bar, 242, 6, 115, 30, to_bytes("python3"))
    ft.ft_widget_set_style(tab2, to_bytes(
        "background: #24051c; color: #a1a1aa; font-size: 11px; border: 1px solid #3c1233;"
    ))
    ft.ft_button_set_corner_radius(tab2, 4.0)

    # Inactive Tab 3
    tab3 = ft.ft_button_create(tab_bar, 364, 6, 80, 30, to_bytes("htop"))
    ft.ft_widget_set_style(tab3, to_bytes(
        "background: #24051c; color: #a1a1aa; font-size: 11px; border: 1px solid #3c1233;"
    ))
    ft.ft_button_set_corner_radius(tab3, 4.0)

    # Inactive Tab 4
    tab4 = ft.ft_button_create(tab_bar, 451, 6, 95, 30, to_bytes("fastfetch"))
    ft.ft_widget_set_style(tab4, to_bytes(
        "background: #24051c; color: #a1a1aa; font-size: 11px; border: 1px solid #3c1233;"
    ))
    ft.ft_button_set_corner_radius(tab4, 4.0)

    # New Tab Button
    btn_new_tab = ft.ft_button_create(tab_bar, 553, 6, 30, 30, to_bytes("+"))
    ft.ft_widget_set_style(btn_new_tab, to_bytes(
        "background: #24051c; color: #a1a1aa; font-size: 13px; font-weight: bold; border: 1px solid #3c1233;"
    ))
    ft.ft_button_set_corner_radius(btn_new_tab, 4.0)

    # Terminal Visual Mode Indicator on the right of the tab bar
    lbl_glass_status = ft.ft_text_create(tab_bar, win_w - 235, 12, 225, 20, to_bytes("[32-bit ARGB TrueColor Visual]"))
    ft.ft_widget_set_style(lbl_glass_status, to_bytes("color: #e95420; font-size: 11px; font-weight: bold;"))

    # -------------------------------------------------------------
    # 2. Terminal Console Output (Solid Text Over Translucent Glass)
    # -------------------------------------------------------------
    term_x = 24
    cur_y = 56
    line_h = 22

    # Prompt 1
    p1_user = ft.ft_text_create(win, term_x, cur_y, 100, line_h, to_bytes("afumi@ubuntu"))
    ft.ft_widget_set_style(p1_user, to_bytes("color: #4ade80; font-size: 13px; font-weight: bold;"))

    p1_sep = ft.ft_text_create(win, term_x + 98, cur_y, 8, line_h, to_bytes(":"))
    ft.ft_widget_set_style(p1_sep, to_bytes("color: #a1a1aa; font-size: 13px;"))

    p1_dir = ft.ft_text_create(win, term_x + 108, cur_y, 185, line_h, to_bytes("~/projects/floria-toolkit"))
    ft.ft_widget_set_style(p1_dir, to_bytes("color: #38bdf8; font-size: 13px; font-weight: bold;"))

    p1_cmd = ft.ft_text_create(win, term_x + 298, cur_y, 300, line_h, to_bytes("$ git status"))
    ft.ft_widget_set_style(p1_cmd, to_bytes("color: #ffffff; font-size: 13px;"))

    cur_y += line_h + 2

    # Git status details
    out1 = ft.ft_text_create(win, term_x, cur_y, 400, line_h, to_bytes("On branch main"))
    ft.ft_widget_set_style(out1, to_bytes("color: #f4f4f5; font-size: 12px; font-weight: bold;"))
    cur_y += line_h

    out2 = ft.ft_text_create(win, term_x, cur_y, 500, line_h, to_bytes("Your branch is up to date with 'origin/main'."))
    ft.ft_widget_set_style(out2, to_bytes("color: #a1a1aa; font-size: 12px;"))
    cur_y += line_h

    out3 = ft.ft_text_create(win, term_x, cur_y, 400, line_h, to_bytes("Changes to be committed:"))
    ft.ft_widget_set_style(out3, to_bytes("color: #facc15; font-size: 12px; font-weight: bold;"))
    cur_y += line_h

    out4 = ft.ft_text_create(win, term_x, cur_y, 550, line_h, to_bytes("  (use \"git restore --staged <file>...\" to unstage)"))
    ft.ft_widget_set_style(out4, to_bytes("color: #71717a; font-size: 12px;"))
    cur_y += line_h

    files = [
        ("modified:   src/main/pascal/ft.backend.x11.pas", "(32-bit ARGB TrueColor visual & X11 colormap)"),
        ("modified:   src/main/pascal/ft.canvas.agg.pas", "(Alpha modulation & AggPas blend modes)"),
        ("modified:   src/main/pascal/ft.theme.pas",      "(Window background opacity factor)"),
        ("modified:   include/ft.h",                     "(ft_window_set_background_opacity C ABI)"),
    ]

    for fname, note in files:
        f_lbl = ft.ft_text_create(win, term_x + 16, cur_y, 350, line_h, to_bytes(fname))
        ft.ft_widget_set_style(f_lbl, to_bytes("color: #22c55e; font-size: 12px; font-weight: bold;"))

        n_lbl = ft.ft_text_create(win, term_x + 375, cur_y, 420, line_h, to_bytes(note))
        ft.ft_widget_set_style(n_lbl, to_bytes("color: #94a3b8; font-size: 12px;"))
        cur_y += line_h

    cur_y += 6

    # Prompt 2: system banner
    p2_user = ft.ft_text_create(win, term_x, cur_y, 100, line_h, to_bytes("afumi@ubuntu"))
    ft.ft_widget_set_style(p2_user, to_bytes("color: #4ade80; font-size: 13px; font-weight: bold;"))

    p2_sep = ft.ft_text_create(win, term_x + 98, cur_y, 8, line_h, to_bytes(":"))
    ft.ft_widget_set_style(p2_sep, to_bytes("color: #a1a1aa; font-size: 13px;"))

    p2_dir = ft.ft_text_create(win, term_x + 108, cur_y, 185, line_h, to_bytes("~/projects/floria-toolkit"))
    ft.ft_widget_set_style(p2_dir, to_bytes("color: #38bdf8; font-size: 13px; font-weight: bold;"))

    p2_cmd = ft.ft_text_create(win, term_x + 298, cur_y, 400, line_h, to_bytes("$ ./floria --display-info"))
    ft.ft_widget_set_style(p2_cmd, to_bytes("color: #ffffff; font-size: 13px;"))
    cur_y += line_h + 2

    # Info banner line 1
    sys1 = ft.ft_text_create(win, term_x + 8, cur_y, 700, line_h, to_bytes("[OK] Compositor: Active  |  Depth: 32-bit TrueColor  |  Engine: AggPas Subpixel AA"))
    ft.ft_widget_set_style(sys1, to_bytes("color: #a78bfa; font-size: 12px; font-weight: bold;"))
    cur_y += line_h

    # Info banner line 2
    sys2 = ft.ft_text_create(win, term_x + 8, cur_y, 750, line_h, to_bytes("[OK] Window Background: Translucent  |  Widgets & Text: 100% Solid & Crisp"))
    ft.ft_widget_set_style(sys2, to_bytes("color: #38bdf8; font-size: 12px;"))
    cur_y += line_h + 4

    # Active Prompt 3 with cursor block
    p3_user = ft.ft_text_create(win, term_x, cur_y, 100, line_h, to_bytes("afumi@ubuntu"))
    ft.ft_widget_set_style(p3_user, to_bytes("color: #4ade80; font-size: 13px; font-weight: bold;"))

    p3_sep = ft.ft_text_create(win, term_x + 98, cur_y, 8, line_h, to_bytes(":"))
    ft.ft_widget_set_style(p3_sep, to_bytes("color: #a1a1aa; font-size: 13px;"))

    p3_dir = ft.ft_text_create(win, term_x + 108, cur_y, 185, line_h, to_bytes("~/projects/floria-toolkit"))
    ft.ft_widget_set_style(p3_dir, to_bytes("color: #38bdf8; font-size: 13px; font-weight: bold;"))

    p3_cmd = ft.ft_text_create(win, term_x + 298, cur_y, 30, line_h, to_bytes("$ #"))
    ft.ft_widget_set_style(p3_cmd, to_bytes("color: #ffffff; font-size: 13px; font-weight: bold;"))

    # -------------------------------------------------------------
    # 3. Floating Preferences & Opacity Controls (Solid Card Panel)
    # -------------------------------------------------------------
    card_y = win_h - 175
    card_h = 155
    card_w = win_w - 48
    panel = ft.ft_container_create(win, term_x, card_y, card_w, card_h)
    ft.ft_container_set_padding(panel, 0.0, 0.0)
    ft.ft_container_set_scrollbar_mode(panel, 0)
    ft.ft_widget_set_style(panel, to_bytes(
        "background: #18181b; border: 1px solid #3f3f46; border-radius: 8px;"
    ))
    ft.ft_container_set_corner_radius(panel, 8.0)
    ft.ft_container_set_draw_frame(panel, 1)

    # Card Title
    card_title = ft.ft_text_create(panel, 16, 12, 500, 22, to_bytes("[Preferences] Terminal Background Transparency Controls"))
    ft.ft_widget_set_style(card_title, to_bytes("color: #f4f4f5; font-size: 13px; font-weight: bold;"))

    card_desc = ft.ft_text_create(panel, 16, 34, 780, 18, to_bytes(
        "Window background is translucent (showing desktop). All text, buttons, and controls remain 100% solid & opaque."
    ))
    ft.ft_widget_set_style(card_desc, to_bytes("color: #a1a1aa; font-size: 11px;"))

    # Row 1: Slider and Presets
    lbl_slider = ft.ft_text_create(panel, 16, 62, 140, 22, to_bytes("Background Opacity:"))
    ft.ft_widget_set_style(lbl_slider, to_bytes("color: #e4e4e7; font-size: 12px; font-weight: bold;"))

    lbl_opacity_val = ft.ft_text_create(panel, 165, 62, 45, 22, to_bytes("80%"))
    ft.ft_widget_set_style(lbl_opacity_val, to_bytes("color: #38bdf8; font-size: 13px; font-weight: bold;"))

    slider = ft.ft_slider_create(panel, 215, 64, 210, 18, 0)
    ft.ft_slider_set_range(slider, 0.10, 1.0)
    ft.ft_slider_set_value(slider, 0.80)

    # Preset buttons
    presets = [
        ("60% Glass", 0.60, 85),
        ("75% Subtle", 0.75, 85),
        ("85% Standard", 0.85, 92),
        ("100% Solid", 1.00, 85),
    ]

    def set_opacity_val(val):
        ft.ft_window_set_background_opacity(win, val)
        ft.ft_slider_set_value(slider, val)
        pct = int(round(val * 100))
        ft.ft_text_set_text(lbl_opacity_val, to_bytes(f"{pct}%"))

    def on_slider_change(sld, val, ud):
        ft.ft_window_set_background_opacity(win, val)
        pct = int(round(val * 100))
        ft.ft_text_set_text(lbl_opacity_val, to_bytes(f"{pct}%"))
    cb_slider = SLIDER_CB(on_slider_change)
    g_callbacks.append(cb_slider)
    ft.ft_slider_on_change(slider, cb_slider, None)

    preset_x = 440
    for label, op_val, btn_w in presets:
        btn_p = ft.ft_button_create(panel, preset_x, 60, btn_w, 26, to_bytes(label))
        ft.ft_widget_set_style(btn_p, to_bytes(
            "background: #27272a; color: #f4f4f5; font-size: 10px; font-weight: bold; border: 1px solid #3f3f46;"
        ))
        ft.ft_button_set_corner_radius(btn_p, 4.0)

        def make_preset_cb(v):
            def cb(btn, ud):
                set_opacity_val(v)
            return CLICK_CB(cb)
        cb_p = make_preset_cb(op_val)
        g_callbacks.append(cb_p)
        ft.ft_button_on_click(btn_p, cb_p, None)
        preset_x += btn_w + 8

    # Row 2: Background Tint Row
    lbl_tint = ft.ft_text_create(panel, 16, 105, 135, 22, to_bytes("Background Tint:"))
    ft.ft_widget_set_style(lbl_tint, to_bytes("color: #e4e4e7; font-size: 12px; font-weight: bold;"))

    tints = [
        ("Ubuntu Aubergine", "#2c001e", "#3c0f32", 140),
        ("Obsidian Charcoal", "#121214", "#27272a", 140),
        ("Deep Navy Glass", "#0a1128", "#1c2541", 140),
        ("Console Green", "#041f15", "#064e3b", 130),
    ]

    tint_x = 155
    for name, hex_col, tab_col, t_w in tints:
        btn_t = ft.ft_button_create(panel, tint_x, 102, t_w, 26, to_bytes(name))
        ft.ft_widget_set_style(btn_t, to_bytes(
            f"background: {hex_col}; color: #f4f4f5; font-size: 10px; font-weight: bold; border: 1px solid #52525b;"
        ))
        ft.ft_button_set_corner_radius(btn_t, 4.0)

        def make_tint_cb(h_col, t_col):
            def cb(btn, ud):
                ft.ft_widget_set_style(win, to_bytes(f"background-color: {h_col};"))
                ft.ft_widget_set_style(tab1, to_bytes(
                    f"background: {t_col}; color: #ffffff; font-size: 11px; font-weight: bold; border-top: 2px solid #e95420;"
                ))
            return CLICK_CB(cb)
        cb_t = make_tint_cb(hex_col, tab_col)
        g_callbacks.append(cb_t)
        ft.ft_button_on_click(btn_t, cb_t, None)
        tint_x += t_w + 8

    ft.ft_widget_show(win)
    ft.ft_main_loop()

if __name__ == "__main__":
    main()

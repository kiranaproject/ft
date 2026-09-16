#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Background Blur & Frosted Glass Showcase
Demonstrates:
  1. Window-Level Compositor Background Blur (_NET_WM_BLUR_BEHIND_REGION & _KDE_NET_WM_BLUR_BEHIND_REGION).
  2. In-Window Frosted Glass Backdrop Blur (AggPas multi-pass downsampled blur).
  3. CSS backdrop-filter: blur(Npx) support.
  4. Light Acrylic and Dark Obsidian Frosted Glass Cards with anti-aliased rounded corners.
  5. Real-time dynamic blur radius adjustment via slider.
"""

import ctypes
import os
import sys

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

# Callback signatures
CLICK_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)
SLIDER_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_double, ctypes.c_void_p)
TOGGLE_CB = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_int32, ctypes.c_void_p)

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
ft.ft_window_set_background_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_window_set_background_opacity.restype = None
ft.ft_window_get_background_opacity.argtypes = [ctypes.c_void_p]
ft.ft_window_get_background_opacity.restype = ctypes.c_double
ft.ft_window_set_background_blur.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_window_set_background_blur.restype = None
ft.ft_window_get_background_blur.argtypes = [ctypes.c_void_p]
ft.ft_window_get_background_blur.restype = ctypes.c_int32

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

ft.ft_switch_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_switch_create.restype = ctypes.c_void_p
ft.ft_switch_set_checked.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_switch_set_checked.restype = None
ft.ft_switch_on_toggle.argtypes = [ctypes.c_void_p, TOGGLE_CB, ctypes.c_void_p]
ft.ft_switch_on_toggle.restype = None

ft.ft_container_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_container_create.restype = ctypes.c_void_p
ft.ft_container_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_container_set_corner_radius.restype = None
ft.ft_container_set_backdrop_blur.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_container_set_backdrop_blur.restype = None
ft.ft_container_get_backdrop_blur.argtypes = [ctypes.c_void_p]
ft.ft_container_get_backdrop_blur.restype = ctypes.c_double
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

    win_w = 940
    win_h = 670
    win = ft.ft_window_create(win_w, win_h, to_bytes("Floria Toolkit - Background Blur & Frosted Glass Showcase"))

    # Set translucent window background and enable desktop compositor blur hint
    ft.ft_widget_set_style(win, to_bytes("background-color: #14121e;"))
    ft.ft_window_set_background_opacity(win, 0.85)
    ft.ft_window_set_background_blur(win, 1)

    # -------------------------------------------------------------
    # 1. Rich Background Content Underneath Frosted Cards
    # -------------------------------------------------------------
    # Header Title
    title = ft.ft_text_create(win, 28, 20, 600, 32, to_bytes("Floria Toolkit: Background Blur & Acrylic Glass"))
    ft.ft_widget_set_style(title, to_bytes("font-size: 20px; font-weight: bold; color: #ffffff;"))

    sub = ft.ft_text_create(win, 28, 54, 850, 20, to_bytes(
        "Demonstrating Compositor Blur (_NET_WM_BLUR_BEHIND_REGION) + In-Window Frosted Glass Backdrop Blur"
    ))
    ft.ft_widget_set_style(sub, to_bytes("font-size: 12px; color: #a1a1aa;"))

    # Decorative background content layer (high-contrast stripes & colorful badges to show off blur)
    bg_banner = ft.ft_container_create(win, 28, 88, win_w - 56, 175)
    ft.ft_container_set_padding(bg_banner, 0.0, 0.0)
    ft.ft_container_set_scrollbar_mode(bg_banner, 0)
    ft.ft_widget_set_style(bg_banner, to_bytes(
        "background: #1e1b2e; border: 1px solid #332d4f; border-radius: 10px;"
    ))

    # Colorful banners and tags inside the background banner
    colors = [
        ("#ef4444", "High Performance AggPas Subpixel Engine"),
        ("#f97316", "32-bit TrueColor ARGB Translucency"),
        ("#eab308", "Universal Unicode Multilingual Shaping"),
        ("#10b981", "Fast Multi-Pass Downsampled Stack Blur"),
        ("#06b6d4", "CSS backdrop-filter: blur(Npx) Support"),
        ("#8b5cf6", "Zero 3rd-Party Dependencies (No Cairo/GTK)"),
    ]

    tag_y = 12
    for col_hex, tag_text in colors:
        tag = ft.ft_text_create(bg_banner, 16, tag_y, win_w - 90, 22, to_bytes(f"*  {tag_text}"))
        ft.ft_widget_set_style(tag, to_bytes(f"color: {col_hex}; font-size: 12px; font-weight: bold;"))
        tag_y += 26

    # -------------------------------------------------------------
    # 2. Frosted Glass Cards (Overlapping the content)
    # -------------------------------------------------------------
    card_w = 426
    card_h = 240
    card_y = 180

    # Card 1: Light Frosted Acrylic Card (Overlaps the bottom of the banner)
    card1 = ft.ft_container_create(win, 28, card_y, card_w, card_h)
    ft.ft_container_set_padding(card1, 14.0, 14.0)
    ft.ft_container_set_scrollbar_mode(card1, 0)
    ft.ft_container_set_corner_radius(card1, 14.0)
    ft.ft_container_set_backdrop_blur(card1, 16.0)
    ft.ft_widget_set_style(card1, to_bytes(
        "background: rgba(255, 255, 255, 0.20); border: 1px solid rgba(255, 255, 255, 0.45); border-radius: 14px;"
    ))

    c1_title = ft.ft_text_create(card1, 0, 0, card_w - 28, 24, to_bytes("Light Acrylic Glass (16px Blur)"))
    ft.ft_widget_set_style(c1_title, to_bytes("color: #ffffff; font-size: 14px; font-weight: bold;"))

    c1_desc = ft.ft_text_create(card1, 0, 28, card_w - 28, 48, to_bytes(
        "Notice how the colorful text and graphics underneath this card are smoothly blurred into frosted glass, while child text stays crisp!"
    ))
    ft.ft_widget_set_style(c1_desc, to_bytes("color: #f1f5f9; font-size: 11px;"))

    btn1 = ft.ft_button_create(card1, 0, 90, 140, 32, to_bytes("Frosted Button"))
    ft.ft_widget_set_style(btn1, to_bytes(
        "background: rgba(255, 255, 255, 0.35); color: #ffffff; font-size: 11px; font-weight: bold; border: 1px solid #ffffff;"
    ))
    ft.ft_button_set_corner_radius(btn1, 6.0)

    btn2 = ft.ft_button_create(card1, 150, 90, 140, 32, to_bytes("Accent Action"))
    ft.ft_widget_set_style(btn2, to_bytes(
        "background: #3b82f6; color: #ffffff; font-size: 11px; font-weight: bold;"
    ))
    ft.ft_button_set_corner_radius(btn2, 6.0)

    sw1 = ft.ft_switch_create(card1, 0, 140, 240, 26, to_bytes("Vibrancy Effect"))
    ft.ft_switch_set_checked(sw1, 1)

    # Card 2: Dark Obsidian Frosted Glass Card
    card2 = ft.ft_container_create(win, 484, card_y, card_w, card_h)
    ft.ft_container_set_padding(card2, 14.0, 14.0)
    ft.ft_container_set_scrollbar_mode(card2, 0)
    ft.ft_container_set_corner_radius(card2, 14.0)
    ft.ft_container_set_backdrop_blur(card2, 16.0)
    ft.ft_widget_set_style(card2, to_bytes(
        "background: rgba(18, 18, 22, 0.65); border: 1px solid rgba(255, 255, 255, 0.18); border-radius: 14px;"
    ))

    c2_title = ft.ft_text_create(card2, 0, 0, card_w - 28, 24, to_bytes("Obsidian Glass (16px Blur)"))
    ft.ft_widget_set_style(c2_title, to_bytes("color: #ffffff; font-size: 14px; font-weight: bold;"))

    c2_desc = ft.ft_text_create(card2, 0, 28, card_w - 28, 48, to_bytes(
        "Dark frosted glass container with deep tint and high contrast. Anti-aliased subpixel rendering keeps edges razor-sharp."
    ))
    ft.ft_widget_set_style(c2_desc, to_bytes("color: #cbd5e1; font-size: 11px;"))

    btn_dark = ft.ft_button_create(card2, 0, 90, 160, 32, to_bytes("Dark Glass Action"))
    ft.ft_widget_set_style(btn_dark, to_bytes(
        "background: rgba(39, 39, 42, 0.85); color: #f4f4f5; font-size: 11px; font-weight: bold; border: 1px solid #52525b;"
    ))
    ft.ft_button_set_corner_radius(btn_dark, 6.0)

    sw2 = ft.ft_switch_create(card2, 0, 140, 240, 26, to_bytes("Anti-Aliased Corners"))
    ft.ft_switch_set_checked(sw2, 1)

    # -------------------------------------------------------------
    # 3. Interactive Blur Control Panel at Bottom
    # -------------------------------------------------------------
    panel_y = win_h - 220
    panel_h = 200
    panel_w = win_w - 56
    panel = ft.ft_container_create(win, 28, panel_y, panel_w, panel_h)
    ft.ft_container_set_padding(panel, 0.0, 0.0)
    ft.ft_container_set_scrollbar_mode(panel, 0)
    ft.ft_container_set_corner_radius(panel, 12.0)
    ft.ft_container_set_backdrop_blur(panel, 12.0)
    ft.ft_widget_set_style(panel, to_bytes(
        "background: rgba(24, 24, 27, 0.82); border: 1px solid #3f3f46; border-radius: 12px;"
    ))

    p_title = ft.ft_text_create(panel, 18, 14, 500, 22, to_bytes("Blur Configuration & Real-Time Controls"))
    ft.ft_widget_set_style(p_title, to_bytes("color: #ffffff; font-size: 14px; font-weight: bold;"))

    p_desc = ft.ft_text_create(panel, 18, 36, panel_w - 36, 18, to_bytes(
        "Adjust in-window backdrop blur radius or toggle window-level compositor blur for transparent see-through."
    ))
    ft.ft_widget_set_style(p_desc, to_bytes("color: #a1a1aa; font-size: 11px;"))

    # Slider row
    lbl_blur = ft.ft_text_create(panel, 18, 68, 160, 22, to_bytes("Backdrop Blur Radius:"))
    ft.ft_widget_set_style(lbl_blur, to_bytes("color: #e4e4e7; font-size: 12px; font-weight: bold;"))

    lbl_blur_val = ft.ft_text_create(panel, 185, 68, 55, 22, to_bytes("16 px"))
    ft.ft_widget_set_style(lbl_blur_val, to_bytes("color: #38bdf8; font-size: 13px; font-weight: bold;"))

    slider = ft.ft_slider_create(panel, 248, 70, 205, 18, 0)
    ft.ft_slider_set_range(slider, 0.0, 30.0)
    ft.ft_slider_set_value(slider, 16.0)

    def set_blur_radius(val):
        ft.ft_container_set_backdrop_blur(card1, val)
        ft.ft_container_set_backdrop_blur(card2, val)
        ft.ft_container_set_backdrop_blur(panel, val)
        ft.ft_slider_set_value(slider, val)
        pct = int(round(val))
        ft.ft_text_set_text(lbl_blur_val, to_bytes(f"{pct} px"))
        ft.ft_text_set_text(c1_title, to_bytes(f"Light Acrylic Glass ({pct}px Blur)"))
        ft.ft_text_set_text(c2_title, to_bytes(f"Obsidian Glass ({pct}px Blur)"))

    def on_slider_change(sld, val, ud):
        set_blur_radius(val)
    cb_slider = SLIDER_CB(on_slider_change)
    g_callbacks.append(cb_slider)
    ft.ft_slider_on_change(slider, cb_slider, None)

    # Preset buttons
    preset_x = 465
    presets = [
        ("0px (Off)", 0.0, 75),
        ("8px (Subtle)", 8.0, 85),
        ("16px (Standard)", 16.0, 105),
        ("24px (Heavy)", 24.0, 95),
    ]

    for label, r_val, b_w in presets:
        btn_p = ft.ft_button_create(panel, preset_x, 66, b_w, 26, to_bytes(label))
        ft.ft_widget_set_style(btn_p, to_bytes(
            "background: #27272a; color: #f4f4f5; font-size: 10px; font-weight: bold; border: 1px solid #3f3f46;"
        ))
        ft.ft_button_set_corner_radius(btn_p, 4.0)

        def make_preset_cb(v):
            def cb(btn, ud):
                set_blur_radius(v)
            return CLICK_CB(cb)
        cb_p = make_preset_cb(r_val)
        g_callbacks.append(cb_p)
        ft.ft_button_on_click(btn_p, cb_p, None)
        preset_x += b_w + 8

    # Row 2: Compositor Window Blur Switch
    sw_comp = ft.ft_switch_create(panel, 18, 115, 340, 26, to_bytes("Compositor Window Blur (_NET_WM_BLUR_BEHIND_REGION)"))
    ft.ft_switch_set_checked(sw_comp, 1)

    def on_comp_blur_toggle(sw, checked, ud):
        ft.ft_window_set_background_blur(win, 1 if checked else 0)
    cb_comp = TOGGLE_CB(on_comp_blur_toggle)
    g_callbacks.append(cb_comp)
    ft.ft_switch_on_toggle(sw_comp, cb_comp, None)

    # Status Note
    status_lbl = ft.ft_text_create(panel, 18, 155, panel_w - 36, 20, to_bytes(
        "Pure native Free Pascal + AggPas implementation | Zero external dependencies | 60 FPS subpixel rendering"
    ))
    ft.ft_widget_set_style(status_lbl, to_bytes("color: #10b981; font-size: 11px; font-weight: bold;"))

    ft.ft_widget_show(win)
    ft.ft_main_loop()

if __name__ == "__main__":
    main()

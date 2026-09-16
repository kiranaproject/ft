#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Opacity & Transparency Showcase
Demonstrates:
  1. Window Opacity (_NET_WM_WINDOW_OPACITY on X11) - live desktop transparency.
  2. Hierarchical Widget Opacity - container cards propagate alpha to all children.
  3. Image & Text Opacity - AggPas subpixel alpha compositing.
  4. CSS Opacity & Transitions - 'opacity: <val>; transition: opacity 300ms ease;'
  5. Dark Mode & dynamic theme adaptation.
"""

import ctypes
import os
import sys
import time

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
ft.ft_window_get_opacity.argtypes = [ctypes.c_void_p]
ft.ft_window_get_opacity.restype = ctypes.c_double

ft.ft_widget_show.argtypes = [ctypes.c_void_p]
ft.ft_widget_show.restype = None
ft.ft_widget_set_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_widget_set_opacity.restype = None
ft.ft_widget_get_opacity.argtypes = [ctypes.c_void_p]
ft.ft_widget_get_opacity.restype = ctypes.c_double
ft.ft_widget_set_style.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_style.restype = None
ft.ft_widget_set_style_id.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_style_id.restype = None
ft.ft_widget_set_style_class.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_style_class.restype = None

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
ft.ft_container_set_draw_frame.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_container_set_draw_frame.restype = None
ft.ft_container_set_padding.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
ft.ft_container_set_padding.restype = None

ft.ft_image_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_image_create.restype = ctypes.c_void_p

# Theme & CSS
ft.ft_theme_set.argtypes = [ctypes.c_char_p]
ft.ft_theme_set.restype = ctypes.c_int32
ft.ft_theme_get_dark_mode.argtypes = []
ft.ft_theme_get_dark_mode.restype = ctypes.c_int32
ft.ft_theme_set_dark_mode.argtypes = [ctypes.c_int32]
ft.ft_theme_set_dark_mode.restype = None
ft.ft_style_load_css_string.argtypes = [ctypes.c_char_p]
ft.ft_style_load_css_string.restype = ctypes.c_int32

def main():
    ft.ft_init()

    # Load custom stylesheet demonstrating CSS opacity transitions
    demo_css = """
    .banner {
        background: #ffffff;
        border: 1px solid #cbd5e1;
    }
    .banner.dark {
        background: #1e293b;
        border: 1px solid #334155;
    }
    .card {
        background: #ffffff;
        border: 1px solid #cbd5e1;
    }
    .card.dark {
        background: #1e293b;
        border: 1px solid #334155;
    }
    #ghost-btn {
        opacity: 0.45;
        transition: opacity 300ms ease, background 300ms ease;
    }
    #ghost-btn:hover {
        opacity: 1.0;
    }
    #toggle-card {
        transition: opacity 400ms ease;
    }
    """
    ft.ft_style_load_css_string(to_bytes(demo_css))

    win_w = 900
    win_h = 650
    win = ft.ft_window_create(win_w, win_h, to_bytes("Floria Toolkit - Opacity & Transparency Showcase"))

    assets_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets"))
    ubuntu_png = os.path.join(assets_dir, "ubuntu_logo.png")
    rocket_png = os.path.join(assets_dir, "emoji_rocket.png")

    # Header section
    title = ft.ft_text_create(win, 24, 20, 500, 32, to_bytes("Floria Toolkit: Window & Widget Opacity"))
    ft.ft_widget_set_style(title, to_bytes("font-size: 20px; font-weight: bold;"))

    subtitle = ft.ft_text_create(win, 24, 54, 750, 22, to_bytes("Complete subpixel alpha modulation for X11 windows, containers, images & CSS transitions"))
    ft.ft_widget_set_style(subtitle, to_bytes("color: #7f8c8d; font-size: 12px;"))

    # Theme toggle button in header
    def on_theme_toggle(btn, ud):
        cur = ft.ft_theme_get_dark_mode()
        ft.ft_theme_set_dark_mode(0 if cur else 1)
    cb_theme = CLICK_CB(on_theme_toggle)
    g_callbacks.append(cb_theme)
    theme_btn = ft.ft_button_create(win, win_w - 144, 22, 120, 34, to_bytes("Toggle Theme"))
    ft.ft_button_on_click(theme_btn, cb_theme, None)

    # -------------------------------------------------------------
    # Section 1: Window Opacity (X11 _NET_WM_WINDOW_OPACITY)
    # -------------------------------------------------------------
    win_group = ft.ft_container_create(win, 24, 90, 852, 80)
    ft.ft_container_set_draw_frame(win_group, 1)
    ft.ft_container_set_corner_radius(win_group, 8.0)
    ft.ft_container_set_padding(win_group, 16.0, 12.0)
    ft.ft_widget_set_style_class(win_group, to_bytes("banner"))

    win_lbl = ft.ft_text_create(win_group, 0, 2, 420, 22, to_bytes("OS Window Opacity (_NET_WM_WINDOW_OPACITY): 100%"))
    ft.ft_widget_set_style(win_lbl, to_bytes("font-weight: bold; font-size: 13px;"))

    win_hint = ft.ft_text_create(win_group, 0, 26, 480, 20, to_bytes("Controls X11 compositor transparency. Desktop wallpaper shows through!"))
    ft.ft_widget_set_style(win_hint, to_bytes("color: #64748b; font-size: 11px;"))

    win_slider = ft.ft_slider_create(win_group, 510, 12, 290, 28, 0)
    ft.ft_slider_set_range(win_slider, 20.0, 100.0)
    ft.ft_slider_set_value(win_slider, 100.0)

    def on_win_slider(slider, val, ud):
        norm = val / 100.0
        ft.ft_window_set_opacity(win, norm)
        ft.ft_text_set_text(win_lbl, to_bytes(f"OS Window Opacity (_NET_WM_WINDOW_OPACITY): {int(val)}%"))
    cb_win_slider = SLIDER_CB(on_win_slider)
    g_callbacks.append(cb_win_slider)
    ft.ft_slider_on_change(win_slider, cb_win_slider, None)

    # -------------------------------------------------------------
    # Section 2: Left Column - Card Container with nested widgets
    # -------------------------------------------------------------
    col_w = 414
    card = ft.ft_container_create(win, 24, 186, col_w, 436)
    ft.ft_container_set_draw_frame(card, 1)
    ft.ft_container_set_corner_radius(card, 10.0)
    ft.ft_container_set_padding(card, 16.0, 14.0)
    ft.ft_widget_set_style_class(card, to_bytes("card"))

    card_title = ft.ft_text_create(card, 0, 0, 380, 24, to_bytes("Container Alpha Stack (Hierarchical)"))
    ft.ft_widget_set_style(card_title, to_bytes("font-weight: bold; font-size: 14px;"))

    card_desc = ft.ft_text_create(card, 0, 24, 380, 42, to_bytes("Container opacity modulates all nested children: background, borders, buttons, text, and images."))
    ft.ft_widget_set_style(card_desc, to_bytes("color: #64748b; font-size: 11px;"))

    # Slider controlling the card container's opacity
    card_slider_lbl = ft.ft_text_create(card, 0, 72, 250, 20, to_bytes("Container Opacity: 100%"))
    ft.ft_widget_set_style(card_slider_lbl, to_bytes("font-weight: bold; font-size: 12px;"))

    card_slider = ft.ft_slider_create(card, 0, 94, 380, 26, 0)
    ft.ft_slider_set_range(card_slider, 10.0, 100.0)
    ft.ft_slider_set_value(card_slider, 100.0)

    def on_card_slider(slider, val, ud):
        norm = val / 100.0
        ft.ft_widget_set_opacity(card, norm)
        ft.ft_text_set_text(card_slider_lbl, to_bytes(f"Container Opacity: {int(val)}%"))
    cb_card_slider = SLIDER_CB(on_card_slider)
    g_callbacks.append(cb_card_slider)
    ft.ft_slider_on_change(card_slider, cb_card_slider, None)

    # Nested widgets inside card:
    # 1. Image
    img_widget = None
    if os.path.exists(ubuntu_png):
        img_widget = ft.ft_image_create(card, 0, 140, 64, 64, to_bytes(ubuntu_png))
    elif os.path.exists(rocket_png):
        img_widget = ft.ft_image_create(card, 0, 140, 64, 64, to_bytes(rocket_png))

    img_info = ft.ft_text_create(card, 80, 146, 290, 22, to_bytes("Nested 32-bit PNG Image"))
    ft.ft_widget_set_style(img_info, to_bytes("font-weight: bold; font-size: 13px;"))
    img_sub = ft.ft_text_create(card, 80, 172, 290, 20, to_bytes("Subpixel alpha blended into canvas"))
    ft.ft_widget_set_style(img_sub, to_bytes("color: #64748b; font-size: 11px;"))

    # 2. Individual image opacity slider
    img_slider_lbl = ft.ft_text_create(card, 0, 220, 250, 20, to_bytes("Image Child Opacity: 100%"))
    ft.ft_widget_set_style(img_slider_lbl, to_bytes("font-weight: bold; font-size: 12px;"))

    img_slider = ft.ft_slider_create(card, 0, 242, 380, 26, 0)
    ft.ft_slider_set_range(img_slider, 0.0, 100.0)
    ft.ft_slider_set_value(img_slider, 100.0)

    def on_img_slider(slider, val, ud):
        norm = val / 100.0
        if img_widget:
            ft.ft_widget_set_opacity(img_widget, norm)
        ft.ft_text_set_text(img_slider_lbl, to_bytes(f"Image Child Opacity: {int(val)}%"))
    cb_img_slider = SLIDER_CB(on_img_slider)
    g_callbacks.append(cb_img_slider)
    ft.ft_slider_on_change(img_slider, cb_img_slider, None)

    # 3. Interactive buttons and switch inside card
    card_btn1 = ft.ft_button_create(card, 0, 288, 182, 36, to_bytes("Nested Button A"))
    card_btn2 = ft.ft_button_create(card, 198, 288, 182, 36, to_bytes("Nested Button B"))

    card_switch = ft.ft_switch_create(card, 0, 340, 240, 30, to_bytes("Card Toggle Switch"))
    ft.ft_switch_set_checked(card_switch, 1)

    # -------------------------------------------------------------
    # Section 3: Right Column - CSS Opacity & Transitions
    # -------------------------------------------------------------
    right_x = 24 + col_w + 24
    card_css = ft.ft_container_create(win, right_x, 186, col_w, 436)
    ft.ft_container_set_draw_frame(card_css, 1)
    ft.ft_container_set_corner_radius(card_css, 10.0)
    ft.ft_container_set_padding(card_css, 16.0, 14.0)
    ft.ft_widget_set_style_class(card_css, to_bytes("card"))

    css_title = ft.ft_text_create(card_css, 0, 0, 380, 24, to_bytes("CSS Opacity & Transitions"))
    ft.ft_widget_set_style(css_title, to_bytes("font-weight: bold; font-size: 14px;"))

    css_desc = ft.ft_text_create(card_css, 0, 24, 380, 42, to_bytes("CSS 'opacity' with smooth 60 FPS transitions. Hover or click to trigger animated alpha interpolation."))
    ft.ft_widget_set_style(css_desc, to_bytes("color: #64748b; font-size: 11px;"))

    # Demo 1: CSS Hover Fade Button
    css_b1_lbl = ft.ft_text_create(card_css, 0, 72, 380, 20, to_bytes("1. Hover Fade Button (CSS :hover transition):"))
    ft.ft_widget_set_style(css_b1_lbl, to_bytes("font-weight: bold; font-size: 12px;"))

    ghost_btn = ft.ft_button_create(card_css, 0, 96, 380, 42, to_bytes("Hover Me! (Fades 45% -> 100%)"))
    ft.ft_widget_set_style_id(ghost_btn, to_bytes("ghost-btn"))
    ft.ft_button_set_corner_radius(ghost_btn, 6.0)

    # Demo 2: Dynamic CSS Style Change with Transition
    css_b2_lbl = ft.ft_text_create(card_css, 0, 156, 380, 20, to_bytes("2. Dynamic CSS Opacity Animation (30% <-> 100%):"))
    ft.ft_widget_set_style(css_b2_lbl, to_bytes("font-weight: bold; font-size: 12px;"))

    anim_box = ft.ft_container_create(card_css, 0, 182, 380, 90)
    ft.ft_container_set_draw_frame(anim_box, 1)
    ft.ft_container_set_corner_radius(anim_box, 8.0)
    ft.ft_container_set_padding(anim_box, 14.0, 10.0)
    ft.ft_widget_set_style_id(anim_box, to_bytes("toggle-card"))
    ft.ft_widget_set_style(anim_box, to_bytes("background: #3b82f6; opacity: 1.0;"))

    anim_inner_text = ft.ft_text_create(anim_box, 0, 4, 340, 22, to_bytes("Fading Container Card"))
    ft.ft_widget_set_style(anim_inner_text, to_bytes("color: #ffffff; font-weight: bold; font-size: 13px;"))
    anim_inner_sub = ft.ft_text_create(anim_box, 0, 28, 340, 20, to_bytes("Click button below to animate opacity"))
    ft.ft_widget_set_style(anim_inner_sub, to_bytes("color: #dbeafe; font-size: 11px;"))

    fade_state = {"faded": False}
    def on_toggle_fade(btn, ud):
        fade_state["faded"] = not fade_state["faded"]
        if fade_state["faded"]:
            ft.ft_widget_set_style(anim_box, to_bytes("background: #3b82f6; opacity: 0.3;"))
        else:
            ft.ft_widget_set_style(anim_box, to_bytes("background: #3b82f6; opacity: 1.0;"))
    cb_toggle_fade = CLICK_CB(on_toggle_fade)
    g_callbacks.append(cb_toggle_fade)
    fade_btn = ft.ft_button_create(card_css, 0, 284, 380, 36, to_bytes("Toggle Opacity Transition"))
    ft.ft_button_on_click(fade_btn, cb_toggle_fade, None)

    # Demo 3: Discrete Opacity Presets
    preset_lbl = ft.ft_text_create(card_css, 0, 334, 380, 20, to_bytes("3. Quick Opacity Presets:"))
    ft.ft_widget_set_style(preset_lbl, to_bytes("font-weight: bold; font-size: 12px;"))

    preset_25 = ft.ft_button_create(card_css, 0, 358, 86, 32, to_bytes("25%"))
    preset_50 = ft.ft_button_create(card_css, 98, 358, 86, 32, to_bytes("50%"))
    preset_75 = ft.ft_button_create(card_css, 196, 358, 86, 32, to_bytes("75%"))
    preset_100 = ft.ft_button_create(card_css, 294, 358, 86, 32, to_bytes("100%"))

    def make_preset_cb(pct):
        def cb(btn, ud):
            norm = pct / 100.0
            ft.ft_slider_set_value(card_slider, pct)
            ft.ft_widget_set_opacity(card, norm)
            ft.ft_text_set_text(card_slider_lbl, to_bytes(f"Container Opacity: {int(pct)}%"))
        return CLICK_CB(cb)

    cb25 = make_preset_cb(25.0)
    cb50 = make_preset_cb(50.0)
    cb75 = make_preset_cb(75.0)
    cb100 = make_preset_cb(100.0)
    g_callbacks.extend([cb25, cb50, cb75, cb100])
    ft.ft_button_on_click(preset_25, cb25, None)
    ft.ft_button_on_click(preset_50, cb50, None)
    ft.ft_button_on_click(preset_75, cb75, None)
    ft.ft_button_on_click(preset_100, cb100, None)

    ft.ft_widget_show(win)
    ft.ft_main_loop()

if __name__ == "__main__":
    main()

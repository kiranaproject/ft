#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Native SVG Vector Graphics Showcase
Demonstrates:
  - Zero-dependency SVG 1.1 DOM and path rendering directly onto AggPas canvas
  - Dynamic loading of SVG files and embedded SVG markup strings via TFtImage
  - Infinite vector scaling: aspect-fit, stretch, and centered modes
  - Opacity modulation with canvas alpha stack
  - High-performance vector antialiasing with smooth curves, arcs, and CSS presentation styling
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
ft.ft_widget_show.argtypes = [ctypes.c_void_p]
ft.ft_widget_show.restype = None

ft.ft_container_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_container_create.restype = ctypes.c_void_p

ft.ft_text_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_text_create.restype = ctypes.c_void_p

ft.ft_button_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_button_create.restype = ctypes.c_void_p
ft.ft_button_on_click.argtypes = [ctypes.c_void_p, CLICK_CB, ctypes.c_void_p]
ft.ft_button_on_click.restype = None

ft.ft_slider_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_slider_create.restype = ctypes.c_void_p
ft.ft_slider_set_range.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double]
ft.ft_slider_set_range.restype = None
ft.ft_slider_set_value.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_slider_set_value.restype = None
ft.ft_slider_on_change.argtypes = [ctypes.c_void_p, SLIDER_CB, ctypes.c_void_p]
ft.ft_slider_on_change.restype = None

# Image / SVG
ft.ft_image_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_image_create.restype = ctypes.c_void_p
ft.ft_image_load_file.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_image_load_file.restype = None
ft.ft_image_load_svg_file.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_image_load_svg_file.restype = None
ft.ft_image_load_svg_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_image_load_svg_string.restype = None
ft.ft_image_set_scale_mode.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_image_set_scale_mode.restype = None
ft.ft_image_set_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_image_set_opacity.restype = None

# Styling
ft.ft_theme_set.argtypes = [ctypes.c_char_p]
ft.ft_theme_set.restype = ctypes.c_int32
ft.ft_widget_set_style.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_style.restype = None

# SVG Sample Presets
SVG_SHIELD = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <path d="M 100 20 L 160 50 C 160 120 100 170 100 170 C 100 170 40 120 40 50 Z"
        fill="#3b82f6" stroke="#1d4ed8" stroke-width="4" stroke-linejoin="round" />
  <path d="M 100 35 L 145 60 C 145 115 100 155 100 155 C 100 155 55 115 55 60 Z"
        fill="#60a5fa" />
  <polyline points="75,95 95,115 130,75" fill="none" stroke="#ffffff" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" />
</svg>"""

SVG_GEOMETRIC = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <rect x="20" y="20" width="160" height="160" rx="30" fill="#181825" stroke="#cba6f7" stroke-width="3" />
  <circle cx="100" cy="100" r="50" fill="#f38ba8" />
  <polygon points="100,50 145,130 55,130" fill="#f9e2af" opacity="0.85" />
  <circle cx="100" cy="100" r="20" fill="#89dceb" />
</svg>"""

def main():
    ft.ft_init()
    ft.ft_theme_set(to_bytes("dracula"))

    win = ft.ft_window_create(840, 620, to_bytes("Floria Toolkit - SVG Vector Graphics Engine"))
    ft.ft_widget_set_style(win, to_bytes("background-color: #1e1e2e;"))

    # Title & Subtitle Header
    header = ft.ft_container_create(win, 20, 15, 800, 75)
    ft.ft_widget_set_style(header, to_bytes("background-color: #282a36; border-radius: 12px; border: 1px solid #44475a;"))

    title = ft.ft_text_create(header, 20, 10, 760, 26, to_bytes("Native Vector SVG Renderer"))
    ft.ft_widget_set_style(title, to_bytes("color: #50fa7b; font-size: 18px; font-weight: bold;"))

    subtitle = ft.ft_text_create(header, 20, 38, 760, 22, to_bytes("Zero-dependency SVG 1.1 DOM, affine transforms, arc decomposition & AggPas rasterization"))
    ft.ft_widget_set_style(subtitle, to_bytes("color: #f8f8f2; font-size: 12px;"))

    # Left Container: SVG Display Viewport
    viewport = ft.ft_container_create(win, 20, 100, 520, 500)
    ft.ft_widget_set_style(viewport, to_bytes("background-color: #282a36; border-radius: 12px; border: 1px solid #44475a;"))

    svg_asset_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/vector_showcase.svg"))

    # Main Image / SVG widget
    img_widget = ft.ft_image_create(viewport, 20, 20, 480, 450, to_bytes(svg_asset_path))

    # Right Container: Interactive Controls
    ctrl_panel = ft.ft_container_create(win, 560, 100, 260, 500)
    ft.ft_widget_set_style(ctrl_panel, to_bytes("background-color: #282a36; border-radius: 12px; border: 1px solid #44475a;"))

    lbl_source = ft.ft_text_create(ctrl_panel, 20, 20, 220, 20, to_bytes("Vector Source:"))
    ft.ft_widget_set_style(lbl_source, to_bytes("color: #bd93f9; font-weight: bold; font-size: 13px;"))

    # Button: Full Showcase SVG Asset
    btn_showcase = ft.ft_button_create(ctrl_panel, 20, 45, 220, 36, to_bytes("Showcase Icon File"))
    ft.ft_widget_set_style(btn_showcase, to_bytes("background-color: #44475a; color: #f8f8f2; border-radius: 8px;"))

    def on_showcase_click(btn, user_data):
        ft.ft_image_load_svg_file(img_widget, to_bytes(svg_asset_path))
    cb_showcase = CLICK_CB(on_showcase_click)
    g_callbacks.append(cb_showcase)
    ft.ft_button_on_click(btn_showcase, cb_showcase, None)

    # Button: Security Shield SVG String
    btn_shield = ft.ft_button_create(ctrl_panel, 20, 90, 220, 36, to_bytes("Shield Vector String"))
    ft.ft_widget_set_style(btn_shield, to_bytes("background-color: #44475a; color: #f8f8f2; border-radius: 8px;"))

    def on_shield_click(btn, user_data):
        ft.ft_image_load_svg_string(img_widget, to_bytes(SVG_SHIELD))
    cb_shield = CLICK_CB(on_shield_click)
    g_callbacks.append(cb_shield)
    ft.ft_button_on_click(btn_shield, cb_shield, None)

    # Button: Geometric Composition SVG String
    btn_geom = ft.ft_button_create(ctrl_panel, 20, 135, 220, 36, to_bytes("Geometric Composition"))
    ft.ft_widget_set_style(btn_geom, to_bytes("background-color: #44475a; color: #f8f8f2; border-radius: 8px;"))

    def on_geom_click(btn, user_data):
        ft.ft_image_load_svg_string(img_widget, to_bytes(SVG_GEOMETRIC))
    cb_geom = CLICK_CB(on_geom_click)
    g_callbacks.append(cb_geom)
    ft.ft_button_on_click(btn_geom, cb_geom, None)

    # Scale Modes
    lbl_mode = ft.ft_text_create(ctrl_panel, 20, 195, 220, 20, to_bytes("Scale Mode:"))
    ft.ft_widget_set_style(lbl_mode, to_bytes("color: #bd93f9; font-weight: bold; font-size: 13px;"))

    btn_fit = ft.ft_button_create(ctrl_panel, 20, 220, 105, 34, to_bytes("Aspect Fit"))
    ft.ft_widget_set_style(btn_fit, to_bytes("background-color: #6272a4; color: #f8f8f2; border-radius: 6px;"))
    def on_fit_click(btn, user_data):
        ft.ft_image_set_scale_mode(img_widget, 0)
    cb_fit = CLICK_CB(on_fit_click)
    g_callbacks.append(cb_fit)
    ft.ft_button_on_click(btn_fit, cb_fit, None)

    btn_stretch = ft.ft_button_create(ctrl_panel, 135, 220, 105, 34, to_bytes("Stretch"))
    ft.ft_widget_set_style(btn_stretch, to_bytes("background-color: #44475a; color: #f8f8f2; border-radius: 6px;"))
    def on_stretch_click(btn, user_data):
        ft.ft_image_set_scale_mode(img_widget, 1)
    cb_stretch = CLICK_CB(on_stretch_click)
    g_callbacks.append(cb_stretch)
    ft.ft_button_on_click(btn_stretch, cb_stretch, None)

    btn_center = ft.ft_button_create(ctrl_panel, 20, 262, 105, 34, to_bytes("Centered 1:1"))
    ft.ft_widget_set_style(btn_center, to_bytes("background-color: #44475a; color: #f8f8f2; border-radius: 6px;"))
    def on_center_click(btn, user_data):
        ft.ft_image_set_scale_mode(img_widget, 2)
    cb_center = CLICK_CB(on_center_click)
    g_callbacks.append(cb_center)
    ft.ft_button_on_click(btn_center, cb_center, None)

    btn_none = ft.ft_button_create(ctrl_panel, 135, 262, 105, 34, to_bytes("Top-Left 1:1"))
    ft.ft_widget_set_style(btn_none, to_bytes("background-color: #44475a; color: #f8f8f2; border-radius: 6px;"))
    def on_none_click(btn, user_data):
        ft.ft_image_set_scale_mode(img_widget, 3)
    cb_none = CLICK_CB(on_none_click)
    g_callbacks.append(cb_none)
    ft.ft_button_on_click(btn_none, cb_none, None)

    # Opacity Slider
    lbl_opacity = ft.ft_text_create(ctrl_panel, 20, 320, 220, 20, to_bytes("Vector Opacity: 100%"))
    ft.ft_widget_set_style(lbl_opacity, to_bytes("color: #bd93f9; font-weight: bold; font-size: 13px;"))

    slider_opacity = ft.ft_slider_create(ctrl_panel, 20, 345, 220, 28, 0)
    ft.ft_slider_set_range(slider_opacity, 0.0, 1.0)
    ft.ft_slider_set_value(slider_opacity, 1.0)

    def on_opacity_change(slider, val, user_data):
        pct = int(round(val * 100))
        ft.ft_image_set_opacity(img_widget, ctypes.c_double(val))
    cb_opacity = SLIDER_CB(on_opacity_change)
    g_callbacks.append(cb_opacity)
    ft.ft_slider_on_change(slider_opacity, cb_opacity, None)

    # Tech Specs Badge
    specs_box = ft.ft_container_create(ctrl_panel, 15, 395, 230, 85)
    ft.ft_widget_set_style(specs_box, to_bytes("background-color: #191a21; border-radius: 8px; border: 1px solid #44475a;"))

    specs_txt = ft.ft_text_create(specs_box, 10, 10, 210, 65, to_bytes("• Free Pascal AggPas Backend\n• Pure Math Bézier Decomposition\n• Zero LibRsvg or Cairo Overhead"))
    ft.ft_widget_set_style(specs_txt, to_bytes("color: #8be9fd; font-size: 10px;"))

    ft.ft_widget_show(win)
    print("SVG Vector Graphics showcase running...")
    ft.ft_main_loop()

if __name__ == "__main__":
    main()

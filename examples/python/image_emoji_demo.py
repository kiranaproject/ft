#!/usr/bin/env python3
"""
Floria Toolkit (Ft) - Image & Emoji Drawing Showcase
Demonstrates:
  - Loading PNG image assets with alpha transparency
  - The FtImage widget (TFtImage) with Fit, Stretch, and Center scaling
  - Direct raw RGBA buffer ingestion into FtBitmap
  - Alpha blending over dynamic theme backgrounds (Light, Dark Mode, Nord, Dracula)
  - Interactive opacity slider and scaling mode toggles
"""

import ctypes
import os
import sys
import time

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

# Global callback references
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
ft.ft_text_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_text_create.restype = ctypes.c_void_p
ft.ft_text_set_text.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_text_set_text.restype = None
ft.ft_widget_set_font.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_font.restype = None
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
ft.ft_container_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32]
ft.ft_container_create.restype = ctypes.c_void_p

# Theme
ft.ft_theme_set.argtypes = [ctypes.c_char_p]
ft.ft_theme_set.restype = ctypes.c_int32
ft.ft_theme_get_dark_mode.argtypes = []
ft.ft_theme_get_dark_mode.restype = ctypes.c_int32
ft.ft_theme_set_dark_mode.argtypes = [ctypes.c_int32]
ft.ft_theme_set_dark_mode.restype = None
ft.ft_widget_set_style.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_style.restype = None

# Bitmap API
ft.ft_bitmap_create.argtypes = [ctypes.c_int32, ctypes.c_int32]
ft.ft_bitmap_create.restype = ctypes.c_void_p
ft.ft_bitmap_load_file.argtypes = [ctypes.c_char_p]
ft.ft_bitmap_load_file.restype = ctypes.c_void_p
ft.ft_bitmap_create_from_rgba.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32]
ft.ft_bitmap_create_from_rgba.restype = ctypes.c_void_p
ft.ft_bitmap_get_width.argtypes = [ctypes.c_void_p]
ft.ft_bitmap_get_width.restype = ctypes.c_int32
ft.ft_bitmap_get_height.argtypes = [ctypes.c_void_p]
ft.ft_bitmap_get_height.restype = ctypes.c_int32
ft.ft_bitmap_destroy.argtypes = [ctypes.c_void_p]
ft.ft_bitmap_destroy.restype = None

# Image Widget API
ft.ft_image_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_image_create.restype = ctypes.c_void_p
ft.ft_image_load_file.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_image_load_file.restype = None
ft.ft_image_load_memory.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int32]
ft.ft_image_load_memory.restype = None
ft.ft_image_set_bitmap.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int32]
ft.ft_image_set_bitmap.restype = None
ft.ft_image_set_scale_mode.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_image_set_scale_mode.restype = None
ft.ft_image_set_opacity.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_image_set_opacity.restype = None

# Scale modes
FT_IMAGE_SCALE_FIT = 0
FT_IMAGE_SCALE_STRETCH = 1
FT_IMAGE_SCALE_CENTER = 2
FT_IMAGE_SCALE_NONE = 3

def generate_dynamic_heart_rgba(size=64):
    """Generate a crisp RGBA heart bitmap in memory."""
    buf = bytearray(size * size * 4)
    cx = size / 2.0
    cy = size / 2.0
    for y in range(size):
        for x in range(size):
            # Normalized coordinates: x in [-1.5, 1.5], y in [-1.5, 1.5]
            nx = (x - cx) / (size * 0.35)
            ny = -(y - cy) / (size * 0.35) + 0.3
            # Heart implicit equation: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
            val = (nx**2 + ny**2 - 1.0)**3 - (nx**2) * (ny**3)
            idx = (y * size + x) * 4
            if val <= 0:
                # Inside heart: gradient red/pink
                t = (y / size)
                r = int(255 - t * 40)
                g = int(40 + t * 30)
                b = int(80 + t * 80)
                buf[idx + 0] = r
                buf[idx + 1] = g
                buf[idx + 2] = b
                buf[idx + 3] = 255
            elif val < 0.15:
                # Anti-aliased edge
                alpha = int((1.0 - (val / 0.15)) * 255)
                buf[idx + 0] = 240
                buf[idx + 1] = 40
                buf[idx + 2] = 80
                buf[idx + 3] = alpha
            else:
                # Transparent
                buf[idx + 0] = 0
                buf[idx + 1] = 0
                buf[idx + 2] = 0
                buf[idx + 3] = 0
    return bytes(buf)

def main():
    ft.ft_init()

    win_w, win_h = 860, 620
    win = ft.ft_window_create(win_w, win_h, b"Floria Toolkit - Image & Emoji Drawing Showcase")

    # Header
    title = ft.ft_text_create(win, 24, 20, 500, 30, b"Image & Emoji Rendering Showcase")
    ft.ft_widget_set_font(title, b"Inter-Bold-18")

    sub = ft.ft_text_create(win, 24, 52, 500, 20, b"High-performance alpha blitting and bilinear scaling via AggPas")
    ft.ft_widget_set_font(sub, b"Inter-Regular-11")

    # Dark Mode & Theme Toggle
    def on_dark_toggle(btn, ud):
        cur = ft.ft_theme_get_dark_mode()
        ft.ft_theme_set_dark_mode(not cur)

    btn_dark = ft.ft_button_create(win, 580, 22, 110, 32, b"Dark Mode")
    cb_dark = CLICK_CB(on_dark_toggle)
    g_callbacks.append(cb_dark)
    ft.ft_button_on_click(btn_dark, cb_dark, None)

    def on_theme_nord(btn, ud):
        ft.ft_theme_set(b"nord")
    btn_nord = ft.ft_button_create(win, 700, 22, 70, 32, b"Nord")
    cb_nord = CLICK_CB(on_theme_nord)
    g_callbacks.append(cb_nord)
    ft.ft_button_on_click(btn_nord, cb_nord, None)

    def on_theme_dracula(btn, ud):
        ft.ft_theme_set(b"dracula")
    btn_drac = ft.ft_button_create(win, 776, 22, 70, 32, b"Dracula")
    cb_drac = CLICK_CB(on_theme_dracula)
    g_callbacks.append(cb_drac)
    ft.ft_button_on_click(btn_drac, cb_drac, None)

    # Locate Assets
    assets_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets"))
    smile_path = os.path.join(assets_dir, "emoji_smile.png")
    rocket_path = os.path.join(assets_dir, "emoji_rocket.png")
    star_path = os.path.join(assets_dir, "emoji_star.png")

    # Card 1: PNG Emojis from Disk
    x1, y1 = 24, 90
    card1 = ft.ft_container_create(win, x1, y1, 390, 340)
    ft.ft_widget_set_style(card1, b"background-color: rgba(128, 128, 128, 0.08); border-radius: 10px;")

    c1_title = ft.ft_text_create(card1, 16, 14, 350, 22, b"1. PNG Emoji Assets from Disk")
    ft.ft_widget_set_font(c1_title, b"Inter-Bold-13")

    # Smile Image
    img_smile = ft.ft_image_create(card1, 16, 46, 100, 100, to_bytes(smile_path))
    ft.ft_image_set_scale_mode(img_smile, FT_IMAGE_SCALE_FIT)
    ft.ft_widget_set_style(img_smile, b"background-color: rgba(255, 255, 255, 0.12); border-radius: 8px;")
    lbl_s = ft.ft_text_create(card1, 16, 152, 100, 18, b"Smile (100x100)")
    ft.ft_widget_set_font(lbl_s, b"Inter-Medium-10")

    # Rocket Image (Scaled down)
    img_rocket = ft.ft_image_create(card1, 140, 46, 100, 100, to_bytes(rocket_path))
    ft.ft_image_set_scale_mode(img_rocket, FT_IMAGE_SCALE_FIT)
    ft.ft_widget_set_style(img_rocket, b"background-color: rgba(255, 255, 255, 0.12); border-radius: 8px;")
    lbl_r = ft.ft_text_create(card1, 140, 152, 100, 18, b"Rocket (100x100)")
    ft.ft_widget_set_font(lbl_r, b"Inter-Medium-10")

    # Star Image
    img_star = ft.ft_image_create(card1, 264, 46, 100, 100, to_bytes(star_path))
    ft.ft_image_set_scale_mode(img_star, FT_IMAGE_SCALE_FIT)
    ft.ft_widget_set_style(img_star, b"background-color: rgba(255, 255, 255, 0.12); border-radius: 8px;")
    lbl_st = ft.ft_text_create(card1, 264, 152, 100, 18, b"Star (100x100)")
    ft.ft_widget_set_font(lbl_st, b"Inter-Medium-10")

    # Card 1 bottom: Row of smaller inline emoji icons (32x32)
    row_title = ft.ft_text_create(card1, 16, 185, 350, 20, b"Inline Mini Emojis (32x32):")
    ft.ft_widget_set_font(row_title, b"Inter-SemiBold-11")

    img_s_mini = ft.ft_image_create(card1, 16, 215, 36, 36, to_bytes(smile_path))
    img_r_mini = ft.ft_image_create(card1, 66, 215, 36, 36, to_bytes(rocket_path))
    img_st_mini = ft.ft_image_create(card1, 116, 215, 36, 36, to_bytes(star_path))

    # Dynamic Memory Heart Emoji
    heart_bytes = generate_dynamic_heart_rgba(64)
    heart_ptr = ctypes.c_char_p(heart_bytes)
    bmp_heart = ft.ft_bitmap_create_from_rgba(heart_ptr, 64, 64)
    img_heart = ft.ft_image_create(card1, 166, 215, 36, 36, None)
    ft.ft_image_set_bitmap(img_heart, bmp_heart, 1)

    desc_lbl1 = ft.ft_text_create(card1, 16, 265, 350, 18, b"Icons maintain subpixel clarity and alpha")
    ft.ft_widget_set_font(desc_lbl1, b"Inter-Regular-10")
    desc_lbl2 = ft.ft_text_create(card1, 16, 285, 350, 18, b"transparency across any theme background.")
    ft.ft_widget_set_font(desc_lbl2, b"Inter-Regular-10")

    # Card 2: Interactive Scaling & Opacity
    x2, y2 = 434, 90
    card2 = ft.ft_container_create(win, x2, y2, 402, 340)
    ft.ft_widget_set_style(card2, b"background-color: rgba(128, 128, 128, 0.08); border-radius: 10px;")

    c2_title = ft.ft_text_create(card2, 16, 14, 360, 22, b"2. Dynamic Scaling & Opacity")
    ft.ft_widget_set_font(c2_title, b"Inter-Bold-13")

    # Preview Frame
    target_img = ft.ft_image_create(card2, 16, 46, 210, 160, to_bytes(smile_path))
    ft.ft_image_set_scale_mode(target_img, FT_IMAGE_SCALE_FIT)
    ft.ft_widget_set_style(target_img, b"background-color: rgba(255, 255, 255, 0.15); border-radius: 10px;")

    # Scale mode switcher buttons
    def set_mode_fit(btn, ud):
        ft.ft_image_set_scale_mode(target_img, FT_IMAGE_SCALE_FIT)
    btn_fit = ft.ft_button_create(card2, 242, 46, 144, 30, b"Mode: Aspect Fit")
    cb_fit = CLICK_CB(set_mode_fit)
    g_callbacks.append(cb_fit)
    ft.ft_button_on_click(btn_fit, cb_fit, None)

    def set_mode_center(btn, ud):
        ft.ft_image_set_scale_mode(target_img, FT_IMAGE_SCALE_CENTER)
    btn_cen = ft.ft_button_create(card2, 242, 86, 144, 30, b"Mode: 1:1 Center")
    cb_cen = CLICK_CB(set_mode_center)
    g_callbacks.append(cb_cen)
    ft.ft_button_on_click(btn_cen, cb_cen, None)

    def set_mode_stretch(btn, ud):
        ft.ft_image_set_scale_mode(target_img, FT_IMAGE_SCALE_STRETCH)
    btn_str = ft.ft_button_create(card2, 242, 126, 144, 30, b"Mode: Stretch")
    cb_str = CLICK_CB(set_mode_stretch)
    g_callbacks.append(cb_str)
    ft.ft_button_on_click(btn_str, cb_str, None)

    def switch_to_rocket(btn, ud):
        ft.ft_image_load_file(target_img, to_bytes(rocket_path))
    btn_sw = ft.ft_button_create(card2, 242, 166, 144, 30, b"Swap to Rocket")
    cb_sw = CLICK_CB(switch_to_rocket)
    g_callbacks.append(cb_sw)
    ft.ft_button_on_click(btn_sw, cb_sw, None)

    # Opacity Slider
    lbl_op = ft.ft_text_create(card2, 16, 222, 220, 18, b"Opacity: 100%")
    ft.ft_widget_set_font(lbl_op, b"Inter-Medium-11")

    sl_opacity = ft.ft_slider_create(card2, 16, 246, 370, 24, 0)
    ft.ft_slider_set_range(sl_opacity, 0.0, 1.0)
    ft.ft_slider_set_value(sl_opacity, 1.0)

    def on_opacity_change(slider, val, ud):
        ft.ft_image_set_opacity(target_img, val)
        pct = int(val * 100)
        txt = f"Opacity: {pct}%".encode("utf-8")
        ft.ft_text_set_text(lbl_op, txt)
    cb_op = SLIDER_CB(on_opacity_change)
    g_callbacks.append(cb_op)
    ft.ft_slider_on_change(sl_opacity, cb_op, None)

    # Bottom Status Bar
    status_bar = ft.ft_text_create(win, 24, 580, 810, 24, b"[Status] Ready - PNG image decoding and alpha-blended vector blitting active.")
    ft.ft_widget_set_font(status_bar, b"Inter-Medium-11")

    ft.ft_widget_show(win)
    ft.ft_main_loop()
    ft.ft_quit()

if __name__ == "__main__":
    main()

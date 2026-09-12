import ctypes
import os

lib_path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../target/bin/libft.so")
)
ft = ctypes.CDLL(lib_path)

CLICK_CALLBACK = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)

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

# Widgets
ft.ft_button_create.argtypes = [
    ctypes.c_void_p,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_char_p,
]
ft.ft_button_create.restype = ctypes.c_void_p

ft.ft_button_on_click.argtypes = [ctypes.c_void_p, CLICK_CALLBACK, ctypes.c_void_p]
ft.ft_button_on_click.restype = None

# Font Management
ft.ft_system_font_get.argtypes = []
ft.ft_system_font_get.restype = ctypes.c_char_p

ft.ft_system_font_set.argtypes = [ctypes.c_char_p]
ft.ft_system_font_set.restype = None

ft.ft_widget_set_font.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_font.restype = None

ft.ft_widget_get_font.argtypes = [ctypes.c_void_p]
ft.ft_widget_get_font.restype = ctypes.c_char_p

ft.ft_screen_dpi_get.argtypes = []
ft.ft_screen_dpi_get.restype = ctypes.c_double

ft.ft_font_gamma_get.argtypes = []
ft.ft_font_gamma_get.restype = ctypes.c_double


def handle_click(widget, user_data):
  print("[Chinese Test] Button clicked!")


cb = CLICK_CALLBACK(handle_click)

ft.ft_init()
sys_font = ft.ft_system_font_get()
gamma = ft.ft_font_gamma_get()
dpi = ft.ft_screen_dpi_get()
print(
    f"[Python Host] System Font: {sys_font.decode('utf-8') if sys_font else 'Default'} (DPI: {dpi:.1f}, Gamma: {gamma:.2f})"
)

win = ft.ft_window_create(
    500, 260, "Floria - 中文测试".encode("utf-8")
)

# Button 1: Inherits default system font (Ubuntu), uses automatic CJK fallback
btn1 = ft.ft_button_create(
    win, 40, 50, 200, 45, "按我 (Click Me)".encode("utf-8")
)
ft.ft_button_on_click(btn1, cb, None)

# Button 2: Explicit CJK font
btn2 = ft.ft_button_create(
    win, 260, 50, 200, 45, "确定 (Confirm)".encode("utf-8")
)
ft.ft_widget_set_font(btn2, b"Noto Sans CJK SC-12")
ft.ft_button_on_click(btn2, cb, None)

# Button 3: Full Chinese phrase
btn3 = ft.ft_button_create(
    win, 40, 130, 420, 50, "你好，世界！欢迎使用 Floria Toolkit".encode("utf-8")
)
ft.ft_widget_set_font(btn3, b"Noto Sans CJK SC-13")
ft.ft_button_on_click(btn3, cb, None)

ft.ft_widget_show(win)
ft.ft_main_loop()

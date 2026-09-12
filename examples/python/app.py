import ctypes
import os

lib_path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../target/bin/libft.so")
)
ft = ctypes.CDLL(lib_path)

CLICK_CALLBACK = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)
HOVER_CALLBACK = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_int32, ctypes.c_void_p)
PRESS_CALLBACK = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_int32, ctypes.c_void_p)
TOGGLE_CALLBACK = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_int32, ctypes.c_void_p)

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

# Widgets: Buttons
ft.ft_button_create.argtypes = [
    ctypes.c_void_p,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_char_p,
]
ft.ft_button_create.restype = ctypes.c_void_p

ft.ft_toggle_button_create.argtypes = [
    ctypes.c_void_p,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_char_p,
]
ft.ft_toggle_button_create.restype = ctypes.c_void_p

ft.ft_button_set_toggle.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_button_set_toggle.restype = None

ft.ft_button_get_toggle.argtypes = [ctypes.c_void_p]
ft.ft_button_get_toggle.restype = ctypes.c_int32

ft.ft_button_set_toggled.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_button_set_toggled.restype = None

ft.ft_button_get_toggled.argtypes = [ctypes.c_void_p]
ft.ft_button_get_toggled.restype = ctypes.c_int32

ft.ft_button_get_state.argtypes = [ctypes.c_void_p]
ft.ft_button_get_state.restype = ctypes.c_int32

ft.ft_button_on_click.argtypes = [ctypes.c_void_p, CLICK_CALLBACK, ctypes.c_void_p]
ft.ft_button_on_click.restype = None

ft.ft_button_on_hover.argtypes = [ctypes.c_void_p, HOVER_CALLBACK, ctypes.c_void_p]
ft.ft_button_on_hover.restype = None

ft.ft_button_on_press.argtypes = [ctypes.c_void_p, PRESS_CALLBACK, ctypes.c_void_p]
ft.ft_button_on_press.restype = None

ft.ft_button_on_toggle.argtypes = [ctypes.c_void_p, TOGGLE_CALLBACK, ctypes.c_void_p]
ft.ft_button_on_toggle.restype = None

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

ft.ft_screen_dpi_set.argtypes = [ctypes.c_double]
ft.ft_screen_dpi_set.restype = None

ft.ft_font_gamma_get.argtypes = []
ft.ft_font_gamma_get.restype = ctypes.c_double

ft.ft_font_gamma_set.argtypes = [ctypes.c_double]
ft.ft_font_gamma_set.restype = None


def handle_click(widget, user_data):
    print("[Python Host] Button OnClick triggered!")

def handle_hover(widget, hovered, user_data):
    state_str = "ENTER (Hovered)" if hovered else "LEAVE (Normal)"
    print(f"[Python Host] Button OnHover: {state_str}")

def handle_press(widget, pressed, user_data):
    state_str = "DOWN (Pressed)" if pressed else "UP (Released)"
    print(f"[Python Host] Button OnPress: {state_str}")

def handle_toggle(widget, toggled, user_data):
    state_str = "ON (Toggled)" if toggled else "OFF (Untoggled)"
    print(f"[Python Host] Button OnToggle: {state_str}")


cb_click = CLICK_CALLBACK(handle_click)
cb_hover = HOVER_CALLBACK(handle_hover)
cb_press = PRESS_CALLBACK(handle_press)
cb_toggle = TOGGLE_CALLBACK(handle_toggle)

ft.ft_init()
sys_font = ft.ft_system_font_get()
gamma = ft.ft_font_gamma_get()
dpi = ft.ft_screen_dpi_get()
print(f"[Python Host] System Font Detected: {sys_font.decode('utf-8') if sys_font else 'Default'} (DPI: {dpi:.1f}, Gamma: {gamma:.2f})")

win = ft.ft_window_create(440, 240, b"Floria Toolkit - Button Display States")

# Button 1: Normal push button with hover, press, release, click
btn1 = ft.ft_button_create(win, 40, 90, 160, 42, b"Push Button")
ft.ft_button_on_click(btn1, cb_click, None)
ft.ft_button_on_hover(btn1, cb_hover, None)
ft.ft_button_on_press(btn1, cb_press, None)

# Button 2: Toggle button with toggle display state
btn2 = ft.ft_toggle_button_create(win, 240, 90, 160, 42, b"Toggle Button")
ft.ft_button_on_click(btn2, cb_click, None)
ft.ft_button_on_hover(btn2, cb_hover, None)
ft.ft_button_on_press(btn2, cb_press, None)
ft.ft_button_on_toggle(btn2, cb_toggle, None)

ft.ft_widget_show(win)
ft.ft_main_loop()

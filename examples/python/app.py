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

# Button Styling: Rounded Corners & Shadows
ft.ft_button_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_button_set_corner_radius.restype = None

ft.ft_button_get_corner_radius.argtypes = [ctypes.c_void_p]
ft.ft_button_get_corner_radius.restype = ctypes.c_double

ft.ft_button_set_shadow.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_button_set_shadow.restype = None

ft.ft_button_get_shadow.argtypes = [ctypes.c_void_p]
ft.ft_button_get_shadow.restype = ctypes.c_int32

# Widgets: Switch
ft.ft_switch_create.argtypes = [
    ctypes.c_void_p,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_int32,
    ctypes.c_char_p,
]
ft.ft_switch_create.restype = ctypes.c_void_p

ft.ft_switch_set_checked.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_switch_set_checked.restype = None

ft.ft_switch_get_checked.argtypes = [ctypes.c_void_p]
ft.ft_switch_get_checked.restype = ctypes.c_int32

ft.ft_switch_toggle.argtypes = [ctypes.c_void_p]
ft.ft_switch_toggle.restype = None

ft.ft_switch_set_toggled.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_switch_set_toggled.restype = None

ft.ft_switch_get_toggled.argtypes = [ctypes.c_void_p]
ft.ft_switch_get_toggled.restype = ctypes.c_int32

ft.ft_switch_get_state.argtypes = [ctypes.c_void_p]
ft.ft_switch_get_state.restype = ctypes.c_int32

ft.ft_switch_on_toggle.argtypes = [ctypes.c_void_p, TOGGLE_CALLBACK, ctypes.c_void_p]
ft.ft_switch_on_toggle.restype = None

ft.ft_switch_on_change.argtypes = [ctypes.c_void_p, TOGGLE_CALLBACK, ctypes.c_void_p]
ft.ft_switch_on_change.restype = None

ft.ft_switch_on_hover.argtypes = [ctypes.c_void_p, HOVER_CALLBACK, ctypes.c_void_p]
ft.ft_switch_on_hover.restype = None

ft.ft_switch_set_corner_radius.argtypes = [ctypes.c_void_p, ctypes.c_double]
ft.ft_switch_set_corner_radius.restype = None

ft.ft_switch_get_corner_radius.argtypes = [ctypes.c_void_p]
ft.ft_switch_get_corner_radius.restype = ctypes.c_double

ft.ft_switch_set_shadow.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_switch_set_shadow.restype = None

ft.ft_switch_get_shadow.argtypes = [ctypes.c_void_p]
ft.ft_switch_get_shadow.restype = ctypes.c_int32

ft.ft_switch_set_caption.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_switch_set_caption.restype = None

ft.ft_switch_get_caption.argtypes = [ctypes.c_void_p]
ft.ft_switch_get_caption.restype = ctypes.c_char_p

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

# Theme Management
ft.ft_theme_set.argtypes = [ctypes.c_char_p]
ft.ft_theme_set.restype = ctypes.c_int32

ft.ft_theme_get.argtypes = []
ft.ft_theme_get.restype = ctypes.c_char_p

ft.ft_theme_get_available.argtypes = []
ft.ft_theme_get_available.restype = ctypes.c_char_p
ft.ft_theme_load_file.argtypes = [ctypes.c_char_p]
ft.ft_theme_load_file.restype = ctypes.c_int32

ft.ft_theme_load_dir.argtypes = [ctypes.c_char_p]
ft.ft_theme_load_dir.restype = ctypes.c_int32

ft.ft_theme_set_dark_mode.argtypes = [ctypes.c_int32]
ft.ft_theme_set_dark_mode.restype = None

ft.ft_theme_get_dark_mode.argtypes = []
ft.ft_theme_get_dark_mode.restype = ctypes.c_int32

ft.ft_theme_has_dark_mode.argtypes = [ctypes.c_char_p]
ft.ft_theme_has_dark_mode.restype = ctypes.c_int32

# Global Theme Rounded Corners & Shadows
ft.ft_theme_set_corner_radius.argtypes = [ctypes.c_double]
ft.ft_theme_set_corner_radius.restype = None

ft.ft_theme_get_corner_radius.argtypes = []
ft.ft_theme_get_corner_radius.restype = ctypes.c_double

ft.ft_theme_set_shadow.argtypes = [ctypes.c_int32]
ft.ft_theme_set_shadow.restype = None

ft.ft_theme_get_shadow.argtypes = []
ft.ft_theme_get_shadow.restype = ctypes.c_int32

DEMO_THEMES = ["default", "nord", "dracula", "gruvbox", "gtk2", "classic"]
current_theme_idx = 0

def handle_cycle_theme(widget, user_data):
    global current_theme_idx
    current_theme_idx = (current_theme_idx + 1) % len(DEMO_THEMES)
    target = DEMO_THEMES[current_theme_idx]
    print(f"[Python Host] Hot-switching theme to: '{target}'")
    ft.ft_theme_set(target.encode('utf-8'))
    print(f"[Python Host] Active theme is now: '{ft.ft_theme_get().decode('utf-8')}' (Dark Mode: {ft.ft_theme_get_dark_mode()})")

def handle_toggle_dark(widget, user_data):
    cur_dark = ft.ft_theme_get_dark_mode()
    nxt_dark = 0 if cur_dark else 1
    print(f"[Python Host] Hot-toggling Dark Mode: {cur_dark} -> {nxt_dark}")
    ft.ft_theme_set_dark_mode(nxt_dark)
    print(f"[Python Host] Dark Mode is now: {'ON' if ft.ft_theme_get_dark_mode() else 'OFF'}")

def handle_hover(widget, hovered, user_data):
    state_str = "ENTER (Hovered)" if hovered else "LEAVE (Normal)"
    print(f"[Python Host] Button OnHover: {state_str}")

def handle_press(widget, pressed, user_data):
    state_str = "DOWN (Pressed)" if pressed else "UP (Released)"
    print(f"[Python Host] Button OnPress: {state_str}")

def handle_toggle(widget, toggled, user_data):
    state_str = "ON (Toggled)" if toggled else "OFF (Untoggled)"
    print(f"[Python Host] Button OnToggle: {state_str}")


RADIUS_PRESETS = [-1.0, 0.0, 6.0, 12.0, 22.0]
RADIUS_LABELS = ["Theme Default", "0px (Square)", "6px (Curved)", "12px (Smooth)", "22px (Pill)"]
radius_idx = 0

def handle_cycle_radius(widget, user_data):
    global radius_idx
    radius_idx = (radius_idx + 1) % len(RADIUS_PRESETS)
    rad = RADIUS_PRESETS[radius_idx]
    print(f"[Python Host] Cycling Corner Radius to: {RADIUS_LABELS[radius_idx]} ({rad})")
    ft.ft_theme_set_corner_radius(rad)

def handle_toggle_shadows(widget, user_data):
    cur_sh = ft.ft_theme_get_shadow()
    nxt_sh = 0 if cur_sh else 1
    print(f"[Python Host] Toggling Shadows: {'ON' if cur_sh else 'OFF'} -> {'ON' if nxt_sh else 'OFF'}")
    ft.ft_theme_set_shadow(nxt_sh)

cb_cycle = CLICK_CALLBACK(handle_cycle_theme)
cb_dark = CLICK_CALLBACK(handle_toggle_dark)
cb_radius = CLICK_CALLBACK(handle_cycle_radius)
cb_shadow = CLICK_CALLBACK(handle_toggle_shadows)
cb_hover = HOVER_CALLBACK(handle_hover)
cb_press = PRESS_CALLBACK(handle_press)
cb_toggle = TOGGLE_CALLBACK(handle_toggle)

ft.ft_init()
sys_font = ft.ft_system_font_get()
gamma = ft.ft_font_gamma_get()
dpi = ft.ft_screen_dpi_get()
cur_theme = ft.ft_theme_get().decode('utf-8')
avail_themes = ft.ft_theme_get_available().decode('utf-8')
is_dark = ft.ft_theme_get_dark_mode()
print(f"[Python Host] System Font Detected: {sys_font.decode('utf-8') if sys_font else 'Default'} (DPI: {dpi:.1f}, Gamma: {gamma:.2f})")
print(f"[Python Host] Active Theme: {cur_theme} (Dark Mode: {'ON' if is_dark else 'OFF'})")
print(f"[Python Host] Available Themes: {avail_themes}")

win = ft.ft_window_create(500, 310, b"Floria Toolkit - Rounded Corners & Drop Shadows")

# Row 1: Next theme & Dark Mode
btn1 = ft.ft_button_create(win, 30, 45, 205, 44, b"Next Theme")
ft.ft_button_on_click(btn1, cb_cycle, None)
ft.ft_button_on_hover(btn1, cb_hover, None)
ft.ft_button_on_press(btn1, cb_press, None)

btn2 = ft.ft_button_create(win, 265, 45, 205, 44, b"Toggle Dark Mode")
ft.ft_button_on_click(btn2, cb_dark, None)
ft.ft_button_on_hover(btn2, cb_hover, None)
ft.ft_button_on_press(btn2, cb_press, None)

# Row 2: Corner Radius & Drop Shadows
btn_rad = ft.ft_button_create(win, 30, 110, 205, 44, b"Cycle Corner Radius")
ft.ft_button_on_click(btn_rad, cb_radius, None)
ft.ft_button_on_hover(btn_rad, cb_hover, None)
ft.ft_button_on_press(btn_rad, cb_press, None)

btn_sh = ft.ft_button_create(win, 265, 110, 205, 44, b"Toggle Shadows")
ft.ft_button_on_click(btn_sh, cb_shadow, None)
ft.ft_button_on_hover(btn_sh, cb_hover, None)
ft.ft_button_on_press(btn_sh, cb_press, None)

# Row 3: Custom Pill Toggle Button (22px radius override)
btn3 = ft.ft_toggle_button_create(win, 135, 185, 230, 44, b"Custom Pill Toggle")
ft.ft_button_set_corner_radius(btn3, 22.0)
ft.ft_button_on_hover(btn3, cb_hover, None)
ft.ft_button_on_press(btn3, cb_press, None)
ft.ft_button_on_toggle(btn3, cb_toggle, None)

def handle_switch_dark(widget, checked, user_data):
    print(f"[Python Host] Dark Mode Switch: {'ON' if checked else 'OFF'}")
    ft.ft_theme_set_dark_mode(checked)

def handle_switch_shadow(widget, checked, user_data):
    print(f"[Python Host] Shadows Switch: {'ON' if checked else 'OFF'}")
    ft.ft_theme_set_shadow(checked)

cb_sw_dark = TOGGLE_CALLBACK(handle_switch_dark)
cb_sw_shadow = TOGGLE_CALLBACK(handle_switch_shadow)

# Row 4: Switches (Interactive Toggle Switches)
sw1 = ft.ft_switch_create(win, 30, 250, 205, 26, b"Dark Mode")
ft.ft_switch_set_checked(sw1, is_dark)
ft.ft_switch_on_toggle(sw1, cb_sw_dark, None)

sw2 = ft.ft_switch_create(win, 265, 250, 205, 26, b"Drop Shadows")
ft.ft_switch_set_checked(sw2, ft.ft_theme_get_shadow())
ft.ft_switch_on_toggle(sw2, cb_sw_shadow, None)

ft.ft_widget_show(win)
ft.ft_main_loop()

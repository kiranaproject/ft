import ctypes
import os
import subprocess
import time

lib_path = os.path.abspath("target/bin/libft.so")
ft = ctypes.CDLL(lib_path)

ft.ft_init.argtypes = []
ft.ft_init.restype = None
ft.ft_window_create.argtypes = [ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_window_create.restype = ctypes.c_void_p
ft.ft_widget_show.argtypes = [ctypes.c_void_p]
ft.ft_widget_show.restype = None
ft.ft_text_create.argtypes = [ctypes.c_void_p, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_int32, ctypes.c_char_p]
ft.ft_text_create.restype = ctypes.c_void_p
ft.ft_text_set_selectable.argtypes = [ctypes.c_void_p, ctypes.c_int32]
ft.ft_text_set_selectable.restype = None
ft.ft_widget_set_font.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ft.ft_widget_set_font.restype = None
ft.ft_main_loop.argtypes = []
ft.ft_main_loop.restype = None

ft.ft_init()

win = ft.ft_window_create(640, 560, "Multilingual Test".encode('utf-8'))

samples = [
    ("English", "Welcome to Floria Toolkit!", "Ubuntu-12"),
    ("Spanish", "¡Hola! Bienvenidos a Floria Toolkit", "Ubuntu-12"),
    ("French", "Bonjour, bienvenue sur Floria Toolkit", "Ubuntu-12"),
    ("German", "Schöne Grüße & Herzlich Willkommen!", "Ubuntu-12"),
    ("Russian", "Привет, мир! Добро пожаловать в Floria", "Ubuntu-12"),
    ("Greek", "Γειά σου κόσμε! Καλώς ήρθατε στο Floria", "Ubuntu-12"),
    ("Japanese", "こんにちは、世界！Floriaへようこそ", "Noto Sans CJK JP-12"),
    ("Chinese (SC)", "你好，世界！欢迎使用 Floria Toolkit", "Noto Sans CJK SC-12"),
    ("Korean", "안녕하세요, 세계! Floria에 오신 것을 환영합니다", "Noto Sans CJK KR-12"),
    ("Arabic", "مرحباً بالعالم! أهلاً بكم في Floria", "Noto Sans Arabic-12"),
    ("Hebrew", "שלום עולם! ברוכים הבאים ל-Floria", "Noto Sans Hebrew-12"),
    ("Thai", "สวัสดีชาวโลก! ยินดีต้อนรับสู่ Floria", "Noto Sans Thai-12"),
    ("Hindi", "नमस्ते दुनिया! Floria Toolkit में स्वागत है", "Noto Sans Devanagari-12"),
]

for idx, (lang, text, font) in enumerate(samples):
    y = 20 + idx * 40
    lbl = ft.ft_text_create(win, 20, y, 120, 30, f"{lang}:".encode('utf-8'))
    ft.ft_text_set_selectable(lbl, 0)
    
    val = ft.ft_text_create(win, 150, y, 460, 30, text.encode('utf-8'))
    ft.ft_text_set_selectable(val, 1)
    if font:
        ft.ft_widget_set_font(val, font.encode('utf-8'))

ft.ft_widget_show(win)
print("Showing window...")
ft.ft_main_loop()

#include "ft.h"
#include <stdio.h>
#include <string.h>

static const char* s_demo_themes[] = {"default", "nord", "dracula", "gruvbox", "gtk2", "classic"};
static const int s_demo_theme_count = 6;
static int s_current_theme_index = 0;

static FtWidget s_banner_text = NULL;
static FtWidget s_lbl_clipboard = NULL;
static FtWidget s_lang_widgets[14];

typedef struct {
    const char* label;
    const char* phrase;
    const char* font;
} LangSample;

static const LangSample s_samples[] = {
    // European & Mediterranean
    {"English", "Welcome to Floria Toolkit!", "Ubuntu-11"},
    {"Spanish", "¡Hola! Bienvenidos a Floria Toolkit", "Ubuntu-11"},
    {"French", "Bonjour, bienvenue sur Floria Toolkit", "Ubuntu-11"},
    {"German", "Schöne Grüße & Herzlich Willkommen!", "Ubuntu-11"},
    {"Russian (Русский)", "Привет, мир! Добро пожаловать в Floria", "Ubuntu-11"},
    {"Greek (Ελληνικά)", "Γειά σου κόσμε! Καλώς ήρθατε στο Floria", "Ubuntu-11"},

    // East Asian (CJK)
    {"Japanese (日本語)", "こんにちは、世界！Floriaへようこそ", "Noto Sans CJK JP-11"},
    {"Chinese Simp (简体中文)", "你好，世界！欢迎使用 Floria Toolkit", "Noto Sans CJK SC-11"},
    {"Chinese Trad (繁體中文)", "你好，世界！歡迎使用 Floria Toolkit", "Noto Sans CJK TC-11"},
    {"Korean (한국어)", "안녕하세요, 세계! Floria에 오신 것을 환영합니다", "Noto Sans CJK KR-11"},

    // South/SE Asian, Arabic & Hebrew
    {"Thai (ภาษาไทย)", "สวัสดีชาวโลก! ยินดีต้อนรับสู่ Floria", "Noto Sans Thai-11"},
    {"Hindi (हिन्दी)", "नमस्ते दुनिया! Floria Toolkit में स्वागत है", "Noto Sans Devanagari-11"},
    {"Arabic (العربية)", "مرحباً بالعالم! أهلاً بكم في Floria", "Noto Sans Arabic-11"},
    {"Hebrew (עברית)", "שלום עולם! ברוכים הבאים ל-Floria", "Noto Sans Hebrew-11"},
};

static const int s_sample_count = sizeof(s_samples) / sizeof(s_samples[0]);

void on_theme_cycle(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_current_theme_index = (s_current_theme_index + 1) % s_demo_theme_count;
    ft_theme_set(s_demo_themes[s_current_theme_index]);
    printf("[Floria Multilingual] Switched theme to: '%s'\n", ft_theme_get());
}

void on_dark_mode_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(checked);
    printf("[Floria Multilingual] Dark mode: %s\n", checked ? "ON" : "OFF");
}

void on_copy_active_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_banner_text) {
        ft_text_copy(s_banner_text);
        const char* clip = ft_clipboard_get_text();
        char buf[256];
        snprintf(buf, sizeof(buf), "Clipboard: %s", (clip && *clip) ? clip : "(empty)");
        if (s_lbl_clipboard)
            ft_text_set_text(s_lbl_clipboard, buf);
        printf("[Floria Multilingual] Copied to clipboard: '%s'\n", clip ? clip : "");
    }
}

void on_sample_btn_click(FtWidget widget, void* user_data) {
    (void)widget;
    int idx = (int)(size_t)user_data;
    if (idx >= 0 && idx < s_sample_count && s_banner_text) {
        ft_text_set_text(s_banner_text, s_samples[idx].phrase);
        if (s_samples[idx].font && s_samples[idx].font[0])
            ft_widget_set_font(s_banner_text, s_samples[idx].font);
        ft_text_select_all(s_banner_text);
        printf("[Floria Multilingual] Selected sample [%s]: %s\n", 
               s_samples[idx].label, s_samples[idx].phrase);
    }
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    printf("[Floria Multilingual] Initialized. System Font: %s | DPI: %.1f | Gamma: %.2f\n",
           ft_system_font_get(), ft_screen_dpi_get(), ft_font_gamma_get());

    FtWidget win = ft_window_create(880, 640, "Floria Toolkit — Multilingual & Internationalization Showcase");

    // Header Title
    FtWidget lbl_title = ft_text_create(win, 24, 12, 832, 26, 
                                        "Floria Toolkit — Internationalization & Unicode Typography");
    ft_text_set_selectable(lbl_title, 0);

    // Header Subtitle
    FtWidget lbl_sub = ft_text_create(win, 24, 38, 832, 20, 
                                      "Full UTF-8 support across Latin, Cyrillic, Greek, CJK (Chinese/Japanese/Korean), Thai, Indic & BiDi/RTL scripts.");
    ft_text_set_selectable(lbl_sub, 0);

    // Top Controls Bar
    FtWidget btn_theme = ft_button_create(win, 24, 66, 140, 36, "Next Theme");
    ft_button_on_click(btn_theme, on_theme_cycle, NULL);

    FtWidget sw_dark = ft_switch_create(win, 180, 71, 140, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_mode_toggle, NULL);

    FtWidget btn_copy = ft_button_create(win, 335, 66, 170, 36, "Copy Active Phrase");
    ft_button_on_click(btn_copy, on_copy_active_click, NULL);

    s_lbl_clipboard = ft_text_create(win, 520, 72, 335, 24, "Clipboard: (empty)");
    ft_text_set_selectable(s_lbl_clipboard, 1);

    // Section 1 Header (Column 1: European & Mediterranean)
    FtWidget lbl_col1 = ft_text_create(win, 24, 115, 400, 22, "1. European & Mediterranean Scripts:");
    ft_text_set_selectable(lbl_col1, 0);

    // Section 2 Header (Column 2: Asian & Global Scripts)
    FtWidget lbl_col2 = ft_text_create(win, 450, 115, 400, 22, "2. Asian & Global Writing Systems:");
    ft_text_set_selectable(lbl_col2, 0);

    // Build sample rows
    int start_y = 142;
    int row_h = 52;

    for (int i = 0; i < s_sample_count; ++i) {
        int is_col2 = (i >= 6);
        int col_x = is_col2 ? 450 : 24;
        int row_idx = is_col2 ? (i - 6) : i;
        int cur_y = start_y + row_idx * row_h;

        // Label above sample
        char lbl_buf[128];
        snprintf(lbl_buf, sizeof(lbl_buf), "%s:", s_samples[i].label);
        FtWidget lbl_lang = ft_text_create(win, col_x, cur_y, 260, 18, lbl_buf);
        ft_text_set_selectable(lbl_lang, 0);
        if (s_samples[i].font && s_samples[i].font[0])
            ft_widget_set_font(lbl_lang, s_samples[i].font);

        // Quick "Select & Test" button
        FtWidget btn_test = ft_button_create(win, col_x + 335, cur_y - 2, 65, 22, "Select");
        ft_button_on_click(btn_test, on_sample_btn_click, (void*)(size_t)i);

        // The phrase widget itself (selectable!)
        s_lang_widgets[i] = ft_text_create(win, col_x, cur_y + 20, 400, 26, s_samples[i].phrase);
        ft_text_set_selectable(s_lang_widgets[i], 1);
        if (s_samples[i].font && s_samples[i].font[0])
            ft_widget_set_font(s_lang_widgets[i], s_samples[i].font);
    }

    // Bottom Banner Area: Active Selected Text for Editing / Inspection
    FtWidget lbl_banner_title = ft_text_create(win, 24, 564, 832, 20, 
                                               "Interactive UTF-8 Text Selection & Copying Banner (Click 'Select' above or drag & double-click below):");
    ft_text_set_selectable(lbl_banner_title, 0);

    s_banner_text = ft_text_create(win, 24, 588, 832, 34, 
                                   "こんにちは、世界！欢迎使用 Floria Toolkit (Click & drag to select any part)");
    ft_text_set_selectable(s_banner_text, 1);
    ft_widget_set_font(s_banner_text, "Noto Sans CJK JP-13");

    ft_widget_show(win);
    printf("[Floria Multilingual] Running main loop...\n");
    ft_main_loop();

    return 0;
}

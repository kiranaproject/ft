#include "ft.h"
#include <stdio.h>
#include <string.h>

static FtWidget s_cont1 = NULL;
static FtWidget s_cont2 = NULL;
static FtWidget s_lbl_status = NULL;
static FtWidget s_lbl_c1_pos = NULL;
static FtWidget s_lbl_c2_pos = NULL;

static const char* s_demo_themes[] = {"default", "nord", "dracula", "gruvbox", "classic"};
static const int s_demo_theme_count = 5;
static int s_current_theme_index = 0;

static void on_item_click(FtWidget widget, void* user_data) {
    (void)widget;
    const char* item_name = (const char*)user_data;
    if (s_lbl_status && item_name) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Clicked '%s' inside container!", item_name);
        ft_text_set_text(s_lbl_status, buf);
    }
}

static void on_c1_scroll(FtWidget widget, double value, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_lbl_c1_pos) {
        char buf[64];
        snprintf(buf, sizeof(buf), "Box 1 Scroll Y: %.1f", value);
        ft_text_set_text(s_lbl_c1_pos, buf);
    }
}

static void on_c2_scroll(FtWidget widget, double value, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_lbl_c2_pos) {
        char buf[64];
        snprintf(buf, sizeof(buf), "ListView Scroll Y: %.1f", value);
        ft_text_set_text(s_lbl_c2_pos, buf);
    }
}

static void on_toggle_frame(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int cur = ft_container_get_draw_frame(s_cont1);
    ft_container_set_draw_frame(s_cont1, !cur);
    if (s_lbl_status) {
        ft_text_set_text(s_lbl_status, cur ? "Status: Box 1 frame disabled (frameless viewport)" : "Status: Box 1 frame enabled");
    }
}

static void on_mode_none(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_container_set_scrollbar_mode(s_cont1, FT_SCROLLBAR_MODE_NONE);
    if (s_lbl_status) ft_text_set_text(s_lbl_status, "Status: Box 1 ScrollBar Mode: NONE (hidden)");
}

static void on_mode_vert(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_container_set_scrollbar_mode(s_cont1, FT_SCROLLBAR_MODE_VERTICAL_ONLY);
    if (s_lbl_status) ft_text_set_text(s_lbl_status, "Status: Box 1 ScrollBar Mode: VERTICAL ONLY");
}

static void on_mode_both(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_container_set_scrollbar_mode(s_cont1, FT_SCROLLBAR_MODE_AUTO_BOTH);
    if (s_lbl_status) ft_text_set_text(s_lbl_status, "Status: Box 1 ScrollBar Mode: AUTO BOTH");
}

static void on_theme_cycle(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_current_theme_index = (s_current_theme_index + 1) % s_demo_theme_count;
    ft_theme_set(s_demo_themes[s_current_theme_index]);
    if (s_lbl_status) {
        char buf[64];
        snprintf(buf, sizeof(buf), "Status: Theme set to '%s'", s_demo_themes[s_current_theme_index]);
        ft_text_set_text(s_lbl_status, buf);
    }
}

static void on_dark_toggle(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int is_dark = !ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(is_dark);
    if (s_lbl_status) {
        ft_text_set_text(s_lbl_status, is_dark ? "Status: Dark mode enabled" : "Status: Light mode enabled");
    }
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    FtWidget win = ft_window_create(760, 580, "Floria Toolkit - Reusable Container Widget (TFtContainer)");

    // Window Title & Description
    FtWidget title = ft_text_create(win, 20, 12, 720, 24, "Floria Toolkit Native Container Box (TFtContainer / ScrolledWindow)");
    ft_text_set_selectable(title, 0);

    FtWidget subtitle = ft_text_create(win, 20, 36, 720, 18, "Reusable container hosting child widgets with automatic scrollbars, viewport clipping, and relative layout");
    ft_text_set_selectable(subtitle, 0);

    // Section 1 Header
    FtWidget h1 = ft_text_create(win, 20, 60, 350, 18, "1. Form Box (Entries, Switches, Buttons):");
    ft_text_set_selectable(h1, 0);

    // Section 2 Header
    FtWidget h2 = ft_text_create(win, 390, 60, 350, 18, "2. Component ListView (Lazarus-style items):");
    ft_text_set_selectable(h2, 0);

    // --- Container 1: Form & Controls Box ---
    s_cont1 = ft_container_create(win, 20, 82, 350, 300);
    ft_container_set_scrollbar_mode(s_cont1, FT_SCROLLBAR_MODE_AUTO_BOTH);
    ft_container_on_scroll(s_cont1, on_c1_scroll, NULL);

    // Hosted children inside s_cont1 (coordinates are relative to container client area)
    FtWidget c1_t1 = ft_text_create(s_cont1, 8, 8, 250, 20, "User Account Settings:");
    ft_text_set_selectable(c1_t1, 0);

    ft_text_create(s_cont1, 8, 34, 120, 18, "Username:");
    ft_entry_create(s_cont1, 8, 54, 300, 32, "florian_kaempfl");

    ft_text_create(s_cont1, 8, 94, 120, 18, "Email Address:");
    ft_entry_create(s_cont1, 8, 114, 300, 32, "florian@freepascal.org");

    ft_text_create(s_cont1, 8, 154, 250, 18, "Environment Preferences:");
    ft_switch_create(s_cont1, 8, 178, 220, 24, "Hardware Accelerated AGG");
    ft_switch_create(s_cont1, 8, 208, 220, 24, "Anti-Aliased Typography");
    ft_switch_create(s_cont1, 8, 238, 220, 24, "Synchronize Lazarus Themes");

    ft_text_create(s_cont1, 8, 270, 250, 18, "Bio & Description:");
    ft_textarea_create(s_cont1, 8, 290, 300, 70, "Floria Toolkit container\nSmooth child scrolling!\nPixel-perfect AGG clipping.");

    FtWidget btn_save = ft_button_create(s_cont1, 8, 370, 140, 32, "Save Profile");
    ft_button_on_click(btn_save, on_item_click, (void*)"Save Profile");

    FtWidget btn_reset = ft_button_create(s_cont1, 158, 370, 150, 32, "Reset Form");
    ft_button_on_click(btn_reset, on_item_click, (void*)"Reset Form");

    FtWidget btn_export = ft_button_create(s_cont1, 8, 410, 300, 32, "Export Configuration (.xml)");
    ft_button_on_click(btn_export, on_item_click, (void*)"Export Configuration");

    // --- Container 2: ListView / Palette Box ---
    s_cont2 = ft_container_create(win, 390, 82, 350, 300);
    ft_container_set_scrollbar_mode(s_cont2, FT_SCROLLBAR_MODE_AUTO_BOTH);
    ft_container_on_scroll(s_cont2, on_c2_scroll, NULL);

    static const char* list_items[] = {
        "01. Free Pascal Compiler (FPC)",
        "02. Lazarus IDE Visual Designer",
        "03. Anti-Grain Geometry Engine",
        "04. Floria Custom Agg Canvas",
        "05. Native UTF-8 Text Selection",
        "06. ScrolledWindow Viewport Box",
        "07. Integrated Auto ScrollBars",
        "08. Rounded Corner Theme Plates",
        "09. High-DPI Subpixel Glyphs",
        "10. Native X11 Backend Server",
        "11. Pure C Dynamic Shared Library",
        "12. Smooth Child Shift Navigation"
    };
    int list_count = sizeof(list_items) / sizeof(list_items[0]);

    for (int i = 0; i < list_count; i++) {
        int y_pos = 6 + (i * 38);
        FtWidget row_txt = ft_text_create(s_cont2, 8, y_pos + 6, 210, 20, list_items[i]);
        ft_text_set_selectable(row_txt, 0);

        FtWidget row_btn = ft_button_create(s_cont2, 230, y_pos, 85, 28, "Inspect");
        ft_button_on_click(row_btn, on_item_click, (void*)list_items[i]);
    }

    // --- Bottom Controls Section ---
    s_lbl_c1_pos = ft_text_create(win, 20, 390, 170, 20, "Box 1 Scroll Y: 0.0");
    ft_text_set_selectable(s_lbl_c1_pos, 0);

    s_lbl_c2_pos = ft_text_create(win, 390, 390, 170, 20, "ListView Scroll Y: 0.0");
    ft_text_set_selectable(s_lbl_c2_pos, 0);

    // Status readout
    s_lbl_status = ft_text_create(win, 20, 415, 720, 22, "Status: Ready - interact with controls inside containers, or drag scrollbars!");
    ft_text_set_selectable(s_lbl_status, 0);

    // Mode Buttons for Container 1
    FtWidget btn_m_auto = ft_button_create(win, 20, 445, 110, 30, "Auto Scroll");
    ft_button_on_click(btn_m_auto, on_mode_both, NULL);

    FtWidget btn_m_vert = ft_button_create(win, 136, 445, 110, 30, "Vert Only");
    ft_button_on_click(btn_m_vert, on_mode_vert, NULL);

    FtWidget btn_m_none = ft_button_create(win, 252, 445, 110, 30, "Hide Bars");
    ft_button_on_click(btn_m_none, on_mode_none, NULL);

    FtWidget btn_frame = ft_button_create(win, 370, 445, 110, 30, "Toggle Frame");
    ft_button_on_click(btn_frame, on_toggle_frame, NULL);

    // Theme and Dark mode buttons
    FtWidget btn_theme = ft_button_create(win, 490, 445, 120, 30, "Switch Theme");
    ft_button_on_click(btn_theme, on_theme_cycle, NULL);

    FtWidget btn_dark = ft_button_create(win, 616, 445, 120, 30, "Toggle Dark");
    ft_button_on_click(btn_dark, on_dark_toggle, NULL);

    // Explanation Note
    FtWidget note = ft_text_create(win, 20, 490, 720, 60,
        "Notes: TFtContainer manages plate borders, focus rings, scrollbars, and inner AGG scissor clipping.\n"
        "TFtTextArea and TFtEntry now inherit from TFtContainer, sharing identical plate rendering and theme styling.\n"
        "Child widgets placed inside TFtContainer use relative coordinates and automatically scroll with zero drift.");
    ft_text_set_selectable(note, 0);

    ft_widget_show(win);
    ft_main_loop();
    ft_quit();
    return 0;
}

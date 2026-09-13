#include "ft.h"
#include <stdio.h>
#include <string.h>

static FtWidget s_lbl_vval = NULL;
static FtWidget s_lbl_hval = NULL;
static FtWidget s_lbl_mode = NULL;
static FtWidget s_textarea = NULL;

static const char* s_demo_themes[] = {"default", "nord", "dracula", "gruvbox", "classic"};
static const int s_demo_theme_count = 5;
static int s_current_theme_index = 0;

void on_vscroll(FtWidget widget, double value, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_lbl_vval) {
        char buf[64];
        snprintf(buf, sizeof(buf), "V-ScrollBar: %.1f", value);
        ft_text_set_text(s_lbl_vval, buf);
    }
}

void on_hscroll(FtWidget widget, double value, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_lbl_hval) {
        char buf[64];
        snprintf(buf, sizeof(buf), "H-ScrollBar: %.1f", value);
        ft_text_set_text(s_lbl_hval, buf);
    }
}

void on_mode_none(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_textarea_set_scrollbar_mode(s_textarea, FT_SCROLLBAR_MODE_NONE);
    ft_text_set_text(s_lbl_mode, "Current Mode: Hide Scroll Bars (NONE)");
}

void on_mode_horiz(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_textarea_set_scrollbar_mode(s_textarea, FT_SCROLLBAR_MODE_HORIZONTAL_ONLY);
    ft_text_set_text(s_lbl_mode, "Current Mode: Only Horizontal");
}

void on_mode_vert(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_textarea_set_scrollbar_mode(s_textarea, FT_SCROLLBAR_MODE_VERTICAL_ONLY);
    ft_text_set_text(s_lbl_mode, "Current Mode: Only Vertical");
}

void on_mode_both(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_textarea_set_scrollbar_mode(s_textarea, FT_SCROLLBAR_MODE_AUTO_BOTH);
    ft_text_set_text(s_lbl_mode, "Current Mode: Auto Show Both (Default)");
}

void on_theme_cycle(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_current_theme_index = (s_current_theme_index + 1) % s_demo_theme_count;
    ft_theme_set(s_demo_themes[s_current_theme_index]);
}

void on_dark_toggle(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(!ft_theme_get_dark_mode());
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    FtWidget win = ft_window_create(620, 520, "Floria Toolkit - ScrollBar & TextArea Integration");

    // Title
    FtWidget title = ft_text_create(win, 24, 16, 570, 24, "Floria Toolkit Native ScrollBar & Scrollable TextArea");
    ft_text_set_selectable(title, 0);

    // 1. Standalone ScrollBars section
    FtWidget sec1 = ft_text_create(win, 24, 46, 570, 20, "1. Standalone ScrollBar Widgets (Drag thumb, click track, or mouse wheel):");
    ft_text_set_selectable(sec1, 0);

    // Standalone Vertical ScrollBar
    FtWidget vsb = ft_scrollbar_create(win, 24, 72, 12, 100, FT_SCROLLBAR_VERTICAL);
    ft_scrollbar_set_range(vsb, 0.0, 100.0, 25.0);
    ft_scrollbar_set_value(vsb, 20.0);
    ft_scrollbar_on_scroll(vsb, on_vscroll, NULL);

    s_lbl_vval = ft_text_create(win, 44, 76, 220, 20, "V-ScrollBar: 20.0");
    ft_text_set_selectable(s_lbl_vval, 0);

    // Standalone Horizontal ScrollBar
    s_lbl_hval = ft_text_create(win, 44, 114, 220, 20, "H-ScrollBar: 45.0");
    ft_text_set_selectable(s_lbl_hval, 0);

    FtWidget hsb = ft_scrollbar_create(win, 44, 138, 220, 12, FT_SCROLLBAR_HORIZONTAL);
    ft_scrollbar_set_range(hsb, 0.0, 150.0, 30.0);
    ft_scrollbar_set_value(hsb, 45.0);
    ft_scrollbar_on_scroll(hsb, on_hscroll, NULL);

    // 2. Integrated TextArea section
    FtWidget sec2 = ft_text_create(win, 24, 185, 570, 20, "2. TextArea ScrollBar Modes (Hide, Only Horizontal, Only Vertical, Auto Both):");
    ft_text_set_selectable(sec2, 0);

    const char* sample_long_text =
        "Floria Toolkit (Ft) - Multi-line Editor with Integrated Hardware Scissor Clipping\n"
        "--------------------------------------------------------------------------------------------------------------------\n"
        "Line 1: This is a very wide line that exceeds the text area viewport horizontally so you can test horizontal scrolling!\n"
        "Line 2: Floria Toolkit is written in modern Object Pascal with AGG anti-aliased subpixel vector graphics.\n"
        "Line 3: Try dragging the vertical or horizontal scrollbar thumbs on the edges.\n"
        "Line 4: You can also use the mouse wheel to scroll vertically, or use left/right arrow navigation.\n"
        "Line 5: Shift+Arrow keys or mouse drag will select multi-line blocks with full cut/copy/paste clipboard sync.\n"
        "Line 6: The text is accurately scissor-clipped so it never bleeds past the rounded plate or under the scrollbars.\n"
        "Line 7: Use the buttons below to switch the scrollbar mode dynamically at runtime.\n"
        "Line 8: Mode options: None (hidden), Only Horizontal, Only Vertical, or Auto Both.\n"
        "Line 9: Theme integration adapts the scrollbar track and thumb to Light, Dark, Nord, Dracula, and Gruvbox themes.\n"
        "Line 10: Pure vector beauty. Fast, lightweight, and completely native.";

    s_textarea = ft_textarea_create(win, 24, 210, 572, 170, sample_long_text);
    ft_textarea_set_scrollbar_mode(s_textarea, FT_SCROLLBAR_MODE_AUTO_BOTH);

    // Mode status label
    s_lbl_mode = ft_text_create(win, 24, 390, 572, 22, "Current Mode: Auto Show Both (Default)");
    ft_text_set_selectable(s_lbl_mode, 0);

    // Mode buttons
    FtWidget btn_none = ft_button_create(win, 24, 418, 134, 38, "Hide Bars");
    ft_button_on_click(btn_none, on_mode_none, NULL);

    FtWidget btn_horiz = ft_button_create(win, 168, 418, 134, 38, "Horizontal Only");
    ft_button_on_click(btn_horiz, on_mode_horiz, NULL);

    FtWidget btn_vert = ft_button_create(win, 312, 418, 134, 38, "Vertical Only");
    ft_button_on_click(btn_vert, on_mode_vert, NULL);

    FtWidget btn_both = ft_button_create(win, 456, 418, 140, 38, "Auto Both");
    ft_button_on_click(btn_both, on_mode_both, NULL);

    // Theme & Dark Mode buttons
    FtWidget btn_thm = ft_button_create(win, 24, 466, 278, 38, "Cycle Theme (Nord/Dracula/...)");
    ft_button_on_click(btn_thm, on_theme_cycle, NULL);

    FtWidget btn_drk = ft_button_create(win, 318, 466, 278, 38, "Toggle Dark Mode");
    ft_button_on_click(btn_drk, on_dark_toggle, NULL);

    ft_widget_show(win);
    ft_main_loop();

    return 0;
}

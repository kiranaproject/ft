#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ft.h"

static FtWidget s_pathbar_main = NULL;
static FtWidget s_pathbar_deep = NULL;
static FtWidget s_pathbar_win = NULL;
static FtWidget s_lbl_status = NULL;
static FtWidget s_lbl_mode = NULL;

static void on_path_navigated(FtWidget pathbar, const char* path, void* user_data) {
    (void)pathbar; (void)user_data;
    char buf[512];
    snprintf(buf, sizeof(buf), "Navigated: %s", path ? path : "");
    if (s_lbl_status)
        ft_text_set_text(s_lbl_status, buf);
    printf("[PathBar] %s\n", buf);
}

static void on_mode_changed(FtWidget pathbar, int32_t mode, void* user_data) {
    (void)pathbar; (void)user_data;
    const char* mode_name = (mode == FT_PATH_BAR_MODE_EDIT) ? "Inline Edit (Enter=save, Esc=cancel)" : "Interactive Breadcrumbs";
    char buf[128];
    snprintf(buf, sizeof(buf), "Mode: %s", mode_name);
    if (s_lbl_mode)
        ft_text_set_text(s_lbl_mode, buf);
    printf("[PathBar] %s\n", buf);
}

static void on_nav_home(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_pathbar_main) {
        ft_path_bar_set_path(s_pathbar_main, "/home/afumi");
        on_path_navigated(s_pathbar_main, "/home/afumi", NULL);
    }
}

static void on_nav_projects(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_pathbar_main) {
        ft_path_bar_set_path(s_pathbar_main, "/home/afumi/Documents/projects/floria-toolkit");
        on_path_navigated(s_pathbar_main, "/home/afumi/Documents/projects/floria-toolkit", NULL);
    }
}

static void on_nav_root(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_pathbar_main) {
        ft_path_bar_set_path(s_pathbar_main, "/");
        on_path_navigated(s_pathbar_main, "/", NULL);
    }
}

static void on_toggle_mode(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_pathbar_main) {
        int32_t cur = ft_path_bar_get_mode(s_pathbar_main);
        int32_t next = (cur == FT_PATH_BAR_MODE_BREADCRUMBS) ? FT_PATH_BAR_MODE_EDIT : FT_PATH_BAR_MODE_BREADCRUMBS;
        ft_path_bar_set_mode(s_pathbar_main, next);
    }
}

static void on_theme_toggle(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    int is_dark = ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(!is_dark);
}

int main(int argc, char* argv[]) {
    (void)argc; (void)argv;

    ft_init();

    FtWidget win = ft_window_create(720, 560, "Floria Toolkit — Nautilus-style Dual-Mode PathBar");
    if (!win) {
        fprintf(stderr, "Failed to create window.\n");
        return 1;
    }

    /* Header */
    FtWidget title = ft_text_create(win, 24, 18, 672, 26, "Nautilus-Style Dual-Mode PathBar (TFtPathBar)");
    ft_widget_set_font(title, "Sans Bold 16");

    FtWidget desc1 = ft_text_create(win, 24, 46, 672, 18, 
        "Click segment pills to navigate, click empty space or edit button to switch to text mode.");
    ft_widget_set_font(desc1, "Sans 10");

    FtWidget desc2 = ft_text_create(win, 24, 66, 672, 18, 
        "Press Enter to commit, Escape to cancel, or Ctrl+L to quickly edit.");
    ft_widget_set_font(desc2, "Sans 10");

    /* 1. Main PathBar */
    FtWidget lbl1 = ft_text_create(win, 24, 96, 672, 20, "1. Standard PathBar (Click empty area or button to edit):");
    ft_widget_set_font(lbl1, "Sans Bold 11");

    s_pathbar_main = ft_path_bar_create(win, 24, 120, 672, 36, "/home/afumi/Documents/projects/floria-toolkit");
    ft_path_bar_on_navigate(s_pathbar_main, on_path_navigated, NULL);
    ft_path_bar_on_mode_change(s_pathbar_main, on_mode_changed, NULL);

    /* Status indicators */
    s_lbl_status = ft_text_create(win, 24, 162, 470, 20, "Navigated: /home/afumi/Documents/projects/floria-toolkit");
    ft_widget_set_font(s_lbl_status, "Monospace 9");

    s_lbl_mode = ft_text_create(win, 500, 162, 196, 20, "Mode: Interactive Breadcrumbs");
    ft_widget_set_font(s_lbl_mode, "Sans Italic 9");

    /* Quick Preset Navigation Buttons */
    FtWidget lbl_presets = ft_text_create(win, 24, 194, 672, 20, "Quick Presets & Actions:");
    ft_widget_set_font(lbl_presets, "Sans Bold 11");

    FtWidget btn_home = ft_button_create(win, 24, 218, 110, 32, "Home (~)");
    ft_button_on_click(btn_home, on_nav_home, NULL);

    FtWidget btn_proj = ft_button_create(win, 142, 218, 120, 32, "Projects");
    ft_button_on_click(btn_proj, on_nav_projects, NULL);

    FtWidget btn_root = ft_button_create(win, 270, 218, 90, 32, "Root (/)");
    ft_button_on_click(btn_root, on_nav_root, NULL);

    FtWidget btn_toggle = ft_button_create(win, 368, 218, 140, 32, "Toggle Edit Mode");
    ft_button_on_click(btn_toggle, on_toggle_mode, NULL);

    FtWidget btn_theme = ft_button_create(win, 516, 218, 180, 32, "Toggle Dark/Light Mode");
    ft_button_on_click(btn_theme, on_theme_toggle, NULL);

    /* 2. Deeply Nested Long Path (Showcases ellipsis collapse and tail leaf visibility) */
    FtWidget lbl2 = ft_text_create(win, 24, 270, 672, 20, "2. Compact Width with Long Path (Smart '…' middle ellipsis collapse):");
    ft_widget_set_font(lbl2, "Sans Bold 11");

    s_pathbar_deep = ft_path_bar_create(win, 24, 294, 380, 36, "/usr/local/share/floria-toolkit/examples/themes/dark/accents/emerald");
    ft_path_bar_on_navigate(s_pathbar_deep, on_path_navigated, NULL);

    FtWidget desc_deep = ft_text_create(win, 416, 302, 280, 20, "(Preserves leaf folders, collapses middle)");
    ft_widget_set_font(desc_deep, "Sans Italic 9");

    /* 3. Windows / System Path */
    FtWidget lbl3 = ft_text_create(win, 24, 350, 672, 20, "3. Windows Path with Drive Letter & Custom Root Display Name:");
    ft_widget_set_font(lbl3, "Sans Bold 11");

    s_pathbar_win = ft_path_bar_create(win, 24, 374, 520, 36, "C:\\Users\\afumi\\AppData\\Local\\Floria\\Settings");
    ft_path_bar_on_navigate(s_pathbar_win, on_path_navigated, NULL);

    /* 4. Help note */
    FtWidget note_card = ft_container_create(win, 24, 430, 672, 100);
    ft_container_set_corner_radius(note_card, 8.0);
    ft_container_set_scrollbar_mode(note_card, FT_SCROLLBAR_MODE_NONE);

    FtWidget tip_title = ft_text_create(note_card, 16, 10, 640, 18, "Interactive Tips:");
    ft_widget_set_font(tip_title, "Sans Bold 10");

    FtWidget tip1 = ft_text_create(note_card, 16, 30, 640, 18,
        "• Hover over empty space on the right of any path bar: notice the I-beam text cursor.");
    ft_widget_set_font(tip1, "Sans 9");

    FtWidget tip2 = ft_text_create(note_card, 16, 50, 640, 18,
        "• Click empty space: transforms immediately into an inline edit field with text selected.");
    ft_widget_set_font(tip2, "Sans 9");

    FtWidget tip3 = ft_text_create(note_card, 16, 70, 640, 18,
        "• Press Enter or the toggle button to commit and return to breadcrumb buttons.");
    ft_widget_set_font(tip3, "Sans 9");

    ft_widget_show(win);
    printf("[PathBar] Running main loop...\n");
    ft_main_loop();

    return 0;
}

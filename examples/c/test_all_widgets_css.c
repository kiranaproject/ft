#include <stdio.h>
#include <stdlib.h>
#include "ft.h"

static FtWidget g_win;
static FtWidget g_btn_cycle;
static FtWidget g_btn_action;
static FtWidget g_switch1;
static FtWidget g_switch2;
static FtWidget g_entry;
static FtWidget g_textarea;
static FtWidget g_scrollbar;
static FtWidget g_lbl_title;
static FtWidget g_lbl_status;

static int s_theme_step = 0;

static void update_status_label(const char* name) {
    char buf[128];
    snprintf(buf, sizeof(buf), "Active Theme: %s (Click cycle button to switch)", name);
    ft_text_set_text(g_lbl_status, buf);
}

static void on_cycle_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_theme_step = (s_theme_step + 1) % 7;

    switch (s_theme_step) {
        case 0:
            printf("Switching to Default Light\n");
            ft_theme_set_dark_mode(0);
            ft_theme_set("default");
            update_status_label("Default (Light)");
            break;
        case 1:
            printf("Switching to Default Dark\n");
            ft_theme_set_dark_mode(1);
            ft_theme_set("default");
            update_status_label("Default (Dark Mode)");
            break;
        case 2:
            printf("Switching to Dracula\n");
            ft_theme_set_dark_mode(0);
            ft_theme_set("dracula");
            update_status_label("Dracula");
            break;
        case 3:
            printf("Switching to Nord\n");
            ft_theme_set_dark_mode(0);
            ft_theme_set("nord");
            update_status_label("Nord");
            break;
        case 4:
            printf("Switching to Gruvbox\n");
            ft_theme_set_dark_mode(0);
            ft_theme_set("gruvbox");
            update_status_label("Gruvbox");
            break;
        case 5:
            printf("Switching to GTK2\n");
            ft_theme_set_dark_mode(0);
            ft_theme_set("gtk2");
            update_status_label("GTK2 Classic");
            break;
        case 6:
            printf("Switching to Classic\n");
            ft_theme_set_dark_mode(0);
            ft_theme_set("classic");
            update_status_label("Classic Slate");
            break;
    }
}

int main(void) {
    ft_init();

    g_win = ft_window_create(620, 520, "Floria Toolkit - Unified CSS Styling Test");

    // Title label
    g_lbl_title = ft_text_create(g_win, 24, 18, 570, 24, "Floria Toolkit Unified CSS Styling Test");
    ft_text_set_selectable(g_lbl_title, 0);

    // Status label
    g_lbl_status = ft_text_create(g_win, 24, 46, 570, 20, "Active Theme: Default (Light)");
    ft_text_set_selectable(g_lbl_status, 0);

    // Section: Buttons
    g_btn_cycle = ft_button_create(g_win, 24, 76, 270, 36, "Cycle CSS Theme");
    ft_button_on_click(g_btn_cycle, on_cycle_click, NULL);

    g_btn_action = ft_button_create(g_win, 314, 76, 270, 36, "Action Button");

    // Section: Switches
    g_switch1 = ft_switch_create(g_win, 24, 126, 160, 26, "Feature A (Off)");
    ft_switch_set_checked(g_switch1, 0);

    g_switch2 = ft_switch_create(g_win, 210, 126, 160, 26, "Feature B (On)");
    ft_switch_set_checked(g_switch2, 1);

    // Section: Text Entry
    g_entry = ft_entry_create(g_win, 24, 166, 560, 36, "Floria Toolkit CSS styled Entry widget");

    // Section: Multi-line TextArea
    const char* sample = "Floria Toolkit native multi-line text editor.\n"
                         "All background plates, borders, selection colors,\n"
                         "and text colors are dynamically resolved from CSS themes.\n"
                         "Transitions animate border and background colors smoothly!";
    g_textarea = ft_textarea_create(g_win, 24, 214, 560, 150, sample);

    // Section: Standalone ScrollBar
    g_scrollbar = ft_scrollbar_create(g_win, 24, 380, 560, 14, FT_SCROLLBAR_HORIZONTAL);
    ft_scrollbar_set_range(g_scrollbar, 0, 100, 30);
    ft_scrollbar_set_value(g_scrollbar, 40);

    // Bottom info
    FtWidget lbl_footer = ft_text_create(g_win, 24, 410, 560, 20, "Every element renders purely through CSS stylesheets & transitions.");
    ft_text_set_selectable(lbl_footer, 0);

    ft_widget_show(g_win);
    ft_main_loop();
    ft_quit();
    return 0;
}

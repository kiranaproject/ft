#include "ft.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FtWidget s_status_lbl = NULL;
static FtNotebook s_notebook = NULL;
static int s_tab_counter = 3;

static void on_btn_click(void* sender, void* user_data) {
    const char* name = (const char*)user_data;
    if (s_status_lbl && name) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Clicked %s", name);
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_new_tab_click(void* sender, void* user_data) {
    (void)sender;
    (void)user_data;
    if (s_notebook) {
        char title[64];
        snprintf(title, sizeof(title), "Document %d", ++s_tab_counter);
        ft_notebook_add_tab(s_notebook, title, 1);
        if (s_status_lbl) {
            char buf[128];
            snprintf(buf, sizeof(buf), "Status: Added new tab '%s' with close button", title);
            ft_text_set_text(s_status_lbl, buf);
        }
    }
}

static void on_toggle_theme(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int dark = ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(!dark);
    if (s_status_lbl) {
        ft_text_set_text(s_status_lbl, dark ? "Status: Theme changed to Light" : "Status: Theme changed to Dark");
    }
}

int main(void) {
    printf("[WINDOW BUTTON DEMO] Initializing Floria Toolkit...\n");
    ft_init();

    FtWidget win = ft_window_create(840, 680, "Floria Toolkit - TFtWindowButton Showcase");

    // Title and Subtitle
    ft_text_create(win, 30, 18, 620, 24, "TFtWindowButton Showcase (Tabs, Titlebars, Top Panels)");
    ft_text_create(win, 30, 44, 620, 20, "Reusable vector buttons with smooth 180ms ease-out hover transition animation & halo bloom.");

    FtWidget theme_btn = ft_button_create(win, 670, 20, 140, 32, "Toggle Dark Mode");
    ft_button_on_click(theme_btn, on_toggle_theme, NULL);

    // =========================================================================
    // SECTION 1: macOS Style (wbsCircle) - Traffic Light Window Controls
    // =========================================================================
    FtWidget card1 = ft_container_create(win, 30, 75, 780, 115);
    ft_container_set_draw_frame(card1, 1);
    ft_container_set_scrollbar_mode(card1, 0);
    ft_text_create(card1, 15, 10, 500, 20, "1. macOS Style (wbsCircle) - Traffic Light Halo Controls:");

    // Titlebar mock header
    FtWidget title1 = ft_container_create(card1, 15, 36, 750, 48);
    ft_container_set_draw_frame(title1, 1);
    ft_container_set_scrollbar_mode(title1, 0);
    ft_text_create(title1, 280, 14, 250, 20, "Window 1 - Document Editor");

    // Window buttons: Close, Minimize, Maximize (Chevron), Restore (Chevron), Pin, Add
    FtWidget c_close = ft_window_button_create(title1, 14, 14, 20, 20, FT_WINDOW_BUTTON_CLOSE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(c_close, on_btn_click, "Close [wbkClose (Circle)]");

    FtWidget c_min = ft_window_button_create(title1, 40, 14, 20, 20, FT_WINDOW_BUTTON_MINIMIZE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(c_min, on_btn_click, "Minimize [wbkMinimize (Circle)]");

    FtWidget c_max = ft_window_button_create(title1, 66, 14, 20, 20, FT_WINDOW_BUTTON_MAXIMIZE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(c_max, on_btn_click, "Maximize [wbkMaximize (Mac outward chevron ↗ ↙)]");

    FtWidget c_res = ft_window_button_create(title1, 92, 14, 20, 20, FT_WINDOW_BUTTON_RESTORE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(c_res, on_btn_click, "Restore [wbkRestore (Mac inward chevron ↘ ↖)]");

    FtWidget c_pin = ft_window_button_create(title1, 118, 14, 20, 20, FT_WINDOW_BUTTON_PIN, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(c_pin, on_btn_click, "Pin [wbkPin (Circle)]");

    FtWidget c_add = ft_window_button_create(title1, 716, 14, 20, 20, FT_WINDOW_BUTTON_ADD, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(c_add, on_btn_click, "Add Tab [wbkAdd (Circle)]");

    // =========================================================================
    // SECTION 2: GTK / GNOME Style (wbsSquircle) - Modern Pill Controls
    // =========================================================================
    FtWidget card2 = ft_container_create(win, 30, 205, 780, 115);
    ft_container_set_draw_frame(card2, 1);
    ft_container_set_scrollbar_mode(card2, 0);
    ft_text_create(card2, 15, 10, 500, 20, "2. GTK / GNOME Style (wbsSquircle) - Client-Side HeaderBar Controls:");

    FtWidget title2 = ft_container_create(card2, 15, 36, 750, 48);
    ft_container_set_draw_frame(title2, 1);
    ft_container_set_scrollbar_mode(title2, 0);
    ft_text_create(title2, 280, 14, 250, 20, "Window 2 - File Browser");

    FtWidget sq_menu = ft_window_button_create(title2, 14, 13, 22, 22, FT_WINDOW_BUTTON_MENU, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_on_click(sq_menu, on_btn_click, "Menu [wbkMenu (Squircle)]");

    FtWidget sq_shade = ft_window_button_create(title2, 42, 13, 22, 22, FT_WINDOW_BUTTON_SHADE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_on_click(sq_shade, on_btn_click, "Shade / Rollup [wbkShade (Squircle)]");

    FtWidget sq_min = ft_window_button_create(title2, 656, 13, 22, 22, FT_WINDOW_BUTTON_MINIMIZE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_on_click(sq_min, on_btn_click, "Minimize [wbkMinimize (Squircle)]");

    FtWidget sq_max = ft_window_button_create(title2, 684, 13, 22, 22, FT_WINDOW_BUTTON_MAXIMIZE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_on_click(sq_max, on_btn_click, "Maximize [wbkMaximize (Squircle)]");

    FtWidget sq_close = ft_window_button_create(title2, 712, 13, 22, 22, FT_WINDOW_BUTTON_CLOSE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_on_click(sq_close, on_btn_click, "Close [wbkClose (Squircle)]");

    // =========================================================================
    // SECTION 3: Traditional Windows Caption Style (wbsSquare)
    // =========================================================================
    FtWidget card3 = ft_container_create(win, 30, 335, 780, 115);
    ft_container_set_draw_frame(card3, 1);
    ft_container_set_scrollbar_mode(card3, 0);
    ft_text_create(card3, 15, 10, 500, 20, "3. Traditional Windows Style (wbsSquare) - Flat Caption Controls:");

    FtWidget title3 = ft_container_create(card3, 15, 36, 750, 48);
    ft_container_set_draw_frame(title3, 1);
    ft_container_set_scrollbar_mode(title3, 0);
    ft_text_create(title3, 18, 14, 300, 20, "Window 3 - System Settings");

    FtWidget w_min = ft_window_button_create(title3, 638, 9, 34, 30, FT_WINDOW_BUTTON_MINIMIZE, FT_WINDOW_BUTTON_SQUARE);
    ft_window_button_on_click(w_min, on_btn_click, "Minimize [wbkMinimize (Square)]");

    FtWidget w_max = ft_window_button_create(title3, 674, 9, 34, 30, FT_WINDOW_BUTTON_MAXIMIZE, FT_WINDOW_BUTTON_SQUARE);
    ft_window_button_on_click(w_max, on_btn_click, "Maximize [wbkMaximize (Square)]");

    FtWidget w_close = ft_window_button_create(title3, 710, 9, 34, 30, FT_WINDOW_BUTTON_CLOSE, FT_WINDOW_BUTTON_SQUARE);
    ft_window_button_on_click(w_close, on_btn_click, "Close [wbkClose (Square)]");

    // =========================================================================
    // SECTION 4: Tab Strip Integration (TFtNotebook)
    // =========================================================================
    FtWidget card4 = ft_container_create(win, 30, 465, 780, 160);
    ft_container_set_draw_frame(card4, 1);
    ft_container_set_scrollbar_mode(card4, 0);
    ft_text_create(card4, 15, 10, 500, 20, "4. Tab Strip Integration (TFtNotebook tab close buttons using TFtWindowButton):");

    s_notebook = ft_notebook_create(card4, 15, 34, 710, 110);
    FtTabPage t1 = ft_notebook_add_tab(s_notebook, "Project Code (Closeable)", 1);
    ft_text_create(t1, 15, 15, 450, 20, "Tab 1 content: Close button uses TFtWindowButton.DrawWindowButton");

    FtTabPage t2 = ft_notebook_add_tab(s_notebook, "Terminal Output (Closeable)", 1);
    ft_text_create(t2, 15, 15, 450, 20, "Tab 2 content: Click 'x' close button to test interactive tab closing");

    FtTabPage t3 = ft_notebook_add_tab(s_notebook, "Overview (Pinned)", 0);
    ft_text_create(t3, 15, 15, 450, 20, "Tab 3 content: Non-closeable pinned tab");

    // '+' New Tab Button next to notebook
    FtWidget add_tab_btn = ft_window_button_create(card4, 735, 38, 26, 26, FT_WINDOW_BUTTON_ADD, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(add_tab_btn, on_new_tab_click, NULL);

    // =========================================================================
    // STATUS BAR
    // =========================================================================
    s_status_lbl = ft_text_create(win, 30, 642, 780, 20, "Status: Ready - interact with any window button or tab close button!");

    ft_widget_show(win);
    printf("[WINDOW BUTTON DEMO] Entering main loop...\n");
    ft_main_loop();

    return 0;
}

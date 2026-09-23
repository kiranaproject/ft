#include "ft.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FtWidget s_status_lbl = NULL;

static void on_btn_click(FtWidget widget, void* user_data) {
    (void)widget;
    const char* label = (const char*)user_data;
    if (s_status_lbl && label) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Clicked '%s'", label);
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_toggle_theme(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int dark = ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(!dark);
    if (s_status_lbl) {
        ft_text_set_text(s_status_lbl, dark ? "Status: Theme changed to Light mode" : "Status: Theme changed to Dark mode");
    }
}

int main(void) {
    printf("[SQUIRCLE BUTTON DEMO] Initializing Floria Toolkit...\n");
    ft_init();

    FtWidget win = ft_window_create(820, 620, "Floria Toolkit - Squircle Button Theme Showcase");

    // Title and Subtitle
    ft_text_create(win, 30, 20, 600, 24, "Floria Squircle Button Identity");
    ft_text_create(win, 30, 46, 600, 20, "Default buttons redesigned with Floria squircle window button geometry, palette & halo bloom.");

    FtWidget theme_btn = ft_button_create(win, 650, 22, 140, 34, "Toggle Dark Mode");
    ft_button_on_click(theme_btn, on_toggle_theme, NULL);

    // =========================================================================
    // SECTION 1: Default Squircle Buttons (Signature Floria Identity)
    // =========================================================================
    FtWidget card1 = ft_container_create(win, 30, 80, 760, 150);
    ft_container_set_draw_frame(card1, 1);
    ft_container_set_scrollbar_mode(card1, 0);
    ft_text_create(card1, 20, 12, 500, 20, "1. Standard Buttons (Theme Default - Squircle Geometry & Accent Borders):");

    FtWidget btn1 = ft_button_create(card1, 20, 42, 160, 36, "Standard Button");
    ft_button_on_click(btn1, on_btn_click, "Standard Button");

    FtWidget btn2 = ft_button_create(card1, 200, 42, 160, 36, "Toggle Button");
    ft_button_set_toggle(btn2, 1);
    ft_button_set_toggled(btn2, 1);
    ft_button_on_click(btn2, on_btn_click, "Toggled Button");

    FtWidget btn3 = ft_button_create(card1, 380, 42, 160, 36, "Disabled Button");
    ft_widget_set_enabled(btn3, 0);

    FtWidget btn4 = ft_button_create(card1, 560, 42, 175, 36, "With Accent Glow");
    ft_button_on_click(btn4, on_btn_click, "With Accent Glow");

    ft_text_create(card1, 20, 92, 720, 20, "Hover over buttons to observe the soft radiant halo bloom and accent illumination,");
    ft_text_create(card1, 20, 114, 720, 20, "identical to Floria's squircle titlebar and panel window controls.");

    // =========================================================================
    // SECTION 2: Window Buttons Comparison (Squircle Window Buttons)
    // =========================================================================
    FtWidget card2 = ft_container_create(win, 30, 245, 760, 130);
    ft_container_set_draw_frame(card2, 1);
    ft_container_set_scrollbar_mode(card2, 0);
    ft_text_create(card2, 20, 12, 500, 20, "2. Comparison: TFtWindowButton (wbsSquircle Header Controls):");

    FtWidget title_mock = ft_container_create(card2, 20, 38, 720, 44);
    ft_container_set_draw_frame(title_mock, 1);
    ft_container_set_scrollbar_mode(title_mock, 0);
    ft_text_create(title_mock, 220, 12, 280, 20, "File Manager Header Bar (Squircle)");

    ft_window_button_create(title_mock, 12, 11, 22, 22, FT_WINDOW_BUTTON_MENU, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_create(title_mock, 40, 11, 22, 22, FT_WINDOW_BUTTON_SHADE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_create(title_mock, 626, 11, 22, 22, FT_WINDOW_BUTTON_MINIMIZE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_create(title_mock, 656, 11, 22, 22, FT_WINDOW_BUTTON_MAXIMIZE, FT_WINDOW_BUTTON_SQUIRCLE);
    ft_window_button_create(title_mock, 686, 11, 22, 22, FT_WINDOW_BUTTON_CLOSE, FT_WINDOW_BUTTON_SQUIRCLE);

    ft_text_create(card2, 20, 94, 720, 20, "Notice how the color palette, smooth corner radius, and subtle borders unify the look.");

    // =========================================================================
    // SECTION 3: Button Sizes & Semantic Variants
    // =========================================================================
    FtWidget card3 = ft_container_create(win, 30, 390, 760, 140);
    ft_container_set_draw_frame(card3, 1);
    ft_container_set_scrollbar_mode(card3, 0);
    ft_text_create(card3, 20, 12, 500, 20, "3. Semantic Accent Variants (Matching squircle radius & halo):");

    FtWidget p_btn = ft_button_create(card3, 20, 42, 160, 36, "Primary Action");
    ft_widget_set_style(p_btn, "background-color: #3b82f6; color: #ffffff; border-color: #2563eb; border-radius: 7px;");
    ft_button_on_click(p_btn, on_btn_click, "Primary Action");

    FtWidget s_btn = ft_button_create(card3, 200, 42, 160, 36, "Confirm (Success)");
    ft_widget_set_style(s_btn, "background-color: #10b981; color: #ffffff; border-color: #059669; border-radius: 7px;");
    ft_button_on_click(s_btn, on_btn_click, "Success Action");

    FtWidget d_btn = ft_button_create(card3, 380, 42, 160, 36, "Delete (Danger)");
    ft_widget_set_style(d_btn, "background-color: #ef4444; color: #ffffff; border-color: #dc2626; border-radius: 7px;");
    ft_button_on_click(d_btn, on_btn_click, "Danger Action");

    FtWidget sm_btn = ft_button_create(card3, 560, 44, 85, 32, "Small");
    ft_button_on_click(sm_btn, on_btn_click, "Small");

    FtWidget lg_btn = ft_button_create(card3, 655, 38, 85, 42, "Large");
    ft_button_on_click(lg_btn, on_btn_click, "Large");

    ft_text_create(card3, 20, 94, 720, 20, "Crisp text contrast and 0.5px downward tactile response when pressed.");

    // Status label at bottom
    s_status_lbl = ft_text_create(win, 30, 550, 760, 24, "Status: Ready. Try clicking or hovering buttons.");

    ft_widget_show(win);
    ft_main_loop();
    ft_quit();
    return 0;
}

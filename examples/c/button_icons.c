#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ft.h"

static const char* s_demo_themes[] = {
    "default", "nord", "dracula", "gruvbox", "gtk2", "classic"
};
static int s_demo_theme_count = sizeof(s_demo_themes) / sizeof(s_demo_themes[0]);
static int s_current_theme_index = 0;

static FtWidget s_lbl_status = NULL;

/* Sample embedded SVG icons */
static const char* SVG_FOLDER = 
    "<svg viewBox=\"0 0 24 24\" width=\"20\" height=\"20\">"
    "<path d=\"M10 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z\" fill=\"#eab308\"/>"
    "</svg>";

static const char* SVG_SAVE = 
    "<svg viewBox=\"0 0 24 24\" width=\"20\" height=\"20\">"
    "<path d=\"M17 3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V7l-4-4zm-5 16c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3zm3-10H5V5h10v4z\" fill=\"#3b82f6\"/>"
    "</svg>";

static const char* SVG_REFRESH = 
    "<svg viewBox=\"0 0 24 24\" width=\"20\" height=\"20\">"
    "<path d=\"M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z\" fill=\"#10b981\"/>"
    "</svg>";

static const char* SVG_SETTINGS = 
    "<svg viewBox=\"0 0 24 24\" width=\"20\" height=\"20\">"
    "<path d=\"M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z\" fill=\"#64748b\"/>"
    "</svg>";

static const char* SVG_DELETE = 
    "<svg viewBox=\"0 0 24 24\" width=\"20\" height=\"20\">"
    "<path d=\"M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z\" fill=\"#ef4444\"/>"
    "</svg>";

static void on_btn_click(FtWidget widget, void* user_data) {
    const char* name = (const char*)user_data;
    char buf[128];
    snprintf(buf, sizeof(buf), "Clicked: %s", name ? name : "Button");
    if (s_lbl_status)
        ft_text_set_text(s_lbl_status, buf);
    printf("[Button Icons] %s\n", buf);
}

static void on_theme_cycle(FtWidget widget, void* user_data) {
    (void)widget; (void)user_data;
    s_current_theme_index = (s_current_theme_index + 1) % s_demo_theme_count;
    ft_theme_set(s_demo_themes[s_current_theme_index]);
    if (s_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Active Theme: %s", ft_theme_get());
        ft_text_set_text(s_lbl_status, buf);
    }
}

static void on_dark_mode_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget; (void)user_data;
    ft_theme_set_dark_mode(checked);
    if (s_lbl_status)
        ft_text_set_text(s_lbl_status, checked ? "Dark Mode: ON" : "Dark Mode: OFF");
}

/* ========================================================================= */
/* Custom Vector Drawing Callbacks                                           */
/* ========================================================================= */

/* 1. Custom Icon Painter: Draws a vector play triangle inside a glowing ring */
static void on_paint_play_icon(FtWidget button, void* canvas, double x, double y, double w, double h, int32_t state, void* user_data) {
    (void)button; (void)user_data;
    double cx = x + w / 2.0;
    double cy = y + h / 2.0;
    double r = (w < h ? w : h) / 2.0;

    /* Circle background */
    if (state == 1) /* Hover */
        ft_canvas_draw_circle(canvas, cx, cy, r, 0.23, 0.51, 0.96, 0.25);
    else if (state == 2) /* Pressed */
        ft_canvas_draw_circle(canvas, cx, cy, r, 0.15, 0.39, 0.92, 0.40);
    else
        ft_canvas_draw_circle(canvas, cx, cy, r, 0.23, 0.51, 0.96, 0.15);

    /* Play triangle glyph using simple lines/polygon */
    double tri_w = r * 0.9;
    double x1 = cx - tri_w * 0.4;
    double y1 = cy - tri_w * 0.55;
    double x2 = cx - tri_w * 0.4;
    double y2 = cy + tri_w * 0.55;
    double x3 = cx + tri_w * 0.6;
    double y3 = cy;

    ft_canvas_draw_line(canvas, x1, y1, x2, y2, 2.5, 0.23, 0.51, 0.96, 1.0);
    ft_canvas_draw_line(canvas, x2, y2, x3, y3, 2.5, 0.23, 0.51, 0.96, 1.0);
    ft_canvas_draw_line(canvas, x3, y3, x1, y1, 2.5, 0.23, 0.51, 0.96, 1.0);
}

/* 2. Custom Icon Painter: Color Swatch / Palette icon */
static void on_paint_color_palette(FtWidget button, void* canvas, double x, double y, double w, double h, int32_t state, void* user_data) {
    (void)button; (void)state; (void)user_data;
    double half_w = (w - 3.0) / 2.0;
    double half_h = (h - 3.0) / 2.0;
    double rad = 3.0;

    /* 4 mini colored squircle tiles */
    ft_canvas_draw_rounded_rect(canvas, x, y, half_w, half_h, rad, 0.93, 0.27, 0.27, 1.0); /* Red */
    ft_canvas_draw_rounded_rect(canvas, x + half_w + 3.0, y, half_w, half_h, rad, 0.10, 0.73, 0.51, 1.0); /* Green */
    ft_canvas_draw_rounded_rect(canvas, x, y + half_h + 3.0, half_w, half_h, rad, 0.23, 0.51, 0.96, 1.0); /* Blue */
    ft_canvas_draw_rounded_rect(canvas, x + half_w + 3.0, y + half_h + 3.0, half_w, half_h, rad, 0.95, 0.60, 0.07, 1.0); /* Amber */
}

/* 3. Custom Button Overlay: Notification badge drawn on top-right corner */
static void on_paint_badge_overlay(FtWidget button, void* canvas, double x, double y, double w, double h, int32_t state, void* user_data) {
    (void)button; (void)h; (void)state; (void)user_data;
    double badge_r = 9.0;
    double badge_cx = x + w - 4.0;
    double badge_cy = y + 4.0;

    /* Red badge circle with white outline */
    ft_canvas_draw_circle(canvas, badge_cx, badge_cy, badge_r, 0.94, 0.27, 0.27, 1.0);
    ft_canvas_draw_circle(canvas, badge_cx, badge_cy, badge_r + 1.0, 1.0, 1.0, 1.0, 0.8);

    /* "3" count text */
    ft_canvas_draw_text_centered(canvas, (int)(badge_cx - badge_r), (int)(badge_cy - badge_r + 1.0),
                                 (int)(badge_r * 2), (int)(badge_r * 2), "3", NULL, 1.0, 1.0, 1.0);
}

int main(void) {
    ft_init();

    FtWidget win = ft_window_create(820, 580, "Floria Toolkit — Button Icon & Custom Drawing Showcase");

    // Header Title & Subtitle
    FtWidget title = ft_text_create(win, 24, 16, 770, 26, "Button Icons & Vector Custom Drawing");
    ft_text_set_selectable(title, 0);

    FtWidget sub = ft_text_create(win, 24, 42, 770, 20, 
                                  "High-performance vector SVG icons, flexible alignment (Left/Right/Top/Only), and live custom painting.");
    ft_text_set_selectable(sub, 0);

    // Controls Bar
    FtWidget btn_theme = ft_button_create(win, 24, 70, 130, 34, "Next Theme");
    ft_button_on_click(btn_theme, on_theme_cycle, NULL);

    FtWidget sw_dark = ft_switch_create(win, 170, 74, 130, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_mode_toggle, NULL);

    s_lbl_status = ft_text_create(win, 320, 76, 470, 22, "Status: Ready");
    ft_text_set_selectable(s_lbl_status, 1);

    // Section 1: Standard Icons & Positions
    FtWidget sec1 = ft_text_create(win, 24, 120, 770, 22, "1. Vector SVG Icons with Different Alignments:");
    ft_text_set_selectable(sec1, 0);

    // 1A: Icon Left (Default)
    FtWidget btn_save = ft_button_create(win, 24, 150, 130, 38, "Save");
    ft_button_set_icon_svg(btn_save, SVG_SAVE);
    ft_button_set_icon_position(btn_save, FT_BUTTON_ICON_LEFT);
    ft_button_on_click(btn_save, on_btn_click, (void*)"Save File (Icon Left)");

    // 1B: Icon Right
    FtWidget btn_open = ft_button_create(win, 170, 150, 140, 38, "Open Folder");
    ft_button_set_icon_svg(btn_open, SVG_FOLDER);
    ft_button_set_icon_position(btn_open, FT_BUTTON_ICON_RIGHT);
    ft_button_on_click(btn_open, on_btn_click, (void*)"Open Folder (Icon Right)");

    // 1C: Icon Top (Vertical button layout)
    FtWidget btn_refresh = ft_button_create(win, 326, 150, 95, 68, "Refresh");
    ft_button_set_icon_svg(btn_refresh, SVG_REFRESH);
    ft_button_set_icon_position(btn_refresh, FT_BUTTON_ICON_TOP);
    ft_button_set_icon_size(btn_refresh, 22, 22);
    ft_button_on_click(btn_refresh, on_btn_click, (void*)"Refresh (Icon Top)");

    // 1D: Icon Only (Compact tool button)
    FtWidget btn_settings = ft_button_create(win, 437, 150, 44, 38, "");
    ft_button_set_icon_svg(btn_settings, SVG_SETTINGS);
    ft_button_set_icon_position(btn_settings, FT_BUTTON_ICON_ONLY);
    ft_button_on_click(btn_settings, on_btn_click, (void*)"Settings (Icon Only)");

    // 1E: Delete with Icon Left and Danger Styling
    FtWidget btn_delete = ft_button_create(win, 497, 150, 130, 38, "Delete");
    ft_button_set_icon_svg(btn_delete, SVG_DELETE);
    ft_button_set_icon_position(btn_delete, FT_BUTTON_ICON_LEFT);
    ft_button_on_click(btn_delete, on_btn_click, (void*)"Delete (Icon Left)");

    // Section 2: Custom Drawing on Buttons
    FtWidget sec2 = ft_text_create(win, 24, 240, 770, 22, "2. Custom Canvas Drawing (Vector Icon Callbacks & Overlays):");
    ft_text_set_selectable(sec2, 0);

    // 2A: Custom Vector Play Button (Drawn live with ft_canvas_draw_circle & lines)
    FtWidget btn_play = ft_button_create(win, 24, 270, 150, 42, "Play Media");
    ft_button_set_icon_size(btn_play, 24, 24);
    ft_button_set_icon_position(btn_play, FT_BUTTON_ICON_LEFT);
    ft_button_on_paint_icon(btn_play, on_paint_play_icon, NULL);
    ft_button_on_click(btn_play, on_btn_click, (void*)"Play Media (Custom Vector Icon)");

    // 2B: Custom Color Palette Icon Button
    FtWidget btn_palette = ft_button_create(win, 190, 270, 150, 42, "Palette");
    ft_button_set_icon_size(btn_palette, 20, 20);
    ft_button_set_icon_position(btn_palette, FT_BUTTON_ICON_LEFT);
    ft_button_on_paint_icon(btn_palette, on_paint_color_palette, NULL);
    ft_button_on_click(btn_palette, on_btn_click, (void*)"Color Palette (Custom Vector Tiles)");

    // 2C: Button with Custom Post-Paint Overlay (Notification Badge)
    FtWidget btn_inbox = ft_button_create(win, 356, 270, 150, 42, "Inbox");
    ft_button_set_icon_svg(btn_inbox, SVG_FOLDER);
    ft_button_set_icon_position(btn_inbox, FT_BUTTON_ICON_LEFT);
    ft_button_on_paint(btn_inbox, on_paint_badge_overlay, NULL);
    ft_button_on_click(btn_inbox, on_btn_click, (void*)"Inbox (Badge Overlay)");

    // Section 3: CSS-Themed Squircle & Pill Buttons with Icons
    FtWidget sec3 = ft_text_create(win, 24, 340, 770, 22, "3. CSS Theming Integration & Pill Radii with Icons:");
    ft_text_set_selectable(sec3, 0);

    FtWidget btn_pill = ft_button_create(win, 24, 370, 180, 40, "Pill Action");
    ft_button_set_icon_svg(btn_pill, SVG_REFRESH);
    ft_button_set_corner_radius(btn_pill, 20.0); /* Full pill curve */
    ft_button_on_click(btn_pill, on_btn_click, (void*)"Pill Action (Radius 20)");

    FtWidget btn_squircle = ft_button_create(win, 220, 370, 180, 40, "Settings Panel");
    ft_button_set_icon_svg(btn_squircle, SVG_SETTINGS);
    ft_button_set_corner_radius(btn_squircle, 10.0);
    ft_button_on_click(btn_squircle, on_btn_click, (void*)"Settings Panel (Radius 10)");

    // Description lines
    FtWidget d0 = ft_text_create(win, 24, 430, 770, 20, "Icon & Custom Drawing Capabilities:");
    ft_text_set_selectable(d0, 0);
    FtWidget d1 = ft_text_create(win, 36, 452, 758, 20, "• Native SVG rendering with arbitrary viewports, scalable width/height, and opacity.");
    ft_text_set_selectable(d1, 0);
    FtWidget d2 = ft_text_create(win, 36, 474, 758, 20, "• 4 standard positions: Left, Right, Top (vertical layout), and Icon-Only (compact toolbars).");
    ft_text_set_selectable(d2, 0);
    FtWidget d3 = ft_text_create(win, 36, 496, 758, 20, "• Tactile click shift: icons and custom vector drawing shift by 1px on click with text.");
    ft_text_set_selectable(d3, 0);
    FtWidget d4 = ft_text_create(win, 36, 518, 758, 20, "• Custom callbacks: paint custom vector icons or overlays using rich ft_canvas_* APIs.");
    ft_text_set_selectable(d4, 0);

    ft_widget_show(win);
    printf("[Button Icons] Running main loop...\n");
    ft_main_loop();

    return 0;
}

/**
 * amamizu_showcase.c -- Showcase for the Amamizu (雨水) Mac Liquid Glass CSS Theme
 *
 * Demonstrates:
 *   - Mac-inspired liquid glass, Aqua gel vibrancy, and crystalline refraction
 *   - macOS Traffic Light Buttons (Close, Minimize, Maximize)
 *   - Real in-window frosted glass blur overlapping underlying colorful vector content
 *   - Translucent glass surfaces with backdrop-filter: blur(20px)
 *   - Specular highlight borders and capsule pill geometry
 *   - Morning Rain (Light Mode) and Midnight Rain (Dark Mode)
 */
#include <stdio.h>
#include <stdlib.h>
#include "ft.h"

static FtWidget g_win;
static FtWidget g_lbl_title;
static FtWidget g_lbl_subtitle;
static FtWidget g_switch_dark;
static FtWidget g_switch_egl;
static FtWidget g_bg_canvas;
static FtWidget g_glass_card;
static FtWidget g_btn_liquid;
static FtWidget g_btn_accent;
static FtWidget g_btn_disabled;
static FtWidget g_url_entry;
static FtWidget g_entry;
static FtWidget g_textarea;
static FtWidget g_scrollbar;
static FtWidget g_lbl_status;

static void on_dark_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[Amamizu] Dark Mode toggled: %s\n", checked ? "Midnight Rain (ON)" : "Morning Rain (OFF)");
    ft_theme_set_dark_mode(checked);
    ft_theme_set("amamizu");

    int32_t egl_active = ft_window_is_hardware_accelerated(g_win);
    char buf[256];
    snprintf(buf, sizeof(buf), "Mode: %s | Compositor: %s",
        checked ? "Midnight Rain" : "Morning Rain",
        egl_active ? "EGL 1.5 + GLES2 GPU (Immediate)" : "Software XCB PutImage");
    ft_text_set_text(g_lbl_status, buf);
}

static void on_egl_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_window_set_hardware_accelerated(g_win, checked);
    if (checked) {
        /* Swap interval 0 = non-blocking immediate flip (no VSync latency stall) */
        ft_window_set_swap_interval(g_win, 0);
    }
    int32_t active = ft_window_is_hardware_accelerated(g_win);
    printf("[Amamizu] EGL Acceleration: %s\n", active ? "ENABLED (EGL 1.5 + GLES2)" : "DISABLED (Software XCB)");
    char buf[256];
    snprintf(buf, sizeof(buf), "Mode: %s | Compositor: %s",
        ft_theme_get_dark_mode() ? "Midnight Rain" : "Morning Rain",
        active ? "EGL 1.5 + GLES2 GPU (Immediate)" : "Software XCB PutImage");
    ft_text_set_text(g_lbl_status, buf);
}

static void on_btn_liquid_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[Amamizu] Liquid Glass button clicked!\n");
    ft_text_set_text(g_lbl_status, "Liquid Glass Button pressed — Tactile ripple transition activated.");
}

static void on_btn_accent_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[Amamizu] Aqua Gel Action button clicked!\n");
    ft_text_set_text(g_lbl_status, "Aqua Gel Droplet clicked — Mac liquid wave animation triggered.");
}

static void on_traffic_light_click(FtWidget widget, void* user_data) {
    (void)widget;
    const char* action = (const char*)user_data;
    char buf[128];
    snprintf(buf, sizeof(buf), "macOS Traffic Light Clicked: %s", action);
    printf("[Amamizu] %s\n", buf);
    ft_text_set_text(g_lbl_status, buf);
}

int main(void) {
    ft_init();

    /* Auto-enable EGL hardware acceleration if supported by GPU */
    int32_t egl_available = ft_egl_is_available();
    if (egl_available) {
        ft_backend_enable_egl(1);
    }

    /* Apply the Amamizu theme */
    ft_theme_set("amamizu");
    ft_theme_set_dark_mode(0);

    /* Window: 760x630 */
    g_win = ft_window_create(760, 630, "Amamizu (雨水) — Mac Liquid Glass CSS Theme");

    /* macOS Traffic Light Buttons (Close, Minimize, Maximize) */
    FtWidget btn_close = ft_window_button_create(g_win, 20, 20, 16, 16, FT_WINDOW_BUTTON_CLOSE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(btn_close, on_traffic_light_click, "Close (Red)");

    FtWidget btn_min = ft_window_button_create(g_win, 42, 20, 16, 16, FT_WINDOW_BUTTON_MINIMIZE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(btn_min, on_traffic_light_click, "Minimize (Yellow)");

    FtWidget btn_max = ft_window_button_create(g_win, 64, 20, 16, 16, FT_WINDOW_BUTTON_MAXIMIZE, FT_WINDOW_BUTTON_CIRCLE);
    ft_window_button_on_click(btn_max, on_traffic_light_click, "Zoom / Maximize (Green)");

    /* Header section */
    g_lbl_title = ft_text_create(g_win, 96, 12, 450, 22, "Amamizu (Rainwater) — Mac Liquid Glass");
    ft_text_set_selectable(g_lbl_title, 0);

    g_lbl_subtitle = ft_text_create(g_win, 96, 36, 450, 18, "macOS Aqua vibrancy, frosted blur, and crystalline refraction");
    ft_text_set_selectable(g_lbl_subtitle, 0);

    /* Top-right Switches: Dark Mode and EGL GPU Acceleration */
    g_switch_dark = ft_switch_create(g_win, 556, 8, 180, 24, "Midnight Rain");
    ft_switch_set_checked(g_switch_dark, 0);
    ft_switch_on_toggle(g_switch_dark, on_dark_toggle, NULL);

    g_switch_egl = ft_switch_create(g_win, 556, 34, 180, 24, "EGL GPU Accel");
    if (egl_available) {
        ft_window_set_swap_interval(g_win, 0);
        ft_switch_set_checked(g_switch_egl, ft_window_is_hardware_accelerated(g_win));
        ft_switch_on_toggle(g_switch_egl, on_egl_toggle, NULL);
    } else {
        ft_switch_set_checked(g_switch_egl, 0);
        ft_widget_set_enabled(g_switch_egl, 0);
    }

    /* -------------------------------------------------------------
     * 1. Underlying Colorful Canvas Layer (The Graphic Backdrop)
     * ------------------------------------------------------------- */
    g_bg_canvas = ft_container_create(g_win, 24, 68, 712, 130);
    ft_container_set_backdrop_blur(g_bg_canvas, 0.0);
    ft_container_set_scrollbar_mode(g_bg_canvas, 0);
    ft_widget_set_style(g_bg_canvas,
        "background: #111827; border: 1px solid #1f2937; border-radius: 14px;");

    FtWidget bg_lbl = ft_text_create(g_bg_canvas, 16, 8, 680, 18,
        "Underlying Graphic Canvas (Colorful vector layers underneath frosted glass):");
    ft_widget_set_style(bg_lbl, "color: #94a3b8; font-size: 11px; font-weight: bold;");

    /* Colorful vibrant stripe tags rendered on the underlying layer */
    FtWidget tag1 = ft_text_create(g_bg_canvas, 16, 28, 680, 18, "• High Performance AggPas 2D Subpixel Vector Graphics Engine");
    ft_widget_set_style(tag1, "color: #f43f5e; font-size: 11px; font-weight: bold;");

    FtWidget tag2 = ft_text_create(g_bg_canvas, 16, 46, 680, 18, "• 32-bit TrueColor ARGB Translucency with Subpixel Anti-Aliasing");
    ft_widget_set_style(tag2, "color: #f97316; font-size: 11px; font-weight: bold;");

    FtWidget tag3 = ft_text_create(g_bg_canvas, 16, 64, 680, 18, "• Universal HarfBuzz + BiDi Native Multilingual Typography");
    ft_widget_set_style(tag3, "color: #eab308; font-size: 11px; font-weight: bold;");

    FtWidget tag4 = ft_text_create(g_bg_canvas, 16, 82, 680, 18, "• Optical Frosted Glass Gaussian Diffusion Filter (20px Blur)");
    ft_widget_set_style(tag4, "color: #10b981; font-size: 11px; font-weight: bold;");

    FtWidget tag5 = ft_text_create(g_bg_canvas, 16, 100, 680, 18, "• Specular Highlight Rims with Subpixel Alpha Gradients");
    ft_widget_set_style(tag5, "color: #06b6d4; font-size: 11px; font-weight: bold;");

    /* -------------------------------------------------------------
     * 2. Overlapping Frosted Liquid Glass Card
     *    Positioned at Y=132 to directly overlap the bottom 66px of g_bg_canvas!
     * ------------------------------------------------------------- */
    g_glass_card = ft_container_create(g_win, 24, 132, 712, 452);
    ft_container_set_backdrop_blur(g_glass_card, 20.0);
    ft_container_set_scrollbar_mode(g_glass_card, 0);

    /* Inside the card (coordinates relative to container): Title */
    FtWidget card_title = ft_text_create(g_glass_card, 20, 14, 672, 22,
        "Frosted Acrylic Glass Surface (backdrop-filter: blur(20px)) — Blurs underlying canvas above!");
    ft_text_set_selectable(card_title, 0);

    /* Liquid Glass Buttons row */
    g_btn_liquid = ft_button_create(g_glass_card, 20, 44, 180, 36, "Liquid Glass Plate");
    ft_button_on_click(g_btn_liquid, on_btn_liquid_click, NULL);

    g_btn_accent = ft_button_create(g_glass_card, 214, 44, 180, 36, "Aqua Gel Droplet");
    ft_widget_set_style_class(g_btn_accent, "primary");
    ft_button_on_click(g_btn_accent, on_btn_accent_click, NULL);

    g_btn_disabled = ft_button_create(g_glass_card, 408, 44, 140, 36, "Subdued Pill");
    ft_widget_set_enabled(g_btn_disabled, 0);

    /* UrlEntry capsule (pill shape) inside glass card */
    g_url_entry = ft_url_entry_create(g_glass_card, 20, 92, 672, 34, "https://floria.dev/themes/amamizu.css");

    /* Glass Recess Entry */
    g_entry = ft_entry_create(g_glass_card, 20, 136, 672, 34, "Amamizu crystalline text input recess with specular glow");

    /* Glass Multi-line TextArea */
    const char* sample_text =
        "/* Amamizu (Rainwater) Theme Specifications */\n"
        "• Translucent frosted glass cards with 20px Gaussian backdrop blur overlapping content.\n"
        "• Specular highlight 1px borders with fine sub-pixel alpha gradients.\n"
        "• Pill capsules (border-radius: 9999px) for URL omnibox, switches & traffic lights.\n"
        "• Luminous Aqua Gel Droplet blue and electric cyan for interactive accent buttons.\n"
        "• Fluid CSS ease transitions (180ms cubic ease) on hover, press, and focus states.";
    g_textarea = ft_textarea_create(g_glass_card, 20, 180, 672, 215, sample_text);

    /* Standalone ScrollBar inside glass card */
    g_scrollbar = ft_scrollbar_create(g_glass_card, 20, 405, 672, 12, FT_SCROLLBAR_HORIZONTAL);
    ft_scrollbar_set_range(g_scrollbar, 0, 100, 35);
    ft_scrollbar_set_value(g_scrollbar, 45);

    /* Status label at the bottom */
    char init_status[256];
    snprintf(init_status, sizeof(init_status),
        "Mode: Morning Rain | Compositor: %s",
        ft_window_is_hardware_accelerated(g_win) ? "EGL 1.5 + GLES2 GPU (Immediate)" : "Software XCB PutImage");
    g_lbl_status = ft_text_create(g_win, 24, 594, 712, 18, init_status);
    ft_text_set_selectable(g_lbl_status, 0);

    ft_widget_show(g_win);
    ft_main_loop();
    ft_quit();

    return 0;
}

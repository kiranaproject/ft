#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ft.h"

static FtWidget g_win = NULL;
static FtWidget g_lbl_status = NULL;
static FtWidget g_lbl_fps = NULL;
static FtWidget g_btn_vsync = NULL;
static int32_t g_vsync = 1;

static void on_toggle_vsync(FtWidget widget, void* user_data) {
    (void)user_data;
    g_vsync = !g_vsync;
    ft_window_set_swap_interval(g_win, g_vsync);
    if (g_vsync) {
        ft_button_set_caption(widget, "VSync: ON (60 Hz Lock)");
        ft_text_set_text(g_lbl_fps, "Presentation: Hardware VSync Synchronized (Tear-Free)");
    } else {
        ft_button_set_caption(widget, "VSync: OFF (Uncapped)");
        ft_text_set_text(g_lbl_fps, "Presentation: Uncapped Maximum FPS Mode");
    }
}

static void on_switch_gpu(FtWidget widget, int32_t active, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[EGL Showcase] Hardware acceleration switch: %s\n", active ? "Enabled" : "Disabled");
}

int main(void) {
    printf("[EGL Showcase] Initializing Floria Toolkit...\n");
    ft_init();

    int32_t egl_ok = ft_egl_is_available();
    printf("[EGL Showcase] EGL Availability: %s\n", egl_ok ? "AVAILABLE" : "NOT AVAILABLE");

    // Enable hardware-accelerated presentation by default
    if (egl_ok) {
        ft_backend_enable_egl(1);
    }

    // Set amamizu theme with dark mode
    ft_theme_set_dark_mode(1);
    ft_theme_set("amamizu");

    // Create main window
    g_win = ft_window_create(900, 620, "Floria Toolkit — EGL GPU Hardware Acceleration Showcase");
    ft_window_set_position(g_win, 150, 100);

    int32_t is_gpu = ft_window_is_hardware_accelerated(g_win);
    printf("[EGL Showcase] Window hardware accelerated: %s\n", is_gpu ? "YES (EGL/GLES2)" : "NO (Software XCB)");

    // Window Title & Subtitle
    FtWidget title = ft_text_create(g_win, 30, 24, 840, 36, "GPU-Accelerated Presentation Engine");
    ft_widget_set_style(title, "font-size: 22px; font-weight: bold; color: #ffffff;");

    char status_str[256];
    if (is_gpu) {
        snprintf(status_str, sizeof(status_str),
                 "Backend: EGL 1.5 + OpenGL ES 2.0 Direct Texture Streaming | Hardware VSync Active");
    } else {
        snprintf(status_str, sizeof(status_str),
                 "Backend: Software Fallback (XCB PutImage)");
    }
    g_lbl_status = ft_text_create(g_win, 30, 62, 840, 24, status_str);
    ft_widget_set_style(g_lbl_status, "font-size: 13px; color: #4ade80;");

    // Frosted Glass Container with Liquid Glass styling
    FtWidget glass_card = ft_container_create(g_win, 30, 96, 840, 480);
    ft_widget_set_style_class(glass_card, "frosted-glass");
    ft_widget_set_style(glass_card,
        "background: rgba(255, 255, 255, 0.08);"
        "backdrop-filter: blur(24px);"
        "border: 1px solid rgba(255, 255, 255, 0.2);"
        "border-radius: 16px;");

    // Card Header
    FtWidget card_title = ft_text_create(glass_card, 24, 20, 400, 28, "Hardware Presentation Controls");
    ft_widget_set_style(card_title, "font-size: 17px; font-weight: bold; color: #f8fafc;");

    // Control 1: VSync Toggle Button
    g_btn_vsync = ft_button_create(glass_card, 24, 60, 220, 38, "VSync: ON (60 Hz Lock)");
    ft_widget_set_style_class(g_btn_vsync, "glass-button");
    ft_widget_set_style(g_btn_vsync,
        "background: rgba(59, 130, 246, 0.4);"
        "border: 1px solid rgba(147, 197, 253, 0.5);"
        "border-radius: 10px;"
        "color: #ffffff;"
        "font-weight: 600;");
    ft_button_on_click(g_btn_vsync, on_toggle_vsync, NULL);

    // Control 2: GPU Acceleration Switch
    FtWidget lbl_switch = ft_text_create(glass_card, 270, 68, 160, 24, "Hardware Compositor:");
    ft_widget_set_style(lbl_switch, "color: #cbd5e1; font-size: 13px;");

    FtWidget sw = ft_switch_create(glass_card, 440, 64, 52, 28, "GPU");
    ft_switch_set_checked(sw, is_gpu ? 1 : 0);
    ft_switch_on_toggle(sw, on_switch_gpu, NULL);

    // Control 3: Interactive Text Entry inside Frosted Glass
    FtWidget lbl_entry = ft_text_create(glass_card, 24, 120, 200, 24, "GPU Texture Streaming Input:");
    ft_widget_set_style(lbl_entry, "color: #94a3b8; font-size: 13px;");

    FtWidget entry = ft_entry_create(glass_card, 24, 146, 420, 38, "Type here to observe zero-latency GPU invalidation...");
    ft_widget_set_style(entry,
        "background: rgba(15, 23, 42, 0.5);"
        "border: 1px solid rgba(255, 255, 255, 0.15);"
        "border-radius: 8px;"
        "color: #f1f5f9;"
        "padding: 8px;");

    // Performance Metrics Banner
    g_lbl_fps = ft_text_create(glass_card, 24, 210, 790, 30,
        "Presentation: Hardware VSync Synchronized (Tear-Free)");
    ft_widget_set_style(g_lbl_fps,
        "background: rgba(15, 23, 42, 0.4);"
        "border: 1px solid rgba(255, 255, 255, 0.1);"
        "border-radius: 8px;"
        "color: #38bdf8;"
        "font-size: 13px;"
        "padding: 6px;");

    // Features Checklist
    FtWidget feat_box = ft_container_create(glass_card, 24, 260, 790, 190);
    ft_widget_set_style(feat_box,
        "background: rgba(0, 0, 0, 0.25);"
        "border: 1px solid rgba(255, 255, 255, 0.08);"
        "border-radius: 10px;");

    FtWidget f1 = ft_text_create(feat_box, 16, 16, 750, 24, "✔  Khronos EGL 1.5 Dynamic Loader (zero hard binary link dependency)");
    ft_widget_set_style(f1, "color: #e2e8f0; font-size: 13px;");

    FtWidget f2 = ft_text_create(feat_box, 16, 46, 750, 24, "✔  OpenGL ES 2.0 / GL Fullscreen Quad Rendering with GLSL Shaders");
    ft_widget_set_style(f2, "color: #e2e8f0; font-size: 13px;");

    FtWidget f3 = ft_text_create(feat_box, 16, 76, 750, 24, "✔  Direct 32-bit BGRA Pixel Pipeline without CPU color swizzling");
    ft_widget_set_style(f3, "color: #e2e8f0; font-size: 13px;");

    FtWidget f4 = ft_text_create(feat_box, 16, 106, 750, 24, "✔  Sub-rectangle GPU texture streaming for partial dirty regions");
    ft_widget_set_style(f4, "color: #e2e8f0; font-size: 13px;");

    FtWidget f5 = ft_text_create(feat_box, 16, 136, 750, 24, "✔  Graceful automatic fallback to XCB PutImage if GPU/EGL is unavailable");
    ft_widget_set_style(f5, "color: #e2e8f0; font-size: 13px;");

    ft_widget_show(g_win);
    printf("[EGL Showcase] Window shown. Entering main loop...\n");
    ft_main_loop();

    return 0;
}

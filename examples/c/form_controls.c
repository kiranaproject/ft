#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ft.h"

typedef enum {
    RENDER_ENGINE_AGG2D = 0,
    RENDER_ENGINE_OPENGL = 1,
    RENDER_ENGINE_VULKAN = 2
} RenderEngineMode;

static FtWidget g_win = NULL;
static FtWidget g_lbl_status = NULL;
static FtWidget g_pbar_determinate = NULL;
static FtWidget g_pbar_vert = NULL;
static FtWidget g_pbar_indeterminate = NULL;
static FtWidget g_lbl_slider_val = NULL;
static FtWidget g_slider_horiz = NULL;
static FtWidget g_slider_vert = NULL;

/* Checkboxes */
static FtWidget g_cb_hw = NULL;
static FtWidget g_cb_fps = NULL;
static FtWidget g_cb_aa = NULL;

/* RadioButtons */
static FtWidget g_rb_agg = NULL;
static FtWidget g_rb_gl = NULL;
static FtWidget g_rb_vk = NULL;

/* Active Engine State & Visualizer */
static RenderEngineMode g_active_engine = RENDER_ENGINE_AGG2D;
static int32_t g_egl_available = 0;
static int32_t g_show_fps = 0;
static uint64_t g_frame_count = 0;
static double g_current_fps = 60.0;
static double g_frame_time_ms = 16.6;

/* Visualizer Widgets */
static FtWidget g_engine_badge = NULL;
static FtWidget g_lbl_engine_mode = NULL;
static FtWidget g_lbl_engine_info1 = NULL;
static FtWidget g_lbl_engine_info2 = NULL;
static FtWidget g_lbl_engine_fps = NULL;

static void update_render_engine(RenderEngineMode mode) {
    char buf[256];
    if (mode == RENDER_ENGINE_OPENGL) {
        if (!g_egl_available) {
            snprintf(buf, sizeof(buf), "[Render Engine] OpenGL/EGL backend is not supported on this display — fallback to Agg2D");
            if (g_lbl_status) ft_text_set_text(g_lbl_status, buf);
            if (g_rb_agg) ft_radio_set_checked(g_rb_agg, 1);
            g_active_engine = RENDER_ENGINE_AGG2D;
            return;
        }

        g_active_engine = RENDER_ENGINE_OPENGL;
        ft_window_set_hardware_accelerated(g_win, 1);
        ft_window_set_swap_interval(g_win, 0); /* Immediate GPU presentation */

        if (g_cb_hw) ft_checkbox_set_checked(g_cb_hw, 1);
        if (g_rb_gl) ft_radio_set_checked(g_rb_gl, 1);

        if (g_lbl_engine_mode) {
            ft_text_set_text(g_lbl_engine_mode, "OpenGL ES 2.0 / EGL");
            ft_widget_set_style(g_lbl_engine_mode, "font-size: 11px; font-weight: bold; color: #38bdf8;");
        }
        if (g_lbl_engine_info1) {
            ft_text_set_text(g_lbl_engine_info1, "• GPU Direct Texture Quad");
        }
        if (g_lbl_engine_info2) {
            ft_text_set_text(g_lbl_engine_info2, "• Bilinear Filtered Surface");
        }

        snprintf(buf, sizeof(buf), "[Render Engine] Switched to OpenGL Accelerated Raster (EGL 1.5 + GLES2 GPU Direct Texture Streaming)");
        if (g_lbl_status) ft_text_set_text(g_lbl_status, buf);
    } else if (mode == RENDER_ENGINE_AGG2D) {
        g_active_engine = RENDER_ENGINE_AGG2D;
        ft_window_set_hardware_accelerated(g_win, 0);

        if (g_cb_hw) ft_checkbox_set_checked(g_cb_hw, 0);
        if (g_rb_agg) ft_radio_set_checked(g_rb_agg, 1);

        if (g_lbl_engine_mode) {
            ft_text_set_text(g_lbl_engine_mode, "Agg2D Pure CPU");
            ft_widget_set_style(g_lbl_engine_mode, "font-size: 11px; font-weight: bold; color: #10b981;");
        }
        if (g_lbl_engine_info1) {
            ft_text_set_text(g_lbl_engine_info1, "• AggPas 2.4 Vector Engine");
        }
        if (g_lbl_engine_info2) {
            ft_text_set_text(g_lbl_engine_info2, "• XCB 32-bit ARGB PutImage");
        }

        snprintf(buf, sizeof(buf), "[Render Engine] Switched to Agg2D Software Rendering (Pure CPU 32-bit ARGB via XCB)");
        if (g_lbl_status) ft_text_set_text(g_lbl_status, buf);
    } else if (mode == RENDER_ENGINE_VULKAN) {
        snprintf(buf, sizeof(buf), "[Render Engine] Vulkan backend is not available on this platform — remaining on %s",
                 (g_active_engine == RENDER_ENGINE_OPENGL) ? "OpenGL ES 2.0 GPU" : "Agg2D Pure CPU");
        if (g_lbl_status) ft_text_set_text(g_lbl_status, buf);
        /* Revert radio to actual active engine */
        if (g_active_engine == RENDER_ENGINE_OPENGL) {
            if (g_rb_gl) ft_radio_set_checked(g_rb_gl, 1);
        } else {
            if (g_rb_agg) ft_radio_set_checked(g_rb_agg, 1);
        }
    }

    if (g_engine_badge) {
        ft_widget_invalidate(g_engine_badge);
    }
}

static void on_paint_engine_badge(FtWidget button, void* canvas, double x, double y, double w, double h, int32_t state, void* user_data) {
    (void)button; (void)state; (void)user_data;

    /* FPS and frame delta calculation */
    static struct timespec s_last_time = {0, 0};
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    if (s_last_time.tv_sec != 0) {
        double dt = (now.tv_sec - s_last_time.tv_sec) + (now.tv_nsec - s_last_time.tv_nsec) * 1e-9;
        if (dt > 0.0001 && dt < 1.0) {
            double instant_fps = 1.0 / dt;
            g_current_fps = g_current_fps * 0.9 + instant_fps * 0.1;
            g_frame_time_ms = dt * 1000.0;
        }
    }
    s_last_time = now;
    g_frame_count++;

    if (g_show_fps && (g_frame_count % 10 == 0) && g_lbl_engine_fps) {
        char buf[64];
        snprintf(buf, sizeof(buf), "FPS: %.1f (%.1f ms)", g_current_fps, g_frame_time_ms);
        ft_text_set_text(g_lbl_engine_fps, buf);
    }

    double cx = x + w / 2.0;
    double cy = y + h / 2.0;

    if (g_active_engine == RENDER_ENGINE_AGG2D) {
        /* Card Background: Dark Emerald / Slate */
        ft_canvas_draw_rounded_rect(canvas, x, y, w, h, 8.0, 0.06, 0.10, 0.16, 0.95);
        ft_canvas_draw_rounded_rect_outline(canvas, x, y, w, h, 8.0, 1.5, 0.06, 0.72, 0.50, 0.85);

        /* Agg2D Vector Visuals: High-precision concentric vector circles & crosshairs */
        ft_canvas_draw_circle(canvas, cx, cy - 6, 26.0, 0.06, 0.72, 0.50, 0.12);
        ft_canvas_draw_circle(canvas, cx, cy - 6, 18.0, 0.06, 0.72, 0.50, 0.22);
        ft_canvas_draw_circle(canvas, cx, cy - 6, 10.0, 0.06, 0.72, 0.50, 0.45);
        ft_canvas_draw_circle(canvas, cx, cy - 6, 3.5, 1.0, 1.0, 1.0, 0.90);

        /* Anti-aliased vector crosshair lines */
        ft_canvas_draw_line(canvas, cx - 32, cy - 6, cx + 32, cy - 6, 1.0, 0.06, 0.72, 0.50, 0.40);
        ft_canvas_draw_line(canvas, cx, cy - 6 - 32, cx, cy - 6 + 32, 1.0, 0.06, 0.72, 0.50, 0.40);

        /* Precision vector diamond */
        ft_canvas_draw_line(canvas, cx, cy - 6 - 22, cx + 22, cy - 6, 1.0, 0.10, 0.85, 0.60, 0.70);
        ft_canvas_draw_line(canvas, cx + 22, cy - 6, cx, cy - 6 + 22, 1.0, 0.10, 0.85, 0.60, 0.70);
        ft_canvas_draw_line(canvas, cx, cy - 6 + 22, cx - 22, cy - 6, 1.0, 0.10, 0.85, 0.60, 0.70);
        ft_canvas_draw_line(canvas, cx - 22, cy - 6, cx, cy - 6 - 22, 1.0, 0.10, 0.85, 0.60, 0.70);

        /* Emblem Text */
        ft_canvas_draw_text_centered(canvas, (int32_t)x, (int32_t)(y + h - 22), (int32_t)w, 18, "AGG2D VECTOR", NULL, 0.10, 0.85, 0.60);
    } else {
        /* Card Background: Deep Space Blue / Cyan */
        ft_canvas_draw_rounded_rect(canvas, x, y, w, h, 8.0, 0.04, 0.08, 0.16, 0.95);
        ft_canvas_draw_rounded_rect_outline(canvas, x, y, w, h, 8.0, 1.5, 0.06, 0.65, 0.95, 0.85);

        /* OpenGL GPU Visuals: 3D Perspective Texture Quad & Grid */
        ft_canvas_draw_line(canvas, cx - 28, cy - 20, cx + 28, cy - 20, 1.2, 0.22, 0.74, 0.97, 0.75);
        ft_canvas_draw_line(canvas, cx + 28, cy - 20, cx + 34, cy + 10, 1.2, 0.22, 0.74, 0.97, 0.75);
        ft_canvas_draw_line(canvas, cx + 34, cy + 10, cx - 22, cy + 10, 1.2, 0.22, 0.74, 0.97, 0.75);
        ft_canvas_draw_line(canvas, cx - 22, cy + 10, cx - 28, cy - 20, 1.2, 0.22, 0.74, 0.97, 0.75);

        /* Perspective grid diagonals */
        ft_canvas_draw_line(canvas, cx - 28, cy - 20, cx + 34, cy + 10, 1.0, 0.06, 0.50, 0.85, 0.35);
        ft_canvas_draw_line(canvas, cx + 28, cy - 20, cx - 22, cy + 10, 1.0, 0.06, 0.50, 0.85, 0.35);

        /* Glowing GPU Core Orbit */
        ft_canvas_draw_circle(canvas, cx + 3, cy - 5, 14.0, 0.06, 0.65, 0.95, 0.25);
        ft_canvas_draw_circle(canvas, cx + 3, cy - 5, 8.0, 0.22, 0.74, 0.97, 0.50);
        ft_canvas_draw_circle(canvas, cx + 3, cy - 5, 3.0, 1.0, 1.0, 1.0, 0.95);

        /* Emblem Text */
        ft_canvas_draw_text_centered(canvas, (int32_t)x, (int32_t)(y + h - 22), (int32_t)w, 18, "OPENGL ES 2.0", NULL, 0.22, 0.74, 0.97);
    }
}

static void on_window_gl_draw(FtWidget window, int32_t width, int32_t height, void* user_data) {
    (void)window; (void)width; (void)height; (void)user_data;
    /* Direct OpenGL callback executed on each GPU presentation frame */
}

static void on_dark_mode_click(FtWidget btn, void* user_data) {
    (void)btn;
    (void)user_data;
    int32_t dark = ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(!dark);
    if (g_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "[Status] Dark mode set to: %s", (!dark) ? "ON" : "OFF");
        ft_text_set_text(g_lbl_status, buf);
    }
}

static void on_theme_button_click(FtWidget btn, void* user_data) {
    (void)btn;
    const char* theme_name = (const char*)user_data;
    if (theme_name) {
        ft_theme_set(theme_name);
        if (g_lbl_status) {
            char buf[128];
            snprintf(buf, sizeof(buf), "[Status] Applied theme: %s", theme_name);
            ft_text_set_text(g_lbl_status, buf);
        }
    }
}

static void on_checkbox_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)user_data;

    if (widget == g_cb_hw) {
        update_render_engine(checked ? RENDER_ENGINE_OPENGL : RENDER_ENGINE_AGG2D);
        return;
    }

    if (widget == g_cb_fps) {
        g_show_fps = checked;
        if (!checked) {
            if (g_lbl_engine_fps) ft_text_set_text(g_lbl_engine_fps, "FPS: Hidden");
        } else {
            if (g_lbl_engine_fps) {
                char buf[64];
                snprintf(buf, sizeof(buf), "FPS: %.1f (%.1f ms)", g_current_fps, g_frame_time_ms);
                ft_text_set_text(g_lbl_engine_fps, buf);
            }
        }
        if (g_lbl_status) {
            char buf[128];
            snprintf(buf, sizeof(buf), "[Performance] Live FPS & timing stats: %s", checked ? "ENABLED" : "DISABLED");
            ft_text_set_text(g_lbl_status, buf);
        }
        return;
    }

    if (widget == g_cb_aa) {
        ft_font_gamma_set(checked ? 1.0 : 1.4);
        if (g_lbl_status) {
            char buf[128];
            snprintf(buf, sizeof(buf), "[Typography] Subpixel anti-aliasing: %s (Font Gamma: %.1f)",
                     checked ? "OPTIMAL" : "OFF", checked ? 1.0 : 1.4);
            ft_text_set_text(g_lbl_status, buf);
        }
        return;
    }
}

static void on_radio_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)user_data;
    if (!checked) return;

    if (widget == g_rb_agg) {
        update_render_engine(RENDER_ENGINE_AGG2D);
    } else if (widget == g_rb_gl) {
        update_render_engine(RENDER_ENGINE_OPENGL);
    } else if (widget == g_rb_vk) {
        update_render_engine(RENDER_ENGINE_VULKAN);
    }
}

static void on_combo_change(FtWidget widget, int32_t selected_index, const char* text, void* user_data) {
    (void)widget;
    (void)user_data;
    if (g_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "[ComboBox] Selected item #%d: '%s'", selected_index, text ? text : "");
        ft_text_set_text(g_lbl_status, buf);
    }

    /* If item corresponds to a known theme, apply it */
    if (text) {
        if (strstr(text, "Default")) ft_theme_set("default");
        else if (strstr(text, "Nord")) ft_theme_set("nord");
        else if (strstr(text, "Dracula")) ft_theme_set("dracula");
        else if (strstr(text, "Gruvbox")) ft_theme_set("gruvbox");
        else if (strstr(text, "GTK2")) ft_theme_set("gtk2");
        else if (strstr(text, "Classic")) ft_theme_set("classic");
    }
}

static void on_slider_horiz_change(FtWidget widget, double value, void* user_data) {
    (void)widget;
    (void)user_data;
    if (g_pbar_determinate) {
        ft_progressbar_set_value(g_pbar_determinate, value);
    }
    if (g_lbl_slider_val) {
        char buf[64];
        snprintf(buf, sizeof(buf), "Value: %.0f%%", value);
        ft_text_set_text(g_lbl_slider_val, buf);
    }
    if (g_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "[Slider] Horizontal slider value: %.1f", value);
        ft_text_set_text(g_lbl_status, buf);
    }
}

static void on_slider_vert_change(FtWidget widget, double value, void* user_data) {
    (void)widget;
    (void)user_data;
    if (g_pbar_vert) {
        ft_progressbar_set_value(g_pbar_vert, value);
    }
    if (g_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "[Slider] Vertical slider value: %.1f", value);
        ft_text_set_text(g_lbl_status, buf);
    }
}

static void on_indeterminate_toggle(FtWidget btn, void* user_data) {
    (void)btn;
    (void)user_data;
    if (g_pbar_indeterminate) {
        int32_t ind = ft_progressbar_get_indeterminate(g_pbar_indeterminate);
        ft_progressbar_set_indeterminate(g_pbar_indeterminate, !ind);
        if (g_lbl_status) {
            char buf[128];
            snprintf(buf, sizeof(buf), "[ProgressBar] Indeterminate mode set to: %s", (!ind) ? "ANIMATED" : "PAUSED");
            ft_text_set_text(g_lbl_status, buf);
        }
    }
}

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    ft_init();

    g_egl_available = ft_egl_is_available();
    if (g_egl_available) {
        ft_backend_enable_egl(1);
    }

    g_win = ft_window_create(860, 680, "Floria Toolkit - Form Controls & Meters Demo");
    if (!g_win) {
        fprintf(stderr, "Failed to create window\n");
        return 1;
    }

    if (g_egl_available) {
        ft_window_on_gl_draw(g_win, on_window_gl_draw, NULL);
    }

    /* Top Bar: Title & Theme Switches */
    FtWidget lbl_title = ft_text_create(g_win, 24, 18, 380, 28, "Form Controls & Meters");
    ft_widget_set_font(lbl_title, "Inter-Bold-18");

    FtWidget btn_dark = ft_button_create(g_win, 430, 16, 95, 30, "Dark Mode");
    ft_button_on_click(btn_dark, on_dark_mode_click, NULL);

    FtWidget btn_nord = ft_button_create(g_win, 532, 16, 75, 30, "Nord");
    ft_button_on_click(btn_nord, on_theme_button_click, (void*)"nord");

    FtWidget btn_drac = ft_button_create(g_win, 613, 16, 75, 30, "Dracula");
    ft_button_on_click(btn_drac, on_theme_button_click, (void*)"dracula");

    FtWidget btn_gruv = ft_button_create(g_win, 694, 16, 75, 30, "Gruvbox");
    ft_button_on_click(btn_gruv, on_theme_button_click, (void*)"gruvbox");

    FtWidget btn_def = ft_button_create(g_win, 775, 16, 65, 30, "Default");
    ft_button_on_click(btn_def, on_theme_button_click, (void*)"default");

    /* ========================================================================= */
    /* LEFT PANEL: SELECTORS (CheckBox, RadioButton, ComboBox)                   */
    /* ========================================================================= */
    FtWidget left_card = ft_container_create(g_win, 24, 62, 390, 550);
    ft_container_set_draw_frame(left_card, 1);
    ft_container_set_corner_radius(left_card, 8.0);
    ft_container_set_padding(left_card, 16.0, 16.0);
    ft_container_set_scrollbar_mode(left_card, 0);

    /* Section A: CheckBoxes */
    FtWidget h_cb = ft_text_create(left_card, 0, 0, 350, 22, "Checkboxes (TFtCheckBox)");
    ft_widget_set_font(h_cb, "Inter-Bold-13");

    g_cb_hw = ft_checkbox_create(left_card, 0, 30, 350, 24, "Hardware acceleration enabled");
    ft_checkbox_set_checked(g_cb_hw, 0);
    ft_checkbox_on_toggle(g_cb_hw, on_checkbox_toggle, (void*)"Hardware Acceleration");

    g_cb_fps = ft_checkbox_create(left_card, 0, 62, 350, 24, "Show live FPS and performance stats");
    ft_checkbox_set_checked(g_cb_fps, 0);
    ft_checkbox_on_toggle(g_cb_fps, on_checkbox_toggle, (void*)"Live FPS & Stats");

    g_cb_aa = ft_checkbox_create(left_card, 0, 94, 350, 24, "Enable subpixel text anti-aliasing");
    ft_checkbox_set_checked(g_cb_aa, 1);
    ft_checkbox_on_toggle(g_cb_aa, on_checkbox_toggle, (void*)"Subpixel Anti-aliasing");

    /* Section B: RadioButtons */
    FtWidget h_rb = ft_text_create(left_card, 0, 138, 350, 22, "Radio Buttons (TFtRadioButton)");
    ft_widget_set_font(h_rb, "Inter-Bold-13");

    g_rb_agg = ft_radio_create(left_card, 0, 168, 350, 24, "Agg2D Software Rendering (Pure CPU)");
    ft_radio_set_group(g_rb_agg, 1);
    ft_radio_set_checked(g_rb_agg, 1);
    ft_radio_on_toggle(g_rb_agg, on_radio_toggle, (void*)"Agg2D");

    g_rb_gl = ft_radio_create(left_card, 0, 200, 350, 24, "OpenGL Accelerated Raster (GPU)");
    ft_radio_set_group(g_rb_gl, 1);
    ft_radio_set_checked(g_rb_gl, 0);
    ft_radio_on_toggle(g_rb_gl, on_radio_toggle, (void*)"OpenGL");

    g_rb_vk = ft_radio_create(left_card, 0, 232, 350, 24, "Vulkan Low-Overhead Engine");
    ft_radio_set_group(g_rb_vk, 1);
    ft_radio_set_checked(g_rb_vk, 0);
    ft_radio_on_toggle(g_rb_vk, on_radio_toggle, (void*)"Vulkan");

    /* Section C: ComboBoxes */
    FtWidget h_combo = ft_text_create(left_card, 0, 276, 350, 22, "Drop-down Select (TFtComboBox)");
    ft_widget_set_font(h_combo, "Inter-Bold-13");

    ft_text_create(left_card, 0, 306, 350, 20, "Theme Selection:");
    FtWidget combo_theme = ft_combobox_create(left_card, 0, 330, 350, 32);
    ft_combobox_add_item(combo_theme, "Default Theme");
    ft_combobox_add_item(combo_theme, "Nord Theme");
    ft_combobox_add_item(combo_theme, "Dracula Theme");
    ft_combobox_add_item(combo_theme, "Gruvbox Theme");
    ft_combobox_add_item(combo_theme, "GTK2 Theme");
    ft_combobox_add_item(combo_theme, "Classic Theme");
    ft_combobox_set_selected(combo_theme, 0);
    ft_combobox_on_change(combo_theme, on_combo_change, NULL);

    ft_text_create(left_card, 0, 376, 350, 20, "Target Architecture:");
    FtWidget combo_arch = ft_combobox_create(left_card, 0, 400, 350, 32);
    ft_combobox_add_item(combo_arch, "x86_64-linux-gnu");
    ft_combobox_add_item(combo_arch, "aarch64-linux-gnu");
    ft_combobox_add_item(combo_arch, "riscv64-linux-gnu");
    ft_combobox_add_item(combo_arch, "armv7l-linux-gnueabihf");
    ft_combobox_set_selected(combo_arch, 0);
    ft_combobox_on_change(combo_arch, on_combo_change, NULL);

    /* ========================================================================= */
    /* RIGHT PANEL: METERS (Slider, ProgressBar, Active Engine Visualizer)        */
    /* ========================================================================= */
    FtWidget right_card = ft_container_create(g_win, 432, 62, 408, 550);
    ft_container_set_draw_frame(right_card, 1);
    ft_container_set_corner_radius(right_card, 8.0);
    ft_container_set_padding(right_card, 16.0, 16.0);
    ft_container_set_scrollbar_mode(right_card, 0);

    /* Section A: Horizontal Slider & Determinate ProgressBar */
    FtWidget h_meters = ft_text_create(right_card, 0, 0, 370, 22, "Sliders & Progress (TFtSlider / TFtProgressBar)");
    ft_widget_set_font(h_meters, "Inter-Bold-13");

    ft_text_create(right_card, 0, 30, 260, 20, "Horizontal Slider (0..100):");
    g_lbl_slider_val = ft_text_create(right_card, 270, 30, 100, 20, "Value: 45%");

    g_slider_horiz = ft_slider_create(right_card, 0, 54, 370, 24, FT_SLIDER_HORIZONTAL);
    ft_slider_set_range(g_slider_horiz, 0.0, 100.0);
    ft_slider_set_value(g_slider_horiz, 45.0);
    ft_slider_on_change(g_slider_horiz, on_slider_horiz_change, NULL);

    ft_text_create(right_card, 0, 88, 370, 20, "Linked Progress Bar (Determinate):");
    g_pbar_determinate = ft_progressbar_create(right_card, 0, 112, 370, 20, FT_PROGRESS_HORIZONTAL);
    ft_progressbar_set_range(g_pbar_determinate, 0.0, 100.0);
    ft_progressbar_set_value(g_pbar_determinate, 45.0);
    ft_progressbar_set_show_text(g_pbar_determinate, 1);
    ft_progressbar_set_corner_radius(g_pbar_determinate, 5.0);

    /* Section B: Indeterminate Animated ProgressBar */
    ft_text_create(right_card, 0, 146, 370, 20, "Indeterminate Activity Bar (Smooth 60 FPS):");
    g_pbar_indeterminate = ft_progressbar_create(right_card, 0, 170, 370, 16, FT_PROGRESS_HORIZONTAL);
    ft_progressbar_set_indeterminate(g_pbar_indeterminate, 1);
    ft_progressbar_set_corner_radius(g_pbar_indeterminate, 4.0);

    FtWidget btn_toggle_ind = ft_button_create(right_card, 0, 196, 170, 28, "Toggle Activity");
    ft_button_on_click(btn_toggle_ind, on_indeterminate_toggle, NULL);

    /* Section C: Vertical Slider & Vertical ProgressBar */
    FtWidget lbl_v_head = ft_text_create(right_card, 0, 242, 370, 20, "Vertical Orientation & Active Engine:");
    ft_widget_set_font(lbl_v_head, "Inter-Bold-12");

    ft_text_create(right_card, 10, 266, 60, 18, "Slider:");
    g_slider_vert = ft_slider_create(right_card, 16, 290, 24, 180, FT_SLIDER_VERTICAL);
    ft_slider_set_range(g_slider_vert, 0.0, 100.0);
    ft_slider_set_value(g_slider_vert, 70.0);
    ft_slider_on_change(g_slider_vert, on_slider_vert_change, NULL);

    ft_text_create(right_card, 75, 266, 65, 18, "Progress:");
    g_pbar_vert = ft_progressbar_create(right_card, 88, 290, 20, 180, FT_PROGRESS_VERTICAL);
    ft_progressbar_set_range(g_pbar_vert, 0.0, 100.0);
    ft_progressbar_set_value(g_pbar_vert, 70.0);
    ft_progressbar_set_corner_radius(g_pbar_vert, 6.0);

    /* Section D: Active Engine Visualizer & Live Performance */
    FtWidget lbl_engine_head = ft_text_create(right_card, 156, 266, 214, 18, "Active Pipeline:");
    ft_widget_set_font(lbl_engine_head, "Inter-Bold-12");

    g_engine_badge = ft_button_create(right_card, 156, 288, 214, 95, "");
    ft_button_on_paint(g_engine_badge, on_paint_engine_badge, NULL);
    ft_button_set_shadow(g_engine_badge, 0);

    g_lbl_engine_mode = ft_text_create(right_card, 156, 388, 214, 18, "Agg2D Pure CPU");
    ft_widget_set_font(g_lbl_engine_mode, "Inter-Bold-11");
    ft_widget_set_style(g_lbl_engine_mode, "color: #10b981;");

    g_lbl_engine_info1 = ft_text_create(right_card, 156, 408, 214, 16, "• AggPas 2.4 Vector");
    ft_widget_set_style(g_lbl_engine_info1, "font-size: 10px; color: #94a3b8;");

    g_lbl_engine_info2 = ft_text_create(right_card, 156, 426, 214, 16, "• XCB 32-bit ARGB Blit");
    ft_widget_set_style(g_lbl_engine_info2, "font-size: 10px; color: #94a3b8;");

    g_lbl_engine_fps = ft_text_create(right_card, 156, 446, 214, 18, "FPS: Hidden");
    ft_widget_set_font(g_lbl_engine_fps, "Inter-Bold-11");
    ft_widget_set_style(g_lbl_engine_fps, "color: #64748b;");

    /* ========================================================================= */
    /* BOTTOM BAR: Event Log & Status                                            */
    /* ========================================================================= */
    g_lbl_status = ft_text_create(g_win, 24, 630, 810, 26, "[Status] Ready - interact with any form control above.");
    ft_widget_set_font(g_lbl_status, "Inter-Medium-12");

    /* Initialize rendering engine state */
    update_render_engine(RENDER_ENGINE_AGG2D);

    ft_widget_show(g_win);
    ft_main_loop();
    ft_quit();

    return 0;
}

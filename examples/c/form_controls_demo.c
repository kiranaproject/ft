#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ft.h"

static FtWidget g_lbl_status = NULL;
static FtWidget g_pbar_determinate = NULL;
static FtWidget g_pbar_vert = NULL;
static FtWidget g_pbar_indeterminate = NULL;
static FtWidget g_lbl_slider_val = NULL;
static FtWidget g_slider_horiz = NULL;
static FtWidget g_slider_vert = NULL;

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
    (void)widget;
    const char* name = (const char*)user_data;
    if (g_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "[CheckBox] '%s' toggled -> %s", name ? name : "CheckBox", checked ? "CHECKED" : "UNCHECKED");
        ft_text_set_text(g_lbl_status, buf);
    }
}

static void on_radio_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    const char* name = (const char*)user_data;
    if (checked && g_lbl_status) {
        char buf[128];
        snprintf(buf, sizeof(buf), "[Radio] Selected option: '%s'", name ? name : "Unknown");
        ft_text_set_text(g_lbl_status, buf);
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

    FtWidget win = ft_window_create(860, 680, "Floria Toolkit - Form Controls & Meters Demo");
    if (!win) {
        fprintf(stderr, "Failed to create window\n");
        return 1;
    }

    /* Top Bar: Title & Theme Switches */
    FtWidget lbl_title = ft_text_create(win, 24, 18, 380, 28, "Form Controls & Meters");
    ft_widget_set_font(lbl_title, "Inter-Bold-18");

    FtWidget btn_dark = ft_button_create(win, 430, 16, 95, 30, "Dark Mode");
    ft_button_on_click(btn_dark, on_dark_mode_click, NULL);

    FtWidget btn_nord = ft_button_create(win, 532, 16, 75, 30, "Nord");
    ft_button_on_click(btn_nord, on_theme_button_click, (void*)"nord");

    FtWidget btn_drac = ft_button_create(win, 613, 16, 75, 30, "Dracula");
    ft_button_on_click(btn_drac, on_theme_button_click, (void*)"dracula");

    FtWidget btn_gruv = ft_button_create(win, 694, 16, 75, 30, "Gruvbox");
    ft_button_on_click(btn_gruv, on_theme_button_click, (void*)"gruvbox");

    FtWidget btn_def = ft_button_create(win, 775, 16, 65, 30, "Default");
    ft_button_on_click(btn_def, on_theme_button_click, (void*)"default");

    /* ========================================================================= */
    /* LEFT PANEL: SELECTORS (CheckBox, RadioButton, ComboBox)                   */
    /* ========================================================================= */
    FtWidget left_card = ft_container_create(win, 24, 62, 390, 550);
    ft_container_set_draw_frame(left_card, 1);
    ft_container_set_corner_radius(left_card, 8.0);
    ft_container_set_padding(left_card, 16.0, 16.0);

    /* Section A: CheckBoxes */
    FtWidget h_cb = ft_text_create(left_card, 0, 0, 350, 22, "Checkboxes (TFtCheckBox)");
    ft_widget_set_font(h_cb, "Inter-Bold-13");

    FtWidget cb1 = ft_checkbox_create(left_card, 0, 30, 350, 24, "Hardware acceleration enabled");
    ft_checkbox_set_checked(cb1, 1);
    ft_checkbox_on_toggle(cb1, on_checkbox_toggle, (void*)"Hardware Acceleration");

    FtWidget cb2 = ft_checkbox_create(left_card, 0, 62, 350, 24, "Show live FPS and performance stats");
    ft_checkbox_set_checked(cb2, 0);
    ft_checkbox_on_toggle(cb2, on_checkbox_toggle, (void*)"Live FPS & Stats");

    FtWidget cb3 = ft_checkbox_create(left_card, 0, 94, 350, 24, "Enable subpixel text anti-aliasing");
    ft_checkbox_set_checked(cb3, 1);
    ft_checkbox_on_toggle(cb3, on_checkbox_toggle, (void*)"Subpixel Anti-aliasing");

    /* Section B: RadioButtons */
    FtWidget h_rb = ft_text_create(left_card, 0, 138, 350, 22, "Radio Buttons (TFtRadioButton)");
    ft_widget_set_font(h_rb, "Inter-Bold-13");

    FtWidget rb1 = ft_radio_create(left_card, 0, 168, 350, 24, "Agg2D Software Rendering (Pure CPU)");
    ft_radio_set_group(rb1, 1);
    ft_radio_set_checked(rb1, 1);
    ft_radio_on_toggle(rb1, on_radio_toggle, (void*)"Agg2D Software Rendering");

    FtWidget rb2 = ft_radio_create(left_card, 0, 200, 350, 24, "OpenGL Accelerated Raster (GPU)");
    ft_radio_set_group(rb2, 1);
    ft_radio_set_checked(rb2, 0);
    ft_radio_on_toggle(rb2, on_radio_toggle, (void*)"OpenGL Accelerated Raster");

    FtWidget rb3 = ft_radio_create(left_card, 0, 232, 350, 24, "Vulkan Low-Overhead Engine");
    ft_radio_set_group(rb3, 1);
    ft_radio_set_checked(rb3, 0);
    ft_radio_on_toggle(rb3, on_radio_toggle, (void*)"Vulkan Low-Overhead Engine");

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
    /* RIGHT PANEL: METERS (Slider, ProgressBar)                                 */
    /* ========================================================================= */
    FtWidget right_card = ft_container_create(win, 432, 62, 408, 550);
    ft_container_set_draw_frame(right_card, 1);
    ft_container_set_corner_radius(right_card, 8.0);
    ft_container_set_padding(right_card, 16.0, 16.0);

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

    /* Section C: Vertical Slider & Vertical ProgressBar Side-by-Side */
    FtWidget lbl_v_head = ft_text_create(right_card, 0, 242, 370, 20, "Vertical Orientation:");
    ft_widget_set_font(lbl_v_head, "Inter-Bold-12");

    ft_text_create(right_card, 20, 266, 100, 18, "Slider:");
    g_slider_vert = ft_slider_create(right_card, 45, 290, 24, 180, FT_SLIDER_VERTICAL);
    ft_slider_set_range(g_slider_vert, 0.0, 100.0);
    ft_slider_set_value(g_slider_vert, 70.0);
    ft_slider_on_change(g_slider_vert, on_slider_vert_change, NULL);

    ft_text_create(right_card, 150, 266, 110, 18, "Progress Bar:");
    g_pbar_vert = ft_progressbar_create(right_card, 185, 290, 20, 180, FT_PROGRESS_VERTICAL);
    ft_progressbar_set_range(g_pbar_vert, 0.0, 100.0);
    ft_progressbar_set_value(g_pbar_vert, 70.0);
    ft_progressbar_set_corner_radius(g_pbar_vert, 6.0);

    FtWidget lbl_n0 = ft_text_create(right_card, 230, 310, 140, 20, "Live Controls:");
    ft_widget_set_font(lbl_n0, "Inter-Bold-12");
    ft_text_create(right_card, 230, 335, 140, 18, "- Drag sliders");
    ft_text_create(right_card, 230, 355, 140, 18, "- Click checkboxes");
    ft_text_create(right_card, 230, 375, 140, 18, "- Select radios");
    ft_text_create(right_card, 230, 395, 140, 18, "- Dropdown menus");
    ft_text_create(right_card, 230, 415, 140, 18, "- 60 FPS animations");

    /* ========================================================================= */
    /* BOTTOM BAR: Event Log & Status                                            */
    /* ========================================================================= */
    g_lbl_status = ft_text_create(win, 24, 630, 810, 26, "[Status] Ready - interact with any form control above.");
    ft_widget_set_font(g_lbl_status, "Inter-Medium-12");

    ft_widget_show(win);
    ft_main_loop();
    ft_quit();

    return 0;
}

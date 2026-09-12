#include "ft.h"
#include <stdio.h>
#include <string.h>

static const char* s_demo_themes[] = {"default", "nord", "dracula", "gruvbox", "gtk2", "classic"};
static const int s_demo_theme_count = 6;
static int s_current_theme_index = 0;

static const double s_radius_presets[] = {-1.0, 0.0, 6.0, 12.0, 22.0};
static const char* s_radius_labels[] = {"Theme Default", "0px (Square)", "6px (Curved)", "12px (Smooth)", "22px (Pill)"};
static int s_radius_index = 0;

void on_theme_cycle_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_current_theme_index = (s_current_theme_index + 1) % s_demo_theme_count;
    const char* target = s_demo_themes[s_current_theme_index];
    printf("[Floria Toolkit C] Switching to theme '%s' (Hot-swapping!)...\n", target);
    ft_theme_set(target);
    printf("[Floria Toolkit C] Active theme: '%s' | Radius: %.1f | Shadow: %s | Dark: %s\n", 
           ft_theme_get(), ft_theme_get_corner_radius(), 
           ft_theme_get_shadow() ? "ON" : "OFF",
           ft_theme_get_dark_mode() ? "ON" : "OFF");
}

void on_dark_mode_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int cur_dark = ft_theme_get_dark_mode();
    int next_dark = !cur_dark;
    printf("[Floria Toolkit C] Toggling Dark Mode: %s -> %s (Hot-swapping!)...\n",
           cur_dark ? "ON" : "OFF", next_dark ? "ON" : "OFF");
    ft_theme_set_dark_mode(next_dark);
}

void on_radius_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_radius_index = (s_radius_index + 1) % 5;
    printf("[Floria Toolkit C] Cycling Theme Corner Radius: %s\n", s_radius_labels[s_radius_index]);
    ft_theme_set_corner_radius(s_radius_presets[s_radius_index]);
}

void on_shadow_toggle_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int cur_shadow = ft_theme_get_shadow();
    int next_shadow = !cur_shadow;
    printf("[Floria Toolkit C] Toggling Shadows: %s -> %s\n",
           cur_shadow ? "ON" : "OFF", next_shadow ? "ON" : "OFF");
    ft_theme_set_shadow(next_shadow);
}

void on_button_hover(FtWidget widget, int32_t hovered, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit C] Button Hover: %s (%s)\n", 
           hovered ? "ENTER" : "LEAVE", (char*)user_data);
}

void on_button_press(FtWidget widget, int32_t pressed, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit C] Button Press: %s (%s)\n", 
           pressed ? "DOWN (Pressed)" : "UP (Released)", (char*)user_data);
}

void on_button_toggle(FtWidget widget, int32_t toggled, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit C] Button Toggle: %s (%s)\n", 
           toggled ? "ON" : "OFF", (char*)user_data);
}

void on_switch_dark_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[Floria Toolkit C] Dark Mode Switch: %s\n", checked ? "ON" : "OFF");
    ft_theme_set_dark_mode(checked);
}

void on_switch_shadow_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[Floria Toolkit C] Shadows Switch: %s\n", checked ? "ON" : "OFF");
    ft_theme_set_shadow(checked);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    printf("[Floria Toolkit C] System font: %s (DPI: %.1f, Gamma: %.2f)\n", 
           ft_system_font_get(), ft_screen_dpi_get(), ft_font_gamma_get());
    printf("[Floria Toolkit C] Active theme: %s (Dark Mode: %s)\n",
           ft_theme_get(), ft_theme_get_dark_mode() ? "ON" : "OFF");
    printf("[Floria Toolkit C] Available themes: %s\n", ft_theme_get_available());

    FtWidget win = ft_window_create(500, 315, "Floria Toolkit (C Demo) - Widgets & Theming");

    // Row 1: Theme & Dark Mode
    FtWidget btn1 = ft_button_create(win, 30, 45, 205, 44, "Next Theme");
    ft_button_on_click(btn1, on_theme_cycle_click, (void*)"ThemeCycleBtn");
    ft_button_on_hover(btn1, on_button_hover, (void*)"ThemeCycleBtn");
    ft_button_on_press(btn1, on_button_press, (void*)"ThemeCycleBtn");

    FtWidget btn2 = ft_button_create(win, 265, 45, 205, 44, "Toggle Dark Mode");
    ft_button_on_click(btn2, on_dark_mode_click, (void*)"DarkModeBtn");
    ft_button_on_hover(btn2, on_button_hover, (void*)"DarkModeBtn");
    ft_button_on_press(btn2, on_button_press, (void*)"DarkModeBtn");

    // Row 2: Corner Radius & Shadow Toggles
    FtWidget btn_radius = ft_button_create(win, 30, 105, 205, 44, "Cycle Corner Radius");
    ft_button_on_click(btn_radius, on_radius_click, (void*)"RadiusBtn");
    ft_button_on_hover(btn_radius, on_button_hover, (void*)"RadiusBtn");
    ft_button_on_press(btn_radius, on_button_press, (void*)"RadiusBtn");

    FtWidget btn_shadow = ft_button_create(win, 265, 105, 205, 44, "Toggle Drop Shadows");
    ft_button_on_click(btn_shadow, on_shadow_toggle_click, (void*)"ShadowBtn");
    ft_button_on_hover(btn_shadow, on_button_hover, (void*)"ShadowBtn");
    ft_button_on_press(btn_shadow, on_button_press, (void*)"ShadowBtn");

    // Row 3: Custom Per-Widget Styled Toggle Button (Pill shaped: 22px radius)
    FtWidget btn3 = ft_toggle_button_create(win, 135, 168, 230, 42, "Custom Pill Toggle");
    ft_button_set_corner_radius(btn3, 21.0); // Override per-widget corner radius to pill!
    ft_button_on_hover(btn3, on_button_hover, (void*)"ToggleBtn");
    ft_button_on_press(btn3, on_button_press, (void*)"ToggleBtn");
    ft_button_on_toggle(btn3, on_button_toggle, (void*)"ToggleBtn");

    // Row 4: Switch Widgets
    FtWidget sw_dark = ft_switch_create(win, 30, 235, 205, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_switch_dark_toggle, (void*)"DarkSwitch");

    FtWidget sw_shadow = ft_switch_create(win, 265, 235, 205, 26, "Drop Shadows");
    ft_switch_set_checked(sw_shadow, ft_theme_get_shadow());
    ft_switch_on_toggle(sw_shadow, on_switch_shadow_toggle, (void*)"ShadowSwitch");

    ft_widget_show(win);
    ft_main_loop();

    return 0;
}
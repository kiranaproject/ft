#include "ft.h"
#include <stdio.h>

void on_button_click(FtWidget widget, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit C] Button Clicked! (%s)\n", (char*)user_data);
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

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    printf("[Floria Toolkit C] System font: %s (DPI: %.1f, Gamma: %.2f)\n", 
           ft_system_font_get(), ft_screen_dpi_get(), ft_font_gamma_get());

    FtWidget win = ft_window_create(440, 240, "Floria Toolkit (C Demo) - Display States");

    // Standard push button
    FtWidget btn1 = ft_button_create(win, 40, 90, 160, 42, "Push Button");
    ft_button_on_click(btn1, on_button_click, (void*)"PushBtn");
    ft_button_on_hover(btn1, on_button_hover, (void*)"PushBtn");
    ft_button_on_press(btn1, on_button_press, (void*)"PushBtn");

    // Toggle button
    FtWidget btn2 = ft_toggle_button_create(win, 240, 90, 160, 42, "Toggle Button");
    ft_button_on_click(btn2, on_button_click, (void*)"ToggleBtn");
    ft_button_on_hover(btn2, on_button_hover, (void*)"ToggleBtn");
    ft_button_on_press(btn2, on_button_press, (void*)"ToggleBtn");
    ft_button_on_toggle(btn2, on_button_toggle, (void*)"ToggleBtn");

    ft_widget_show(win);
    ft_main_loop();

    return 0;
}
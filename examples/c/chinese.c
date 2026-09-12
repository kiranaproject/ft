#include "ft.h"
#include <stdio.h>

void on_button_click(FtWidget widget, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit C] Button clicked: %s\n", (char*)user_data);
}

int main(void) {
    ft_init();

    printf("[Floria Toolkit C] System font: %s (DPI: %.1f, Gamma: %.2f)\n",
           ft_system_font_get(), ft_screen_dpi_get(), ft_font_gamma_get());

    FtWidget win = ft_window_create(500, 260, "Floria - 中文测试");

    // Button 1: Default system font with automatic CJK fallback
    FtWidget btn1 = ft_button_create(win, 40, 50, 200, 45, "按我 (Click Me)");
    ft_button_on_click(btn1, on_button_click, (void*)"Btn1_ClickMe");

    // Button 2: Explicit CJK font
    FtWidget btn2 = ft_button_create(win, 260, 50, 200, 45, "确定 (Confirm)");
    ft_widget_set_font(btn2, "Noto Sans CJK SC-12");
    ft_button_on_click(btn2, on_button_click, (void*)"Btn2_Confirm");

    // Button 3: Sentence with mixed CJK & Latin
    FtWidget btn3 = ft_button_create(win, 40, 130, 420, 50, "你好，世界！欢迎使用 Floria Toolkit");
    ft_widget_set_font(btn3, "Noto Sans CJK SC-13");
    ft_button_on_click(btn3, on_button_click, (void*)"Btn3_HelloWorld");

    ft_widget_show(win);
    ft_main_loop();

    return 0;
}

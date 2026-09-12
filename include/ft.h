#ifndef FLORIA_TOOLKIT_H
#define FLORIA_TOOLKIT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* FtWidget;

/* Callback Types */
typedef void (*FtClickCallback)(FtWidget widget, void* user_data);
typedef void (*FtHoverCallback)(FtWidget widget, int32_t hovered, void* user_data);
typedef void (*FtPressCallback)(FtWidget widget, int32_t pressed, void* user_data);
typedef void (*FtToggleCallback)(FtWidget widget, int32_t toggled, void* user_data);

/* Button States */
enum {
    FT_BUTTON_STATE_NORMAL = 0,
    FT_BUTTON_STATE_HOVERED = 1,
    FT_BUTTON_STATE_PRESSED = 2
};

/* Core Lifecycle */
void ft_init(void);
void ft_main_loop(void);
void ft_quit(void);

/* Window Management */
FtWidget ft_window_create(int32_t width, int32_t height, const char* title);
void ft_window_set_title(FtWidget window, const char* title);
void ft_widget_show(FtWidget widget);

/* Widgets: Buttons */
FtWidget ft_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);
FtWidget ft_toggle_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);

void ft_button_set_toggle(FtWidget button, int32_t can_toggle);
int32_t ft_button_get_toggle(FtWidget button);
void ft_button_set_toggled(FtWidget button, int32_t toggled);
int32_t ft_button_get_toggled(FtWidget button);
int32_t ft_button_get_state(FtWidget button);

void ft_button_on_click(FtWidget button, FtClickCallback callback, void* user_data);
void ft_button_on_hover(FtWidget button, FtHoverCallback callback, void* user_data);
void ft_button_on_press(FtWidget button, FtPressCallback callback, void* user_data);
void ft_button_on_toggle(FtWidget button, FtToggleCallback callback, void* user_data);

/* Font & DPI Management */
const char* ft_system_font_get(void);
void ft_system_font_set(const char* font_desc);
void ft_widget_set_font(FtWidget widget, const char* font_desc);
const char* ft_widget_get_font(FtWidget widget);
double ft_screen_dpi_get(void);
void ft_screen_dpi_set(double dpi);
double ft_font_gamma_get(void);
void ft_font_gamma_set(double gamma);

#ifdef __cplusplus
}
#endif

#endif /* FLORIA_TOOLKIT_H */
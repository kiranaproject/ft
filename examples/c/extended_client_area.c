#include "ft.h"
#include <stdio.h>
#include <stdlib.h>

static FtWidget s_header_container = NULL;
static FtWidget s_inset_label = NULL;
static FtWidget s_title_label = NULL;
static FtWidget s_window = NULL;

static void on_insets_changed(FtWidget window, int32_t left, int32_t right, int32_t top, int32_t bottom, void* user_data) {
    (void)window;
    (void)user_data;
    char buf[128];
    snprintf(buf, sizeof(buf), "Controls Inset: [L: %d, R: %d, T: %d, B: %d]", left, right, top, bottom);
    printf("[ECA Demo] %s\n", buf);
    if (s_inset_label) {
        ft_text_set_text(s_inset_label, buf);
    }
    if (s_title_label) {
        int32_t title_x = (left > 0) ? (left + 12) : 16;
        ft_widget_set_bounds(s_title_label, title_x, 14, 300, 24);
    }
}

static void on_header_mouse_down(FtWidget widget, int32_t x, int32_t y, int32_t button, void* user_data) {
    (void)widget;
    (void)user_data;
    if (button == 1 && s_window) {
        int32_t win_x = 0, win_y = 0;
        ft_window_get_position(s_window, &win_x, &win_y);
        int32_t root_x = win_x + x;
        int32_t root_y = win_y + y;
        printf("[ECA Demo] Header drag initiated at root (%d, %d)\n", root_x, root_y);
        ft_window_begin_move(s_window, root_x, root_y);
    }
}

static void on_toggle_eca_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    if (!s_window) return;
    int32_t cur = ft_window_get_extended_client_area(s_window);
    int32_t next = !cur;
    printf("[ECA Demo] Toggling Extended Client Area: %d -> %d\n", cur, next);
    ft_window_set_extended_client_area(s_window, next);
}

int main(void) {
    ft_init();

    s_window = ft_window_create(820, 540, "Floria Extended Client Area Demo");
    ft_window_set_extended_client_area(s_window, 1);
    ft_window_on_controls_inset_changed(s_window, on_insets_changed, NULL);

    // Top unified header bar spanning width at Y=0
    s_header_container = ft_container_create(s_window, 0, 0, 820, 48);
    ft_widget_set_style_class(s_header_container, "eca-header");

    // Header label (offset to avoid window control buttons on the left)
    s_title_label = ft_text_create(s_header_container, 95, 14, 300, 24, "Floria Browser - Extended Client Area");

    // Header mouse down hook for dragging
    ft_window_on_mouse_down(s_window, on_header_mouse_down, NULL);

    // Content container below header
    FtWidget content = ft_container_create(s_window, 20, 68, 780, 450);

    FtWidget desc = ft_text_create(content, 20, 20, 740, 60,
        "This window uses the Extended Client Area (ECA) protocol.\n"
        "The exterior titlebar is eliminated so client pixels extend to Y = 0.\n"
        "The Window Manager (wmsama) draws control buttons directly on top of the client canvas.");
    (void)desc;

    s_inset_label = ft_text_create(content, 20, 90, 740, 30, "Controls Inset: [L: 0, R: 0, T: 0, B: 0]");

    FtWidget toggle_btn = ft_button_create(content, 20, 140, 220, 36, "Toggle Extended Client Area");
    ft_button_on_click(toggle_btn, on_toggle_eca_click, NULL);

    ft_widget_show(s_window);
    ft_main_loop();
    ft_quit();
    return 0;
}

/*
 * popup_dismiss.c — a popup that closes when the user clicks away from it.
 *
 * Demonstrates ft_window_grab_popup_input and ft_window_on_popup_dismiss. The popup is
 * not a menu: it hosts a drawing area, and the toolkit has no idea what is inside it.
 * What it does know is that a click outside the popup means "close it".
 *
 * Prints one line per interesting event so a script can check the behaviour:
 *
 *   READY        the popup is up and holds the grab
 *   CLICK        the drawing area inside the popup was clicked
 *   DISMISSED    the popup was closed by an outside click or Escape
 *   EXIT         the demo finished
 *
 * Run it, then click outside the popup. To check it automatically:
 *
 *   DISPLAY=:2 ./target/example_c_popup_dismiss &
 *   DISPLAY=:2 python3 examples/probe_popup_dismiss.py :2
 */
#include <stdio.h>
#include <stdlib.h>
#include "ft.h"

static FtWidget g_popup = NULL;
static FtWidget g_area = NULL;

static void say(const char* line) {
    printf("%s\n", line);
    fflush(stdout);
}

static void on_area_paint(FtWidget area, FtCanvas canvas, void* user_data) {
    (void)area;
    (void)user_data;
    /* A flat fill, so the popup is visibly a surface rather than a hole. */
    ft_canvas_draw_rect(canvas, 0, 0, 300, 200, 0.16, 0.18, 0.24, 1.0);
    ft_canvas_draw_rect(canvas, 24, 24, 252, 152, 0.28, 0.34, 0.46, 1.0);
}

static void on_area_mouse_down(FtWidget area, int32_t x, int32_t y, int32_t button,
                               void* user_data) {
    (void)area;
    (void)x;
    (void)y;
    (void)button;
    (void)user_data;
    say("CLICK");
}

static void on_dismiss(void* user_data) {
    (void)user_data;
    say("DISMISSED");
    if (g_popup != NULL) {
        ft_widget_hide(g_popup);
    }
}

static void on_main_click(FtWidget window, int32_t x, int32_t y, int32_t button,
                          void* user_data) {
    (void)window;
    (void)x;
    (void)y;
    (void)button;
    (void)user_data;
    if (g_popup == NULL) {
        return;
    }
    /* Reopen so the probe can check Escape after having checked the outside click. The
       click that dismissed the popup never reaches this handler: the popup held the
       pointer grab, so it was reported there instead. */
    ft_widget_show(g_popup);
    ft_window_grab_popup_input(g_popup);
    say("READY");
}

static void open_popup(void) {
    g_popup = ft_window_create(300, 200, "");
    if (g_popup == NULL) {
        say("FAILED to create the popup");
        return;
    }

    /* Popup type gives override-redirect, so no window manager frames it. */
    ft_window_set_window_type(g_popup, FT_WINDOW_TYPE_POPUP_MENU);
    ft_window_set_borderless(g_popup, 1);

    g_area = ft_drawingarea_create(g_popup, 0, 0, 300, 200);
    ft_drawingarea_on_paint(g_area, on_area_paint, NULL);
    ft_drawingarea_on_mouse_down(g_area, on_area_mouse_down, NULL);
    ft_widget_show(g_area);

    ft_window_set_position(g_popup, 220, 180);
    ft_widget_show(g_popup);

    ft_window_on_popup_dismiss(g_popup, on_dismiss, NULL);

    /* Show() maps the window on this same connection and the server handles requests in
       order, so the map is already processed by the time the grab is handled. */
    ft_window_grab_popup_input(g_popup);

    say("READY");
}

int main(int argc, char** argv) {
    (void)argc;
    (void)argv;

    ft_init();
    ft_theme_load_dir("themes");

    FtWidget win = ft_window_create(520, 360, "Popup dismiss demo");
    if (win == NULL) {
        say("FAILED to create the window");
        return 1;
    }
    ft_window_on_mouse_down(win, on_main_click, NULL);
    ft_widget_show(win);

    open_popup();
    ft_main_loop();

    say("EXIT");
    return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ft.h"

static FtWidget g_window = NULL;
static FtWidget g_status_label = NULL;
static FtWidget g_context_menu = NULL;

static void set_status(const char* msg) {
    if (g_status_label) {
        char buf[256];
        snprintf(buf, sizeof(buf), "Status: %s", msg);
        ft_text_set_text(g_status_label, buf);
    }
    printf("[OUTSIDE DEMO] %s\n", msg);
}

static void on_menu_action(FtMenuItem item, void* user_data) {
    const char* action_name = (const char*)user_data;
    if (action_name) {
        set_status(action_name);
    } else {
        const char* cap = ft_menu_item_get_caption(item);
        set_status(cap ? cap : "Action triggered");
    }
}

static void on_toggle_dark(FtMenuItem item, void* user_data) {
    int32_t is_dark = ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(!is_dark);
    set_status(!is_dark ? "Dark mode active" : "Light mode active");
}

static void on_menu_exit(FtMenuItem item, void* user_data) {
    printf("[OUTSIDE DEMO] Exiting...\n");
    ft_quit();
}

int main(int argc, char** argv) {
    printf("[OUTSIDE DEMO] Starting Floria Toolkit Outside-Window Menu Demo...\n");
    ft_init();
    ft_theme_load_dir("themes");

    /* Create a compact 480x180 window specifically to demonstrate menus
       extending outside the parent window bounds onto the desktop */
    g_window = ft_window_create(480, 180, "Floria Toolkit - Menus Outside Window Demo");

    /* Set window position explicitly */
    ft_window_set_position(g_window, 150, 200);

    /* 1. Main Menu Bar */
    FtWidget main_menu = ft_main_menu_create(g_window);

    /* File Menu (approx 212px tall, window is only 180px tall -> extends outside!) */
    FtWidget file_menu = ft_main_menu_add_menu(main_menu, "File");
    FtMenuItem item_new = ft_popup_menu_add_item(file_menu, "New File", on_menu_action, (void*)"File -> New File");
    ft_menu_item_set_shortcut(item_new, "Ctrl+N");

    FtMenuItem item_open = ft_popup_menu_add_item(file_menu, "Open File...", on_menu_action, (void*)"File -> Open File...");
    ft_menu_item_set_shortcut(item_open, "Ctrl+O");

    FtMenuItem item_save = ft_popup_menu_add_item(file_menu, "Save", on_menu_action, (void*)"File -> Save");
    ft_menu_item_set_shortcut(item_save, "Ctrl+S");

    ft_popup_menu_add_separator(file_menu);

    /* Recent Files Cascading Submenu (extends outside to the right of the File menu) */
    FtWidget recent_menu = ft_popup_menu_create(file_menu);
    ft_popup_menu_add_item(recent_menu, "outside_menu.c", on_menu_action, (void*)"outside_menu.c");
    ft_popup_menu_add_item(recent_menu, "ft.backend.x11.pas", on_menu_action, (void*)"ft.backend.x11.pas");
    ft_popup_menu_add_item(recent_menu, "ft.widget.menus.pas", on_menu_action, (void*)"ft.widget.menus.pas");
    ft_popup_menu_add_submenu(file_menu, "Recent Projects", recent_menu);

    ft_popup_menu_add_separator(file_menu);
    FtMenuItem item_exit = ft_popup_menu_add_item(file_menu, "Exit Demo", on_menu_exit, NULL);
    ft_menu_item_set_shortcut(item_exit, "Ctrl+Q");

    /* Edit Menu */
    FtWidget edit_menu = ft_main_menu_add_menu(main_menu, "Edit");
    ft_popup_menu_add_item(edit_menu, "Undo", on_menu_action, (void*)"Edit -> Undo");
    ft_popup_menu_add_item(edit_menu, "Redo", on_menu_action, (void*)"Edit -> Redo");
    ft_popup_menu_add_separator(edit_menu);
    ft_popup_menu_add_item(edit_menu, "Cut", on_menu_action, (void*)"Edit -> Cut");
    ft_popup_menu_add_item(edit_menu, "Copy", on_menu_action, (void*)"Edit -> Copy");
    ft_popup_menu_add_item(edit_menu, "Paste", on_menu_action, (void*)"Edit -> Paste");

    /* View Menu */
    FtWidget view_menu = ft_main_menu_add_menu(main_menu, "View");
    ft_popup_menu_add_check_item(view_menu, "Toggle Dark Theme", ft_theme_get_dark_mode(), on_toggle_dark, NULL);

    /* Window-level context menu */
    g_context_menu = ft_popup_menu_create(g_window);
    ft_popup_menu_add_item(g_context_menu, "Inspect Screen Coordinates", on_menu_action, (void*)"Context -> Coordinates");
    ft_popup_menu_add_item(g_context_menu, "Toggle Dark Theme", on_toggle_dark, NULL);
    ft_popup_menu_add_separator(g_context_menu);
    ft_popup_menu_add_item(g_context_menu, "Close Application", on_menu_exit, NULL);
    ft_window_set_context_menu(g_window, g_context_menu);

    /* Window Body UI */
    FtWidget title = ft_text_create(g_window, 20, 36, 440, 24, "Menus Extend Outside Window Demo");
    ft_widget_set_font(title, "Inter:size=11:bold");

    FtWidget desc = ft_text_create(g_window, 20, 64, 440, 36,
        "Notice this window is only 180px tall. Opening 'File' or right-clicking\n"
        "near the bottom edge extends seamlessly outside onto the desktop!");
    ft_widget_set_font(desc, "Inter:size=9.5");

    g_status_label = ft_text_create(g_window, 20, 108, 440, 24, "Status: Ready (Open File menu or right-click near edges)");
    ft_widget_set_font(g_status_label, "Inter:size=10:bold");
    ft_text_set_color(g_status_label, 0.15, 0.45, 0.90);

    FtWidget hint = ft_text_create(g_window, 20, 140, 440, 20, "Right-click anywhere near bottom or right edge ->");
    ft_widget_set_font(hint, "Inter:size=9");

    /* Show window */
    ft_widget_show(g_window);

    printf("[OUTSIDE DEMO] Main loop starting...\n");
    ft_main_loop();

    return 0;
}

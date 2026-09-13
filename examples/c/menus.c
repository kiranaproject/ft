#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ft.h"

static FtWidget g_window = NULL;
static FtWidget g_status_label = NULL;
static FtWidget g_context_menu = NULL;
static FtWidget g_widget_menu = NULL;
static FtMenuItem g_item_status_bar = NULL;
static FtMenuItem g_item_line_nums = NULL;
static FtMenuItem g_item_dark_mode = NULL;

static void set_status(const char* msg) {
    if (g_status_label) {
        char buf[256];
        snprintf(buf, sizeof(buf), "Last Action: %s", msg);
        ft_text_set_text(g_status_label, buf);
    }
    printf("[MENU DEMO] %s\n", msg);
}

static void on_menu_action(FtMenuItem item, void* user_data) {
    const char* action_name = (const char*)user_data;
    if (action_name) {
        set_status(action_name);
    } else {
        const char* cap = ft_menu_item_get_caption(item);
        set_status(cap ? cap : "Menu item clicked");
    }
}

static void on_toggle_dark_mode(FtMenuItem item, void* user_data) {
    int32_t is_dark = ft_theme_get_dark_mode();
    int32_t new_dark = !is_dark;
    ft_theme_set_dark_mode(new_dark);
    if (g_item_dark_mode)
        ft_menu_item_set_checked(g_item_dark_mode, new_dark);
    set_status(new_dark ? "Dark Mode Enabled" : "Light Mode Enabled");
}

static void on_theme_select(FtMenuItem item, void* user_data) {
    const char* theme_name = (const char*)user_data;
    if (theme_name) {
        ft_theme_set(theme_name);
        char buf[128];
        snprintf(buf, sizeof(buf), "Applied Theme: %s", theme_name);
        set_status(buf);
    }
}

static void on_toggle_view_option(FtMenuItem item, void* user_data) {
    const char* opt_name = (const char*)user_data;
    int32_t checked = ft_menu_item_get_checked(item);
    char buf[128];
    snprintf(buf, sizeof(buf), "%s: %s", opt_name, checked ? "Checked" : "Unchecked");
    set_status(buf);
}

static void on_menu_exit(FtMenuItem item, void* user_data) {
    printf("[MENU DEMO] Exiting application from menu...\n");
    ft_quit();
}

static void on_show_popup_btn(FtWidget btn, void* user_data) {
    /* Explicitly trigger popup menu at fixed coordinates */
    if (g_context_menu) {
        ft_popup_menu_show(g_context_menu, 260, 220);
        set_status("Triggered Popup Menu programmatically at (260, 220)");
    }
}

int main(int argc, char** argv) {
    printf("[MENU DEMO] Initializing Floria Toolkit Menu Demo...\n");
    ft_init();

    /* Load themes if directory exists */
    ft_theme_load_dir("themes");

    /* Create 800x600 main window */
    g_window = ft_window_create(800, 600, "Floria Toolkit - Window Main Menu & Pop-up Menu Demo");

    /* 1. Create Window Main Menu Bar */
    FtWidget main_menu = ft_main_menu_create(g_window);

    /* --- File Menu --- */
    FtWidget file_menu = ft_main_menu_add_menu(main_menu, "File");
    FtMenuItem item_new = ft_popup_menu_add_item(file_menu, "New Project", on_menu_action, (void*)"File -> New Project");
    ft_menu_item_set_shortcut(item_new, "Ctrl+N");

    FtMenuItem item_open = ft_popup_menu_add_item(file_menu, "Open...", on_menu_action, (void*)"File -> Open...");
    ft_menu_item_set_shortcut(item_open, "Ctrl+O");

    FtMenuItem item_save = ft_popup_menu_add_item(file_menu, "Save", on_menu_action, (void*)"File -> Save");
    ft_menu_item_set_shortcut(item_save, "Ctrl+S");

    ft_popup_menu_add_separator(file_menu);

    /* Recent Files Cascading Submenu */
    FtWidget recent_menu = ft_popup_menu_create(file_menu);
    ft_popup_menu_add_item(recent_menu, "floria_core.pas", on_menu_action, (void*)"Opened floria_core.pas");
    ft_popup_menu_add_item(recent_menu, "widget_menus.pas", on_menu_action, (void*)"Opened widget_menus.pas");
    ft_popup_menu_add_item(recent_menu, "libft_export.c", on_menu_action, (void*)"Opened libft_export.c");
    ft_popup_menu_add_submenu(file_menu, "Recent Files", recent_menu);

    ft_popup_menu_add_separator(file_menu);
    FtMenuItem item_exit = ft_popup_menu_add_item(file_menu, "Exit", on_menu_exit, NULL);
    ft_menu_item_set_shortcut(item_exit, "Ctrl+Q");

    /* --- Edit Menu --- */
    FtWidget edit_menu = ft_main_menu_add_menu(main_menu, "Edit");
    FtMenuItem item_undo = ft_popup_menu_add_item(edit_menu, "Undo", on_menu_action, (void*)"Edit -> Undo");
    ft_menu_item_set_shortcut(item_undo, "Ctrl+Z");
    FtMenuItem item_redo = ft_popup_menu_add_item(edit_menu, "Redo", on_menu_action, (void*)"Edit -> Redo");
    ft_menu_item_set_shortcut(item_redo, "Ctrl+Y");
    ft_popup_menu_add_separator(edit_menu);
    FtMenuItem item_cut = ft_popup_menu_add_item(edit_menu, "Cut", on_menu_action, (void*)"Edit -> Cut");
    ft_menu_item_set_shortcut(item_cut, "Ctrl+X");
    FtMenuItem item_copy = ft_popup_menu_add_item(edit_menu, "Copy", on_menu_action, (void*)"Edit -> Copy");
    ft_menu_item_set_shortcut(item_copy, "Ctrl+C");
    FtMenuItem item_paste = ft_popup_menu_add_item(edit_menu, "Paste", on_menu_action, (void*)"Edit -> Paste");
    ft_menu_item_set_shortcut(item_paste, "Ctrl+V");

    /* --- View Menu --- */
    FtWidget view_menu = ft_main_menu_add_menu(main_menu, "View");
    g_item_status_bar = ft_popup_menu_add_check_item(view_menu, "Show Status Bar", 1, on_toggle_view_option, (void*)"Show Status Bar");
    g_item_line_nums = ft_popup_menu_add_check_item(view_menu, "Show Line Numbers", 1, on_toggle_view_option, (void*)"Show Line Numbers");
    g_item_dark_mode = ft_popup_menu_add_check_item(view_menu, "Dark Mode", ft_theme_get_dark_mode(), on_toggle_dark_mode, NULL);
    ft_popup_menu_add_separator(view_menu);

    /* Themes Cascading Submenu */
    FtWidget theme_sub = ft_popup_menu_create(view_menu);
    ft_popup_menu_add_item(theme_sub, "Default (Breeze/Fusion)", on_theme_select, (void*)"default");
    ft_popup_menu_add_item(theme_sub, "Nord Theme", on_theme_select, (void*)"nord");
    ft_popup_menu_add_item(theme_sub, "Dracula Theme", on_theme_select, (void*)"dracula");
    ft_popup_menu_add_item(theme_sub, "Gruvbox Theme", on_theme_select, (void*)"gruvbox");
    ft_popup_menu_add_submenu(view_menu, "Color Themes", theme_sub);

    /* --- Help Menu --- */
    FtWidget help_menu = ft_main_menu_add_menu(main_menu, "Help");
    FtMenuItem item_doc = ft_popup_menu_add_item(help_menu, "Documentation", on_menu_action, (void*)"Help -> Documentation");
    ft_menu_item_set_shortcut(item_doc, "F1");
    ft_popup_menu_add_separator(help_menu);
    ft_popup_menu_add_item(help_menu, "About Floria Toolkit...", on_menu_action, (void*)"Floria Toolkit 1.0 (Feat)");

    /* 2. Create Context Menus (Right-Click) */

    /* Window-level context menu */
    g_context_menu = ft_popup_menu_create(g_window);
    ft_popup_menu_add_item(g_context_menu, "Select All", on_menu_action, (void*)"Context -> Select All");
    ft_popup_menu_add_item(g_context_menu, "Paste Here", on_menu_action, (void*)"Context -> Paste");
    ft_popup_menu_add_separator(g_context_menu);
    ft_popup_menu_add_item(g_context_menu, "Toggle Dark Mode", on_toggle_dark_mode, NULL);
    ft_popup_menu_add_separator(g_context_menu);
    ft_popup_menu_add_item(g_context_menu, "Inspect Window", on_menu_action, (void*)"Window Inspector Opened");
    ft_window_set_context_menu(g_window, g_context_menu);

    /* 3. Build Window Body UI */

    /* Header Title */
    FtWidget title = ft_text_create(g_window, 30, 45, 740, 30, "Floria Toolkit - Window Main Menu & Context Menus");
    ft_widget_set_font(title, "Inter:size=15:bold");

    /* Subtitle / Instructions */
    FtWidget desc = ft_text_create(g_window, 30, 80, 740, 24, 
        "Click menu bar above ('File', 'Edit', 'View', 'Help') or Right-Click anywhere for context menus!");
    ft_widget_set_font(desc, "Inter:size=10");

    /* Status Label displaying last executed action */
    g_status_label = ft_text_create(g_window, 30, 115, 740, 28, "Last Action: Ready (Select a menu item or right-click)");
    ft_widget_set_font(g_status_label, "Inter:size=11:bold");
    ft_text_set_color(g_status_label, 0.15, 0.45, 0.90);

    /* Interactive Container with Widget-Specific Context Menu */
    FtWidget container = ft_container_create(g_window, 30, 160, 460, 280);
    ft_container_set_corner_radius(container, 8.0);
    ft_container_set_draw_frame(container, 1);
    ft_container_set_padding(container, 16, 16);

    FtWidget cont_title = ft_text_create(container, 10, 10, 420, 24, "Right-Click This Box for Custom Context Menu");
    ft_widget_set_font(cont_title, "Inter:size=11:bold");

    FtWidget entry = ft_entry_create(container, 10, 45, 410, 34, "Editable Text Entry (Right click or type)");
    ft_widget_set_font(entry, "Inter:size=10");

    FtWidget textarea = ft_textarea_create(container, 10, 95, 410, 120, 
        "Try the following interactions:\n"
        "1. Click 'File', 'Edit', 'View', or 'Help' in the top menu bar.\n"
        "2. Sweep mouse horizontally across items while open.\n"
        "3. Right-click inside this container or outside in the window.\n"
        "4. Keyboard: Use Up/Down arrow keys and Enter, or Escape to close.");
    ft_widget_set_font(textarea, "Inter:size=10");

    /* Create custom context menu for this container */
    g_widget_menu = ft_popup_menu_create(container);
    ft_popup_menu_add_item(g_widget_menu, "Inspect Container Widget", on_menu_action, (void*)"Container -> Inspect");
    ft_popup_menu_add_item(g_widget_menu, "Clear Container Content", on_menu_action, (void*)"Container -> Clear");
    ft_popup_menu_add_separator(g_widget_menu);
    ft_popup_menu_add_item(g_widget_menu, "Properties...", on_menu_action, (void*)"Container -> Properties");
    ft_widget_set_context_menu(container, g_widget_menu);

    /* Side Control Panel */
    FtWidget btn_popup = ft_button_create(g_window, 510, 160, 250, 40, "Show Context Menu Here");
    ft_button_on_click(btn_popup, on_show_popup_btn, NULL);

    FtWidget btn_dark = ft_button_create(g_window, 510, 215, 250, 40, "Toggle Dark / Light Theme");
    ft_button_on_click(btn_dark, (FtClickCallback)on_toggle_dark_mode, NULL);

    FtWidget btn_nord = ft_button_create(g_window, 510, 270, 250, 36, "Switch to Nord Theme");
    ft_button_on_click(btn_nord, (FtClickCallback)on_theme_select, (void*)"nord");

    FtWidget btn_dracula = ft_button_create(g_window, 510, 315, 250, 36, "Switch to Dracula Theme");
    ft_button_on_click(btn_dracula, (FtClickCallback)on_theme_select, (void*)"dracula");

    FtWidget btn_default = ft_button_create(g_window, 510, 360, 250, 36, "Switch to Default Theme");
    ft_button_on_click(btn_default, (FtClickCallback)on_theme_select, (void*)"default");

    /* Bottom Info Card */
    FtWidget info_box = ft_container_create(g_window, 30, 460, 740, 90);
    ft_container_set_corner_radius(info_box, 6.0);
    ft_container_set_draw_frame(info_box, 1);
    ft_container_set_padding(info_box, 12, 10);

    FtWidget info_txt = ft_text_create(info_box, 10, 8, 700, 60,
        "Vector AGG Menu Capabilities:\n"
        " - Dropdown menus with drop shadow, theme rounded corners, and smooth hover pill highlights\n"
        " - Cascading submenus with auto-clamping to screen edges and smooth navigation\n"
        " - Checkable toggle items with crisp AGG checkmarks and shortcut key hints");
    ft_widget_set_font(info_txt, "Inter:size=9.5");

    /* Show window */
    ft_widget_show(g_window);

    /* Run Floria event loop */
    printf("[MENU DEMO] Starting main loop...\n");
    ft_main_loop();

    return 0;
}

/**
 * file_dialog.c -- Demonstrates TFtFileDialog (Open File, Save File, Select Folder)
 *
 * Build:
 *   cd <repo>
 *   ./build_examples.sh
 *
 * Run:
 *   DISPLAY=:0 LD_LIBRARY_PATH=../../target ./file_dialog
 */
#include <stdio.h>
#include <string.h>
#include "../../include/ft.h"

/* ABI forward declarations (not yet in ft.h) */
extern void* ft_text_create(void* parent, int x, int y, int w, int h, const char* text);
extern void  ft_text_set_text(void* widget, const char* text);

/* -- Globals -- */
static void* g_lbl_result = NULL;
static void* g_btn_open   = NULL;
static void* g_btn_save   = NULL;
static void* g_btn_folder = NULL;

/* -- Callbacks -- */
static void on_btn_open(void* sender, void* user_data) {
    void* dlg = ft_file_dialog_create(FT_DIALOG_OPEN_FILE);
    ft_file_dialog_set_filter(dlg, "All Files (*.*)");

    int ok = ft_file_dialog_show_modal(dlg);
    if (ok) {
        const char* path = ft_file_dialog_get_selected_path(dlg);
        printf("Open: %s\n", path ? path : "(none)");
        if (path) ft_text_set_text(g_lbl_result, path);
    } else {
        printf("Open: cancelled\n");
        ft_text_set_text(g_lbl_result, "(cancelled)");
    }
    ft_file_dialog_destroy(dlg);
}

static void on_btn_save(void* sender, void* user_data) {
    void* dlg = ft_file_dialog_create(FT_DIALOG_SAVE_FILE);
    ft_file_dialog_set_default_name(dlg, "untitled.txt");
    ft_file_dialog_set_filter(dlg, "Text Files (*.txt)");

    int ok = ft_file_dialog_show_modal(dlg);
    if (ok) {
        const char* path = ft_file_dialog_get_selected_path(dlg);
        printf("Save: %s\n", path ? path : "(none)");
        if (path) ft_text_set_text(g_lbl_result, path);
    } else {
        printf("Save: cancelled\n");
        ft_text_set_text(g_lbl_result, "(cancelled)");
    }
    ft_file_dialog_destroy(dlg);
}

static void on_btn_folder(void* sender, void* user_data) {
    void* dlg = ft_file_dialog_create(FT_DIALOG_SELECT_FOLDER);

    int ok = ft_file_dialog_show_modal(dlg);
    if (ok) {
        const char* path = ft_file_dialog_get_selected_path(dlg);
        printf("Folder: %s\n", path ? path : "(none)");
        if (path) ft_text_set_text(g_lbl_result, path);
    } else {
        printf("Folder: cancelled\n");
        ft_text_set_text(g_lbl_result, "(cancelled)");
    }
    ft_file_dialog_destroy(dlg);
}

static void on_dark_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(checked);
}

int main(void) {
    ft_init();

    void* window = ft_window_create(560, 260, "File Dialog Demo");
    /* Root VBox Container */
    FtWidget root_vbox = ft_vbox_create(window, 0, 0, 560, 260);
    ft_flexbox_set_gap(root_vbox, 14.0);
    ft_container_set_padding(root_vbox, 20, 20);
    ft_window_set_layout(window, root_vbox);

    /* Row 1: Header (Title + Spacer + Dark Mode Switch) */
    FtWidget top_hbox = ft_hbox_create(root_vbox, 0, 0, 520, 32);
    ft_widget_set_flex_grow(top_hbox, 0.0);
    ft_flexbox_set_align_items(top_hbox, FT_ALIGN_CENTER);

    FtWidget title_lbl = ft_text_create(top_hbox, 0, 0, 180, 30, "File Dialog Demo");
    ft_widget_set_flex_grow(title_lbl, 0.0);

    FtWidget title_spacer = ft_spacer_create(top_hbox);
    ft_widget_set_flex_grow(title_spacer, 1.0);

    FtWidget sw_dark = ft_switch_create(top_hbox, 0, 0, 130, 26, "Dark Mode");
    ft_widget_set_flex_grow(sw_dark, 0.0);
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_toggle, NULL);

    /* Row 2: Result Label */
    g_lbl_result = ft_text_create(root_vbox, 0, 0, 520, 28, "No file selected yet.");
    ft_widget_set_flex_grow(g_lbl_result, 0.0);

    /* Row 3: Action Buttons (stretching evenly with flex-grow: 1.0) */
    FtWidget btn_hbox = ft_hbox_create(root_vbox, 0, 0, 520, 42);
    ft_widget_set_flex_grow(btn_hbox, 0.0);
    ft_flexbox_set_gap(btn_hbox, 12.0);

    g_btn_open = ft_button_create(btn_hbox, 0, 0, 150, 40, "Open File...");
    ft_widget_set_flex_grow(g_btn_open, 1.0);
    ft_button_on_click(g_btn_open, on_btn_open, NULL);

    g_btn_save = ft_button_create(btn_hbox, 0, 0, 150, 40, "Save File...");
    ft_widget_set_flex_grow(g_btn_save, 1.0);
    ft_button_on_click(g_btn_save, on_btn_save, NULL);

    g_btn_folder = ft_button_create(btn_hbox, 0, 0, 170, 40, "Select Folder...");
    ft_widget_set_flex_grow(g_btn_folder, 1.0);
    ft_button_on_click(g_btn_folder, on_btn_folder, NULL);

    /* Row 4: Footer Hint */
    FtWidget hint_lbl = ft_text_create(root_vbox, 0, 0, 520, 24, "Toggle Dark Mode above to launch file dialogs in dark or light theme.");
    ft_widget_set_flex_grow(hint_lbl, 0.0);

    /* Initial layout calculation */
    ft_flexbox_update_layout(root_vbox);
    ft_widget_show(window);

    ft_main_loop();

    return 0;
}

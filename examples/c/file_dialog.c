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

int main(void) {
    ft_init();

    void* window = ft_window_create(520, 300, "File Dialog Demo");
    ft_widget_show(window);

    /* Heading */
    ft_text_create(window, 20, 20, 480, 32, "File Dialog Demo");

    /* Result label */
    g_lbl_result = ft_text_create(window, 20, 64, 480, 28, "No file selected yet.");

    /* Buttons */
    g_btn_open = ft_button_create(window, 20, 130, 140, 40, "Open File...");
    ft_button_on_click(g_btn_open, on_btn_open, NULL);

    g_btn_save = ft_button_create(window, 180, 130, 140, 40, "Save File...");
    ft_button_on_click(g_btn_save, on_btn_save, NULL);

    g_btn_folder = ft_button_create(window, 340, 130, 160, 40, "Select Folder...");
    ft_button_on_click(g_btn_folder, on_btn_folder, NULL);

    ft_main_loop();

    return 0;
}

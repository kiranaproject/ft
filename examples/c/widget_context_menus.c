#include "ft.h"
#include <stdio.h>
#include <string.h>

static FtWidget s_status_lbl = NULL;

static void on_custom_menu_action(FtWidget item, void* user_data) {
    (void)item;
    const char* action_name = (const char*)user_data;
    printf("[Widget Context Menu Demo] Custom menu clicked: %s\n", action_name ? action_name : "");
    if (s_status_lbl) {
        char buf[256];
        snprintf(buf, sizeof(buf), "Custom Menu: %s", action_name ? action_name : "");
        ft_text_set_text(s_status_lbl, buf);
    }
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    printf("[Widget Context Menu Demo] Starting...\n");

    FtWidget win = ft_window_create(640, 620, "Floria Toolkit - Default Widget Popup Menus Demo");

    // 1. Selectable Text Label
    FtWidget lbl_sel_title = ft_text_create(win, 30, 20, 580, 22, "1. Selectable Text (TFtText with Selectable = 1):");
    ft_text_set_selectable(lbl_sel_title, 0);

    FtWidget txt_selectable = ft_text_create(win, 30, 46, 580, 28, "Right-click me! Select All & Copy are enabled when selected; Cut, Paste, Del are greyed out.");
    ft_text_set_selectable(txt_selectable, 1);

    // 2. Non-Selectable Text Label (bubbles up to window/parent context menu)
    FtWidget lbl_nonsel_title = ft_text_create(win, 30, 84, 580, 22, "2. Non-Selectable Text (Selectable = 0, bubbles up to Window Menu):");
    ft_text_set_selectable(lbl_nonsel_title, 0);

    FtWidget txt_non_selectable = ft_text_create(win, 30, 110, 580, 28, "Right-clicking this label will show the Window Context Menu (bubbles up).");
    ft_text_set_selectable(txt_non_selectable, 0);

    // 3. Editable Entry
    FtWidget lbl_entry_title = ft_text_create(win, 30, 148, 580, 22, "3. Editable Single-Line Entry (TFtEntry, ReadOnly = 0):");
    ft_text_set_selectable(lbl_entry_title, 0);

    FtWidget entry_editable = ft_entry_create(win, 30, 174, 580, 36, "Editable text inside TFtEntry - right click here!");

    // 4. Read-Only Entry
    FtWidget lbl_entry_ro_title = ft_text_create(win, 30, 220, 580, 22, "4. Read-Only Single-Line Entry (TFtEntry, ReadOnly = 1):");
    ft_text_set_selectable(lbl_entry_ro_title, 0);

    FtWidget entry_readonly = ft_entry_create(win, 30, 246, 580, 36, "Read-only TFtEntry content (Cut, Paste, Delete greyed out).");
    ft_entry_set_readonly(entry_readonly, 1);

    // 5. Editable TextArea
    FtWidget lbl_ta_title = ft_text_create(win, 30, 292, 580, 22, "5. Editable Multi-Line TextArea (TFtTextArea, ReadOnly = 0):");
    ft_text_set_selectable(lbl_ta_title, 0);

    FtWidget ta_editable = ft_textarea_create(win, 30, 318, 580, 90,
        "Line 1: Editable TFtTextArea with full context menu support.\n"
        "Line 2: Select text and right-click to test Cut, Copy, Delete.\n"
        "Line 3: Right-click with empty selection tests Paste & Select All.");

    // 6. Read-Only TextArea
    FtWidget lbl_ta_ro_title = ft_text_create(win, 30, 418, 580, 22, "6. Read-Only Multi-Line TextArea (TFtTextArea, ReadOnly = 1):");
    ft_text_set_selectable(lbl_ta_ro_title, 0);

    FtWidget ta_readonly = ft_textarea_create(win, 30, 444, 580, 90,
        "Line 1: Read-Only TFtTextArea content.\n"
        "Line 2: Cut, Paste, and Delete are permanently disabled/greyed out.\n"
        "Line 3: Select All and Copy remain fully operational.");
    ft_textarea_set_readonly(ta_readonly, 1);

    // Status label at the bottom
    s_status_lbl = ft_text_create(win, 30, 548, 580, 24, "Ready. Right-click any widget above to test its context menu.");
    ft_text_set_selectable(s_status_lbl, 1);

    // Attach a custom Window context menu to verify that non-selectable text bubbles up!
    FtWidget win_menu = ft_popup_menu_create(win);
    ft_popup_menu_add_item(win_menu, "Window Action: Inspect Background", on_custom_menu_action, (void*)"Window Background Inspected");
    ft_popup_menu_add_separator(win_menu);
    ft_popup_menu_add_item(win_menu, "Window Action: Refresh Canvas", on_custom_menu_action, (void*)"Window Canvas Refreshed");
    ft_window_set_context_menu(win, win_menu);

    ft_widget_show(win);
    ft_main_loop();

    return 0;
}

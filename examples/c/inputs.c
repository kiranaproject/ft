#include "ft.h"
#include <stdio.h>
#include <string.h>

static FtWidget s_lbl_status = NULL;

static const char* s_demo_themes[] = {"default", "nord", "dracula", "gruvbox", "gtk2", "classic"};
static const int s_demo_theme_count = 6;
static int s_current_theme_index = 0;

void on_theme_cycle_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    s_current_theme_index = (s_current_theme_index + 1) % s_demo_theme_count;
    const char* target = s_demo_themes[s_current_theme_index];
    printf("[Floria Toolkit Input Demo] Switching to theme '%s'...\n", target);
    ft_theme_set(target);
}

void on_dark_mode_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    int next_dark = !ft_theme_get_dark_mode();
    printf("[Floria Toolkit Input Demo] Toggling Dark Mode -> %s\n", next_dark ? "ON" : "OFF");
    ft_theme_set_dark_mode(next_dark);
}

void on_entry_change(FtWidget widget, const char* text, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit Input Demo] [%s] Changed: '%s'\n", (char*)user_data, text ? text : "");
}

void on_entry_submit(FtWidget widget, const char* text, void* user_data) {
    (void)widget;
    printf("[Floria Toolkit Input Demo] [%s] Submitted: '%s'\n", (char*)user_data, text ? text : "");
    if (s_lbl_status) {
        char buf[256];
        snprintf(buf, sizeof(buf), "Submitted: %s", (text && *text) ? text : "(empty)");
        ft_text_set_text(s_lbl_status, buf);
    }
}

void on_textarea_change(FtWidget widget, const char* text, void* user_data) {
    (void)widget;
    (void)user_data;
    printf("[Floria Toolkit Input Demo] TextArea Content Length: %zu chars\n", text ? strlen(text) : 0);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    ft_init();

    printf("[Floria Toolkit Input Demo] Initializing Text Input Showcase...\n");
    printf("[Floria Toolkit Input Demo] Active Theme: %s | System Font: %s\n", 
           ft_theme_get(), ft_system_font_get());

    FtWidget win = ft_window_create(520, 480, "Floria Toolkit - Text Inputs (Entry & TextArea)");

    // Section 1: Header
    FtWidget lbl_header = ft_text_create(win, 30, 16, 460, 22, "Floria Toolkit Native Text Input Controls");
    ft_text_set_selectable(lbl_header, 0);

    // Section 2: Inline Single-Line Text Entry (GtkEntry / QLineEdit)
    FtWidget lbl_entry1 = ft_text_create(win, 30, 46, 460, 20, "Single-Line Entry (GtkEntry / QLineEdit):");
    ft_text_set_selectable(lbl_entry1, 0);

    FtWidget entry1 = ft_entry_create(win, 30, 70, 460, 36, "Floria Toolkit native vector input box");
    ft_entry_on_change(entry1, on_entry_change, (void*)"Entry1");
    ft_entry_on_submit(entry1, on_entry_submit, (void*)"Entry1");

    FtWidget lbl_entry2 = ft_text_create(win, 30, 114, 460, 20, "Entry with Placeholder:");
    ft_text_set_selectable(lbl_entry2, 0);

    FtWidget entry2 = ft_entry_create(win, 30, 138, 460, 36, "");
    ft_entry_set_placeholder(entry2, "Type here and press Enter to submit...");
    ft_entry_on_change(entry2, on_entry_change, (void*)"Entry2");
    ft_entry_on_submit(entry2, on_entry_submit, (void*)"Entry2");

    // Section 3: Multi-Line Text Area (GtkTextView / QTextEdit)
    FtWidget lbl_textarea = ft_text_create(win, 30, 184, 460, 20, "Multi-Line Text Area (GtkTextView / QTextEdit):");
    ft_text_set_selectable(lbl_textarea, 0);

    const char* sample_text = 
        "Welcome to Floria Toolkit (Ft) multi-line text area!\n"
        "Features supported:\n"
        "  - Enter key inserts newlines\n"
        "  - Arrow keys navigate across lines\n"
        "  - Mouse click & drag multi-line selection\n"
        "  - Ctrl+A (Select All), Ctrl+C (Copy), Ctrl+X (Cut), Ctrl+V (Paste)\n"
        "  - Automatic vertical scrolling with custom scroll indicator\n"
        "  - Theme-aware focus ring and background plates";

    FtWidget textarea = ft_textarea_create(win, 30, 208, 460, 150, sample_text);
    ft_textarea_on_change(textarea, on_textarea_change, (void*)"TextArea");

    // Section 4: Status feedback
    s_lbl_status = ft_text_create(win, 30, 368, 460, 22, "Submitted: (press Enter in an Entry to submit)");
    ft_text_set_selectable(s_lbl_status, 1);

    // Section 5: Theme controls
    FtWidget btn_theme = ft_button_create(win, 30, 404, 215, 42, "Cycle Theme");
    ft_button_on_click(btn_theme, on_theme_cycle_click, NULL);

    FtWidget btn_dark = ft_button_create(win, 275, 404, 215, 42, "Toggle Dark Mode");
    ft_button_on_click(btn_dark, on_dark_mode_click, NULL);

    ft_widget_show(win);
    ft_main_loop();

    return 0;
}

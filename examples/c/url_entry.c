#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ft.h"

static FtWidget s_url_main = NULL;
static FtWidget s_url_insecure = NULL;
static FtWidget s_url_internal = NULL;
static FtWidget s_lbl_submit = NULL;
static FtWidget s_lbl_event = NULL;

static void on_url_submitted(FtWidget url_entry, const char* url, void* user_data) {
    (void)url_entry; (void)user_data;
    char buf[512];
    snprintf(buf, sizeof(buf), "Submitted URL: %s", url ? url : "");
    if (s_lbl_submit)
        ft_text_set_text(s_lbl_submit, buf);
    printf("[UrlEntry] %s\n", buf);
}

static void on_security_clicked(FtWidget url_entry, int32_t security_state, void* user_data) {
    (void)url_entry; (void)user_data;
    const char* state_str = "Secure (HTTPS)";
    if (security_state == FT_URL_SECURITY_INSECURE)
        state_str = "Not Secure (Plain HTTP)";
    else if (security_state == FT_URL_SECURITY_INTERNAL)
        state_str = "Floria Internal Page";
    else if (security_state == FT_URL_SECURITY_FILE)
        state_str = "Local File (file://)";

    char buf[256];
    snprintf(buf, sizeof(buf), "Event: Security Chip Clicked (%s)", state_str);
    if (s_lbl_event)
        ft_text_set_text(s_lbl_event, buf);
    printf("[UrlEntry] %s\n", buf);
}

static void on_bookmark_clicked(FtWidget url_entry, int32_t bookmarked, void* user_data) {
    (void)url_entry; (void)user_data;
    char buf[256];
    snprintf(buf, sizeof(buf), "Event: Bookmark Toggled -> %s", bookmarked ? "★ Starred" : "☆ Unstarred");
    if (s_lbl_event)
        ft_text_set_text(s_lbl_event, buf);
    printf("[UrlEntry] %s\n", buf);
}

static void on_action_clicked(FtWidget url_entry, int32_t action_id, void* user_data) {
    (void)url_entry; (void)user_data;
    const char* act_name = "Unknown";
    if (action_id == FT_URL_ACTION_BOOKMARK)
        act_name = "Bookmark";

    char buf[256];
    snprintf(buf, sizeof(buf), "Event: Action Clicked -> %s", act_name);
    if (s_lbl_event)
        ft_text_set_text(s_lbl_event, buf);
    printf("[UrlEntry] %s\n", buf);
}

static void on_load_github(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_url_main) {
        ft_url_entry_set_url(s_url_main, "https://github.com/floria/floria-toolkit?tab=readme-ov-file#installation");
        on_url_submitted(s_url_main, "https://github.com/floria/floria-toolkit?tab=readme-ov-file#installation", NULL);
    }
}

static void on_load_internal(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_url_main) {
        ft_url_entry_set_url(s_url_main, "floria://settings/appearance");
        on_url_submitted(s_url_main, "floria://settings/appearance", NULL);
    }
}

static void on_toggle_star(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    if (s_url_main) {
        int32_t bm = ft_url_entry_get_bookmarked(s_url_main);
        ft_url_entry_set_bookmarked(s_url_main, !bm);
        on_bookmark_clicked(s_url_main, !bm, NULL);
    }
}

static void on_theme_toggle(FtWidget btn, void* user_data) {
    (void)btn; (void)user_data;
    int is_dark = ft_theme_get_dark_mode();
    ft_theme_set_dark_mode(!is_dark);
}

int main(int argc, char* argv[]) {
    (void)argc; (void)argv;

    ft_init();

    FtWidget win = ft_window_create(720, 560, "Floria Toolkit — Chrome-style URL Entry (Omnibox)");
    if (!win) {
        fprintf(stderr, "Failed to create window.\n");
        return 1;
    }

    /* Header */
    FtWidget title = ft_text_create(win, 24, 18, 672, 26, "Chrome-Style Omnibox URL Entry (TFtUrlEntry)");
    ft_widget_set_font(title, "Sans Bold 16");

    FtWidget desc1 = ft_text_create(win, 24, 46, 672, 18, 
        "Domain-contrast highlighting: domain pops in full contrast while scheme and path are dimmed.");
    ft_widget_set_font(desc1, "Sans 10");

    FtWidget desc2 = ft_text_create(win, 24, 66, 672, 18, 
        "Click the URL to edit with inline selection, or click the lock chip or trailing bookmark star.");
    ft_widget_set_font(desc2, "Sans 10");

    /* 1. Main Secure HTTPS URL Bar */
    FtWidget lbl1 = ft_text_create(win, 24, 96, 672, 20, "1. Secure HTTPS URL (Notice high-contrast host vs dimmed scheme/path):");
    ft_widget_set_font(lbl1, "Sans Bold 11");

    s_url_main = ft_url_entry_create(win, 24, 120, 672, 38, 
        "https://github.com/floria/floria-toolkit?tab=readme-ov-file#installation");
    ft_url_entry_on_submit(s_url_main, on_url_submitted, NULL);
    ft_url_entry_on_security_click(s_url_main, on_security_clicked, NULL);
    ft_url_entry_on_bookmark_click(s_url_main, on_bookmark_clicked, NULL);
    ft_url_entry_on_action_click(s_url_main, on_action_clicked, NULL);

    /* Event status indicators */
    s_lbl_submit = ft_text_create(win, 24, 164, 672, 18, 
        "Submitted URL: https://github.com/floria/floria-toolkit?tab=readme-ov-file#installation");
    ft_widget_set_font(s_lbl_submit, "Monospace 9");

    s_lbl_event = ft_text_create(win, 24, 184, 672, 18, "Event: Ready (Click chip or action buttons)");
    ft_widget_set_font(s_lbl_event, "Sans Italic 9");

    /* Quick Preset Navigation Buttons */
    FtWidget lbl_presets = ft_text_create(win, 24, 212, 672, 20, "Quick Presets & Actions:");
    ft_widget_set_font(lbl_presets, "Sans Bold 11");

    FtWidget btn_gh = ft_button_create(win, 24, 236, 115, 32, "GitHub Repo");
    ft_button_on_click(btn_gh, on_load_github, NULL);

    FtWidget btn_int = ft_button_create(win, 147, 236, 120, 32, "Internal Page");
    ft_button_on_click(btn_int, on_load_internal, NULL);

    FtWidget btn_bm = ft_button_create(win, 275, 236, 130, 32, "Toggle Star ★");
    ft_button_on_click(btn_bm, on_toggle_star, NULL);

    FtWidget btn_theme = ft_button_create(win, 413, 236, 185, 32, "Toggle Dark/Light Mode");
    ft_button_on_click(btn_theme, on_theme_toggle, NULL);

    /* 2. Insecure HTTP URL Bar (Warning Triangle + 'Not secure' badge) */
    FtWidget lbl2 = ft_text_create(win, 24, 286, 672, 20, "2. Insecure HTTP URL (Warning Triangle & 'Not secure' Security Chip):");
    ft_widget_set_font(lbl2, "Sans Bold 11");

    s_url_insecure = ft_url_entry_create(win, 24, 310, 540, 38, 
        "http://192.168.1.100:8080/dashboard/api/metrics?period=24h");
    ft_url_entry_set_show_security_badge_text(s_url_insecure, 1);
    ft_url_entry_on_submit(s_url_insecure, on_url_submitted, NULL);
    ft_url_entry_on_security_click(s_url_insecure, on_security_clicked, NULL);

    /* 3. Internal Browser Page */
    FtWidget lbl3 = ft_text_create(win, 24, 366, 672, 20, "3. Internal Floria Page (Custom Internal Page Icon):");
    ft_widget_set_font(lbl3, "Sans Bold 11");

    s_url_internal = ft_url_entry_create(win, 24, 390, 420, 38, "floria://settings/security/passwords");
    ft_url_entry_on_submit(s_url_internal, on_url_submitted, NULL);
    ft_url_entry_on_security_click(s_url_internal, on_security_clicked, NULL);

    /* 4. Interactive Note Card */
    FtWidget note_card = ft_container_create(win, 24, 444, 672, 94);
    ft_container_set_corner_radius(note_card, 8.0);
    ft_container_set_scrollbar_mode(note_card, FT_SCROLLBAR_MODE_NONE);

    FtWidget tip_title = ft_text_create(note_card, 16, 8, 640, 18, "Omnibox Interactive Features:");
    ft_widget_set_font(tip_title, "Sans Bold 10");

    FtWidget tip1 = ft_text_create(note_card, 16, 28, 640, 18,
        "• Unfocused state: Scheme & path parameters are subtly dimmed (~60%) so the host domain stands out.");
    ft_widget_set_font(tip1, "Sans 9");

    FtWidget tip2 = ft_text_create(note_card, 16, 46, 640, 18,
        "• Click into URL: instantly focuses and selects all text for quick replacement or editing.");
    ft_widget_set_font(tip2, "Sans 9");

    FtWidget tip3 = ft_text_create(note_card, 16, 64, 640, 18,
        "• Action buttons: Leading lock chip (site info/security) and trailing bookmark star.");
    ft_widget_set_font(tip3, "Sans 9");

    ft_widget_show(win);
    printf("[UrlEntry] Running main loop...\n");
    ft_main_loop();

    return 0;
}

/**
 * eca_browser_mockup.c — Extended Client Area (ECA) Web Browser Mockup
 *
 * Demonstrates the Extended Client Area protocol in a modern web browser UI:
 *   - Client canvas extends to Y = 0 with no exterior server titlebar.
 *   - Window manager (wmsama) draws server-side control buttons directly on
 *     top of the client canvas and publishes _NET_WM_WINDOW_CONTROLS_INSET.
 *   - Tab strip dynamically shifts past the window manager controls inset.
 *   - Omnibox URL entry bar with domain contrast and security chip.
 *   - Client-initiated window dragging via _NET_WM_MOVERESIZE on empty top bar space.
 *   - Multi-tab navigation with distinct simulated web pages.
 *   - Runtime toggle between ECA mode and standard server-side titlebar mode.
 */

#include "ft.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WIN_WIDTH 1000
#define WIN_HEIGHT 620
#define NUM_TABS 3
#define TAB_WIDTH 185
#define TAB_GAP 6
#define HEADER_HEIGHT 40
#define TOOLBAR_HEIGHT 44
#define STATUS_HEIGHT 28

typedef struct BrowserTab {
    const char* title;
    const char* url;
    int32_t security_state;
    const char* page_heading;
    const char* page_subheading;
    const char* card1_title;
    const char* card1_body;
    const char* card2_title;
    const char* card2_body;
    const char* card3_title;
    const char* card3_body;
} BrowserTab;

static BrowserTab s_tabs[NUM_TABS] = {
    {
        .title = "🌐 Samarinda Desktop",
        .url = "https://samarinda.org/overview",
        .security_state = FT_URL_SECURITY_SECURE,
        .page_heading = "Samarinda Desktop Environment",
        .page_subheading = "Server-Side Compositing & Extended Client Area (ECA) Architecture",
        .card1_title = "Compositor-Managed SSD",
        .card1_body = "Window frame metrics, 12px rounded corners, and drop shadows are rendered server-side by wmsama without client code bloat.",
        .card2_title = "Extended Client Area",
        .card2_body = "Zero-height top frame extents let the browser tab strip extend to Y = 0 while server-side control buttons overlay gracefully.",
        .card3_title = "Shaped Input Routing",
        .card3_body = "ControlsWindow is shaped with XCB_SHAPE_SK_INPUT over vector buttons; empty header space passes events directly to client tabs."
    },
    {
        .title = "⚙️ Floria Toolkit",
        .url = "https://floria.dev/documentation/architecture",
        .security_state = FT_URL_SECURITY_SECURE,
        .page_heading = "Floria Toolkit GUI Engine",
        .page_subheading = "Object-Oriented Pascal & C UI Framework with AggPas 2D Vector Rendering",
        .card1_title = "Precision Vector Graphics",
        .card1_body = "Decoupled 2D AggPas rendering engine produces subpixel-antialiased controls, rounded rectangles, and smooth gradients.",
        .card2_title = "Chrome-Style Omnibox",
        .card2_body = "Domain-contrast highlighting emphasizes the hostname while dimming scheme and path. Includes security chips and bookmarking.",
        .card3_title = "Modern Desktop Widgets",
        .card3_body = "Includes flexible layouts, splitters, tree views, tables, path bars, and native X11/XCB clipboard and drag integration."
    },
    {
        .title = "📜 ECA Protocol Spec",
        .url = "floria://spec/extended-client-area",
        .security_state = FT_URL_SECURITY_INTERNAL,
        .page_heading = "_NET_WM_EXTENDED_CLIENT_AREA Protocol",
        .page_subheading = "ICCCM & EWMH Harmonization for No-Titlebar Server-Decorated Windows",
        .card1_title = "Protocol Atoms",
        .card1_body = "Client sets _NET_WM_EXTENDED_CLIENT_AREA = 1; window manager publishes _NET_WM_WINDOW_CONTROLS_INSET [left, right, top, bottom].",
        .card2_title = "Window Dragging",
        .card2_body = "Empty header bar clicks dispatch _NET_WM_MOVERESIZE client messages, allowing seamless compositor-managed window moves.",
        .card3_title = "Dynamic Adaptation",
        .card3_body = "Clients listen to XCB PropertyNotify on controls insets to reflow tab strips in real time when window manager themes or layouts change."
    }
};

static FtWidget s_window = NULL;
static FtWidget s_header_bar = NULL;
static FtWidget s_tab_buttons[NUM_TABS];
static FtWidget s_btn_new_tab = NULL;

static FtWidget s_toolbar = NULL;
static FtWidget s_btn_back = NULL;
static FtWidget s_btn_forward = NULL;
static FtWidget s_btn_reload = NULL;
static FtWidget s_btn_home = NULL;
static FtWidget s_url_entry = NULL;
static FtWidget s_btn_dark_toggle = NULL;
static FtWidget s_btn_eca_toggle = NULL;

static FtWidget s_viewport_card = NULL;
static FtWidget s_lbl_heading = NULL;
static FtWidget s_lbl_subheading = NULL;
static FtWidget s_card1 = NULL;
static FtWidget s_card1_title = NULL;
static FtWidget s_card1_body = NULL;
static FtWidget s_card2 = NULL;
static FtWidget s_card2_title = NULL;
static FtWidget s_card2_body = NULL;
static FtWidget s_card3 = NULL;
static FtWidget s_card3_title = NULL;
static FtWidget s_card3_body = NULL;
static FtWidget s_lbl_page_counter = NULL;
static FtWidget s_btn_page_action = NULL;

static FtWidget s_status_bar = NULL;
static FtWidget s_lbl_status = NULL;
static FtWidget s_lbl_inset_info = NULL;

static int32_t s_active_tab = 0;
static int32_t s_controls_left = 0;
static int32_t s_controls_right = 0;
static int32_t s_controls_top = 0;
static int32_t s_controls_bottom = 0;
static int32_t s_page_action_count = 0;

static void update_page_content(void);
static void reposition_tab_strip(void);
static void update_status_bar(void);

static void on_insets_changed(FtWidget window, int32_t left, int32_t right, int32_t top, int32_t bottom, void* user_data) {
    (void)window;
    (void)user_data;
    s_controls_left = left;
    s_controls_right = right;
    s_controls_top = top;
    s_controls_bottom = bottom;

    printf("[ECA Browser] Insets received: [L: %d, R: %d, T: %d, B: %d]\n", left, right, top, bottom);
    reposition_tab_strip();
    update_status_bar();
}

static void on_window_mouse_down(FtWidget window, int32_t x, int32_t y, int32_t button, void* user_data) {
    (void)window;
    (void)user_data;
    if (button == 1 && s_window) {
        // Any click reaching the window within the header bar is on empty background space,
        // because interactive tab buttons consume their own mouse down events.
        if (y <= HEADER_HEIGHT) {
            int32_t win_x = 0, win_y = 0;
            ft_window_get_position(s_window, &win_x, &win_y);
            int32_t root_x = win_x + x;
            int32_t root_y = win_y + y;
            printf("[ECA Browser] Window drag initiated via _NET_WM_MOVERESIZE at root (%d, %d)\n", root_x, root_y);
            fflush(stdout);
            ft_window_begin_move(s_window, root_x, root_y);
        }
    }
}

static void on_tab_click(FtWidget button, void* user_data) {
    (void)button;
    intptr_t index = (intptr_t)user_data;
    if (index >= 0 && index < NUM_TABS && index != s_active_tab) {
        s_active_tab = (int32_t)index;
        printf("[ECA Browser] Switched to tab %d: %s\n", s_active_tab, s_tabs[s_active_tab].title);
        reposition_tab_strip();
        update_page_content();
        update_status_bar();
    }
}

static void on_new_tab_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    printf("[ECA Browser] New Tab requested — cycling to next tab.\n");
    s_active_tab = (s_active_tab + 1) % NUM_TABS;
    reposition_tab_strip();
    update_page_content();
    update_status_bar();
}

static void on_back_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    if (s_active_tab > 0) {
        s_active_tab--;
        reposition_tab_strip();
        update_page_content();
        update_status_bar();
    }
}

static void on_forward_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    if (s_active_tab < NUM_TABS - 1) {
        s_active_tab++;
        reposition_tab_strip();
        update_page_content();
        update_status_bar();
    }
}

static void on_reload_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    printf("[ECA Browser] Reloading current page: %s\n", s_tabs[s_active_tab].url);
    if (s_lbl_status) {
        ft_text_set_text(s_lbl_status, "Page refreshed (200 OK — Cache validated)");
    }
}

static void on_home_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    s_active_tab = 0;
    reposition_tab_strip();
    update_page_content();
    update_status_bar();
}

static void on_url_submitted(FtWidget url_entry, const char* url, void* user_data) {
    (void)url_entry;
    (void)user_data;
    printf("[ECA Browser] Navigating to user-submitted URL: %s\n", url ? url : "");
    if (s_lbl_status) {
        char buf[256];
        snprintf(buf, sizeof(buf), "Navigated to: %s", url ? url : "");
        ft_text_set_text(s_lbl_status, buf);
    }
}

static void on_security_chip_click(FtWidget url_entry, int32_t security_state, void* user_data) {
    (void)url_entry;
    (void)user_data;
    const char* sec_str = "Secure TLS 1.3 (Verified by Samarinda CA)";
    if (security_state == FT_URL_SECURITY_INTERNAL) {
        sec_str = "Internal Browser Protocol (floria://)";
    } else if (security_state == FT_URL_SECURITY_INSECURE) {
        sec_str = "Connection Not Encrypted (HTTP)";
    }
    printf("[ECA Browser] Security Chip Clicked: %s\n", sec_str);
    if (s_lbl_status) {
        char buf[256];
        snprintf(buf, sizeof(buf), "Security Certificate: %s", sec_str);
        ft_text_set_text(s_lbl_status, buf);
    }
}

static void on_bookmark_star_click(FtWidget url_entry, int32_t bookmarked, void* user_data) {
    (void)url_entry;
    (void)user_data;
    printf("[ECA Browser] Bookmark toggled -> %s\n", bookmarked ? "Starred (Saved to Bookmarks)" : "Unstarred");
    if (s_lbl_status) {
        ft_text_set_text(s_lbl_status, bookmarked ? "Page added to Favorites" : "Page removed from Favorites");
    }
}

static void on_dark_mode_toggle(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    int32_t is_dark = ft_theme_get_dark_mode();
    int32_t next = !is_dark;
    printf("[ECA Browser] Toggling Dark Mode: %d -> %d\n", is_dark, next);
    ft_theme_set_dark_mode(next);
}

static void on_eca_toggle(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    if (!s_window) return;
    int32_t cur = ft_window_get_extended_client_area(s_window);
    int32_t next = !cur;
    printf("[ECA Browser] Toggling Extended Client Area: %d -> %d\n", cur, next);
    ft_window_set_extended_client_area(s_window, next);
}

static void on_page_action_click(FtWidget button, void* user_data) {
    (void)button;
    (void)user_data;
    s_page_action_count++;
    char buf[128];
    snprintf(buf, sizeof(buf), "Interactive Counter: %d clicks", s_page_action_count);
    if (s_lbl_page_counter) {
        ft_text_set_text(s_lbl_page_counter, buf);
    }
    printf("[ECA Browser] %s\n", buf);
}

static void reposition_tab_strip(void) {
    // Determine start coordinate for tabs past window manager buttons inset
    int32_t start_x = (s_controls_left > 0) ? (s_controls_left + 12) : 16;

    for (int i = 0; i < NUM_TABS; i++) {
        int32_t tab_x = start_x + (i * (TAB_WIDTH + TAB_GAP));
        ft_widget_set_bounds(s_tab_buttons[i], tab_x, 6, TAB_WIDTH, 30);

        // Highlight active tab with a bracket indicator
        char caption[256];
        if (i == s_active_tab) {
            snprintf(caption, sizeof(caption), "● %s", s_tabs[i].title);
        } else {
            snprintf(caption, sizeof(caption), "  %s", s_tabs[i].title);
        }
        ft_button_set_caption(s_tab_buttons[i], caption);
    }

    // New Tab button right after the last tab
    int32_t new_tab_x = start_x + (NUM_TABS * (TAB_WIDTH + TAB_GAP));
    if (s_btn_new_tab) {
        ft_widget_set_bounds(s_btn_new_tab, new_tab_x, 6, 32, 30);
    }
}

static void update_page_content(void) {
    if (s_active_tab < 0 || s_active_tab >= NUM_TABS) return;

    BrowserTab* tab = &s_tabs[s_active_tab];

    // Update URL bar
    if (s_url_entry) {
        ft_url_entry_set_url(s_url_entry, tab->url);
        ft_url_entry_set_security_state(s_url_entry, tab->security_state);
    }

    // Update webpage headings
    if (s_lbl_heading) {
        ft_text_set_text(s_lbl_heading, tab->page_heading);
    }
    if (s_lbl_subheading) {
        ft_text_set_text(s_lbl_subheading, tab->page_subheading);
    }

    // Update feature cards
    if (s_card1_title) ft_text_set_text(s_card1_title, tab->card1_title);
    if (s_card1_body) ft_text_set_text(s_card1_body, tab->card1_body);

    if (s_card2_title) ft_text_set_text(s_card2_title, tab->card2_title);
    if (s_card2_body) ft_text_set_text(s_card2_body, tab->card2_body);

    if (s_card3_title) ft_text_set_text(s_card3_title, tab->card3_title);
    if (s_card3_body) ft_text_set_text(s_card3_body, tab->card3_body);
}

static void update_status_bar(void) {
    if (s_lbl_status) {
        char buf[256];
        snprintf(buf, sizeof(buf), "TLS 1.3 | Active Tab: %d/3 | Zoom: 100%% | Render: AggPas Vector Engine", s_active_tab + 1);
        ft_text_set_text(s_lbl_status, buf);
    }
    if (s_lbl_inset_info) {
        char buf[256];
        int32_t is_eca = ft_window_get_extended_client_area(s_window);
        snprintf(buf, sizeof(buf), "ECA: %s | Controls Inset: [L: %d, R: %d, T: %d, B: %d]",
                 is_eca ? "Active" : "Disabled",
                 s_controls_left, s_controls_right, s_controls_top, s_controls_bottom);
        ft_text_set_text(s_lbl_inset_info, buf);
    }
}

int main(void) {
    setlinebuf(stdout);
    ft_init();

    // Create 1000x620 window
    s_window = ft_window_create(WIN_WIDTH, WIN_HEIGHT, "Floria Browser — Extended Client Area Demo");
    if (!s_window) {
        fprintf(stderr, "Failed to create Floria window.\n");
        return 1;
    }
    ft_window_set_position(s_window, 100, 50);

    // Enable Extended Client Area
    ft_window_set_extended_client_area(s_window, 1);
    ft_window_on_controls_inset_changed(s_window, on_insets_changed, NULL);
    ft_window_on_mouse_down(s_window, on_window_mouse_down, NULL);

    // =========================================================================
    // 1. TOP TAB STRIP BAR (Y = 0 to 40)
    // =========================================================================
    s_header_bar = ft_container_create(s_window, 0, 0, WIN_WIDTH, HEADER_HEIGHT);
    ft_widget_set_style_class(s_header_bar, "browser-tab-strip");

    for (int i = 0; i < NUM_TABS; i++) {
        s_tab_buttons[i] = ft_button_create(s_header_bar, 0, 0, TAB_WIDTH, 30, s_tabs[i].title);
        ft_button_set_corner_radius(s_tab_buttons[i], 6.0);
        ft_button_on_click(s_tab_buttons[i], on_tab_click, (void*)(intptr_t)i);
    }

    s_btn_new_tab = ft_button_create(s_header_bar, 0, 0, 32, 30, "+");
    ft_button_set_corner_radius(s_btn_new_tab, 6.0);
    ft_button_on_click(s_btn_new_tab, on_new_tab_click, NULL);

    reposition_tab_strip();

    // =========================================================================
    // 2. NAVIGATION TOOLBAR (Y = 40 to 84)
    // =========================================================================
    s_toolbar = ft_container_create(s_window, 0, HEADER_HEIGHT, WIN_WIDTH, TOOLBAR_HEIGHT);
    ft_widget_set_style_class(s_toolbar, "browser-toolbar");

    s_btn_back = ft_button_create(s_toolbar, 14, 6, 34, 32, "◀");
    ft_button_set_corner_radius(s_btn_back, 6.0);
    ft_button_on_click(s_btn_back, on_back_click, NULL);

    s_btn_forward = ft_button_create(s_toolbar, 52, 6, 34, 32, "▶");
    ft_button_set_corner_radius(s_btn_forward, 6.0);
    ft_button_on_click(s_btn_forward, on_forward_click, NULL);

    s_btn_reload = ft_button_create(s_toolbar, 90, 6, 34, 32, "↻");
    ft_button_set_corner_radius(s_btn_reload, 6.0);
    ft_button_on_click(s_btn_reload, on_reload_click, NULL);

    s_btn_home = ft_button_create(s_toolbar, 128, 6, 34, 32, "⌂");
    ft_button_set_corner_radius(s_btn_home, 6.0);
    ft_button_on_click(s_btn_home, on_home_click, NULL);

    // Chrome-style Omnibox URL entry
    s_url_entry = ft_url_entry_create(s_toolbar, 172, 4, 616, 36, s_tabs[0].url);
    ft_url_entry_set_corner_radius(s_url_entry, 18.0);
    ft_url_entry_set_show_security_chip(s_url_entry, 1);
    ft_url_entry_set_show_bookmark_button(s_url_entry, 1);
    ft_url_entry_on_submit(s_url_entry, on_url_submitted, NULL);
    ft_url_entry_on_security_click(s_url_entry, on_security_chip_click, NULL);
    ft_url_entry_on_bookmark_click(s_url_entry, on_bookmark_star_click, NULL);

    // Action toggle buttons on the right
    s_btn_dark_toggle = ft_button_create(s_toolbar, 798, 6, 90, 32, "◐ Theme");
    ft_button_set_corner_radius(s_btn_dark_toggle, 6.0);
    ft_button_on_click(s_btn_dark_toggle, on_dark_mode_toggle, NULL);

    s_btn_eca_toggle = ft_button_create(s_toolbar, 896, 6, 92, 32, "⧉ ECA/SSD");
    ft_button_set_corner_radius(s_btn_eca_toggle, 6.0);
    ft_button_on_click(s_btn_eca_toggle, on_eca_toggle, NULL);

    // =========================================================================
    // 3. WEB CONTENT VIEWPORT (Y = 88 to 582)
    // =========================================================================
    s_viewport_card = ft_container_create(s_window, 16, HEADER_HEIGHT + TOOLBAR_HEIGHT + 4, WIN_WIDTH - 32, 492);
    ft_container_set_corner_radius(s_viewport_card, 8.0);
    ft_widget_set_style_class(s_viewport_card, "browser-viewport");

    // Page Heading & Subheading
    s_lbl_heading = ft_text_create(s_viewport_card, 24, 16, WIN_WIDTH - 80, 28, s_tabs[0].page_heading);
    ft_widget_set_font(s_lbl_heading, "Sans Bold 17");

    s_lbl_subheading = ft_text_create(s_viewport_card, 24, 46, WIN_WIDTH - 80, 20, s_tabs[0].page_subheading);
    ft_widget_set_font(s_lbl_subheading, "Sans 10");

    // Feature Card 1
    s_card1 = ft_container_create(s_viewport_card, 24, 76, WIN_WIDTH - 80, 84);
    ft_container_set_corner_radius(s_card1, 6.0);
    s_card1_title = ft_text_create(s_card1, 16, 10, WIN_WIDTH - 112, 20, s_tabs[0].card1_title);
    ft_widget_set_font(s_card1_title, "Sans Bold 12");
    s_card1_body = ft_text_create(s_card1, 16, 34, WIN_WIDTH - 112, 42, s_tabs[0].card1_body);
    ft_widget_set_font(s_card1_body, "Sans 10");

    // Feature Card 2
    s_card2 = ft_container_create(s_viewport_card, 24, 168, WIN_WIDTH - 80, 84);
    ft_container_set_corner_radius(s_card2, 6.0);
    s_card2_title = ft_text_create(s_card2, 16, 10, WIN_WIDTH - 112, 20, s_tabs[0].card2_title);
    ft_widget_set_font(s_card2_title, "Sans Bold 12");
    s_card2_body = ft_text_create(s_card2, 16, 34, WIN_WIDTH - 112, 42, s_tabs[0].card2_body);
    ft_widget_set_font(s_card2_body, "Sans 10");

    // Feature Card 3
    s_card3 = ft_container_create(s_viewport_card, 24, 260, WIN_WIDTH - 80, 84);
    ft_container_set_corner_radius(s_card3, 6.0);
    s_card3_title = ft_text_create(s_card3, 16, 10, WIN_WIDTH - 112, 20, s_tabs[0].card3_title);
    ft_widget_set_font(s_card3_title, "Sans Bold 12");
    s_card3_body = ft_text_create(s_card3, 16, 34, WIN_WIDTH - 112, 42, s_tabs[0].card3_body);
    ft_widget_set_font(s_card3_body, "Sans 10");

    // Interactive Demo Area inside page
    s_btn_page_action = ft_button_create(s_viewport_card, 24, 356, 180, 34, "Test In-Page Action");
    ft_button_set_corner_radius(s_btn_page_action, 6.0);
    ft_button_on_click(s_btn_page_action, on_page_action_click, NULL);

    s_lbl_page_counter = ft_text_create(s_viewport_card, 218, 362, 400, 24, "Interactive Counter: 0 clicks");
    ft_widget_set_font(s_lbl_page_counter, "Sans Italic 11");

    // =========================================================================
    // 4. BOTTOM STATUS BAR (Y = 588 to 616)
    // =========================================================================
    s_status_bar = ft_container_create(s_window, 0, WIN_HEIGHT - STATUS_HEIGHT, WIN_WIDTH, STATUS_HEIGHT);
    ft_widget_set_style_class(s_status_bar, "browser-status-bar");

    s_lbl_status = ft_text_create(s_status_bar, 16, 5, 480, 18, "");
    ft_widget_set_font(s_lbl_status, "Sans 9");

    s_lbl_inset_info = ft_text_create(s_status_bar, 510, 5, 474, 18, "");
    ft_widget_set_font(s_lbl_inset_info, "Monospace 9");

    update_page_content();
    update_status_bar();

    ft_widget_show(s_window);
    ft_main_loop();
    ft_quit();
    return 0;
}

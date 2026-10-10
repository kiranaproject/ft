#include "ft.h"
#include <stdio.h>
#include <stdlib.h>

static FtWidget s_win = NULL;
static FtWidget s_lbl_status = NULL;
static FtWidget s_log_area = NULL;

static void log_message(const char* msg) {
    if (s_log_area && msg) {
        const char* current = ft_textarea_get_text(s_log_area);
        char buf[1024];
        if (current && *current) {
            snprintf(buf, sizeof(buf), "%s\n[LOG] %s", current, msg);
        } else {
            snprintf(buf, sizeof(buf), "[LOG] %s", msg);
        }
        ft_textarea_set_text(s_log_area, buf);
    }
    if (s_lbl_status && msg) {
        char status[128];
        snprintf(status, sizeof(status), "Status: %s", msg);
        ft_text_set_text(s_lbl_status, status);
    }
    printf("[Phase2 Showcase] %s\n", msg);
}

static void on_save_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    log_message("Configuration saved successfully to cluster profile.");
}

static void on_test_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    log_message("Testing connection to cluster host... Connection verified (24ms latency).");
}

static void on_splitter_move(FtSplitter splitter, double pos, void* user_data) {
    (void)splitter;
    (void)user_data;
    char buf[128];
    snprintf(buf, sizeof(buf), "Splitter moved to pane size %.1fpx", pos);
    log_message(buf);
}

static void on_dark_mode_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(checked);
    log_message(checked ? "Theme switched to Dark mode" : "Theme switched to Light mode");
}

int main(void) {
    ft_init();

    printf("[Phase2 Showcase] Starting Micro-Flexbox Phase 2 (Splitter & Grid) Showcase...\n");

    s_win = ft_window_create(980, 720, "Floria Toolkit — Micro-Flexbox Phase 2: Splitter & Grid Integration");

    /* ─── Root Layout: VBox filling entire window client area ─── */
    FtWidget root_vbox = ft_vbox_create(s_win, 0, 0, 980, 720);
    ft_flexbox_set_gap(root_vbox, 8);
    ft_container_set_padding(root_vbox, 12, 12);
    ft_window_set_layout(s_win, root_vbox);

    /* ─── Top Toolbar (HBox) ─── */
    FtWidget top_bar = ft_hbox_create(root_vbox, 0, 0, 0, 38);
    ft_flexbox_set_gap(top_bar, 10);
    ft_flexbox_set_align_items(top_bar, FT_ALIGN_CENTER);
    ft_widget_set_flex_grow(top_bar, 0.0);

    FtWidget title_lbl = ft_text_create(top_bar, 0, 0, 320, 24, "⚡ Cluster Orchestrator Console");
    ft_text_set_selectable(title_lbl, 0);

    ft_spacer_create(top_bar);

    FtWidget sw_dark = ft_switch_create(top_bar, 0, 0, 130, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_mode_toggle, NULL);

    /* ─── Main Workspace: HBox with Flex-Aware Splitters ─── */
    FtWidget main_workspace = ft_hbox_create(root_vbox, 0, 0, 0, 0);
    ft_flexbox_set_gap(main_workspace, 0);
    ft_widget_set_flex_grow(main_workspace, 1.0);

    /* ── Left Sidebar Pane ── */
    FtWidget sidebar = ft_vbox_create(main_workspace, 0, 0, 240, 0);
    ft_flexbox_set_gap(sidebar, 6);
    ft_container_set_padding(sidebar, 8, 8);
    ft_container_set_draw_frame(sidebar, 1);
    ft_container_set_corner_radius(sidebar, 8.0);
    ft_widget_set_flex_grow(sidebar, 0.0);
    ft_widget_set_flex_basis(sidebar, 240.0);

    FtWidget side_header = ft_text_create(sidebar, 0, 0, 180, 22, "Environments");
    ft_text_set_selectable(side_header, 0);

    ft_button_create(sidebar, 0, 0, 180, 30, "● Production (us-east-1)");
    ft_button_create(sidebar, 0, 0, 180, 30, "● Staging (eu-central-1)");
    ft_button_create(sidebar, 0, 0, 180, 30, "● Development (local)");
    ft_button_create(sidebar, 0, 0, 180, 30, "● Disaster Recovery");

    ft_spacer_create(sidebar);
    FtWidget side_tip = ft_text_create(sidebar, 0, 0, 180, 36, "Tip: Drag vertical splitter to resize sidebar");
    ft_text_set_selectable(side_tip, 0);

    /* ── Vertical Flex Splitter between Sidebar and Center ── */
    FtWidget v_splitter = ft_flexbox_add_splitter(main_workspace);
    ft_splitter_set_min_sizes(v_splitter, 140.0, 300.0);
    ft_splitter_on_position_change(v_splitter, on_splitter_move, NULL);

    /* ── Right Work Area: VBox containing Form Grid and Log Pane ── */
    FtWidget work_area = ft_vbox_create(main_workspace, 0, 0, 0, 0);
    ft_flexbox_set_gap(work_area, 0);
    ft_widget_set_flex_grow(work_area, 0.75);

    /* ── Top Pane: Form Grid in Container ── */
    FtWidget form_container = ft_vbox_create(work_area, 0, 0, 0, 420);
    ft_flexbox_set_gap(form_container, 8);
    ft_container_set_padding(form_container, 14, 14);
    ft_container_set_draw_frame(form_container, 1);
    ft_container_set_corner_radius(form_container, 8.0);
    ft_widget_set_flex_grow(form_container, 0.70);
    ft_widget_set_flex_basis(form_container, 410.0);

    /* Declarative 2D Form Grid */
    FtWidget form_grid = ft_form_grid_create(form_container, 0, 0, 0, 0);
    ft_grid_set_gaps(form_grid, 12.0, 8.0);
    ft_widget_set_flex_grow(form_grid, 1.0);

    /* Section 1: Endpoint Configuration */
    ft_form_grid_add_section(form_grid, "Cluster Network Endpoints");

    FtWidget entry_host = ft_entry_create(form_grid, 0, 0, 0, 32, "api.production.floria.internal");
    ft_form_grid_add_row(form_grid, "Primary Hostname:", entry_host);

    FtWidget entry_port = ft_entry_create(form_grid, 0, 0, 0, 32, "8443");
    ft_form_grid_add_row(form_grid, "Target Port:", entry_port);

    FtWidget entry_proto = ft_entry_create(form_grid, 0, 0, 0, 32, "gRPC / HTTP/2 Multiplexed");
    ft_form_grid_add_row(form_grid, "Wire Protocol:", entry_proto);

    /* Section 2: Security & Credentials */
    ft_form_grid_add_section(form_grid, "Authentication & Security Protocols");

    FtWidget entry_token = ft_entry_create(form_grid, 0, 0, 0, 32, "fl_live_948f9328a7e04b7c126d981");
    ft_form_grid_add_row(form_grid, "Service Account Token:", entry_token);

    FtWidget sw_tls = ft_switch_create(form_grid, 0, 0, 120, 26, "TLS 1.3");
    ft_switch_set_checked(sw_tls, 1);
    ft_form_grid_add_row(form_grid, "Strict Mutual TLS (mTLS):", sw_tls);

    /* Button Bar: Spanned across both grid columns with SizeGroup synchronized buttons */
    FtWidget action_bar = ft_hbox_create(form_grid, 0, 0, 0, 36);
    ft_flexbox_set_gap(action_bar, 10);
    ft_flexbox_set_align_items(action_bar, FT_ALIGN_CENTER);

    ft_spacer_create(action_bar);

    FtWidget btn_test = ft_button_create(action_bar, 0, 0, 140, 32, "⚡ Test Connection");
    ft_button_on_click(btn_test, on_test_click, NULL);

    FtWidget btn_save = ft_button_create(action_bar, 0, 0, 100, 32, "💾 Apply & Save");
    ft_button_on_click(btn_save, on_save_click, NULL);

    /* Size Group: Synchronize button widths across the action bar */
    FtSizeGroup btn_group = ft_size_group_create(0); // ftsgHorizontal
    ft_size_group_add_widget(btn_group, btn_test);
    ft_size_group_add_widget(btn_group, btn_save);
    ft_size_group_synchronize(btn_group);

    ft_form_grid_add_spanned(form_grid, action_bar);

    /* ── Horizontal Flex Splitter between Form Grid and Live Log ── */
    FtWidget h_splitter = ft_flexbox_add_splitter(work_area);
    ft_splitter_set_min_sizes(h_splitter, 150.0, 80.0);
    ft_splitter_on_position_change(h_splitter, on_splitter_move, NULL);

    /* ── Bottom Pane: Live Log Terminal ── */
    FtWidget log_container = ft_vbox_create(work_area, 0, 0, 0, 160);
    ft_flexbox_set_gap(log_container, 6);
    ft_container_set_padding(log_container, 10, 10);
    ft_container_set_draw_frame(log_container, 1);
    ft_container_set_corner_radius(log_container, 8.0);
    ft_widget_set_flex_grow(log_container, 0.35);
    ft_widget_set_flex_basis(log_container, 140.0);

    FtWidget log_header = ft_text_create(log_container, 0, 0, 200, 20, "Live Diagnostic Logs");
    ft_text_set_selectable(log_header, 0);

    s_log_area = ft_textarea_create(log_container, 0, 0, 0, 0,
        "[LOG] Orchestrator initialized.\n"
        "[LOG] Micro-Flexbox Phase 2 layout active.\n"
        "[LOG] Dual splitters (horizontal + vertical) dynamically rebalancing flex siblings at 60 FPS.\n"
        "[LOG] Declarative TFtFormGrid automatically aligned multi-row label/input pairs.\n"
        "[LOG] TFtSizeGroup synchronized action button metrics across columns.");
    ft_textarea_set_readonly(s_log_area, 1);
    ft_widget_set_flex_grow(s_log_area, 1.0);

    /* ─── Bottom Status Bar (HBox) ─── */
    FtWidget status_bar = ft_hbox_create(root_vbox, 0, 0, 0, 24);
    ft_flexbox_set_gap(status_bar, 8);
    ft_flexbox_set_align_items(status_bar, FT_ALIGN_CENTER);
    ft_widget_set_flex_grow(status_bar, 0.0);

    s_lbl_status = ft_text_create(status_bar, 0, 0, 400, 20, "Status: Ready • Drag splitters to resize panels dynamically");
    ft_text_set_selectable(s_lbl_status, 0);

    ft_spacer_create(status_bar);

    FtWidget lbl_fps = ft_text_create(status_bar, 0, 0, 180, 20, "60 FPS Interactive Reflow");
    ft_text_set_selectable(lbl_fps, 0);

    /* Initial layout calculation */
    ft_flexbox_update_layout(root_vbox);

    printf("[COORDINATES] sidebar: X=%d, Y=%d, W=%d, H=%d\n",
           ft_widget_get_x(sidebar), ft_widget_get_y(sidebar),
           ft_widget_get_width(sidebar), ft_widget_get_height(sidebar));
    printf("[COORDINATES] v_splitter: X=%d, Y=%d, W=%d, H=%d\n",
           ft_widget_get_x(v_splitter), ft_widget_get_y(v_splitter),
           ft_widget_get_width(v_splitter), ft_widget_get_height(v_splitter));
    printf("[COORDINATES] form_container: X=%d, Y=%d, W=%d, H=%d\n",
           ft_widget_get_x(form_container), ft_widget_get_y(form_container),
           ft_widget_get_width(form_container), ft_widget_get_height(form_container));
    printf("[COORDINATES] h_splitter: X=%d, Y=%d, W=%d, H=%d\n",
           ft_widget_get_x(h_splitter), ft_widget_get_y(h_splitter),
           ft_widget_get_width(h_splitter), ft_widget_get_height(h_splitter));

    ft_widget_show(s_win);

    printf("[Phase2 Showcase] Entering main event loop...\n");
    ft_main_loop();

    /* Cleanup */
    ft_size_group_destroy(btn_group);
    ft_quit();
    return 0;
}

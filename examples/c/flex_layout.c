#include "ft.h"
#include <stdio.h>

static FtWidget s_win = NULL;
static FtWidget s_lbl_status = NULL;

void on_btn_click(FtWidget widget, void* user_data) {
    (void)widget;
    const char* name = (const char*)user_data;
    if (s_lbl_status && name) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Clicked '%s'", name);
        ft_text_set_text(s_lbl_status, buf);
    }
    printf("[FlexLayout] Clicked '%s'\n", name ? name : "button");
}

void on_dark_mode_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(checked);
    printf("[FlexLayout] Dark mode: %s\n", checked ? "ON" : "OFF");
}

int main(void) {
    ft_init();

    printf("[FlexLayout] Initializing Micro-Flexbox showcase...\n");

    s_win = ft_window_create(840, 560, "Floria Toolkit — Micro-Flexbox Layout Showcase");

    /* ── Root Layout: VBox filling window client area ── */
    FtWidget root_vbox = ft_vbox_create(s_win, 0, 0, 840, 560);
    ft_flexbox_set_gap(root_vbox, 12);
    ft_container_set_padding(root_vbox, 14, 14);

    /* Bind root layout to window for automatic responsive reflow */
    ft_window_set_layout(s_win, root_vbox);

    /* ── Row 1: Header / Navigation Toolbar (HBox) ── */
    FtWidget top_bar = ft_hbox_create(root_vbox, 0, 0, 0, 34);
    ft_flexbox_set_gap(top_bar, 8);
    ft_flexbox_set_align_items(top_bar, FT_ALIGN_CENTER);
    ft_widget_set_flex_grow(top_bar, 0.0); // Fixed height

    FtWidget btn_back = ft_button_create(top_bar, 0, 0, 36, 32, "◀");
    ft_button_on_click(btn_back, on_btn_click, (void*)"Back");

    FtWidget btn_fwd = ft_button_create(top_bar, 0, 0, 36, 32, "▶");
    ft_button_on_click(btn_fwd, on_btn_click, (void*)"Forward");

    FtWidget btn_up = ft_button_create(top_bar, 0, 0, 36, 32, "▲");
    ft_button_on_click(btn_up, on_btn_click, (void*)"Up");

    /* Stretchy Address / Search Bar: flex_grow = 1.0! */
    FtWidget entry_search = ft_entry_create(top_bar, 0, 0, 0, 32, "floria://toolkit/layout/micro-flexbox");
    ft_widget_set_flex_grow(entry_search, 1.0);
    ft_widget_set_flex_basis(entry_search, 0.0);

    FtWidget sw_dark = ft_switch_create(top_bar, 0, 0, 140, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_mode_toggle, NULL);

    /* ── Row 2: Main Workspace (HBox, flex_grow = 1.0 consumes vertical space!) ── */
    FtWidget workspace = ft_hbox_create(root_vbox, 0, 0, 0, 0);
    ft_flexbox_set_gap(workspace, 12);
    ft_widget_set_flex_grow(workspace, 1.0); // Stretches vertically!

    /* Sidebar: Fixed-width VBox (width=160) */
    FtWidget sidebar = ft_vbox_create(workspace, 0, 0, 160, 0);
    ft_flexbox_set_gap(sidebar, 6);
    ft_container_set_padding(sidebar, 8, 8);
    ft_container_set_draw_frame(sidebar, 1);
    ft_container_set_corner_radius(sidebar, 8.0);
    ft_widget_set_flex_grow(sidebar, 0.0); // Fixed width

    FtWidget lbl_side_title = ft_text_create(sidebar, 0, 0, 140, 22, "Navigation");
    ft_text_set_selectable(lbl_side_title, 0);

    FtWidget btn_nav1 = ft_button_create(sidebar, 0, 0, 140, 30, "📁 Files");
    ft_button_on_click(btn_nav1, on_btn_click, (void*)"Files");

    FtWidget btn_nav2 = ft_button_create(sidebar, 0, 0, 140, 30, "🎨 Design");
    ft_button_on_click(btn_nav2, on_btn_click, (void*)"Design");

    FtWidget btn_nav3 = ft_button_create(sidebar, 0, 0, 140, 30, "⚙ Settings");
    ft_button_on_click(btn_nav3, on_btn_click, (void*)"Settings");

    /* Spacer in sidebar pushes system info to the bottom */
    ft_spacer_create(sidebar);

    FtWidget lbl_side_info = ft_text_create(sidebar, 0, 0, 140, 18, "v0.1.0 • Ready");
    ft_text_set_selectable(lbl_side_info, 0);

    /* Center Content Area: Stretchy VBox (flex_grow = 1.0!) */
    FtWidget center_panel = ft_vbox_create(workspace, 0, 0, 0, 0);
    ft_flexbox_set_gap(center_panel, 8);
    ft_container_set_padding(center_panel, 12, 12);
    ft_container_set_draw_frame(center_panel, 1);
    ft_container_set_corner_radius(center_panel, 8.0);
    ft_widget_set_flex_grow(center_panel, 1.0); // Stretches horizontally!

    FtWidget lbl_center_title = ft_text_create(center_panel, 0, 0, 0, 24, "Declarative Responsive Layout Area");
    ft_text_set_selectable(lbl_center_title, 0);

    FtWidget lbl_center_desc = ft_text_create(center_panel, 0, 0, 0, 20, 
        "Try resizing this window! The address bar, center panel, and buttons reflow with zero manual math.");
    ft_text_set_selectable(lbl_center_desc, 0);

    /* Stretchy text area filling central space */
    FtWidget ta_content = ft_textarea_create(center_panel, 0, 0, 0, 0, 
        "Floria Toolkit Micro-Flexbox Engine\n"
        "====================================\n\n"
        "Features:\n"
        " • 1D Flexbox direction (ft_hbox_create, ft_vbox_create)\n"
        " • Automatic gap distribution between adjacent widgets\n"
        " • Elastic stretch factors (ft_widget_set_flex_grow)\n"
        " • Cross-axis alignment (stretch, start, center, end)\n"
        " • Automatic window resize reflow (ft_window_set_layout)\n"
        " • Zero coordinate arithmetic required in application code!\n");
    ft_widget_set_flex_grow(ta_content, 1.0); // Stretches to fill vertical height!

    /* Right Inspector: Fixed-width VBox (width=180) */
    FtWidget inspector = ft_vbox_create(workspace, 0, 0, 180, 0);
    ft_flexbox_set_gap(inspector, 8);
    ft_container_set_padding(inspector, 10, 10);
    ft_container_set_draw_frame(inspector, 1);
    ft_container_set_corner_radius(inspector, 8.0);
    ft_widget_set_flex_grow(inspector, 0.0); // Fixed width

    FtWidget lbl_insp_title = ft_text_create(inspector, 0, 0, 160, 22, "Properties");
    ft_text_set_selectable(lbl_insp_title, 0);

    FtWidget sw_grid = ft_switch_create(inspector, 0, 0, 160, 26, "Snap to Grid");
    ft_switch_set_checked(sw_grid, 1);

    FtWidget sw_snap = ft_switch_create(inspector, 0, 0, 160, 26, "Auto-Reflow");
    ft_switch_set_checked(sw_snap, 1);

    FtWidget sw_shadow = ft_switch_create(inspector, 0, 0, 160, 26, "Box Shadow");
    ft_switch_set_checked(sw_shadow, 1);

    /* ── Row 3: Footer Status & Action Bar (HBox) ── */
    FtWidget footer_bar = ft_hbox_create(root_vbox, 0, 0, 0, 36);
    ft_flexbox_set_gap(footer_bar, 8);
    ft_flexbox_set_align_items(footer_bar, FT_ALIGN_CENTER);
    ft_widget_set_flex_grow(footer_bar, 0.0); // Fixed height

    s_lbl_status = ft_text_create(footer_bar, 0, 0, 280, 22, "Status: Ready");
    ft_text_set_selectable(s_lbl_status, 0);

    /* Spacer pushes action buttons to the right edge! */
    ft_spacer_create(footer_bar);

    FtWidget btn_cancel = ft_button_create(footer_bar, 0, 0, 90, 32, "Cancel");
    ft_button_on_click(btn_cancel, on_btn_click, (void*)"Cancel");

    FtWidget btn_apply = ft_button_create(footer_bar, 0, 0, 110, 32, "Apply Layout");
    ft_button_on_click(btn_apply, on_btn_click, (void*)"Apply");

    /* Initial layout calculation */
    ft_flexbox_update_layout(root_vbox);

    ft_widget_show(s_win);
    ft_main_loop();
    ft_quit();
    return 0;
}

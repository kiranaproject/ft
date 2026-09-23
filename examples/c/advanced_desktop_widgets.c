#include "ft.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FtWidget s_status_lbl = NULL;
static FtTable s_data_table = NULL;
static int s_next_id = 100;

static void on_tab_changed(FtNotebook notebook, int32_t new_index, int32_t old_index, void* user_data) {
    (void)notebook;
    (void)user_data;
    if (s_status_lbl) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Switched from Tab %d to Tab %d", old_index + 1, new_index + 1);
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_tree_node_selected(FtTreeView treeview, FtTreeNode node, void* user_data) {
    (void)treeview;
    (void)user_data;
    if (s_status_lbl && node) {
        const char* text = ft_treenode_get_text(node);
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: TreeView node selected: '%s'", text ? text : "(null)");
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_table_row_selected(FtTable table, int32_t row_index, void* user_data) {
    (void)user_data;
    if (s_status_lbl) {
        const char* name = ft_table_get_cell(table, row_index, 0);
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Selected row %d ('%s')", row_index, name ? name : "");
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_splitter_moved(FtSplitter splitter, double pos, void* user_data) {
    (void)splitter;
    (void)user_data;
    if (s_status_lbl) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Splitter dragged to position %.1f px", pos);
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_add_row_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (!s_data_table) return;

    char id_buf[16], price_buf[32];
    snprintf(id_buf, sizeof(id_buf), "%d", s_next_id++);
    snprintf(price_buf, sizeof(price_buf), "$%.2f", 19.99 + (s_next_id % 50));

    int row = ft_table_add_row(s_data_table);
    ft_table_set_cell(s_data_table, row, 0, id_buf);
    ft_table_set_cell(s_data_table, row, 1, "Dynamic Item Record");
    ft_table_set_cell(s_data_table, row, 2, "Hardware");
    ft_table_set_cell(s_data_table, row, 3, price_buf);
    ft_table_set_cell(s_data_table, row, 4, "In Stock");

    if (s_status_lbl) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Status: Added new row with ID #%s (total: %d rows)", id_buf, ft_table_get_row_count(s_data_table));
        ft_text_set_text(s_status_lbl, buf);
    }
}

static void on_delete_row_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (!s_data_table) return;

    int sel = ft_table_get_selected_row(s_data_table);
    if (sel >= 0 && sel < ft_table_get_row_count(s_data_table)) {
        ft_table_delete_row(s_data_table, sel);
        if (s_status_lbl) {
            char buf[128];
            snprintf(buf, sizeof(buf), "Status: Deleted row %d (remaining: %d rows)", sel, ft_table_get_row_count(s_data_table));
            ft_text_set_text(s_status_lbl, buf);
        }
    } else if (s_status_lbl) {
        ft_text_set_text(s_status_lbl, "Status: Please select a row in the table first!");
    }
}

static void on_toggle_grid_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (!s_data_table) return;

    int show = !ft_table_get_show_gridlines(s_data_table);
    ft_table_set_show_gridlines(s_data_table, show);
    if (s_status_lbl) {
        ft_text_set_text(s_status_lbl, show ? "Status: Grid lines enabled" : "Status: Grid lines disabled");
    }
}

static void on_toggle_zebra_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (!s_data_table) return;

    int zebra = !ft_table_get_zebra_striping(s_data_table);
    ft_table_set_zebra_striping(s_data_table, zebra);
    if (s_status_lbl) {
        ft_text_set_text(s_status_lbl, zebra ? "Status: Zebra striping enabled" : "Status: Zebra striping disabled");
    }
}

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    ft_init();

    FtWidget win = ft_window_create(960, 680, "Floria Toolkit - Advanced Desktop Widgets Showcase");
    ft_widget_show(win);

    /* Main Notebook Container */
    FtNotebook notebook = ft_notebook_create(win, 20, 20, 920, 595);
    ft_notebook_on_tab_change(notebook, on_tab_changed, NULL);

    /* ===================================================================== */
    /* TAB 1: Project Explorer (Splitter + TreeView + Table)                  */
    /* ===================================================================== */
    FtTabPage tab1 = ft_notebook_add_tab(notebook, "Project Explorer", 1);

    FtSplitter split1 = ft_splitter_create(tab1, 10, 10, 900, 535, FT_SPLITTER_HORIZONTAL);
    ft_splitter_on_position_change(split1, on_splitter_moved, NULL);

    /* Left: TreeView */
    FtTreeView tree = ft_treeview_create(split1, 0, 0, 270, 535);
    ft_treeview_on_select(tree, on_tree_node_selected, NULL);

    FtTreeNode n_src = ft_treeview_add_node(tree, "src", NULL);
    ft_treenode_set_expanded(n_src, 1);
    FtTreeNode n_main = ft_treenode_add_child(n_src, "main/pascal");
    ft_treenode_set_expanded(n_main, 1);
    ft_treenode_add_child(n_main, "ft.pas");
    ft_treenode_add_child(n_main, "ft.widget.tabs.pas");
    ft_treenode_add_child(n_main, "ft.widget.splitters.pas");
    ft_treenode_add_child(n_main, "ft.widget.treeviews.pas");
    ft_treenode_add_child(n_main, "ft.widget.tables.pas");
    FtTreeNode n_test = ft_treenode_add_child(n_src, "test/pascal");
    ft_treenode_add_child(n_test, "TestRunner.pas");

    FtTreeNode n_inc = ft_treeview_add_node(tree, "include", NULL);
    ft_treenode_add_child(n_inc, "ft.h");

    FtTreeNode n_ex = ft_treeview_add_node(tree, "examples", NULL);
    ft_treenode_set_expanded(n_ex, 1);
    ft_treenode_add_child(n_ex, "c/advanced_desktop_widgets.c");
    ft_treenode_add_child(n_ex, "c/containers.c");
    ft_treenode_add_child(n_ex, "c/menus.c");

    FtTreeNode n_doc = ft_treeview_add_node(tree, "docs", NULL);
    ft_treenode_add_child(n_doc, "ROADMAP.md");
    ft_treenode_add_child(n_doc, "architecture.md");

    /* Right: Table showing file details */
    FtTable tbl_files = ft_table_create(split1, 0, 0, 620, 535);
    ft_table_on_select_row(tbl_files, on_table_row_selected, NULL);
    ft_table_add_column(tbl_files, "Filename", 210, 0); // left
    ft_table_add_column(tbl_files, "Size", 85, 2);      // right
    ft_table_add_column(tbl_files, "Type", 130, 0);     // left
    ft_table_add_column(tbl_files, "Modified Date", 170, 1); // center

    int r;
    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "ft.pas");
    ft_table_set_cell(tbl_files, r, 1, "88 KB");
    ft_table_set_cell(tbl_files, r, 2, "Pascal Shared Lib");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 18:30");

    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "ft.h");
    ft_table_set_cell(tbl_files, r, 1, "28 KB");
    ft_table_set_cell(tbl_files, r, 2, "C Public API");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 18:35");

    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "ft.widget.tabs.pas");
    ft_table_set_cell(tbl_files, r, 1, "14 KB");
    ft_table_set_cell(tbl_files, r, 2, "Tabs / Notebook");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 17:50");

    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "ft.widget.splitters.pas");
    ft_table_set_cell(tbl_files, r, 1, "12 KB");
    ft_table_set_cell(tbl_files, r, 2, "Dual-pane Splitter");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 18:00");

    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "ft.widget.treeviews.pas");
    ft_table_set_cell(tbl_files, r, 1, "13 KB");
    ft_table_set_cell(tbl_files, r, 2, "Hierarchical Tree");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 18:10");

    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "ft.widget.tables.pas");
    ft_table_set_cell(tbl_files, r, 1, "17 KB");
    ft_table_set_cell(tbl_files, r, 2, "DataGrid / Table");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 18:20");

    r = ft_table_add_row(tbl_files);
    ft_table_set_cell(tbl_files, r, 0, "libft.so");
    ft_table_set_cell(tbl_files, r, 1, "2.1 MB");
    ft_table_set_cell(tbl_files, r, 2, "ELF Shared Object");
    ft_table_set_cell(tbl_files, r, 3, "2026-09-17 18:40");

    ft_splitter_set_panes(split1, tree, tbl_files);
    ft_splitter_set_ratio(split1, 0.30);

    /* ===================================================================== */
    /* TAB 2: Data Table & Interactive Controls                              */
    /* ===================================================================== */
    FtTabPage tab2 = ft_notebook_add_tab(notebook, "Data Table & Grid", 1);

    s_data_table = ft_table_create(tab2, 15, 15, 890, 465);
    ft_table_on_select_row(s_data_table, on_table_row_selected, NULL);
    ft_table_add_column(s_data_table, "ID", 70, 1);          // center
    ft_table_add_column(s_data_table, "Product Name", 260, 0); // left
    ft_table_add_column(s_data_table, "Category", 180, 0);     // left
    ft_table_add_column(s_data_table, "Price", 140, 2);        // right
    ft_table_add_column(s_data_table, "Availability", 200, 1); // center

    const char* sample_data[6][5] = {
        {"101", "Floria Studio IDE Pro", "Development Tools", "$249.00", "Instant Download"},
        {"102", "AggPas Vector Graphics Engine", "Graphics Libraries", "$0.00 (Open Source)", "Available"},
        {"103", "Hardware Accelerated Canvas", "Rendering Subsystem", "$79.00", "In Stock"},
        {"104", "SVG 2.0 Vector Processor", "Parsers & Compilers", "$49.50", "In Stock"},
        {"105", "CSS3 Cascade Style Engine", "UI Layout & Styling", "$39.00", "In Stock"},
        {"106", "Unicode & HarfBuzz Shaper", "Typography", "$119.00", "Instant Download"}
    };

    for (int i = 0; i < 6; i++) {
        int row_idx = ft_table_add_row(s_data_table);
        for (int c = 0; c < 5; c++) {
            ft_table_set_cell(s_data_table, row_idx, c, sample_data[i][c]);
        }
    }

    /* Action buttons below table */
    FtWidget btn_add = ft_button_create(tab2, 15, 492, 130, 36, "+ Add Item");
    ft_button_on_click(btn_add, on_add_row_click, NULL);

    FtWidget btn_del = ft_button_create(tab2, 155, 492, 150, 36, "- Delete Selected");
    ft_button_on_click(btn_del, on_delete_row_click, NULL);

    FtWidget btn_grid = ft_button_create(tab2, 315, 492, 160, 36, "Toggle Gridlines");
    ft_button_on_click(btn_grid, on_toggle_grid_click, NULL);

    FtWidget btn_zebra = ft_button_create(tab2, 485, 492, 160, 36, "Toggle Zebra");
    ft_button_on_click(btn_zebra, on_toggle_zebra_click, NULL);

    /* ===================================================================== */
    /* TAB 3: Vertical Splitter                                              */
    /* ===================================================================== */
    FtTabPage tab3 = ft_notebook_add_tab(notebook, "Vertical Splitter", 1);

    FtSplitter split_v = ft_splitter_create(tab3, 10, 10, 900, 535, FT_SPLITTER_VERTICAL);
    ft_splitter_on_position_change(split_v, on_splitter_moved, NULL);

    FtWidget pane_top = ft_container_create(split_v, 0, 0, 900, 260);
    ft_container_set_corner_radius(pane_top, 6.0);
    ft_text_create(pane_top, 20, 20, 800, 30, "Top Pane: Drag the horizontal splitter bar below up/down to resize!");
    ft_text_create(pane_top, 20, 60, 800, 24, "Dual-orientation splitters support min-sizes, hover dots, and live cursor indicators.");

    FtWidget pane_bot = ft_container_create(split_v, 0, 0, 900, 260);
    ft_container_set_corner_radius(pane_bot, 6.0);
    ft_text_create(pane_bot, 20, 20, 800, 30, "Bottom Pane: Live layout recalculation across any container hierarchy.");
    ft_text_create(pane_bot, 20, 60, 800, 24, "Integrated with the Floria Toolkit theme engine, dark mode, and AggPas antialiased rendering.");

    ft_splitter_set_panes(split_v, pane_top, pane_bot);
    ft_splitter_set_ratio(split_v, 0.48);

    /* Bottom Status Bar */
    s_status_lbl = ft_text_create(win, 20, 630, 920, 24, "Ready. Switch tabs, drag splitter, expand tree nodes, or select table rows!");

    ft_main_loop();
    ft_quit();
    return 0;
}

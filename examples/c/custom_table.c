#include "ft.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Sample SVG icon strings */
static const char* SVG_FOLDER = 
    "<svg viewBox=\"0 0 24 24\" width=\"16\" height=\"16\">"
    "<path fill=\"#F59E0B\" d=\"M10 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z\"/>"
    "</svg>";

static const char* SVG_FILE = 
    "<svg viewBox=\"0 0 24 24\" width=\"16\" height=\"16\">"
    "<path fill=\"#3B82F6\" d=\"M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z\"/>"
    "</svg>";

static const char* SVG_GEAR = 
    "<svg viewBox=\"0 0 24 24\" width=\"16\" height=\"16\">"
    "<path fill=\"#8B5CF6\" d=\"M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58a.49.49 0 0 0 .12-.61l-1.92-3.32a.488.488 0 0 0-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54a.484.484 0 0 0-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58a.49.49 0 0 0-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z\"/>"
    "</svg>";

static const char* SVG_HEADER_INFO = 
    "<svg viewBox=\"0 0 24 24\" width=\"16\" height=\"16\">"
    "<circle cx=\"12\" cy=\"12\" r=\"10\" fill=\"#6366F1\"/>"
    "<path fill=\"#FFFFFF\" d=\"M11 7h2v2h-2zm0 4h2v6h-2z\"/>"
    "</svg>";

/* Owner-draw cell callback for status pills and progress bars */
static int32_t on_draw_custom_cell(FtTable table, void* canvas, int32_t row_idx, int32_t col_idx,
                                   double x, double y, double w, double h,
                                   int32_t is_selected, int32_t is_hovered, void* user_data) {
    (void)table;
    (void)is_selected;
    (void)is_hovered;
    (void)user_data;

    /* Column 2: Custom Status Badge (Active = emerald pill, Busy = amber pill, Offline = slate pill) */
    if (col_idx == 2) {
        double badgeW = 68.0;
        double badgeH = 18.0;
        double bx = x + (w - badgeW) * 0.5;
        double by = y + (h - badgeH) * 0.5;

        double r = 0.3, g = 0.3, b = 0.3;
        const char* label = "Offline";

        if (row_idx == 0) {
            r = 0.10; g = 0.70; b = 0.40; /* Emerald */
            label = "Active";
        } else if (row_idx == 1) {
            r = 0.95; g = 0.60; b = 0.10; /* Amber */
            label = "Pending";
        } else if (row_idx == 2) {
            r = 0.20; g = 0.55; b = 0.90; /* Sky */
            label = "Syncing";
        } else {
            r = 0.50; g = 0.55; b = 0.60; /* Slate */
            label = "Offline";
        }

        /* Draw badge rounded pill */
        ft_canvas_draw_rounded_rect(canvas, bx, by, badgeW, badgeH, 9.0, r, g, b, 0.85);
        /* Draw centered text inside badge */
        ft_canvas_draw_text_centered(canvas, (int32_t)bx, (int32_t)(by - 1.0), (int32_t)badgeW, (int32_t)badgeH, label, NULL, 1.0, 1.0, 1.0);
        return 1; /* Handled! */
    }

    /* Column 3: Custom Storage Progress Bar */
    if (col_idx == 3) {
        double barPadX = 10.0;
        double barW = w - barPadX * 2.0;
        double barH = 10.0;
        double bx = x + barPadX;
        double by = y + (h - barH) * 0.5;

        double pct = 0.25;
        if (row_idx == 0) pct = 0.82;
        else if (row_idx == 1) pct = 0.45;
        else if (row_idx == 2) pct = 0.68;
        else pct = 0.15;

        /* Draw background track */
        ft_canvas_draw_rounded_rect(canvas, bx, by, barW, barH, 5.0, 0.3, 0.35, 0.4, 0.35);
        /* Draw filled progress portion */
        ft_canvas_draw_rounded_rect(canvas, bx, by, barW * pct, barH, 5.0, 0.25, 0.65, 0.95, 0.90);
        return 1; /* Handled! */
    }

    return 0; /* Default drawing for other columns */
}

/* Owner-draw header callback for custom header styling */
static int32_t on_draw_custom_header(FtTable table, void* canvas, int32_t col_idx,
                                     double x, double y, double w, double h,
                                     int32_t sort_order, void* user_data) {
    (void)table;
    (void)sort_order;
    (void)user_data;

    /* Custom highlight for the status column */
    if (col_idx == 2) {
        /* Subtle indigo tint on column header */
        ft_canvas_draw_rounded_rect(canvas, x + 2.0, y + 2.0, w - 4.0, h - 4.0, 4.0, 0.35, 0.30, 0.80, 0.40);
        ft_canvas_draw_text_centered(canvas, (int32_t)x, (int32_t)y, (int32_t)w, (int32_t)h, "STATUS (Custom)", NULL, 0.95, 0.95, 1.0);
        return 1; /* Handled */
    }

    return 0; /* Default header for others */
}

static void on_dark_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(checked);
}

int main(void) {
    ft_init();

    FtWidget win = ft_window_create(820, 500, "Floria Toolkit - Table Customization & Owner-Draw Demo");

    /* Create sample icons */
    FtBitmap icon_folder = ft_bitmap_create_from_svg(SVG_FOLDER, 16, 16);
    FtBitmap icon_file = ft_bitmap_create_from_svg(SVG_FILE, 16, 16);
    FtBitmap icon_gear = ft_bitmap_create_from_svg(SVG_GEAR, 16, 16);
    FtBitmap icon_info = ft_bitmap_create_from_svg(SVG_HEADER_INFO, 16, 16);

    /* Description Label */
    ft_text_create(win, 25, 20, 500, 24, "Customized Table with Header Icons, Item Icons & Owner-Draw Callbacks");

    /* Dark Mode Switch */
    FtWidget sw_dark = ft_switch_create(win, 670, 18, 120, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_toggle, NULL);

    /* Main Table */
    FtTable table = ft_table_create(win, 25, 60, 770, 390);
    ft_table_set_row_height(table, 32.0);
    ft_table_set_header_height(table, 32.0);
    ft_table_set_show_gridlines(table, 1);
    ft_table_set_zebra_striping(table, 1);

    /* Add Columns */
    int col_name = ft_table_add_column(table, "Resource Name", 220.0, 0); /* 0 = left */
    int col_type = ft_table_add_column(table, "Category", 130.0, 0);
    ft_table_add_column(table, "Health / Status", 170.0, 1); /* 1 = center */
    ft_table_add_column(table, "Disk Usage", 210.0, 0);

    /* Set Header Icons */
    ft_table_set_column_icon(table, col_name, icon_info);
    ft_table_set_column_icon(table, col_type, icon_gear);

    /* Add Rows */
    int r1 = ft_table_add_row(table);
    ft_table_set_cell(table, r1, 0, "Documents");
    ft_table_set_cell(table, r1, 1, "Directory");
    ft_table_set_cell_icon(table, r1, 0, icon_folder);

    int r2 = ft_table_add_row(table);
    ft_table_set_cell(table, r2, 0, "system_config.xml");
    ft_table_set_cell(table, r2, 1, "Configuration");
    ft_table_set_cell_icon(table, r2, 0, icon_file);

    int r3 = ft_table_add_row(table);
    ft_table_set_cell(table, r3, 0, "Application Services");
    ft_table_set_cell(table, r3, 1, "Daemon Process");
    ft_table_set_cell_icon(table, r3, 0, icon_gear);

    int r4 = ft_table_add_row(table);
    ft_table_set_cell(table, r4, 0, "archive_backup.tar.gz");
    ft_table_set_cell(table, r4, 1, "Archive File");
    ft_table_set_cell_icon(table, r4, 0, icon_file);

    int r5 = ft_table_add_row(table);
    ft_table_set_cell(table, r5, 0, "Media Projects");
    ft_table_set_cell(table, r5, 1, "Directory");
    ft_table_set_cell_icon(table, r5, 0, icon_folder);

    /* Attach Owner-Draw Callbacks */
    ft_table_on_draw_header(table, on_draw_custom_header, NULL);
    ft_table_on_draw_cell(table, on_draw_custom_cell, NULL);

    ft_widget_show(win);
    ft_main_loop();

    /* Clean up bitmaps */
    ft_bitmap_destroy(icon_folder);
    ft_bitmap_destroy(icon_file);
    ft_bitmap_destroy(icon_gear);
    ft_bitmap_destroy(icon_info);

    ft_quit();
    return 0;
}

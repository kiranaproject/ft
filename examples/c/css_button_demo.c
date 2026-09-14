#include <stdio.h>
#include <stdlib.h>
#include "ft.h"

static const char* custom_css =
    "/* Base styling for all buttons that have a class */\n"
    "button.btn-primary {\n"
    "    background-color: #3b82f6;\n"
    "    color: #ffffff;\n"
    "    border-color: #2563eb;\n"
    "    border-width: 1px;\n"
    "    border-radius: 6px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "button.btn-primary:hover {\n"
    "    background-color: #2563eb;\n"
    "    border-color: #1d4ed8;\n"
    "}\n"
    "button.btn-primary:active {\n"
    "    background-color: #1d4ed8;\n"
    "}\n"
    "\n"
    "button.btn-success {\n"
    "    background-color: #10b981;\n"
    "    color: #ffffff;\n"
    "    border-color: #059669;\n"
    "    border-width: 1.5px;\n"
    "    border-radius: 18px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "button.btn-success:hover {\n"
    "    background-color: #059669;\n"
    "    border-color: #047857;\n"
    "}\n"
    "button.btn-success:active {\n"
    "    background-color: #047857;\n"
    "}\n"
    "\n"
    "button.btn-danger {\n"
    "    background-color: #ef4444;\n"
    "    color: #ffffff;\n"
    "    border-color: #dc2626;\n"
    "    border-width: 1px;\n"
    "    border-radius: 8px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "button.btn-danger:hover {\n"
    "    background-color: #dc2626;\n"
    "}\n"
    "button.btn-danger:active {\n"
    "    background-color: #b91c1c;\n"
    "}\n"
    "\n"
    "/* ID selector targeting #amber-card */\n"
    "#amber-card {\n"
    "    background-color: #f59e0b;\n"
    "    color: #1f2937;\n"
    "    border-color: #d97706;\n"
    "    border-width: 2px;\n"
    "    border-radius: 12px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "#amber-card:hover {\n"
    "    background-color: #d97706;\n"
    "    color: #ffffff;\n"
    "}\n";

static const char* neon_css =
    "button.btn-primary {\n"
    "    background-color: #06b6d4;\n"
    "    color: #082f49;\n"
    "    border-color: #0891b2;\n"
    "    border-width: 2px;\n"
    "    border-radius: 2px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "button.btn-primary:hover {\n"
    "    background-color: #22d3ee;\n"
    "}\n"
    "\n"
    "button.btn-success {\n"
    "    background-color: #84cc16;\n"
    "    color: #14532d;\n"
    "    border-color: #65a30d;\n"
    "    border-width: 2px;\n"
    "    border-radius: 2px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "button.btn-success:hover {\n"
    "    background-color: #a3e635;\n"
    "}\n"
    "\n"
    "button.btn-danger {\n"
    "    background-color: #ec4899;\n"
    "    color: #ffffff;\n"
    "    border-color: #db2777;\n"
    "    border-width: 2px;\n"
    "    border-radius: 2px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "button.btn-danger:hover {\n"
    "    background-color: #f472b6;\n"
    "}\n"
    "\n"
    "#amber-card {\n"
    "    background-color: #6366f1;\n"
    "    color: #ffffff;\n"
    "    border-color: #4f46e5;\n"
    "    border-width: 2px;\n"
    "    border-radius: 2px;\n"
    "    box-shadow: 1;\n"
    "}\n"
    "#amber-card:hover {\n"
    "    background-color: #818cf8;\n"
    "}\n";

static int current_theme_idx = 0;

static void on_swap_theme_click(FtWidget widget, void* user_data) {
    current_theme_idx = 1 - current_theme_idx;
    if (current_theme_idx == 1) {
        ft_style_load_css_string(neon_css);
        printf("[CSS] Swapped to Neon / Cyberpunk CSS theme!\n");
    } else {
        ft_style_load_css_string(custom_css);
        printf("[CSS] Swapped back to Modern Flat CSS theme!\n");
    }
}

static void on_btn_click(FtWidget widget, void* user_data) {
    const char* label = (const char*)user_data;
    printf("[Click] Button clicked: %s\n", label);
}

int main(int argc, char* argv[]) {
    ft_init();

    FtWidget win = ft_window_create(640, 480, "Floria Toolkit - CSS Button Styling Demo");

    /* 1. Header description */
    ft_text_create(win, 30, 20, 580, 26, "CSS Styling Engine (backed by fcl-css)");

    /* 2. Load the initial CSS rules into global stylesheet */
    int load_res = ft_style_load_css_string(custom_css);
    printf("CSS Stylesheet loaded: %s\n", load_res ? "SUCCESS" : "FAILED");

    /* Button 1: Unstyled default button (uses Floria Theme) */
    ft_text_create(win, 30, 60, 280, 20, "Standard / Unstyled (Theme fallback):");
    FtWidget btn_default = ft_button_create(win, 30, 85, 270, 38, "Theme Default Button");
    ft_button_on_click(btn_default, on_btn_click, "Default Theme");

    /* Button 2: CSS Class .btn-primary */
    ft_text_create(win, 340, 60, 280, 20, "CSS Class (.btn-primary):");
    FtWidget btn_primary = ft_button_create(win, 340, 85, 270, 38, "Primary Button");
    ft_widget_set_style_class(btn_primary, "btn-primary");
    ft_button_on_click(btn_primary, on_btn_click, "Primary");

    /* Button 3: CSS Class .btn-success (Pill shape) */
    ft_text_create(win, 30, 145, 280, 20, "CSS Class (.btn-success / Pill):");
    FtWidget btn_success = ft_button_create(win, 30, 170, 270, 38, "Pill Success Button");
    ft_widget_set_style_class(btn_success, "btn-success");
    ft_button_on_click(btn_success, on_btn_click, "Success Pill");

    /* Button 4: CSS Class .btn-danger */
    ft_text_create(win, 340, 145, 280, 20, "CSS Class (.btn-danger):");
    FtWidget btn_danger = ft_button_create(win, 340, 170, 270, 38, "Danger Button");
    ft_widget_set_style_class(btn_danger, "btn-danger");
    ft_button_on_click(btn_danger, on_btn_click, "Danger");

    /* Button 5: CSS ID Selector #amber-card */
    ft_text_create(win, 30, 230, 280, 20, "CSS ID Selector (#amber-card):");
    FtWidget btn_amber = ft_button_create(win, 30, 255, 270, 38, "Amber Card Button");
    ft_widget_set_style_id(btn_amber, "amber-card");
    ft_button_on_click(btn_amber, on_btn_click, "Amber Card");

    /* Button 6: Inline CSS style (ft_widget_set_style) */
    ft_text_create(win, 340, 230, 280, 20, "Inline CSS (ft_widget_set_style):");
    FtWidget btn_inline = ft_button_create(win, 340, 255, 270, 38, "Purple Inline Style");
    ft_widget_set_style(btn_inline, "background-color: #8b5cf6; color: #ffffff; border-radius: 14px; border-width: 2px; border-color: #7c3aed; box-shadow: 1;");
    ft_button_on_click(btn_inline, on_btn_click, "Inline Purple");

    /* Dynamic CSS Hot-Swap Trigger */
    FtWidget btn_swap = ft_button_create(win, 170, 320, 300, 38, "Swap Stylesheet (Neon Theme)");
    ft_button_on_click(btn_swap, on_swap_theme_click, NULL);

    /* Status labels at bottom */
    ft_text_create(win, 30, 380, 580, 20, "Hover or click the buttons to see hover/active pseudo-class state changes.");
    ft_text_create(win, 30, 405, 580, 20, "Click 'Swap Stylesheet' above to hot-swap between CSS themes at runtime.");
    ft_text_create(win, 30, 430, 580, 20, "Unstyled widgets retain theme defaults while CSS widgets instantly restyle!");

    ft_widget_show(win);
    ft_main_loop();
    ft_quit();
    return 0;
}

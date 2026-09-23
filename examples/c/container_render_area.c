#include "ft.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    ft_init();

    FtWidget win = ft_window_create(960, 560, "Floria Toolkit - Dynamic Container Render Area Demo");
    ft_widget_show(win);

    /* Title & Explanation */
    ft_text_create(win, 30, 20, 900, 32, "Dynamic Container Render Area Conformance");
    ft_text_create(win, 30, 55, 900, 24, "Child items automatically conform to container shape (0px sharp, 16px rounded, 28px squircle) with zero per-widget edits.");

    double radii[3] = {0.0, 16.0, 28.0};
    const char* titles[3] = {
        "Card 1: 0px Sharp Corner",
        "Card 2: 16px Rounded Corner",
        "Card 3: 28px Squircle / Pill Corner"
    };
    const char* header_styles[3] = {
        "background-color: #2563EB; color: #FFFFFF; font-weight: bold; border-radius: 0px;",
        "background-color: #7C3AED; color: #FFFFFF; font-weight: bold; border-radius: 0px;",
        "background-color: #059669; color: #FFFFFF; font-weight: bold; border-radius: 0px;"
    };

    for (int i = 0; i < 3; i++) {
        int card_x = 30 + i * 305;
        int card_y = 100;
        int card_w = 285;
        int card_h = 420;

        /* Outer Container with specific corner radius */
        FtWidget card = ft_container_create(win, card_x, card_y, card_w, card_h);
        ft_container_set_corner_radius(card, radii[i]);
        ft_container_set_scrollbar_mode(card, 0); /* ftSbModeNone */
        ft_container_set_padding(card, 0.0, 0.0); /* Full bleed inside! */

        /* Query dynamic render area */
        double rx, ry, rw, rh, rrad;
        ft_container_get_render_area(card, &rx, &ry, &rw, &rh, &rrad);

        /* Full-bleed Header Banner (a child container drawn flush against the top/left/right edges) */
        /* Notice: child has NO custom rounded code; it's a simple rectangular container! */
        FtWidget banner = ft_container_create(card, 0, 0, card_w, 65);
        ft_widget_set_style(banner, header_styles[i]);
        ft_container_set_draw_frame(banner, 0);
        ft_container_set_scrollbar_mode(banner, 0);
        ft_container_set_padding(banner, 0.0, 0.0);

        char title_buf[64];
        snprintf(title_buf, sizeof(title_buf), "%s", titles[i]);
        FtWidget lbl_t = ft_text_create(banner, 16, 12, card_w - 32, 22, title_buf);
        ft_widget_set_style(lbl_t, "color: #FFFFFF; font-size: 14px; font-weight: bold;");

        char rad_buf[64];
        snprintf(rad_buf, sizeof(rad_buf), "Inner Radius: %.1f px", rrad);
        FtWidget lbl_r = ft_text_create(banner, 16, 36, card_w - 32, 18, rad_buf);
        ft_widget_set_style(lbl_r, "color: #E2E8F0; font-size: 12px;");

        /* Interior Content Area */
        ft_text_create(card, 16, 85, card_w - 32, 20, "Child widgets and fills rendered");
        ft_text_create(card, 16, 110, card_w - 32, 20, "inside this container adhere");
        ft_text_create(card, 16, 135, card_w - 32, 20, "to the exact inner contour.");
        ft_text_create(card, 16, 160, card_w - 32, 20, "Zero per-widget styling hacks!");

        /* Child Buttons inside card */
        FtWidget btn1 = ft_button_create(card, 16, 210, card_w - 32, 36, "Interactive Action");
        (void)btn1;

        FtWidget btn2 = ft_button_create(card, 16, 255, card_w - 32, 36, "Secondary Option");
        (void)btn2;

        /* Bottom Full-Bleed Footer Banner */
        FtWidget footer = ft_container_create(card, 0, card_h - 45, card_w, 45);
        ft_widget_set_style(footer, "background-color: #1E293B; border-radius: 0px;");
        ft_container_set_draw_frame(footer, 0);
        ft_container_set_scrollbar_mode(footer, 0);
        ft_container_set_padding(footer, 0.0, 0.0);

        FtWidget foot_lbl = ft_text_create(footer, 16, 14, card_w - 32, 20, "Bottom Footer (Auto-clipped)");
        ft_widget_set_style(foot_lbl, "color: #94A3B8; font-size: 12px; font-weight: bold;");
    }

    ft_main_loop();
    ft_quit();
    return 0;
}

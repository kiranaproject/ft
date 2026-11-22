#include "ft.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>

/* Embedded 3-frame animated GIF test fixture (32x32, 3 frames) */
static const uint8_t s_sample_gif[423] = {
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x20, 0x00, 0x20, 0x00, 0x81, 0x00, 0x00, 0xFF, 0xFF, 0xFF,
    0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0xFF, 0x0B, 0x4E, 0x45, 0x54, 0x53,
    0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30, 0x03, 0x01, 0x00, 0x00, 0x00, 0x21, 0xF9, 0x04, 0x00,
    0x0A, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x20, 0x00, 0x00, 0x08, 0x61,
    0x00, 0x03, 0x08, 0x1C, 0x48, 0xB0, 0xA0, 0x40, 0x00, 0x08, 0x13, 0x2A, 0x5C, 0x68, 0xB0, 0x21,
    0xC1, 0x85, 0x10, 0x15, 0x3A, 0x9C, 0x18, 0xB1, 0xE2, 0x44, 0x87, 0x15, 0x23, 0x5E, 0x6C, 0x98,
    0x11, 0xE2, 0x46, 0x83, 0x1D, 0x19, 0x7E, 0x7C, 0x18, 0x32, 0xE1, 0x48, 0x92, 0x25, 0x01, 0x9C,
    0x1C, 0x98, 0x12, 0xE1, 0xCA, 0x83, 0x2D, 0x5F, 0x06, 0x68, 0xA9, 0xF2, 0x25, 0x4D, 0x99, 0x37,
    0x6D, 0xC6, 0xD4, 0x99, 0x12, 0xE7, 0xCE, 0x95, 0x34, 0x83, 0x0A, 0x1D, 0x4A, 0xB4, 0xA8, 0xD1,
    0xA3, 0x48, 0x93, 0x2A, 0x5D, 0xCA, 0xB4, 0xA9, 0xD3, 0xA7, 0x50, 0xA3, 0x4A, 0x9D, 0xBA, 0x30,
    0x20, 0x00, 0x21, 0xF9, 0x04, 0x01, 0x0F, 0x00, 0x02, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x19,
    0x00, 0x19, 0x00, 0x81, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x08, 0x62, 0x00, 0x01, 0x08, 0x1C, 0x48, 0xB0, 0xA0, 0x40, 0x01, 0x08, 0x13, 0x22, 0x34, 0xC8,
    0x90, 0xA0, 0x42, 0x85, 0x0D, 0x23, 0x3E, 0x4C, 0x18, 0xB1, 0xE1, 0xC4, 0x85, 0x15, 0x0D, 0x5E,
    0x14, 0x90, 0x51, 0xE3, 0xC5, 0x8E, 0x05, 0x37, 0x82, 0x74, 0xF8, 0x91, 0x61, 0x80, 0x93, 0x28,
    0x53, 0xAA, 0x3C, 0xD9, 0x70, 0xA5, 0xCB, 0x94, 0x2D, 0x5F, 0xBE, 0x8C, 0x29, 0x73, 0x25, 0xCD,
    0x9A, 0x30, 0x4D, 0xE2, 0x54, 0x79, 0x73, 0x67, 0x80, 0x9E, 0x3B, 0x81, 0xE2, 0xDC, 0xE8, 0x33,
    0x25, 0xD1, 0xA2, 0x27, 0x8F, 0x22, 0x55, 0x5A, 0x94, 0xA9, 0x4F, 0xA7, 0x3B, 0xA1, 0x0E, 0xBD,
    0x88, 0xF4, 0x64, 0x40, 0x00, 0x21, 0xF9, 0x04, 0x01, 0x14, 0x00, 0x02, 0x00, 0x2C, 0x08, 0x00,
    0x08, 0x00, 0x18, 0x00, 0x18, 0x00, 0x81, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x08, 0x60, 0x00, 0x01, 0x08, 0x1C, 0x48, 0xB0, 0xA0, 0x40, 0x01, 0x08, 0x13,
    0x0A, 0x30, 0xC8, 0x90, 0xA0, 0xC2, 0x84, 0x0D, 0x23, 0x3E, 0x44, 0x18, 0xB1, 0xE1, 0xC4, 0x85,
    0x15, 0x0D, 0x5E, 0xCC, 0xA8, 0x71, 0x22, 0xC7, 0x82, 0x1B, 0x3F, 0x0E, 0x0C, 0x69, 0x30, 0x80,
    0xC9, 0x93, 0x28, 0x53, 0x06, 0x68, 0xA8, 0xB2, 0xE5, 0x49, 0x96, 0x2E, 0x5B, 0xC2, 0x8C, 0x99,
    0x72, 0x26, 0xCD, 0x97, 0x0C, 0x6F, 0xD6, 0xCC, 0xA9, 0x13, 0x67, 0xC9, 0x9E, 0x26, 0x6D, 0xEA,
    0xBC, 0x28, 0x00, 0xA8, 0x49, 0xA2, 0x46, 0x03, 0x20, 0x35, 0xBA, 0x14, 0x68, 0xD3, 0x9E, 0x4F,
    0x87, 0x5E, 0x4C, 0x1A, 0x10, 0x00, 0x3B
};

/* Embedded 3-frame animated PNG (APNG) test fixture (32x32, 3 frames) */
static const uint8_t s_sample_apng[360] = {
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20, 0x08, 0x06, 0x00, 0x00, 0x00, 0x73, 0x7A, 0x7A,
    0xF4, 0x00, 0x00, 0x00, 0x08, 0x61, 0x63, 0x54, 0x4C, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
    0x00, 0xCE, 0xED, 0xBA, 0xC0, 0x00, 0x00, 0x00, 0x1A, 0x66, 0x63, 0x54, 0x4C, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x00, 0x0A, 0x00, 0x00, 0x9A, 0x27, 0x23, 0xEA, 0x00, 0x00, 0x00, 0x35, 0x49,
    0x44, 0x41, 0x54, 0x78, 0x9C, 0xED, 0xCE, 0xB1, 0x11, 0x00, 0x20, 0x0C, 0x03, 0x31, 0x87, 0xA9,
    0xD8, 0xBF, 0x62, 0x2B, 0xD8, 0x81, 0x14, 0x69, 0xA4, 0xDE, 0xE7, 0xAF, 0x9B, 0x9C, 0x34, 0x55,
    0xB2, 0x7F, 0xB7, 0xAB, 0x7B, 0xDE, 0x25, 0x40, 0x80, 0x00, 0x01, 0x02, 0x04, 0x08, 0x18, 0x0F,
    0x00, 0x00, 0xC6, 0x3D, 0xC8, 0xFB, 0x02, 0x22, 0x8F, 0x83, 0xA3, 0xC5, 0x00, 0x00, 0x00, 0x1A,
    0x66, 0x63, 0x54, 0x4C, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x19, 0x00, 0x00, 0x00, 0x19,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x14, 0x00, 0x00, 0x3C, 0x7C,
    0x72, 0x59, 0x00, 0x00, 0x00, 0x30, 0x66, 0x64, 0x41, 0x54, 0x00, 0x00, 0x00, 0x02, 0x78, 0x9C,
    0xED, 0xCD, 0x31, 0x11, 0x00, 0x00, 0x08, 0xC3, 0xC0, 0x80, 0x7F, 0x61, 0xB8, 0x02, 0x09, 0x0C,
    0x5D, 0x93, 0xB9, 0xD7, 0x07, 0x33, 0xFB, 0xAA, 0x77, 0xB1, 0x4C, 0x8A, 0x74, 0x7A, 0x20, 0x22,
    0x22, 0x22, 0x22, 0x22, 0x02, 0x1C, 0x2A, 0x4B, 0x01, 0xE9, 0x8E, 0xEE, 0x66, 0x76, 0x00, 0x00,
    0x00, 0x1A, 0x66, 0x63, 0x54, 0x4C, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00,
    0x00, 0x18, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x08, 0x00, 0x01, 0x00, 0x05, 0x00, 0x00,
    0x51, 0xFB, 0xCF, 0x05, 0x00, 0x00, 0x00, 0x2C, 0x66, 0x64, 0x41, 0x54, 0x00, 0x00, 0x00, 0x04,
    0x78, 0x9C, 0x63, 0x60, 0x18, 0x05, 0xA3, 0x60, 0x14, 0x30, 0x12, 0x56, 0xF2, 0xFF, 0x04, 0x25,
    0x16, 0x30, 0x51, 0xA2, 0x79, 0xD4, 0x82, 0x51, 0x0B, 0x46, 0x2D, 0x18, 0xB5, 0x60, 0xD4, 0x02,
    0x7A, 0x59, 0x00, 0x00, 0xF2, 0x21, 0x01, 0xE7, 0x97, 0x54, 0x63, 0x55, 0x00, 0x00, 0x00, 0x00,
    0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
};

/* Embedded SMIL animated SVG test fixture (200x200, rotating group, pulsing nodes, color cycling) */
static const char* s_sample_svg =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 200 200\" width=\"200\" height=\"200\">\n"
    "  <defs>\n"
    "    <linearGradient id=\"grad1\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\">\n"
    "      <stop offset=\"0%\" stop-color=\"#38bdf8\"/>\n"
    "      <stop offset=\"100%\" stop-color=\"#818cf8\"/>\n"
    "    </linearGradient>\n"
    "  </defs>\n"
    "  <rect width=\"200\" height=\"200\" rx=\"24\" fill=\"#0f172a\"/>\n"
    "  <circle cx=\"100\" cy=\"100\" r=\"65\" fill=\"none\" stroke=\"#334155\" stroke-width=\"4\" stroke-dasharray=\"6 6\"/>\n"
    "  <g id=\"rotor\">\n"
    "    <animateTransform attributeName=\"transform\" type=\"rotate\" from=\"0 100 100\" to=\"360 100 100\" dur=\"3s\" repeatCount=\"indefinite\"/>\n"
    "    <circle cx=\"100\" cy=\"35\" r=\"14\" fill=\"#06b6d4\">\n"
    "      <animate attributeName=\"r\" values=\"10; 18; 10\" dur=\"1.5s\" repeatCount=\"indefinite\"/>\n"
    "      <animate attributeName=\"opacity\" values=\"0.6; 1.0; 0.6\" dur=\"1.5s\" repeatCount=\"indefinite\"/>\n"
    "    </circle>\n"
    "    <circle cx=\"100\" cy=\"165\" r=\"12\" fill=\"#f59e0b\">\n"
    "      <animate attributeName=\"fill\" values=\"#f59e0b; #ef4444; #10b981; #f59e0b\" dur=\"3s\" repeatCount=\"indefinite\"/>\n"
    "    </circle>\n"
    "    <circle cx=\"35\" cy=\"100\" r=\"10\" fill=\"#a855f7\"/>\n"
    "    <circle cx=\"165\" cy=\"100\" r=\"10\" fill=\"#10b981\"/>\n"
    "  </g>\n"
    "  <circle cx=\"100\" cy=\"100\" r=\"32\" fill=\"url(#grad1)\">\n"
    "    <animate attributeName=\"r\" values=\"26; 38; 26\" dur=\"2s\" repeatCount=\"indefinite\"/>\n"
    "  </circle>\n"
    "  <circle cx=\"100\" cy=\"100\" r=\"16\" fill=\"#ffffff\">\n"
    "    <animate attributeName=\"opacity\" values=\"0.4; 0.95; 0.4\" dur=\"1s\" repeatCount=\"indefinite\"/>\n"
    "  </circle>\n"
    "</svg>\n";

static FtWidget s_win = NULL;
static FtWidget s_img = NULL;
static FtWidget s_lbl_info = NULL;
static FtWidget s_lbl_status = NULL;

static void update_status_labels(void) {
    if (!s_img) return;

    int total_frames = ft_image_get_frame_count(s_img);
    int current_frame = ft_image_get_current_frame(s_img);
    int is_playing = ft_image_is_playing(s_img);
    int is_svg_anim = ft_image_is_svg_animated(s_img);

    char info_buf[256];
    if (is_svg_anim) {
        snprintf(info_buf, sizeof(info_buf),
                 "Format: Animated SVG (SMIL Vector)  |  State: %s  |  Resolution: Native Vector (Scale Independent)",
                 is_playing ? "Playing (60 FPS SMIL continuous)" : "Paused / Stopped");
    } else {
        snprintf(info_buf, sizeof(info_buf),
                 "Frames: %d  |  Current Index: %d  |  State: %s",
                 total_frames, current_frame,
                 is_playing ? "Playing (60 FPS ticker)" : "Paused / Stopped");
    }

    if (s_lbl_info) {
        ft_text_set_text(s_lbl_info, info_buf);
    }
}

static void on_play_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        ft_image_play(s_img);
        update_status_labels();
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, "Action: Started playback");
        printf("[AnimatedImages] Playback started\n");
    }
}

static void on_pause_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        ft_image_pause(s_img);
        update_status_labels();
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, "Action: Paused playback");
        printf("[AnimatedImages] Playback paused\n");
    }
}

static void on_stop_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        ft_image_stop(s_img);
        update_status_labels();
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, "Action: Stopped playback (rewound to frame 0)");
        printf("[AnimatedImages] Playback stopped\n");
    }
}

static void on_prev_frame_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        int cur = ft_image_get_current_frame(s_img);
        if (cur > 0)
            ft_image_set_current_frame(s_img, cur - 1);
        else {
            int count = ft_image_get_frame_count(s_img);
            if (count > 0)
                ft_image_set_current_frame(s_img, count - 1);
        }
        update_status_labels();
    }
}

static void on_next_frame_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        int cur = ft_image_get_current_frame(s_img);
        int count = ft_image_get_frame_count(s_img);
        if (count > 0)
            ft_image_set_current_frame(s_img, (cur + 1) % count);
        update_status_labels();
    }
}

static void on_scale_mode_click(FtWidget widget, void* user_data) {
    (void)widget;
    int mode = (int)(intptr_t)user_data;
    if (s_img) {
        ft_image_set_scale_mode(s_img, mode);
        const char* mode_name = "Fit";
        if (mode == FT_IMAGE_SCALE_STRETCH) mode_name = "Stretch";
        else if (mode == FT_IMAGE_SCALE_CENTER) mode_name = "Center (1:1)";
        else if (mode == FT_IMAGE_SCALE_NONE) mode_name = "None (Top-Left 1:1)";

        char buf[128];
        snprintf(buf, sizeof(buf), "Action: Set scale mode to %s", mode_name);
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, buf);
        printf("[AnimatedImages] Scale mode changed to: %s\n", mode_name);
    }
}

static void on_load_gif_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        ft_image_load_memory(s_img, s_sample_gif, sizeof(s_sample_gif));
        update_status_labels();
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, "Loaded sample GIF (3 frames, 32x32)");
        printf("[AnimatedImages] Loaded sample GIF\n");
    }
}

static void on_load_apng_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        ft_image_load_memory(s_img, s_sample_apng, sizeof(s_sample_apng));
        update_status_labels();
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, "Loaded sample APNG (3 frames, 32x32)");
        printf("[AnimatedImages] Loaded sample APNG\n");
    }
}

static void on_load_svg_click(FtWidget widget, void* user_data) {
    (void)widget;
    (void)user_data;
    if (s_img) {
        ft_image_load_svg_string(s_img, s_sample_svg);
        update_status_labels();
        if (s_lbl_status)
            ft_text_set_text(s_lbl_status, "Loaded sample animated SVG (SMIL rotation, radius pulse, color cycling)");
        printf("[AnimatedImages] Loaded sample animated SVG\n");
    }
}

static void on_dark_mode_toggle(FtWidget widget, int32_t checked, void* user_data) {
    (void)widget;
    (void)user_data;
    ft_theme_set_dark_mode(checked);
    printf("[AnimatedImages] Dark mode: %s\n", checked ? "ON" : "OFF");
}

int main(int argc, char** argv) {
    ft_init();

    printf("[AnimatedImages] Initializing Floria Toolkit Animated Image Player...\n");

    s_win = ft_window_create(860, 620, "Floria Toolkit — Animated Image Player");

    /* Root vertical flexbox layout */
    FtWidget root_vbox = ft_vbox_create(s_win, 0, 0, 860, 620);
    ft_flexbox_set_gap(root_vbox, 12);
    ft_container_set_padding(root_vbox, 14, 14);
    ft_window_set_layout(s_win, root_vbox);

    /* ── Top Bar: Title & Theme Switch ── */
    FtWidget top_bar = ft_hbox_create(root_vbox, 0, 0, 0, 36);
    ft_flexbox_set_gap(top_bar, 10);
    ft_flexbox_set_align_items(top_bar, FT_ALIGN_CENTER);
    ft_widget_set_flex_grow(top_bar, 0.0);

    FtWidget title = ft_text_create(top_bar, 0, 0, 0, 30, "🎞 Animated GIF, APNG & SVG Viewer");
    ft_text_set_selectable(title, 0);
    ft_widget_set_flex_grow(title, 1.0);

    FtWidget sw_dark = ft_switch_create(top_bar, 0, 0, 130, 26, "Dark Mode");
    ft_switch_set_checked(sw_dark, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw_dark, on_dark_mode_toggle, NULL);

    /* ── Workspace: Split into Viewport (left) and Controls (right) ── */
    FtWidget workspace = ft_hbox_create(root_vbox, 0, 0, 0, 0);
    ft_flexbox_set_gap(workspace, 14);
    ft_widget_set_flex_grow(workspace, 1.0);

    /* Left Viewport Panel */
    FtWidget viewport_panel = ft_vbox_create(workspace, 0, 0, 0, 0);
    ft_container_set_padding(viewport_panel, 12, 12);
    ft_container_set_draw_frame(viewport_panel, 1);
    ft_container_set_corner_radius(viewport_panel, 8.0);
    ft_widget_set_flex_grow(viewport_panel, 1.0);

    /* Image Widget inside Viewport */
    s_img = ft_image_create(viewport_panel, 0, 0, 0, 0, "");
    ft_widget_set_flex_grow(s_img, 1.0);
    ft_image_set_scale_mode(s_img, FT_IMAGE_SCALE_FIT);

    /* Load input file if given, otherwise load embedded GIF */
    if (argc > 1 && argv[1] != NULL && argv[1][0] != '\0') {
        printf("[AnimatedImages] Loading external file: %s\n", argv[1]);
        ft_image_load_file(s_img, argv[1]);
    } else {
        printf("[AnimatedImages] Loading default embedded GIF fixture\n");
        ft_image_load_memory(s_img, s_sample_gif, sizeof(s_sample_gif));
    }

    /* Right Control Sidebar */
    FtWidget controls_panel = ft_vbox_create(workspace, 0, 0, 260, 0);
    ft_flexbox_set_gap(controls_panel, 8);
    ft_container_set_padding(controls_panel, 12, 12);
    ft_container_set_draw_frame(controls_panel, 1);
    ft_container_set_corner_radius(controls_panel, 8.0);
    ft_widget_set_flex_grow(controls_panel, 0.0);

    FtWidget lbl_ctrl_title = ft_text_create(controls_panel, 0, 0, 236, 24, "Playback Controls");
    ft_text_set_selectable(lbl_ctrl_title, 0);

    /* Play / Pause / Stop buttons */
    FtWidget btn_play = ft_button_create(controls_panel, 0, 0, 236, 32, "▶ Play");
    ft_button_on_click(btn_play, on_play_click, NULL);

    FtWidget btn_pause = ft_button_create(controls_panel, 0, 0, 236, 32, "⏸ Pause");
    ft_button_on_click(btn_pause, on_pause_click, NULL);

    FtWidget btn_stop = ft_button_create(controls_panel, 0, 0, 236, 32, "⏹ Stop");
    ft_button_on_click(btn_stop, on_stop_click, NULL);

    /* Frame stepping row */
    FtWidget step_row = ft_hbox_create(controls_panel, 0, 0, 236, 32);
    ft_flexbox_set_gap(step_row, 6);
    ft_widget_set_flex_grow(step_row, 0.0);

    FtWidget btn_prev = ft_button_create(step_row, 0, 0, 0, 32, "⏮ Prev");
    ft_widget_set_flex_grow(btn_prev, 1.0);
    ft_button_on_click(btn_prev, on_prev_frame_click, NULL);

    FtWidget btn_next = ft_button_create(step_row, 0, 0, 0, 32, "⏭ Next");
    ft_widget_set_flex_grow(btn_next, 1.0);
    ft_button_on_click(btn_next, on_next_frame_click, NULL);

    /* Scale mode buttons */
    FtWidget lbl_scale = ft_text_create(controls_panel, 0, 0, 236, 22, "Scaling Modes");
    ft_text_set_selectable(lbl_scale, 0);

    FtWidget btn_fit = ft_button_create(controls_panel, 0, 0, 236, 30, "Scale: Fit (Aspect Ratio)");
    ft_button_on_click(btn_fit, on_scale_mode_click, (void*)(intptr_t)FT_IMAGE_SCALE_FIT);

    FtWidget btn_stretch = ft_button_create(controls_panel, 0, 0, 236, 30, "Scale: Stretch");
    ft_button_on_click(btn_stretch, on_scale_mode_click, (void*)(intptr_t)FT_IMAGE_SCALE_STRETCH);

    FtWidget btn_center = ft_button_create(controls_panel, 0, 0, 236, 30, "Scale: Center 1:1");
    ft_button_on_click(btn_center, on_scale_mode_click, (void*)(intptr_t)FT_IMAGE_SCALE_CENTER);

    FtWidget btn_none = ft_button_create(controls_panel, 0, 0, 236, 30, "Scale: Top-Left 1:1");
    ft_button_on_click(btn_none, on_scale_mode_click, (void*)(intptr_t)FT_IMAGE_SCALE_NONE);

    /* Switch embedded samples */
    FtWidget lbl_samples = ft_text_create(controls_panel, 0, 0, 236, 22, "Built-in Fixtures");
    ft_text_set_selectable(lbl_samples, 0);

    FtWidget btn_sample_gif = ft_button_create(controls_panel, 0, 0, 236, 30, "Load Sample GIF");
    ft_button_on_click(btn_sample_gif, on_load_gif_click, NULL);

    FtWidget btn_sample_apng = ft_button_create(controls_panel, 0, 0, 236, 30, "Load Sample APNG");
    ft_button_on_click(btn_sample_apng, on_load_apng_click, NULL);

    FtWidget btn_sample_svg = ft_button_create(controls_panel, 0, 0, 236, 30, "Load Sample SVG");
    ft_button_on_click(btn_sample_svg, on_load_svg_click, NULL);

    /* ── Bottom Status Bar ── */
    FtWidget bottom_bar = ft_vbox_create(root_vbox, 0, 0, 0, 48);
    ft_flexbox_set_gap(bottom_bar, 2);
    ft_container_set_padding(bottom_bar, 6, 8);
    ft_container_set_draw_frame(bottom_bar, 1);
    ft_container_set_corner_radius(bottom_bar, 6.0);
    ft_widget_set_flex_grow(bottom_bar, 0.0);

    s_lbl_info = ft_text_create(bottom_bar, 0, 0, 0, 20, "Metadata: Ready");
    ft_text_set_selectable(s_lbl_info, 0);

    s_lbl_status = ft_text_create(bottom_bar, 0, 0, 0, 20, "Ready. Use buttons to control playback or pass image path as argument.");
    ft_text_set_selectable(s_lbl_status, 0);

    update_status_labels();

    ft_flexbox_update_layout(root_vbox);
    ft_widget_show(s_win);

    printf("[AnimatedImages] Starting event loop...\n");
    ft_main_loop();
    ft_quit();

    return 0;
}

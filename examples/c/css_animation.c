#include <stdio.h>
#include <stdlib.h>
#include "ft.h"

static const char* animation_css =
    "/* Button 1: Smooth Background & Text Color Transition */\n"
    "button.btn-color-morph {\n"
    "    background-color: #4338ca;\n"
    "    color: #ffffff;\n"
    "    border-color: #3730a3;\n"
    "    border-width: 1.5px;\n"
    "    border-radius: 8px;\n"
    "    box-shadow: 1;\n"
    "    transition: background-color 400ms ease-out, border-color 400ms ease-out;\n"
    "}\n"
    "button.btn-color-morph:hover {\n"
    "    background-color: #06b6d4;\n"
    "    border-color: #0891b2;\n"
    "    color: #082f49;\n"
    "}\n"
    "button.btn-color-morph:active {\n"
    "    background-color: #059669;\n"
    "    border-color: #047857;\n"
    "    color: #ffffff;\n"
    "}\n"
    "\n"
    "/* Button 2: Morphing Shape (Rectangle -> Pill) */\n"
    "button.btn-pill-morph {\n"
    "    background-color: #3b82f6;\n"
    "    color: #ffffff;\n"
    "    border-color: #2563eb;\n"
    "    border-width: 1.5px;\n"
    "    border-radius: 4px;\n"
    "    box-shadow: 1;\n"
    "    transition: border-radius 350ms ease-in-out, background-color 350ms ease-in-out;\n"
    "}\n"
    "button.btn-pill-morph:hover {\n"
    "    background-color: #8b5cf6;\n"
    "    border-color: #7c3aed;\n"
    "    border-radius: 20px;\n"
    "}\n"
    "button.btn-pill-morph:active {\n"
    "    background-color: #6d28d9;\n"
    "    border-radius: 12px;\n"
    "}\n"
    "\n"
    "/* Button 3: Pulsing Border Width & Color */\n"
    "button.btn-border-pulse {\n"
    "    background-color: #1e293b;\n"
    "    color: #f1f5f9;\n"
    "    border-color: #475569;\n"
    "    border-width: 1px;\n"
    "    border-radius: 10px;\n"
    "    box-shadow: 1;\n"
    "    transition: border-width 300ms ease, border-color 300ms ease, background-color 300ms ease;\n"
    "}\n"
    "button.btn-border-pulse:hover {\n"
    "    background-color: #0f172a;\n"
    "    border-color: #38bdf8;\n"
    "    border-width: 3.5px;\n"
    "    color: #38bdf8;\n"
    "}\n"
    "button.btn-border-pulse:active {\n"
    "    background-color: #38bdf8;\n"
    "    color: #0f172a;\n"
    "}\n"
    "\n"
    "/* Button 4: Cubic Bezier Timing Curve */\n"
    "button.btn-bezier {\n"
    "    background-color: #f43f5e;\n"
    "    color: #ffffff;\n"
    "    border-color: #e11d48;\n"
    "    border-width: 2px;\n"
    "    border-radius: 6px;\n"
    "    box-shadow: 1;\n"
    "    transition: all 450ms cubic-bezier(0.25, 0.1, 0.25, 1.0);\n"
    "}\n"
    "button.btn-bezier:hover {\n"
    "    background-color: #fbbf24;\n"
    "    border-color: #f59e0b;\n"
    "    color: #78350f;\n"
    "    border-radius: 18px;\n"
    "}\n";

static void on_btn_click(FtWidget widget, void* user_data) {
    const char* label = (const char*)user_data;
    printf("[Click] Button clicked: %s (Animation running: %d)\n", label, ft_animation_is_running());
}

static int g_btn6_toggled = 0;
static void on_btn6_click(FtWidget widget, void* user_data) {
    g_btn6_toggled = !g_btn6_toggled;
    if (g_btn6_toggled) {
        ft_widget_set_style(widget, "background-color: #10b981; color: #ffffff; border-radius: 19px; border-width: 2px; border-color: #059669; box-shadow: 1; transition: all 300ms ease;");
        printf("[Click] Button 6: dynamically morphing to Emerald pill (300ms inline transition, running=%d)\n", ft_animation_is_running());
    } else {
        ft_widget_set_style(widget, "background-color: #8b5cf6; color: #ffffff; border-radius: 10px; border-width: 1.5px; border-color: #7c3aed; box-shadow: 1; transition: all 300ms ease;");
        printf("[Click] Button 6: dynamically morphing back to Violet rectangle (300ms inline transition, running=%d)\n", ft_animation_is_running());
    }
}

int main(int argc, char* argv[]) {
    ft_init();

    FtWidget win = ft_window_create(660, 430, "Floria Toolkit - CSS Transitions & Animations");

    /* 1. Header description */
    ft_text_create(win, 30, 20, 600, 26, "60 FPS CSS Transition Engine (Zero-CPU when Idle)");

    /* 2. Load CSS animation stylesheet */
    int load_res = ft_style_load_css_string(animation_css);
    printf("CSS Stylesheet loaded: %s\n", load_res ? "SUCCESS" : "FAILED");

    /* Button 1: Color Morph (Indigo -> Cyan -> Emerald) */
    ft_text_create(win, 30, 60, 280, 20, "1. Color Morph (400ms ease-out):");
    FtWidget btn1 = ft_button_create(win, 30, 85, 280, 38, "Indigo -> Cyan Morph");
    ft_widget_set_style_class(btn1, "btn-color-morph");
    ft_button_on_click(btn1, on_btn_click, "Color Morph");

    /* Button 2: Shape Morph (Rectangle -> Pill) */
    ft_text_create(win, 350, 60, 280, 20, "2. Pill Morph (350ms ease-in-out):");
    FtWidget btn2 = ft_button_create(win, 350, 85, 280, 38, "Rectangle -> Round Pill");
    ft_widget_set_style_class(btn2, "btn-pill-morph");
    ft_button_on_click(btn2, on_btn_click, "Pill Morph");

    /* Button 3: Border Pulse (Width & Glow) */
    ft_text_create(win, 30, 150, 280, 20, "3. Border Pulse (300ms ease):");
    FtWidget btn3 = ft_button_create(win, 30, 175, 280, 38, "Border 1px -> 3.5px Pulse");
    ft_widget_set_style_class(btn3, "btn-border-pulse");
    ft_button_on_click(btn3, on_btn_click, "Border Pulse");

    /* Button 4: Cubic Bezier (Custom Curve) */
    ft_text_create(win, 350, 150, 280, 20, "4. Cubic Bezier (450ms curve):");
    FtWidget btn4 = ft_button_create(win, 350, 175, 280, 38, "Rose -> Amber Bezier");
    ft_widget_set_style_class(btn4, "btn-bezier");
    ft_button_on_click(btn4, on_btn_click, "Cubic Bezier");

    /* Button 5: Instant fallback (No transition declared) */
    ft_text_create(win, 30, 240, 280, 20, "5. Unanimated (Instant Snap):");
    FtWidget btn5 = ft_button_create(win, 30, 265, 280, 38, "Instant Standard Button");
    ft_button_on_click(btn5, on_btn_click, "Instant Unanimated");


    /* Button 6: Inline animated transition */
    ft_text_create(win, 350, 240, 280, 20, "6. Inline Transition (Click to Toggle):");
    FtWidget btn6 = ft_button_create(win, 350, 265, 280, 38, "Click to Morph Style (Inline)");
    ft_widget_set_style(btn6, "background-color: #8b5cf6; color: #ffffff; border-radius: 10px; border-width: 1.5px; border-color: #7c3aed; box-shadow: 1; transition: all 300ms ease;");
    ft_button_on_click(btn6, on_btn6_click, NULL);

    /* Status footer */
    ft_text_create(win, 30, 335, 600, 20, "Hover and leave the buttons to experience smooth 60 FPS transitions!");
    ft_text_create(win, 30, 360, 600, 20, "Notice seamless mid-animation reversal: leaving midway reverses smoothly.");
    ft_text_create(win, 30, 385, 600, 20, "Zero CPU when idle: ticker pauses when no animations are actively running.");

    ft_widget_show(win);
    ft_main_loop();
    ft_quit();
    return 0;
}

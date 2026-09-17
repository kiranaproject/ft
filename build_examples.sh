#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p target

echo "[INFO] Compiling Floria Toolkit C examples..."

# Common compiler and linker flags:
# -Wl,-rpath,'$ORIGIN' ensures the executable can find libft.so in the same directory
CFLAGS="-Wall -O2 -Iinclude"
LDFLAGS="-Ltarget -lft -Wl,-rpath,'\$ORIGIN'"

eval gcc $CFLAGS examples/c/main.c $LDFLAGS -o target/c_example
eval gcc $CFLAGS examples/c/main.c $LDFLAGS -o target/example_main
eval gcc $CFLAGS examples/c/multilingual.c $LDFLAGS -o target/multilingual_example
eval gcc $CFLAGS examples/c/multilingual.c $LDFLAGS -o target/example_multilingual
eval gcc $CFLAGS examples/c/chinese.c $LDFLAGS -o target/example_chinese
eval gcc $CFLAGS examples/c/inputs.c $LDFLAGS -o target/input_example
eval gcc $CFLAGS examples/c/inputs.c $LDFLAGS -o target/example_inputs
eval gcc $CFLAGS examples/c/scrollbars.c $LDFLAGS -o target/scrollbar_example
eval gcc $CFLAGS examples/c/scrollbars.c $LDFLAGS -o target/example_scrollbars
eval gcc $CFLAGS examples/c/containers.c $LDFLAGS -o target/example_containers
eval gcc $CFLAGS examples/c/menus.c $LDFLAGS -o target/example_menus
eval gcc $CFLAGS examples/c/menus.c $LDFLAGS -o target/menu_example
eval gcc $CFLAGS examples/c/outside_menu_demo.c $LDFLAGS -o target/example_outside_menus
eval gcc $CFLAGS examples/c/outside_menu_demo.c $LDFLAGS -o target/outside_menu_demo
eval gcc $CFLAGS examples/c/widget_context_menus_demo.c $LDFLAGS -o target/widget_context_menus_demo
eval gcc $CFLAGS examples/c/widget_context_menus_demo.c $LDFLAGS -o target/example_widget_context_menus
eval gcc $CFLAGS examples/c/css_button_demo.c $LDFLAGS -o target/example_css_button
eval gcc $CFLAGS examples/c/css_button_demo.c $LDFLAGS -o target/css_button_demo
eval gcc $CFLAGS examples/c/css_animation_demo.c $LDFLAGS -o target/example_css_animation
eval gcc $CFLAGS examples/c/css_animation_demo.c $LDFLAGS -o target/css_animation_demo
eval gcc $CFLAGS examples/c/form_controls_demo.c $LDFLAGS -o target/example_form_controls
eval gcc $CFLAGS examples/c/form_controls_demo.c $LDFLAGS -o target/form_controls_demo
eval gcc $CFLAGS examples/c/test_all_widgets_css.c $LDFLAGS -o target/test_all_widgets_css
eval gcc $CFLAGS examples/c/advanced_desktop_widgets_demo.c $LDFLAGS -o target/advanced_desktop_widgets_demo
eval gcc $CFLAGS examples/c/advanced_desktop_widgets_demo.c $LDFLAGS -o target/example_advanced_desktop_widgets

echo "[INFO] Successfully built all C examples in target/:"
ls -lh target/example_* target/c_example target/input_example target/scrollbar_example target/multilingual_example target/menu_example target/outside_menu_demo target/widget_context_menus_demo target/css_button_demo target/css_animation_demo target/form_controls_demo target/test_all_widgets_css target/advanced_desktop_widgets_demo

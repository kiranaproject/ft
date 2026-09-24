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

eval gcc $CFLAGS examples/c/main.c $LDFLAGS -o target/example_c_main
eval gcc $CFLAGS examples/c/multilingual.c $LDFLAGS -o target/example_c_multilingual
eval gcc $CFLAGS examples/c/chinese.c $LDFLAGS -o target/example_c_chinese
eval gcc $CFLAGS examples/c/inputs.c $LDFLAGS -o target/example_c_inputs
eval gcc $CFLAGS examples/c/scrollbars.c $LDFLAGS -o target/example_c_scrollbars
eval gcc $CFLAGS examples/c/containers.c $LDFLAGS -o target/example_c_containers
eval gcc $CFLAGS examples/c/container_render_area.c $LDFLAGS -o target/example_c_container_render_area
eval gcc $CFLAGS examples/c/menus.c $LDFLAGS -o target/example_c_menus
eval gcc $CFLAGS examples/c/outside_menu.c $LDFLAGS -o target/example_c_outside_menus
eval gcc $CFLAGS examples/c/widget_context_menus.c $LDFLAGS -o target/example_c_widget_context_menus
eval gcc $CFLAGS examples/c/css_button.c $LDFLAGS -o target/example_c_css_button
eval gcc $CFLAGS examples/c/css_animation.c $LDFLAGS -o target/example_c_css_animation
eval gcc $CFLAGS examples/c/form_controls.c $LDFLAGS -o target/example_c_form_controls
eval gcc $CFLAGS examples/c/test_all_widgets_css.c $LDFLAGS -o target/example_c_test_all_widgets_css
eval gcc $CFLAGS examples/c/advanced_desktop_widgets.c $LDFLAGS -o target/example_c_advanced_desktop_widgets
eval gcc $CFLAGS examples/c/window_button.c $LDFLAGS -o target/example_c_window_button
eval gcc $CFLAGS examples/c/custom_table.c $LDFLAGS -o target/example_c_custom_table
eval gcc $CFLAGS examples/c/squircle_button.c $LDFLAGS -o target/example_c_squircle_button
eval gcc $CFLAGS examples/c/button_icons.c $LDFLAGS -o target/example_c_button_icons

echo "[INFO] Successfully built all C examples in target/:"
ls -lh target/example_c_*

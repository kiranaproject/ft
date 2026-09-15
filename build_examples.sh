#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p target/bin

echo "[INFO] Compiling Floria Toolkit C examples..."

# Common compiler and linker flags:
# -Wl,-rpath,'$ORIGIN' ensures the executable can find libft.so in the same directory
# -Wl,-rpath,'$ORIGIN/..' ensures it can find libft.so in the parent directory
CFLAGS="-Wall -O2 -Iinclude"
LDFLAGS="-Ltarget/bin -lft -Wl,-rpath,'\$ORIGIN',-rpath,'\$ORIGIN/..'"

eval gcc $CFLAGS examples/c/main.c $LDFLAGS -o target/bin/c_example
eval gcc $CFLAGS examples/c/main.c $LDFLAGS -o target/bin/example_main
eval gcc $CFLAGS examples/c/multilingual.c $LDFLAGS -o target/bin/multilingual_example
eval gcc $CFLAGS examples/c/multilingual.c $LDFLAGS -o target/bin/example_multilingual
eval gcc $CFLAGS examples/c/chinese.c $LDFLAGS -o target/bin/example_chinese
eval gcc $CFLAGS examples/c/inputs.c $LDFLAGS -o target/bin/input_example
eval gcc $CFLAGS examples/c/inputs.c $LDFLAGS -o target/bin/example_inputs
eval gcc $CFLAGS examples/c/scrollbars.c $LDFLAGS -o target/bin/scrollbar_example
eval gcc $CFLAGS examples/c/scrollbars.c $LDFLAGS -o target/bin/example_scrollbars
eval gcc $CFLAGS examples/c/containers.c $LDFLAGS -o target/bin/example_containers
eval gcc $CFLAGS examples/c/menus.c $LDFLAGS -o target/bin/example_menus
eval gcc $CFLAGS examples/c/menus.c $LDFLAGS -o target/bin/menu_example
eval gcc $CFLAGS examples/c/outside_menu_demo.c $LDFLAGS -o target/bin/example_outside_menus
eval gcc $CFLAGS examples/c/outside_menu_demo.c $LDFLAGS -o target/bin/outside_menu_demo
eval gcc $CFLAGS examples/c/widget_context_menus_demo.c $LDFLAGS -o target/bin/widget_context_menus_demo
eval gcc $CFLAGS examples/c/widget_context_menus_demo.c $LDFLAGS -o target/bin/example_widget_context_menus
eval gcc $CFLAGS examples/c/css_button_demo.c $LDFLAGS -o target/bin/example_css_button
eval gcc $CFLAGS examples/c/css_button_demo.c $LDFLAGS -o target/bin/css_button_demo
eval gcc $CFLAGS examples/c/css_animation_demo.c $LDFLAGS -o target/bin/example_css_animation
eval gcc $CFLAGS examples/c/css_animation_demo.c $LDFLAGS -o target/bin/css_animation_demo
eval gcc $CFLAGS examples/c/form_controls_demo.c $LDFLAGS -o target/bin/example_form_controls
eval gcc $CFLAGS examples/c/form_controls_demo.c $LDFLAGS -o target/bin/form_controls_demo

echo "[INFO] Successfully built all C examples in target/bin/:"
ls -lh target/bin/example_* target/bin/c_example target/bin/input_example target/bin/scrollbar_example target/bin/multilingual_example target/bin/menu_example target/bin/outside_menu_demo target/bin/widget_context_menus_demo target/bin/css_button_demo target/bin/css_animation_demo target/bin/form_controls_demo

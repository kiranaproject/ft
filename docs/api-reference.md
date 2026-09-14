# Floria Toolkit (`Ft`) - C API Reference

This document provides a comprehensive reference for the Floria Toolkit C ABI exported by `libft.so` and declared in [`include/ft.h`](../include/ft.h).

---

## Table of Contents
1. [Core Lifecycle](#core-lifecycle)
2. [Window Management](#window-management)
3. [Widget Focus & Keyboard Navigation](#widget-focus--keyboard-navigation)
4. [Push Button & Toggle Button](#push-button--toggle-button)
5. [Toggle Switch](#toggle-switch)
6. [Text / Label](#text--label)
7. [Entry (Single-Line Input)](#entry-single-line-input)
8. [TextArea (Multi-Line Text)](#textarea-multi-line-text)
9. [ScrollBar](#scrollbar)
10. [Container (Scrollable Viewport)](#container-scrollable-viewport)
11. [Window Main Menu](#window-main-menu)
12. [Pop-up & Context Menus](#pop-up--context-menus)
13. [Menu Items](#menu-items)
14. [Context Menu & Window Attachment](#context-menu--window-attachment)
15. [Clipboard Management](#clipboard-management)
16. [Theme Management](#theme-management)
17. [CSS Styling & Animation](#css-styling--animation)
18. [Typography & Screen DPI](#typography--screen-dpi)

---

## Core Lifecycle

| Function | Description |
|---|---|
| `void ft_init(void)` | Initializes the toolkit backend, font subsystem, CSS sheet, and theme manager. |
| `void ft_main_loop(void)` | Enters the event dispatch loop. Blocks until all normal windows close or `ft_quit()` is called. |
| `void ft_quit(void)` | Terminates the main loop and cleans up toolkit resources. |

---

## Window Management

| Function | Description |
|---|---|
| `FtWidget ft_window_create(int32_t w, int32_t h, const char* title)` | Creates and returns a top-level native window. |
| `void ft_window_set_title(FtWidget win, const char* title)` | Sets the window title string (EWMH UTF-8 and legacy WM_NAME). |
| `void ft_window_set_borderless(FtWidget win, int32_t borderless)` | Enables (`1`) or disables (`0`) window manager decorations and titlebar. |
| `int32_t ft_window_get_borderless(FtWidget win)` | Returns `1` if the window is borderless, `0` otherwise. |
| `void ft_window_set_skip_taskbar(FtWidget win, int32_t skip)` | Toggles whether window is hidden from taskbar and pager (`_NET_WM_STATE_SKIP_TASKBAR`). |
| `int32_t ft_window_get_skip_taskbar(FtWidget win)` | Returns `1` if skipped from taskbar, `0` otherwise. |
| `void ft_window_set_window_type(FtWidget win, int32_t type)` | Sets EWMH window type (`FT_WINDOW_TYPE_NORMAL`, `DIALOG`, `POPUP_MENU`, `DROPDOWN_MENU`, `TOOLTIP`, `UTILITY`). |
| `int32_t ft_window_get_window_type(FtWidget win)` | Returns current EWMH window type. |
| `void ft_window_set_position(FtWidget win, int32_t x, int32_t y)` | Explicitly moves window to screen coordinates `(x, y)`. |
| `void ft_window_get_position(FtWidget win, int32_t* x, int32_t* y)` | Queries root screen coordinates of the window. |
| `void ft_widget_show(FtWidget widget)` | Maps and displays the widget/window on screen. |
| `void ft_widget_hide(FtWidget widget)` | Unmaps and hides the widget/window. |

---

## Widget Focus & Keyboard Navigation

| Function | Description |
|---|---|
| `void ft_widget_set_focus(FtWidget widget)` | Programmatically assigns keyboard focus to widget (draws theme focus ring). |
| `int32_t ft_widget_has_focus(FtWidget widget)` | Returns `1` if widget currently holds keyboard focus, `0` otherwise. |
| `void ft_widget_set_focusable(FtWidget widget, int32_t focusable)` | Enables or disables focus reception. Drops focus if currently focused. |
| `int32_t ft_widget_get_focusable(FtWidget widget)` | Returns `1` if widget is focusable, `0` otherwise. |

### Built-in Keyboard Controls
- **`Tab` / `Shift+Tab`**: Forward / backward focus traversal through all focusable widgets with cyclic wrapping.
- **`Space`**: Presses down on keypress, activates on key release (Button, Toggle Button) or toggles state (Switch).
- **`Return` / `Enter`**: Immediately activates button click or switch toggle.
- **`Left Arrow` / `Right Arrow`**: Direct control on focused switches (Left = OFF, Right = ON).
- **`Ctrl+A` / `Escape`**: Select all or clear selection on selectable text widgets.

---

## Push Button & Toggle Button

| Function | Description |
|---|---|
| `FtWidget ft_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption)` | Creates a standard push button. |
| `FtWidget ft_toggle_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption)` | Creates a toggleable button. |
| `void ft_button_set_toggle(FtWidget btn, int32_t can_toggle)` | Enables (`1`) or disables (`0`) toggle mode on a button. |
| `void ft_button_set_toggled(FtWidget btn, int32_t toggled)` | Sets toggle state (`0` = untoggled, `1` = toggled). |
| `int32_t ft_button_get_toggled(FtWidget btn)` | Queries whether button is currently toggled. |
| `int32_t ft_button_get_state(FtWidget btn)` | Returns interaction state (`FT_BUTTON_STATE_NORMAL`, `HOVERED`, `PRESSED`). |
| `void ft_button_on_click(FtWidget btn, FtClickCallback cb, void* user_data)` | Registers click callback (`void (*)(FtWidget, void*)`). |
| `void ft_button_on_hover(FtWidget btn, FtHoverCallback cb, void* user_data)` | Registers mouse enter/leave callback (`void (*)(FtWidget, int32_t hovered, void*)`). |
| `void ft_button_on_press(FtWidget btn, FtPressCallback cb, void* user_data)` | Registers mouse button down/up callback (`void (*)(FtWidget, int32_t pressed, void*)`). |
| `void ft_button_on_toggle(FtWidget btn, FtToggleCallback cb, void* user_data)` | Registers toggle state change callback (`void (*)(FtWidget, int32_t toggled, void*)`). |
| `void ft_button_set_corner_radius(FtWidget btn, double radius)` | Sets per-widget corner radius (`-1.0` inherits theme). |
| `void ft_button_set_shadow(FtWidget btn, int32_t enabled)` | Sets per-widget shadow (`-1` inherits theme, `0` = off, `1` = on). |

---

## Toggle Switch

| Function | Description |
|---|---|
| `FtWidget ft_switch_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption)` | Creates a modern toggle switch widget. |
| `void ft_switch_set_checked(FtWidget sw, int32_t checked)` | Sets checked state (`1` = ON, `0` = OFF). |
| `int32_t ft_switch_get_checked(FtWidget sw)` | Returns `1` if checked, `0` if unchecked. |
| `void ft_switch_toggle(FtWidget sw)` | Inverts the switch state. |
| `void ft_switch_on_toggle(FtWidget sw, FtSwitchCallback cb, void* user_data)` | Registers toggle callback (`void (*)(FtWidget, int32_t checked, void*)`). |
| `void ft_switch_set_corner_radius(FtWidget sw, double radius)` | Sets per-widget track corner radius. |
| `void ft_switch_set_shadow(FtWidget sw, int32_t enabled)` | Sets per-widget drop shadow. |
| `void ft_switch_set_caption(FtWidget sw, const char* caption)` | Sets adjacent label text. |
| `const char* ft_switch_get_caption(FtWidget sw)` | Gets adjacent label text. |

---

## Text / Label

| Function | Description |
|---|---|
| `FtWidget ft_text_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* text)` | Creates a text / label widget. |
| `void ft_text_set_text(FtWidget txt, const char* text)` | Sets the text string. |
| `const char* ft_text_get_text(FtWidget txt)` | Retrieves current text string. |
| `void ft_text_set_selectable(FtWidget txt, int32_t selectable)` | Enables or disables mouse text selection (`1` = selectable, `0` = static label). |
| `int32_t ft_text_get_selectable(FtWidget txt)` | Queries whether text can be selected. |
| `const char* ft_text_get_selected_text(FtWidget txt)` | Returns currently selected substring. |
| `void ft_text_select_all(FtWidget txt)` | Selects all characters. |
| `void ft_text_clear_selection(FtWidget txt)` | Clears active selection. |
| `void ft_text_copy(FtWidget txt)` | Copies selected text to the system clipboard. |
| `void ft_text_set_alignment(FtWidget txt, int32_t align)` | Sets text alignment (`FT_TEXT_ALIGN_LEFT`, `CENTER`, `RIGHT`). |
| `int32_t ft_text_get_alignment(FtWidget txt)` | Gets current text alignment. |
| `void ft_text_set_color(FtWidget txt, double r, double g, double b)` | Sets custom text color override. |
| `void ft_text_reset_color(FtWidget txt)` | Resets text color to follow theme. |

---

## Entry (Single-Line Input)
*Equivalent to `GtkEntry` in GTK and `QLineEdit` in Qt.*

| Function | Description |
|---|---|
| `FtWidget ft_entry_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* text)` | Creates a single-line text input box. |
| `void ft_entry_set_text(FtWidget entry, const char* text)` | Sets entry text. |
| `const char* ft_entry_get_text(FtWidget entry)` | Retrieves entry text. |
| `void ft_entry_set_placeholder(FtWidget entry, const char* placeholder)` | Sets grayed-out placeholder hint. |
| `const char* ft_entry_get_placeholder(FtWidget entry)` | Retrieves placeholder string. |
| `void ft_entry_set_readonly(FtWidget entry, int32_t readonly_mode)` | Enables (`1`) or disables (`0`) read-only mode. |
| `int32_t ft_entry_get_readonly(FtWidget entry)` | Returns `1` if read-only, `0` otherwise. |
| `void ft_entry_on_change(FtWidget entry, FtTextChangeCallback cb, void* user_data)` | Registers text modification callback (`void (*)(FtWidget, const char*, void*)`). |
| `void ft_entry_on_submit(FtWidget entry, FtTextSubmitCallback cb, void* user_data)` | Registers Enter/Return submit callback (`void (*)(FtWidget, const char*, void*)`). |
| `void ft_entry_set_corner_radius(FtWidget entry, double radius)` | Sets per-widget corner radius. |

---

## TextArea (Multi-Line Text)
*Equivalent to `GtkTextView` in GTK and `QTextEdit` / `QPlainTextEdit` in Qt.*

| Function | Description |
|---|---|
| `FtWidget ft_textarea_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* text)` | Creates a multi-line text area widget. |
| `void ft_textarea_set_text(FtWidget ta, const char* text)` | Sets multi-line text string (supports `\n`). |
| `const char* ft_textarea_get_text(FtWidget ta)` | Retrieves complete multi-line text. |
| `void ft_textarea_set_placeholder(FtWidget ta, const char* placeholder)` | Sets placeholder hint shown when empty. |
| `const char* ft_textarea_get_placeholder(FtWidget ta)` | Retrieves placeholder string. |
| `void ft_textarea_set_readonly(FtWidget ta, int32_t readonly_mode)` | Enables (`1`) or disables (`0`) read-only mode. |
| `int32_t ft_textarea_get_readonly(FtWidget ta)` | Returns `1` if read-only, `0` otherwise. |
| `void ft_textarea_on_change(FtWidget ta, FtTextChangeCallback cb, void* user_data)` | Registers text modification callback. |
| `void ft_textarea_set_corner_radius(FtWidget ta, double radius)` | Sets per-widget corner radius. |
| `void ft_textarea_set_scrollbar_mode(FtWidget ta, int32_t mode)` | Sets scrollbar policy (`FT_SCROLLBAR_MODE_NONE`, `HORIZONTAL_ONLY`, `VERTICAL_ONLY`, `AUTO_BOTH`). |
| `int32_t ft_textarea_get_scrollbar_mode(FtWidget ta)` | Returns current scrollbar policy. |
| `FtWidget ft_textarea_get_vscrollbar(FtWidget ta)` | Returns the internal vertical scrollbar. |
| `FtWidget ft_textarea_get_hscrollbar(FtWidget ta)` | Returns the internal horizontal scrollbar. |

---

## ScrollBar

| Function | Description |
|---|---|
| `FtWidget ft_scrollbar_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t orientation)` | Creates a scrollbar (`0` = Horizontal, `1` = Vertical). |
| `void ft_scrollbar_set_orientation(FtWidget sb, int32_t orientation)` | Sets orientation (`0` = Horizontal, `1` = Vertical). |
| `int32_t ft_scrollbar_get_orientation(FtWidget sb)` | Returns current orientation. |
| `void ft_scrollbar_set_range(FtWidget sb, double min, double max, double page_size)` | Configures range limits and proportional thumb page size. |
| `void ft_scrollbar_set_value(FtWidget sb, double value)` | Sets current position (clamped between min and max). |
| `double ft_scrollbar_get_value(FtWidget sb)` | Retrieves current position value. |
| `double ft_scrollbar_get_min(FtWidget sb)` | Retrieves minimum range limit. |
| `double ft_scrollbar_get_max(FtWidget sb)` | Retrieves maximum range limit. |
| `double ft_scrollbar_get_page_size(FtWidget sb)` | Retrieves viewport page size. |
| `void ft_scrollbar_set_step(FtWidget sb, double step)` | Sets small step size for wheel/clicks. |
| `double ft_scrollbar_get_step(FtWidget sb)` | Retrieves small step size. |
| `void ft_scrollbar_on_scroll(FtWidget sb, FtScrollCallback cb, void* user_data)` | Registers live scroll callback (`void (*)(FtWidget, double, void*)`). |
| `void ft_scrollbar_set_corner_radius(FtWidget sb, double radius)` | Sets corner radius override for thumb. |

---

## Container (Scrollable Viewport)
*Equivalent to `GtkScrolledWindow` in GTK and `QScrollArea` in Qt.*

| Function | Description |
|---|---|
| `FtWidget ft_container_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h)` | Creates a reusable container / viewport box. |
| `void ft_container_set_scrollbar_mode(FtWidget container, int32_t mode)` | Sets scrollbar policy (`0`=None, `1`=Horiz, `2`=Vert, `3`=Auto Both). |
| `int32_t ft_container_get_scrollbar_mode(FtWidget container)` | Returns current scrollbar policy. |
| `void ft_container_set_content_size(FtWidget container, double w, double h)` | Explicitly sets virtual content dimensions. |
| `void ft_container_get_content_size(FtWidget container, double* w, double* h)` | Retrieves virtual content dimensions. |
| `void ft_container_set_scroll_pos(FtWidget container, double sx, double sy)` | Scrolls container to specific coordinates. |
| `double ft_container_get_scroll_x(FtWidget container)` | Returns horizontal scroll offset. |
| `double ft_container_get_scroll_y(FtWidget container)` | Returns vertical scroll offset. |
| `void ft_container_set_corner_radius(FtWidget container, double radius)` | Sets per-container corner radius. |
| `double ft_container_get_corner_radius(FtWidget container)` | Returns container corner radius. |
| `void ft_container_set_padding(FtWidget container, double pad_x, double pad_y)` | Sets inner padding around child widgets. |
| `void ft_container_set_draw_frame(FtWidget container, int32_t draw_frame)` | Toggles background frame rendering (`1`=on, `0`=off). |
| `int32_t ft_container_get_draw_frame(FtWidget container)` | Returns `1` if background plate is drawn. |
| `void ft_container_set_draw_focus_ring(FtWidget container, int32_t draw_ring)` | Toggles focus ring around container. |
| `int32_t ft_container_get_draw_focus_ring(FtWidget container)` | Queries whether focus ring is enabled. |
| `void ft_container_set_auto_content_size(FtWidget container, int32_t auto_sz)` | Automatically expands content area to fit all children. |
| `int32_t ft_container_get_auto_content_size(FtWidget container)` | Queries auto content sizing state. |
| `FtWidget ft_container_get_vscrollbar(FtWidget container)` | Returns vertical scrollbar widget. |
| `FtWidget ft_container_get_hscrollbar(FtWidget container)` | Returns horizontal scrollbar widget. |
| `void ft_container_on_scroll(FtWidget container, FtScrollCallback cb, void* user_data)` | Registers scroll callback. |
| `void ft_container_get_client_rect(FtWidget container, double* x, double* y, double* w, double* h)` | Computes inner client viewport area excluding scrollbars. |
| `void ft_container_update_scrollbars(FtWidget container)` | Recalculates scrollbar ranges, visibility, and layout. |

---

## Window Main Menu

| Function | Description |
|---|---|
| `FtWidget ft_main_menu_create(FtWidget window)` | Creates a main menu bar attached to the window. |
| `FtWidget ft_main_menu_add_menu(FtWidget main_menu, const char* caption)` | Adds a top-level menu column (e.g. `"File"`) and returns its popup menu. |
| `FtMenuItem ft_main_menu_add_item(FtWidget main_menu, const char* caption, FtWidget popup)` | Attaches an existing popup menu as a top-level item. |
| `int32_t ft_main_menu_item_count(FtWidget main_menu)` | Returns number of top-level menus. |
| `FtMenuItem ft_main_menu_get_item(FtWidget main_menu, int32_t index)` | Retrieves top-level menu item at index. |
| `void ft_main_menu_close(FtWidget main_menu)` | Closes any open dropdown menu. |

---

## Pop-up & Context Menus

| Function | Description |
|---|---|
| `FtWidget ft_popup_menu_create(FtWidget parent)` | Creates a standalone popup menu. |
| `FtMenuItem ft_popup_menu_add_item(FtWidget popup, const char* caption, FtMenuCallback cb, void* user_data)` | Appends an interactive menu item with callback. |
| `FtMenuItem ft_popup_menu_add_check_item(FtWidget popup, const char* caption, int32_t checked, FtMenuCallback cb, void* user_data)` | Appends a toggleable checkmark item. |
| `FtMenuItem ft_popup_menu_add_separator(FtWidget popup)` | Appends a horizontal separator line. |
| `FtMenuItem ft_popup_menu_add_submenu(FtWidget popup, const char* caption, FtWidget submenu)` | Appends a cascading child submenu (`▶`). |
| `int32_t ft_popup_menu_item_count(FtWidget popup)` | Returns item count in menu. |
| `FtMenuItem ft_popup_menu_get_item(FtWidget popup, int32_t index)` | Retrieves menu item at index. |
| `void ft_popup_menu_show(FtWidget popup, int32_t x, int32_t y)` | Opens popup menu at window coordinates `(x, y)`. |
| `void ft_popup_menu_close(FtWidget popup)` | Closes popup menu and all active submenus. |
| `void ft_popup_menu_clear(FtWidget popup)` | Removes all items from the popup menu. |
| `void ft_popup_menu_set_corner_radius(FtWidget popup, double radius)` | Sets corner radius override for menu plate. |

---

## Menu Items

| Function | Description |
|---|---|
| `void ft_menu_item_set_caption(FtMenuItem item, const char* caption)` | Sets item text (use `"-"` for separator). |
| `const char* ft_menu_item_get_caption(FtMenuItem item)` | Gets item text. |
| `void ft_menu_item_set_shortcut(FtMenuItem item, const char* shortcut)` | Sets right-aligned shortcut hint (e.g. `"Ctrl+S"`). |
| `const char* ft_menu_item_get_shortcut(FtMenuItem item)` | Gets shortcut hint. |
| `void ft_menu_item_set_enabled(FtMenuItem item, int32_t enabled)` | Enables (`1`) or disables (`0`) menu item. |
| `int32_t ft_menu_item_get_enabled(FtMenuItem item)` | Returns `1` if enabled, `0` if disabled. |
| `void ft_menu_item_set_checked(FtMenuItem item, int32_t checked)` | Sets checked state (`1` = checked, `0` = unchecked). |
| `int32_t ft_menu_item_get_checked(FtMenuItem item)` | Returns checked state. |
| `void ft_menu_item_set_checkable(FtMenuItem item, int32_t checkable)` | Enables or disables checkable mode. |
| `int32_t ft_menu_item_get_checkable(FtMenuItem item)` | Returns `1` if item can toggle check state. |
| `void ft_menu_item_set_submenu(FtMenuItem item, FtWidget submenu)` | Attaches a cascading child `TFtPopupMenu`. |
| `FtWidget ft_menu_item_get_submenu(FtMenuItem item)` | Returns attached child submenu or `NULL`. |
| `void ft_menu_item_on_click(FtMenuItem item, FtMenuCallback cb, void* user_data)` | Registers item click handler. |
| `void ft_menu_item_set_tag(FtMenuItem item, int64_t tag)` | Attaches user integer/pointer tag. |
| `int64_t ft_menu_item_get_tag(FtMenuItem item)` | Retrieves user tag. |

---

## Context Menu & Window Attachment

| Function | Description |
|---|---|
| `void ft_widget_set_context_menu(FtWidget widget, FtWidget popup_menu)` | Attaches right-click context menu to any widget. |
| `FtWidget ft_widget_get_context_menu(FtWidget widget)` | Returns attached context menu of widget. |
| `void ft_window_set_context_menu(FtWidget window, FtWidget popup_menu)` | Attaches default right-click context menu to window. |
| `FtWidget ft_window_get_context_menu(FtWidget window)` | Returns attached context menu of window. |
| `void ft_window_set_main_menu(FtWidget window, FtWidget main_menu)` | Sets active top-level main menu on window. |
| `FtWidget ft_window_get_main_menu(FtWidget window)` | Returns main menu of window. |

---

## Clipboard Management

| Function | Description |
|---|---|
| `void ft_clipboard_set_text(const char* text)` | Stores UTF-8 text in the system clipboard and X11 selection. |
| `const char* ft_clipboard_get_text(void)` | Retrieves text from system clipboard. |

---

## Theme Management

| Function | Description |
|---|---|
| `int32_t ft_theme_set(const char* name)` | Switches active theme (`"default"`, `"nord"`, `"dracula"`, `"gruvbox"`, `"gtk2"`, `"classic"`). |
| `const char* ft_theme_get(void)` | Returns the name of the currently active theme. |
| `const char* ft_theme_get_available(void)` | Returns comma-separated list of available themes. |
| `void ft_theme_set_dark_mode(int32_t enabled)` | Sets dark mode state (`1` = dark, `0` = light). |
| `int32_t ft_theme_get_dark_mode(void)` | Returns `1` if dark mode is active, `0` otherwise. |
| `int32_t ft_theme_has_dark_mode(const char* theme_name)` | Queries if a theme supports dark mode. |
| `void ft_theme_set_corner_radius(double radius)` | Sets global theme corner radius (`-1.0` for theme default). |
| `double ft_theme_get_corner_radius(void)` | Returns current global corner radius. |
| `void ft_theme_set_shadow(int32_t enabled)` | Enables (`1`) or disables (`0`) drop shadows globally. |
| `int32_t ft_theme_get_shadow(void)` | Returns `1` if shadows are enabled, `0` otherwise. |
| `int32_t ft_theme_load_file(const char* filepath)` | Loads a `.css` stylesheet theme directly from disk. |
| `int32_t ft_theme_load_dir(const char* dirpath)` | Scans and registers all `.css` theme files in a directory. |

---

## CSS Styling & Animation

| Function | Description |
|---|---|
| `void ft_widget_set_style_class(FtWidget widget, const char* style_class)` | Assigns CSS class name(s) (space-separated, e.g. `"danger rounded"`). |
| `const char* ft_widget_get_style_class(FtWidget widget)` | Returns assigned CSS class names. |
| `void ft_widget_set_style_id(FtWidget widget, const char* style_id)` | Assigns CSS ID selector (e.g. `"submit-btn"`). |
| `const char* ft_widget_get_style_id(FtWidget widget)` | Returns assigned CSS ID selector. |
| `void ft_widget_set_style(FtWidget widget, const char* inline_css)` | Sets inline CSS declaration string (e.g. `"background-color: #10b981; color: #fff;"`). |
| `const char* ft_widget_get_style(FtWidget widget)` | Retrieves current inline CSS string. |
| `int32_t ft_style_load_css_file(const char* filepath)` | Loads and parses an external CSS file into the global stylesheet. |
| `int32_t ft_style_load_css_string(const char* css_string)` | Parses and appends raw CSS rules into the global stylesheet. |
| `int32_t ft_animation_is_running(void)` | Returns `1` if active transitions/animations are animating, `0` if idle. |

---

## Typography & Screen DPI

| Function | Description |
|---|---|
| `const char* ft_system_font_get(void)` | Returns active system font description. |
| `void ft_system_font_set(const char* font_desc)` | Sets font family, size, and weight (e.g. `"Ubuntu-12.0:bold"`). |
| `void ft_widget_set_font(FtWidget widget, const char* font_desc)` | Sets per-widget font description override. |
| `double ft_screen_dpi_get(void)` | Returns detected or configured screen DPI. |
| `void ft_screen_dpi_set(double dpi)` | Overrides screen DPI for resolution scaling. |
| `double ft_font_gamma_get(void)` | Returns subpixel font antialiasing gamma value. |
| `void ft_font_gamma_set(double gamma)` | Sets subpixel font gamma value. |

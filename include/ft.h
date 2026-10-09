#ifndef FLORIA_TOOLKIT_H
#define FLORIA_TOOLKIT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* FtWidget;
typedef void* FtBitmap;

/* Callback Types */
typedef void (*FtClickCallback)(FtWidget widget, void* user_data);
typedef void (*FtHoverCallback)(FtWidget widget, int32_t hovered, void* user_data);
typedef void (*FtPressCallback)(FtWidget widget, int32_t pressed, void* user_data);
typedef void (*FtToggleCallback)(FtWidget widget, int32_t toggled, void* user_data);

/* Button States */
enum {
    FT_BUTTON_STATE_NORMAL = 0,
    FT_BUTTON_STATE_HOVERED = 1,
    FT_BUTTON_STATE_PRESSED = 2
};

/* Core Lifecycle */
void ft_init(void);
void ft_main_loop(void);
void ft_quit(void);

/* Window Types */
typedef enum {
    FT_WINDOW_TYPE_NORMAL = 0,
    FT_WINDOW_TYPE_DIALOG = 1,
    FT_WINDOW_TYPE_POPUP_MENU = 2,
    FT_WINDOW_TYPE_DROPDOWN_MENU = 3,
    FT_WINDOW_TYPE_TOOLTIP = 4,
    FT_WINDOW_TYPE_UTILITY = 5,
    FT_WINDOW_TYPE_DOCK = 6
} FtWindowType;

/* Window Management & Widget Focus */
FtWidget ft_window_create(int32_t width, int32_t height, const char* title);
void ft_window_set_title(FtWidget window, const char* title);
void ft_window_set_borderless(FtWidget window, int32_t borderless);
int32_t ft_window_get_borderless(FtWidget window);
void ft_window_set_skip_taskbar(FtWidget window, int32_t skip_taskbar);
int32_t ft_window_get_skip_taskbar(FtWidget window);
void ft_window_set_window_type(FtWidget window, int32_t window_type);
int32_t ft_window_get_window_type(FtWidget window);
void ft_window_set_position(FtWidget window, int32_t x, int32_t y);
void ft_window_get_position(FtWidget window, int32_t* x, int32_t* y);
void ft_window_set_opacity(FtWidget window, double opacity);
double ft_window_get_opacity(FtWidget window);
void ft_window_set_background_opacity(FtWidget window, double opacity);
double ft_window_get_background_opacity(FtWidget window);
void ft_window_set_background_blur(FtWidget window, int32_t blur);
int32_t ft_window_get_background_blur(FtWidget window);
void ft_window_set_strut_partial(FtWidget window,
    int32_t left, int32_t right, int32_t top, int32_t bottom,
    int32_t left_start_y, int32_t left_end_y,
    int32_t right_start_y, int32_t right_end_y,
    int32_t top_start_x, int32_t top_end_x,
    int32_t bottom_start_x, int32_t bottom_end_x);
int32_t ft_window_show_modal(FtWidget window);
void ft_window_bring_to_front(FtWidget window);
void ft_window_grab_input(FtWidget window);
void ft_window_ungrab_input(FtWidget window);
void* ft_window_get_native_handle(FtWidget window);
void ft_window_set_layout(FtWidget window, FtWidget layout);

/* Hardware Acceleration & EGL Backend */
int32_t ft_egl_is_available(void);
int32_t ft_backend_enable_egl(int32_t enable);
int32_t ft_backend_is_egl_enabled(void);
FtWidget ft_egl_window_create(int32_t width, int32_t height, const char* title);
int32_t ft_window_is_hardware_accelerated(FtWidget window);
void ft_window_set_hardware_accelerated(FtWidget window, int32_t accelerated);
void ft_window_set_swap_interval(FtWidget window, int32_t interval);
int32_t ft_window_make_current(FtWidget window);
void ft_window_release_current(FtWidget window);
typedef void (*FtWindowGLDrawCallback)(FtWidget window, int32_t width, int32_t height, void* user_data);
void ft_window_on_gl_draw(FtWidget window, FtWindowGLDrawCallback callback, void* user_data);

void ft_widget_show(FtWidget widget);
void ft_widget_hide(FtWidget widget);
void ft_widget_invalidate(FtWidget widget);
void ft_window_repaint(FtWidget window);
void ft_widget_set_focus(FtWidget widget);
int32_t ft_widget_has_focus(FtWidget widget);
void ft_widget_set_focusable(FtWidget widget, int32_t focusable);
int32_t ft_widget_get_focusable(FtWidget widget);
void ft_widget_set_opacity(FtWidget widget, double opacity);
double ft_widget_get_opacity(FtWidget widget);
void ft_widget_set_enabled(FtWidget widget, int32_t enabled);
int32_t ft_widget_get_enabled(FtWidget widget);
int32_t ft_widget_get_parent_render_area(FtWidget widget, double* x, double* y, double* w, double* h, double* radius);
void ft_widget_set_bounds(FtWidget widget, int32_t x, int32_t y, int32_t w, int32_t h);
void ft_widget_get_bounds(FtWidget widget, int32_t* x, int32_t* y, int32_t* w, int32_t* h);
int32_t ft_widget_get_x(FtWidget widget);
int32_t ft_widget_get_y(FtWidget widget);
int32_t ft_widget_get_width(FtWidget widget);
int32_t ft_widget_get_height(FtWidget widget);
void ft_widget_destroy(FtWidget widget);

/* Micro-Flexbox Child Properties & Alignments */
typedef enum {
    FT_ALIGN_SELF_AUTO = 0,
    FT_ALIGN_SELF_STRETCH = 1,
    FT_ALIGN_SELF_START = 2,
    FT_ALIGN_SELF_CENTER = 3,
    FT_ALIGN_SELF_END = 4
} FtAlignSelf;

void ft_widget_set_flex_grow(FtWidget widget, double grow);
double ft_widget_get_flex_grow(FtWidget widget);
void ft_widget_set_flex_shrink(FtWidget widget, double shrink);
double ft_widget_get_flex_shrink(FtWidget widget);
void ft_widget_set_flex_basis(FtWidget widget, double basis);
double ft_widget_get_flex_basis(FtWidget widget);
void ft_widget_set_align_self(FtWidget widget, int32_t align_self);
int32_t ft_widget_get_align_self(FtWidget widget);
void ft_widget_set_margin(FtWidget widget, int32_t left, int32_t top, int32_t right, int32_t bottom);
void ft_widget_set_margin_all(FtWidget widget, int32_t margin);

/* Widget Hints & Tooltips */
void ft_widget_set_hint(FtWidget widget, const char* hint);
const char* ft_widget_get_hint(FtWidget widget);
const char* ft_widget_get_effective_hint(FtWidget widget);
void ft_widget_set_show_hint(FtWidget widget, int32_t show_hint);
int32_t ft_widget_get_show_hint(FtWidget widget);
void ft_set_hint_delay(int32_t delay_ms);
int32_t ft_get_hint_delay(void);

/* Widgets: Buttons */
FtWidget ft_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);
FtWidget ft_toggle_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);

void ft_button_set_toggle(FtWidget button, int32_t can_toggle);
int32_t ft_button_get_toggle(FtWidget button);
void ft_button_set_toggled(FtWidget button, int32_t toggled);
int32_t ft_button_get_toggled(FtWidget button);
int32_t ft_button_get_state(FtWidget button);

void ft_button_on_click(FtWidget button, FtClickCallback callback, void* user_data);
void ft_button_on_hover(FtWidget button, FtHoverCallback callback, void* user_data);
void ft_button_on_press(FtWidget button, FtPressCallback callback, void* user_data);
void ft_button_on_toggle(FtWidget button, FtToggleCallback callback, void* user_data);

/* Button Styling: Rounded Corners & Shadows (-1.0 or -1 to inherit theme default) */
void ft_button_set_corner_radius(FtWidget button, double radius);
double ft_button_get_corner_radius(FtWidget button);
void ft_button_set_shadow(FtWidget button, int32_t enabled);
int32_t ft_button_get_shadow(FtWidget button);

/* Button Caption */
void ft_button_set_caption(FtWidget button, const char* caption);
const char* ft_button_get_caption(FtWidget button);

/* Button Icon Positions */
typedef enum {
    FT_BUTTON_ICON_LEFT = 0,    /* Icon to the left of text (default) */
    FT_BUTTON_ICON_RIGHT = 1,   /* Icon to the right of text */
    FT_BUTTON_ICON_TOP = 2,     /* Icon above text */
    FT_BUTTON_ICON_ONLY = 3     /* Icon centered, caption ignored/hidden */
} FtButtonIconPosition;

/* Button Custom Drawing Callbacks */
typedef void (*FtButtonPaintCallback)(FtWidget button, void* canvas, double x, double y, double w, double h, int32_t state, void* user_data);

/* Button Icon APIs */
void ft_button_set_icon_file(FtWidget button, const char* filepath);
void ft_button_set_icon_svg(FtWidget button, const char* svg_content);
void ft_button_set_icon_bitmap(FtWidget button, FtBitmap bmp, int32_t owns_bitmap);
FtBitmap ft_button_get_icon_bitmap(FtWidget button);
void ft_button_clear_icon(FtWidget button);

void ft_button_set_icon_position(FtWidget button, int32_t position);
int32_t ft_button_get_icon_position(FtWidget button);
void ft_button_set_icon_size(FtWidget button, int32_t width, int32_t height);
void ft_button_get_icon_size(FtWidget button, int32_t* width, int32_t* height);
void ft_button_set_icon_gap(FtWidget button, int32_t gap);
int32_t ft_button_get_icon_gap(FtWidget button);

/* Button Custom Drawing APIs */
void ft_button_on_paint_icon(FtWidget button, FtButtonPaintCallback callback, void* user_data);
void ft_button_on_paint(FtWidget button, FtButtonPaintCallback callback, void* user_data);

/* Widgets: Window Button (Titlebar, Tabs, Panels) */
typedef enum {
    FT_WINDOW_BUTTON_CLOSE = 0,     /* 'x' cross with scarlet glowing halo */
    FT_WINDOW_BUTTON_MINIMIZE,      /* '—' dash with amber halo */
    FT_WINDOW_BUTTON_MAXIMIZE,      /* Mac-style outward chevrons with emerald halo */
    FT_WINDOW_BUTTON_RESTORE,       /* Mac-style inward chevrons with emerald halo */
    FT_WINDOW_BUTTON_SHADE,         /* '▴' rollup chevron */
    FT_WINDOW_BUTTON_PIN,           /* '•' pin / stick indicator */
    FT_WINDOW_BUTTON_MENU,          /* '☰' hamburger menu */
    FT_WINDOW_BUTTON_ADD            /* '+' new tab / add button */
} FtWindowButtonKind;

typedef enum {
    FT_WINDOW_BUTTON_CIRCLE = 0,    /* Circular pill/halo (macOS traffic lights, modern tabs) */
    FT_WINDOW_BUTTON_SQUIRCLE,      /* Rounded rectangle (modern GTK / GNOME header bar) */
    FT_WINDOW_BUTTON_SQUARE         /* Flat rectangle (traditional Windows caption button) */
} FtWindowButtonStyle;

FtWidget ft_window_button_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t kind, int32_t style);
void ft_window_button_set_kind(FtWidget button, int32_t kind);
int32_t ft_window_button_get_kind(FtWidget button);
void ft_window_button_set_style(FtWidget button, int32_t style);
int32_t ft_window_button_get_style(FtWidget button);
void ft_window_button_set_glyph_arm(FtWidget button, double arm);
double ft_window_button_get_glyph_arm(FtWidget button);
void ft_window_button_on_click(FtWidget button, FtClickCallback callback, void* user_data);
void ft_window_button_on_hover(FtWidget button, FtHoverCallback callback, void* user_data);
void ft_window_button_on_press(FtWidget button, FtPressCallback callback, void* user_data);
void ft_window_button_set_transition_duration(FtWidget button, int32_t duration_ms);
int32_t ft_window_button_get_transition_duration(FtWidget button);
double ft_window_button_get_hover_progress(FtWidget button);
void ft_window_button_draw(void* canvas, double bx, double by, double bw, double bh, int32_t kind, int32_t style, int32_t state, int32_t dark_mode, double glyph_arm, double hover_progress);

/* Widgets: Switch */
FtWidget ft_switch_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);
void ft_switch_set_checked(FtWidget switch_widget, int32_t checked);
int32_t ft_switch_get_checked(FtWidget switch_widget);
void ft_switch_toggle(FtWidget switch_widget);
void ft_switch_set_toggled(FtWidget switch_widget, int32_t toggled);
int32_t ft_switch_get_toggled(FtWidget switch_widget);
int32_t ft_switch_get_state(FtWidget switch_widget);

void ft_switch_on_toggle(FtWidget switch_widget, FtToggleCallback callback, void* user_data);
void ft_switch_on_change(FtWidget switch_widget, FtToggleCallback callback, void* user_data);
void ft_switch_on_hover(FtWidget switch_widget, FtHoverCallback callback, void* user_data);

/* Switch Styling: Rounded Corners & Shadows (-1.0 or -1 to inherit theme default) */
void ft_switch_set_corner_radius(FtWidget switch_widget, double radius);
double ft_switch_get_corner_radius(FtWidget switch_widget);
void ft_switch_set_shadow(FtWidget switch_widget, int32_t enabled);
int32_t ft_switch_get_shadow(FtWidget switch_widget);

void ft_switch_set_caption(FtWidget switch_widget, const char* caption);
const char* ft_switch_get_caption(FtWidget switch_widget);

void ft_switch_set_transition_duration(FtWidget switch_widget, int32_t duration_ms);
int32_t ft_switch_get_transition_duration(FtWidget switch_widget);

/* Text Alignment */
enum {
    FT_TEXT_ALIGN_LEFT = 0,
    FT_TEXT_ALIGN_CENTER = 1,
    FT_TEXT_ALIGN_RIGHT = 2
};

/* Widgets: Text / Label */
FtWidget ft_text_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* text);
void ft_text_set_text(FtWidget text_widget, const char* text);
const char* ft_text_get_text(FtWidget text_widget);

/* Selection Option */
void ft_text_set_selectable(FtWidget text_widget, int32_t selectable);
int32_t ft_text_get_selectable(FtWidget text_widget);

/* Selection & Clipboard Operations */
const char* ft_text_get_selected_text(FtWidget text_widget);
void ft_text_select_all(FtWidget text_widget);
void ft_text_clear_selection(FtWidget text_widget);
void ft_text_copy(FtWidget text_widget);

/* Text Alignment & Color */
void ft_text_set_alignment(FtWidget text_widget, int32_t alignment);
int32_t ft_text_get_alignment(FtWidget text_widget);
void ft_text_set_color(FtWidget text_widget, double r, double g, double b);
void ft_text_reset_color(FtWidget text_widget);
void ft_text_set_word_wrap(FtWidget text_widget, int32_t word_wrap);
int32_t ft_text_get_word_wrap(FtWidget text_widget);
void ft_text_set_wrap(FtWidget text_widget, int32_t wrap);
int32_t ft_text_get_wrap(FtWidget text_widget);

/* System Clipboard */
void ft_clipboard_set_text(const char* text);
const char* ft_clipboard_get_text(void);

/* Callbacks for Text Input */
typedef void (*FtEntryChangeCallback)(FtWidget widget, const char* text, void* user_data);
typedef void (*FtEntrySubmitCallback)(FtWidget widget, const char* text, void* user_data);
typedef void (*FtTextAreaChangeCallback)(FtWidget widget, const char* text, void* user_data);

/* Widgets: Entry (Single-Line Inline Input Box / LineEdit) */
FtWidget ft_entry_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* text);
void ft_entry_set_text(FtWidget entry, const char* text);
const char* ft_entry_get_text(FtWidget entry);
void ft_entry_set_placeholder(FtWidget entry, const char* placeholder);
const char* ft_entry_get_placeholder(FtWidget entry);
void ft_entry_set_readonly(FtWidget entry, int32_t readonly_mode);
int32_t ft_entry_get_readonly(FtWidget entry);
void ft_entry_on_change(FtWidget entry, FtEntryChangeCallback callback, void* user_data);
void ft_entry_on_submit(FtWidget entry, FtEntrySubmitCallback callback, void* user_data);
void ft_entry_set_corner_radius(FtWidget entry, double radius);

/* Widgets: PathBar (Nautilus-Style Breadcrumb Path Entry) */
typedef enum {
    FT_PATH_BAR_MODE_BREADCRUMBS = 0,
    FT_PATH_BAR_MODE_EDIT = 1
} FtPathBarMode;

typedef void (*FtPathBarNavigateCallback)(FtWidget pathbar, const char* path, void* user_data);
typedef void (*FtPathBarModeChangeCallback)(FtWidget pathbar, int32_t mode, void* user_data);

FtWidget ft_path_bar_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* initial_path);
void ft_path_bar_set_path(FtWidget pathbar, const char* path);
const char* ft_path_bar_get_path(FtWidget pathbar);
void ft_path_bar_set_mode(FtWidget pathbar, int32_t mode);
int32_t ft_path_bar_get_mode(FtWidget pathbar);
void ft_path_bar_on_navigate(FtWidget pathbar, FtPathBarNavigateCallback callback, void* user_data);
void ft_path_bar_on_mode_change(FtWidget pathbar, FtPathBarModeChangeCallback callback, void* user_data);
FtWidget ft_path_bar_get_entry(FtWidget pathbar);
void ft_path_bar_set_show_edit_button(FtWidget pathbar, int32_t show_button);
int32_t ft_path_bar_get_show_edit_button(FtWidget pathbar);
void ft_path_bar_set_root_display_name(FtWidget pathbar, const char* display_name);
const char* ft_path_bar_get_root_display_name(FtWidget pathbar);
void ft_path_bar_set_corner_radius(FtWidget pathbar, double radius);
double ft_path_bar_get_corner_radius(FtWidget pathbar);

/* Widgets: UrlEntry (Google Chrome-Style Omnibox / URL Bar) */
typedef enum {
    FT_URL_SECURITY_SECURE = 0,     /* HTTPS / padlock icon */
    FT_URL_SECURITY_INSECURE = 1,   /* HTTP / warning triangle */
    FT_URL_SECURITY_INTERNAL = 2,   /* floria:// or chrome:// page icon */
    FT_URL_SECURITY_FILE = 3,       /* file:/// document icon */
    FT_URL_SECURITY_CUSTOM = 4      /* custom badge */
} FtUrlSecurityState;

typedef enum {
    FT_URL_ACTION_BOOKMARK = 1
} FtUrlActionId;

typedef void (*FtUrlEntrySubmitCallback)(FtWidget url_entry, const char* url, void* user_data);
typedef void (*FtUrlEntrySecurityClickCallback)(FtWidget url_entry, int32_t security_state, void* user_data);
typedef void (*FtUrlEntryBookmarkClickCallback)(FtWidget url_entry, int32_t bookmarked, void* user_data);
typedef void (*FtUrlEntryActionClickCallback)(FtWidget url_entry, int32_t action_id, void* user_data);

FtWidget ft_url_entry_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* initial_url);
void ft_url_entry_set_url(FtWidget url_entry, const char* url);
const char* ft_url_entry_get_url(FtWidget url_entry);
void ft_url_entry_set_security_state(FtWidget url_entry, int32_t security_state);
int32_t ft_url_entry_get_security_state(FtWidget url_entry);
void ft_url_entry_set_bookmarked(FtWidget url_entry, int32_t bookmarked);
int32_t ft_url_entry_get_bookmarked(FtWidget url_entry);
void ft_url_entry_set_show_security_chip(FtWidget url_entry, int32_t show_chip);
int32_t ft_url_entry_get_show_security_chip(FtWidget url_entry);
void ft_url_entry_set_show_security_badge_text(FtWidget url_entry, int32_t show_badge_text);
int32_t ft_url_entry_get_show_security_badge_text(FtWidget url_entry);
void ft_url_entry_set_show_bookmark_button(FtWidget url_entry, int32_t show_button);
int32_t ft_url_entry_get_show_bookmark_button(FtWidget url_entry);
void ft_url_entry_set_auto_prefix_https(FtWidget url_entry, int32_t auto_prefix);
int32_t ft_url_entry_get_auto_prefix_https(FtWidget url_entry);
void ft_url_entry_set_corner_radius(FtWidget url_entry, double radius);
double ft_url_entry_get_corner_radius(FtWidget url_entry);
void ft_url_entry_set_editing(FtWidget url_entry, int32_t editing);
int32_t ft_url_entry_get_editing(FtWidget url_entry);

void ft_url_entry_on_submit(FtWidget url_entry, FtUrlEntrySubmitCallback callback, void* user_data);
void ft_url_entry_on_security_click(FtWidget url_entry, FtUrlEntrySecurityClickCallback callback, void* user_data);
void ft_url_entry_on_bookmark_click(FtWidget url_entry, FtUrlEntryBookmarkClickCallback callback, void* user_data);
void ft_url_entry_on_action_click(FtWidget url_entry, FtUrlEntryActionClickCallback callback, void* user_data);
FtWidget ft_url_entry_get_entry(FtWidget url_entry);

/* Widgets: TextArea (Multi-Line Text Area / TextView) */
FtWidget ft_textarea_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* text);
void ft_textarea_set_text(FtWidget textarea, const char* text);
const char* ft_textarea_get_text(FtWidget textarea);
void ft_textarea_set_placeholder(FtWidget textarea, const char* placeholder);
const char* ft_textarea_get_placeholder(FtWidget textarea);
void ft_textarea_set_readonly(FtWidget textarea, int32_t readonly_mode);
int32_t ft_textarea_get_readonly(FtWidget textarea);
void ft_textarea_on_change(FtWidget textarea, FtTextAreaChangeCallback callback, void* user_data);
void ft_textarea_set_corner_radius(FtWidget textarea, double radius);
void ft_textarea_set_scrollbar_mode(FtWidget textarea, int32_t mode);
int32_t ft_textarea_get_scrollbar_mode(FtWidget textarea);
FtWidget ft_textarea_get_vscrollbar(FtWidget textarea);
FtWidget ft_textarea_get_hscrollbar(FtWidget textarea);

/* ScrollBar Enums & Callbacks */
typedef enum {
    FT_SCROLLBAR_HORIZONTAL = 0,
    FT_SCROLLBAR_VERTICAL = 1
} FtScrollBarOrientation;

typedef enum {
    FT_SCROLLBAR_MODE_NONE = 0,
    FT_SCROLLBAR_MODE_HORIZONTAL_ONLY = 1,
    FT_SCROLLBAR_MODE_VERTICAL_ONLY = 2,
    FT_SCROLLBAR_MODE_AUTO_BOTH = 3
} FtScrollBarMode;

typedef void (*FtScrollCallback)(FtWidget widget, double value, void* user_data);

/* Widgets: ScrollBar */
FtWidget ft_scrollbar_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t orientation);
void ft_scrollbar_set_orientation(FtWidget scrollbar, int32_t orientation);
int32_t ft_scrollbar_get_orientation(FtWidget scrollbar);
void ft_scrollbar_set_range(FtWidget scrollbar, double min, double max, double page_size);
void ft_scrollbar_set_value(FtWidget scrollbar, double value);
double ft_scrollbar_get_value(FtWidget scrollbar);
double ft_scrollbar_get_min(FtWidget scrollbar);
double ft_scrollbar_get_max(FtWidget scrollbar);
double ft_scrollbar_get_page_size(FtWidget scrollbar);
void ft_scrollbar_set_step(FtWidget scrollbar, double step);
double ft_scrollbar_get_step(FtWidget scrollbar);
void ft_scrollbar_on_scroll(FtWidget scrollbar, FtScrollCallback callback, void* user_data);
void ft_scrollbar_set_corner_radius(FtWidget scrollbar, double radius);

/* Widgets: Container (Scrollable Box / Viewport / Frame) */
FtWidget ft_container_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
void ft_container_set_scrollbar_mode(FtWidget container, int32_t mode);
int32_t ft_container_get_scrollbar_mode(FtWidget container);
void ft_container_set_content_size(FtWidget container, double width, double height);
void ft_container_get_content_size(FtWidget container, double* width, double* height);
void ft_container_set_scroll_pos(FtWidget container, double scroll_x, double scroll_y);
double ft_container_get_scroll_x(FtWidget container);
double ft_container_get_scroll_y(FtWidget container);
void ft_container_set_corner_radius(FtWidget container, double radius);
double ft_container_get_corner_radius(FtWidget container);
void ft_container_set_backdrop_blur(FtWidget container, double radius);
double ft_container_get_backdrop_blur(FtWidget container);
void ft_container_set_padding(FtWidget container, double pad_x, double pad_y);
void ft_container_set_draw_frame(FtWidget container, int32_t draw_frame);
int32_t ft_container_get_draw_frame(FtWidget container);
void ft_container_set_draw_focus_ring(FtWidget container, int32_t draw_focus_ring);
int32_t ft_container_get_draw_focus_ring(FtWidget container);
void ft_container_set_auto_content_size(FtWidget container, int32_t auto_size);
int32_t ft_container_get_auto_content_size(FtWidget container);
FtWidget ft_container_get_vscrollbar(FtWidget container);
FtWidget ft_container_get_hscrollbar(FtWidget container);
void ft_container_on_scroll(FtWidget container, FtScrollCallback callback, void* user_data);
void ft_container_get_client_rect(FtWidget container, double* x, double* y, double* w, double* h);
void ft_container_get_render_area(FtWidget container, double* x, double* y, double* w, double* h, double* radius);
double ft_container_get_inner_radius(FtWidget container);
double ft_container_get_effective_corner_radius(FtWidget container);
void ft_container_update_scrollbars(FtWidget container);

/* Micro-Flexbox Layout Containers */
typedef enum {
    FT_FLEX_ROW = 0,
    FT_FLEX_COLUMN = 1
} FtFlexDirection;

typedef enum {
    FT_JUSTIFY_START = 0,
    FT_JUSTIFY_CENTER = 1,
    FT_JUSTIFY_END = 2,
    FT_JUSTIFY_SPACE_BETWEEN = 3,
    FT_JUSTIFY_SPACE_AROUND = 4,
    FT_JUSTIFY_SPACE_EVENLY = 5
} FtJustifyContent;

typedef enum {
    FT_ALIGN_STRETCH = 0,
    FT_ALIGN_START = 1,
    FT_ALIGN_CENTER = 2,
    FT_ALIGN_END = 3
} FtAlignItems;

FtWidget ft_flexbox_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t direction);
FtWidget ft_hbox_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
FtWidget ft_vbox_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
FtWidget ft_spacer_create(FtWidget parent);

void ft_flexbox_set_direction(FtWidget flexbox, int32_t direction);
int32_t ft_flexbox_get_direction(FtWidget flexbox);
void ft_flexbox_set_justify_content(FtWidget flexbox, int32_t justify);
int32_t ft_flexbox_get_justify_content(FtWidget flexbox);
void ft_flexbox_set_align_items(FtWidget flexbox, int32_t align);
int32_t ft_flexbox_get_align_items(FtWidget flexbox);
void ft_flexbox_set_gap(FtWidget flexbox, double gap);
double ft_flexbox_get_gap(FtWidget flexbox);
void ft_flexbox_update_layout(FtWidget flexbox);

/* CheckBox Enums & Callbacks */
typedef void (*FtCheckCallback)(FtWidget widget, int32_t checked, void* user_data);

/* Widgets: CheckBox */
FtWidget ft_checkbox_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);
void ft_checkbox_set_checked(FtWidget checkbox, int32_t checked);
int32_t ft_checkbox_get_checked(FtWidget checkbox);
void ft_checkbox_toggle(FtWidget checkbox);
void ft_checkbox_set_caption(FtWidget checkbox, const char* caption);
const char* ft_checkbox_get_caption(FtWidget checkbox);
void ft_checkbox_set_corner_radius(FtWidget checkbox, double radius);
double ft_checkbox_get_corner_radius(FtWidget checkbox);
void ft_checkbox_on_toggle(FtWidget checkbox, FtCheckCallback callback, void* user_data);

/* RadioButton Enums & Callbacks */
typedef void (*FtRadioCallback)(FtWidget widget, int32_t checked, void* user_data);

/* Widgets: RadioButton */
FtWidget ft_radio_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* caption);
void ft_radio_set_checked(FtWidget radio, int32_t checked);
int32_t ft_radio_get_checked(FtWidget radio);
void ft_radio_set_group(FtWidget radio, int32_t group_id);
int32_t ft_radio_get_group(FtWidget radio);
void ft_radio_set_caption(FtWidget radio, const char* caption);
const char* ft_radio_get_caption(FtWidget radio);
void ft_radio_on_toggle(FtWidget radio, FtRadioCallback callback, void* user_data);

/* ComboBox Enums & Callbacks */
typedef void (*FtComboChangeCallback)(FtWidget widget, int32_t selected_index, const char* text, void* user_data);

/* Widgets: ComboBox */
FtWidget ft_combobox_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
int32_t ft_combobox_add_item(FtWidget combobox, const char* item);
void ft_combobox_clear(FtWidget combobox);
int32_t ft_combobox_get_item_count(FtWidget combobox);
const char* ft_combobox_get_item(FtWidget combobox, int32_t index);
void ft_combobox_set_selected(FtWidget combobox, int32_t index);
int32_t ft_combobox_get_selected(FtWidget combobox);
const char* ft_combobox_get_selected_text(FtWidget combobox);
void ft_combobox_set_text(FtWidget combobox, const char* text);
const char* ft_combobox_get_text(FtWidget combobox);
void ft_combobox_set_placeholder(FtWidget combobox, const char* placeholder);
const char* ft_combobox_get_placeholder(FtWidget combobox);
void ft_combobox_set_editable(FtWidget combobox, int32_t editable);
int32_t ft_combobox_get_editable(FtWidget combobox);
void ft_combobox_set_corner_radius(FtWidget combobox, double radius);
double ft_combobox_get_corner_radius(FtWidget combobox);
void ft_combobox_popup(FtWidget combobox);
void ft_combobox_on_change(FtWidget combobox, FtComboChangeCallback callback, void* user_data);

/* Slider Enums & Callbacks */
typedef enum {
    FT_SLIDER_HORIZONTAL = 0,
    FT_SLIDER_VERTICAL = 1
} FtSliderOrientation;

typedef void (*FtSliderChangeCallback)(FtWidget widget, double value, void* user_data);

/* Widgets: Slider */
FtWidget ft_slider_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t orientation);
void ft_slider_set_orientation(FtWidget slider, int32_t orientation);
int32_t ft_slider_get_orientation(FtWidget slider);
void ft_slider_set_range(FtWidget slider, double min, double max);
double ft_slider_get_min(FtWidget slider);
double ft_slider_get_max(FtWidget slider);
void ft_slider_set_value(FtWidget slider, double value);
double ft_slider_get_value(FtWidget slider);
void ft_slider_set_step(FtWidget slider, double step);
double ft_slider_get_step(FtWidget slider);
void ft_slider_set_thumb_size(FtWidget slider, double thumb_size);
double ft_slider_get_thumb_size(FtWidget slider);
void ft_slider_on_change(FtWidget slider, FtSliderChangeCallback callback, void* user_data);

/* ProgressBar Enums */
typedef enum {
    FT_PROGRESS_HORIZONTAL = 0,
    FT_PROGRESS_VERTICAL = 1
} FtProgressOrientation;

/* Widgets: ProgressBar */
FtWidget ft_progressbar_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t orientation);
void ft_progressbar_set_orientation(FtWidget progressbar, int32_t orientation);
int32_t ft_progressbar_get_orientation(FtWidget progressbar);
void ft_progressbar_set_range(FtWidget progressbar, double min, double max);
double ft_progressbar_get_min(FtWidget progressbar);
double ft_progressbar_get_max(FtWidget progressbar);
void ft_progressbar_set_value(FtWidget progressbar, double value);
double ft_progressbar_get_value(FtWidget progressbar);
void ft_progressbar_set_indeterminate(FtWidget progressbar, int32_t indeterminate);
int32_t ft_progressbar_get_indeterminate(FtWidget progressbar);
void ft_progressbar_set_show_text(FtWidget progressbar, int32_t show_text);
int32_t ft_progressbar_get_show_text(FtWidget progressbar);
void ft_progressbar_set_text_format(FtWidget progressbar, const char* format);
const char* ft_progressbar_get_text_format(FtWidget progressbar);
void ft_progressbar_set_corner_radius(FtWidget progressbar, double radius);
double ft_progressbar_get_corner_radius(FtWidget progressbar);

/* Menus: Types and Callbacks */
typedef void* FtMenuItem;
typedef void (*FtMenuCallback)(FtMenuItem item, void* user_data);

/* Menus: Window Main Menu */
FtWidget ft_main_menu_create(FtWidget window);
FtWidget ft_main_menu_add_menu(FtWidget main_menu, const char* caption);
FtMenuItem ft_main_menu_add_item(FtWidget main_menu, const char* caption, FtWidget popup_menu);
int32_t ft_main_menu_item_count(FtWidget main_menu);
FtMenuItem ft_main_menu_get_item(FtWidget main_menu, int32_t index);
void ft_main_menu_close(FtWidget main_menu);

/* Menus: Pop-up / Context Menu */
FtWidget ft_popup_menu_create(FtWidget parent);
FtMenuItem ft_popup_menu_add_item(FtWidget popup_menu, const char* caption, FtMenuCallback callback, void* user_data);
FtMenuItem ft_popup_menu_add_check_item(FtWidget popup_menu, const char* caption, int32_t checked, FtMenuCallback callback, void* user_data);
FtMenuItem ft_popup_menu_add_separator(FtWidget popup_menu);
FtMenuItem ft_popup_menu_add_submenu(FtWidget popup_menu, const char* caption, FtWidget submenu);
int32_t ft_popup_menu_item_count(FtWidget popup_menu);
FtMenuItem ft_popup_menu_get_item(FtWidget popup_menu, int32_t index);
void ft_popup_menu_show(FtWidget popup_menu, int32_t x, int32_t y);
void ft_popup_menu_close(FtWidget popup_menu);
void ft_popup_menu_clear(FtWidget popup_menu);
void ft_popup_menu_set_corner_radius(FtWidget popup_menu, double radius);

/* Menus: Items */
void ft_menu_item_set_caption(FtMenuItem item, const char* caption);
const char* ft_menu_item_get_caption(FtMenuItem item);
void ft_menu_item_set_shortcut(FtMenuItem item, const char* shortcut);
const char* ft_menu_item_get_shortcut(FtMenuItem item);
void ft_menu_item_set_enabled(FtMenuItem item, int32_t enabled);
int32_t ft_menu_item_get_enabled(FtMenuItem item);
void ft_menu_item_set_checked(FtMenuItem item, int32_t checked);
int32_t ft_menu_item_get_checked(FtMenuItem item);
void ft_menu_item_set_checkable(FtMenuItem item, int32_t checkable);
int32_t ft_menu_item_get_checkable(FtMenuItem item);
void ft_menu_item_set_submenu(FtMenuItem item, FtWidget submenu);
FtWidget ft_menu_item_get_submenu(FtMenuItem item);
void ft_menu_item_on_click(FtMenuItem item, FtMenuCallback callback, void* user_data);
void ft_menu_item_set_tag(FtMenuItem item, int64_t tag);
int64_t ft_menu_item_get_tag(FtMenuItem item);

/* Menus: Context Menu & Window Attachment */
void ft_widget_set_context_menu(FtWidget widget, FtWidget popup_menu);
FtWidget ft_widget_get_context_menu(FtWidget widget);
void ft_window_set_context_menu(FtWidget window, FtWidget popup_menu);
FtWidget ft_window_get_context_menu(FtWidget window);
void ft_window_set_main_menu(FtWidget window, FtWidget main_menu);
FtWidget ft_window_get_main_menu(FtWidget window);

/* Font & DPI Management */
const char* ft_system_font_get(void);
void ft_system_font_set(const char* font_desc);
void ft_widget_set_font(FtWidget widget, const char* font_desc);
const char* ft_widget_get_font(FtWidget widget);
double ft_screen_dpi_get(void);
void ft_screen_dpi_set(double dpi);
int32_t ft_screen_get_width(void);
int32_t ft_screen_get_height(void);

typedef int32_t (*FtEventFilterFunc)(void* event);
void ft_register_event_filter(FtEventFilterFunc filter);
typedef void (*FtTickCallback)(void* user_data);
void ft_set_tick_callback(FtTickCallback callback, void* user_data);
void* ft_backend_get_connection(void);
void* ft_backend_get_screen(void);
void* ft_backend_get_key_symbols(void);
double ft_font_gamma_get(void);
void ft_font_gamma_set(double gamma);

/* Theme Management */
int32_t ft_theme_set(const char* theme_name);
const char* ft_theme_get(void);
const char* ft_theme_get_available(void);

/* Global Theme Rounded Corners & Shadows */
void ft_theme_set_corner_radius(double radius);
double ft_theme_get_corner_radius(void);
void ft_theme_set_shadow(int32_t enabled);
int32_t ft_theme_get_shadow(void);

/* Dynamic Theme File Loading */
int32_t ft_theme_load_file(const char* filepath);
int32_t ft_theme_load_dir(const char* dirpath);

/* Dark Mode Options */
void ft_theme_set_dark_mode(int32_t enabled);
int32_t ft_theme_get_dark_mode(void);
int32_t ft_theme_has_dark_mode(const char* theme_name);

/* CSS Styling */
void ft_widget_set_style_class(FtWidget widget, const char* style_class);
const char* ft_widget_get_style_class(FtWidget widget);
void ft_widget_set_style_id(FtWidget widget, const char* style_id);
const char* ft_widget_get_style_id(FtWidget widget);
void ft_widget_set_style(FtWidget widget, const char* inline_css);
const char* ft_widget_get_style(FtWidget widget);
int32_t ft_style_load_css_file(const char* filepath);
int32_t ft_style_load_css_string(const char* css_string);

/* Animation Engine */
int32_t ft_animation_is_running(void);

/* ========================================================================= */
/* Bitmaps, Images & Direct Canvas Drawing                                   */
/* ========================================================================= */

typedef enum {
    FT_IMAGE_SCALE_FIT = 0,     /* Aspect ratio preserved, centered */
    FT_IMAGE_SCALE_STRETCH = 1, /* Stretched to fill entire widget bounds */
    FT_IMAGE_SCALE_CENTER = 2,  /* 1:1 original size, centered */
    FT_IMAGE_SCALE_NONE = 3     /* 1:1 original size at top-left */
} FtImageScaleMode;

/* Bitmap Operations */
FtBitmap ft_bitmap_create(int32_t width, int32_t height);
FtBitmap ft_bitmap_load_file(const char* filepath);
FtBitmap ft_bitmap_load_memory(const void* data, int32_t size);
FtBitmap ft_bitmap_create_from_rgba(const void* pixels, int32_t width, int32_t height);
FtBitmap ft_bitmap_create_from_bgra(const void* pixels, int32_t width, int32_t height);
int32_t ft_bitmap_get_width(FtBitmap bmp);
int32_t ft_bitmap_get_height(FtBitmap bmp);
int32_t ft_bitmap_get_stride(FtBitmap bmp);
void* ft_bitmap_get_pixels(FtBitmap bmp);
FtBitmap ft_bitmap_create_scaled(FtBitmap bmp, int32_t new_width, int32_t new_height);
void ft_bitmap_destroy(FtBitmap bmp);
void ft_bitmap_save_to_file(FtBitmap bmp, const char* filepath);

/* Image Widget */
FtWidget ft_image_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* filepath);
void ft_image_load_file(FtWidget image, const char* filepath);
void ft_image_load_memory(FtWidget image, const void* data, int32_t size);
void ft_image_load_svg_file(FtWidget image, const char* filepath);
void ft_image_load_svg_string(FtWidget image, const char* svg_content);
void ft_image_invalidate_cache(FtWidget image);
void ft_image_set_bitmap(FtWidget image, FtBitmap bmp, int32_t owns_bitmap);
FtBitmap ft_image_get_bitmap(FtWidget image);
void ft_image_set_scale_mode(FtWidget image, int32_t mode);
int32_t ft_image_get_scale_mode(FtWidget image);
void ft_image_set_opacity(FtWidget image, double opacity);
double ft_image_get_opacity(FtWidget image);

/* SVG Bitmap Creation */
FtBitmap ft_bitmap_create_from_svg(const char* svg_content, int32_t width, int32_t height);
FtBitmap ft_bitmap_create_from_svg_file(const char* filepath, int32_t width, int32_t height);

/* Direct Canvas Image Drawing */
void ft_canvas_draw_image(void* canvas, double x, double y, FtBitmap bmp, double opacity);
void ft_canvas_draw_image_scaled(void* canvas, double x, double y, double w, double h, FtBitmap bmp, double opacity);
void ft_canvas_draw_image_part(void* canvas, double x, double y, double w, double h, FtBitmap bmp, int32_t src_x, int32_t src_y, int32_t src_w, int32_t src_h, double opacity);
void ft_canvas_draw_svg(void* canvas, double x, double y, double w, double h, const char* svg_content);
void ft_canvas_draw_svg_file(void* canvas, double x, double y, double w, double h, const char* filepath);

/* Canvas Alpha Stack */
void ft_canvas_push_alpha(void* canvas, double alpha);
void ft_canvas_pop_alpha(void* canvas);
void ft_canvas_reset_alpha(void* canvas);
double ft_canvas_get_alpha(void* canvas);

/* Direct Canvas Vector & Shape Drawing */
void ft_canvas_draw_rect(void* canvas, int32_t x, int32_t y, int32_t w, int32_t h, double r, double g, double b, double a);
void ft_canvas_draw_rounded_rect(void* canvas, double x, double y, double w, double h, double radius, double r, double g, double b, double a);
void ft_canvas_draw_rounded_rect_outline(void* canvas, double x, double y, double w, double h, double radius, double border_width, double r, double g, double b, double a);
void ft_canvas_draw_line(void* canvas, double x1, double y1, double x2, double y2, double width, double r, double g, double b, double a);
void ft_canvas_draw_circle(void* canvas, double cx, double cy, double radius, double r, double g, double b, double a);
void ft_canvas_draw_text(void* canvas, double x, double y, const char* text, void* font, double r, double g, double b);
void ft_canvas_draw_text_left(void* canvas, double x, double y, double w, double h, const char* text, void* font, double r, double g, double b);
void ft_canvas_draw_text_centered(void* canvas, int32_t x, int32_t y, int32_t w, int32_t h, const char* text, void* font, double r, double g, double b);

/* ========================================================================= */
/* Tabs & Notebook Container                                                 */
/* ========================================================================= */

typedef void* FtNotebook;
typedef void* FtTabPage;

typedef void (*FtTabChangeCallback)(FtNotebook notebook, int32_t new_index, int32_t old_index, void* user_data);

FtNotebook ft_notebook_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
FtTabPage ft_notebook_add_tab(FtNotebook notebook, const char* title, int32_t closeable);
void ft_notebook_remove_tab(FtNotebook notebook, int32_t index);
void ft_notebook_clear_tabs(FtNotebook notebook);
int32_t ft_notebook_get_page_count(FtNotebook notebook);
FtTabPage ft_notebook_get_page(FtNotebook notebook, int32_t index);
void ft_notebook_set_active_index(FtNotebook notebook, int32_t index);
int32_t ft_notebook_get_active_index(FtNotebook notebook);
void ft_notebook_set_tab_height(FtNotebook notebook, double height);
double ft_notebook_get_tab_height(FtNotebook notebook);
void ft_notebook_on_tab_change(FtNotebook notebook, FtTabChangeCallback callback, void* user_data);

void ft_tab_page_set_title(FtTabPage page, const char* title);
const char* ft_tab_page_get_title(FtTabPage page);
void ft_tab_page_set_closeable(FtTabPage page, int32_t closeable);
int32_t ft_tab_page_get_closeable(FtTabPage page);
void ft_tab_page_set_icon(FtTabPage page, FtBitmap icon);
FtBitmap ft_tab_page_get_icon(FtTabPage page);

/* ========================================================================= */
/* Splitter Container                                                        */
/* ========================================================================= */

typedef void* FtSplitter;

typedef enum {
    FT_SPLITTER_HORIZONTAL = 0, /* Left and right panes */
    FT_SPLITTER_VERTICAL = 1    /* Top and bottom panes */
} FtSplitterOrientation;

typedef void (*FtSplitterPositionCallback)(FtSplitter splitter, double position, void* user_data);

FtSplitter ft_splitter_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, int32_t orientation);
void ft_splitter_set_panes(FtSplitter splitter, FtWidget pane1, FtWidget pane2);
FtWidget ft_splitter_get_pane1(FtSplitter splitter);
FtWidget ft_splitter_get_pane2(FtSplitter splitter);
void ft_splitter_set_orientation(FtSplitter splitter, int32_t orientation);
int32_t ft_splitter_get_orientation(FtSplitter splitter);
void ft_splitter_set_pos(FtSplitter splitter, double pos);
double ft_splitter_get_pos(FtSplitter splitter);
void ft_splitter_set_ratio(FtSplitter splitter, double ratio);
void ft_splitter_set_splitter_size(FtSplitter splitter, double size);
double ft_splitter_get_splitter_size(FtSplitter splitter);
void ft_splitter_set_min_sizes(FtSplitter splitter, double min_pane1, double min_pane2);
double ft_splitter_get_min_pane1_size(FtSplitter splitter);
double ft_splitter_get_min_pane2_size(FtSplitter splitter);
void ft_splitter_on_position_change(FtSplitter splitter, FtSplitterPositionCallback callback, void* user_data);

/* ========================================================================= */
/* TreeView                                                                  */
/* ========================================================================= */

typedef void* FtTreeView;
typedef void* FtTreeNode;

typedef void (*FtTreeNodeSelectCallback)(FtTreeView treeview, FtTreeNode node, void* user_data);

FtTreeView ft_treeview_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
FtTreeNode ft_treeview_add_node(FtTreeView treeview, const char* text, FtTreeNode parent_node);
void ft_treeview_clear(FtTreeView treeview);
FtTreeNode ft_treeview_get_root(FtTreeView treeview);
FtTreeNode ft_treeview_get_selected_node(FtTreeView treeview);
void ft_treeview_set_selected_node(FtTreeView treeview, FtTreeNode node);
void ft_treeview_set_item_height(FtTreeView treeview, double height);
double ft_treeview_get_item_height(FtTreeView treeview);
void ft_treeview_set_indent_width(FtTreeView treeview, double width);
double ft_treeview_get_indent_width(FtTreeView treeview);
void ft_treeview_on_select(FtTreeView treeview, FtTreeNodeSelectCallback callback, void* user_data);

FtTreeNode ft_treenode_add_child(FtTreeNode node, const char* text);
void ft_treenode_delete_child(FtTreeNode node, int32_t index);
int32_t ft_treenode_get_child_count(FtTreeNode node);
FtTreeNode ft_treenode_get_child(FtTreeNode node, int32_t index);
FtTreeNode ft_treenode_get_parent(FtTreeNode node);
void ft_treenode_set_text(FtTreeNode node, const char* text);
const char* ft_treenode_get_text(FtTreeNode node);
void ft_treenode_set_expanded(FtTreeNode node, int32_t expanded);
int32_t ft_treenode_get_expanded(FtTreeNode node);
void ft_treenode_set_icon(FtTreeNode node, FtBitmap icon);
FtBitmap ft_treenode_get_icon(FtTreeNode node);
void ft_treenode_set_data(FtTreeNode node, void* data);
void* ft_treenode_get_data(FtTreeNode node);
void ft_treenode_set_tag(FtTreeNode node, int32_t tag);
int32_t ft_treenode_get_tag(FtTreeNode node);

/* ========================================================================= */
/* Table / DataGrid                                                          */
/* ========================================================================= */

typedef void* FtTable;

typedef void (*FtTableRowSelectCallback)(FtTable table, int32_t row_index, void* user_data);
typedef void (*FtTableRowDoubleClickCallback)(FtTable table, int32_t row_index, void* user_data);

typedef int32_t (*FtTableDrawHeaderCallback)(FtTable table, void* canvas, int32_t col_idx,
                                             double x, double y, double w, double h,
                                             int32_t sort_order, void* user_data);

typedef int32_t (*FtTableDrawCellCallback)(FtTable table, void* canvas, int32_t row_idx, int32_t col_idx,
                                           double x, double y, double w, double h,
                                           int32_t is_selected, int32_t is_hovered, void* user_data);

FtTable ft_table_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h);
int32_t ft_table_add_column(FtTable table, const char* title, double width, int32_t alignment);
int32_t ft_table_get_column_count(FtTable table);
void ft_table_set_column_title(FtTable table, int32_t col_idx, const char* title);
const char* ft_table_get_column_title(FtTable table, int32_t col_idx);
void ft_table_set_column_width(FtTable table, int32_t col_idx, double width);
double ft_table_get_column_width(FtTable table, int32_t col_idx);
void ft_table_set_column_align(FtTable table, int32_t col_idx, int32_t alignment);
int32_t ft_table_get_column_align(FtTable table, int32_t col_idx);
void ft_table_set_column_icon(FtTable table, int32_t col_idx, FtBitmap icon);
FtBitmap ft_table_get_column_icon(FtTable table, int32_t col_idx);

int32_t ft_table_add_row(FtTable table);
void ft_table_delete_row(FtTable table, int32_t row_idx);
void ft_table_clear_rows(FtTable table);
void ft_table_clear_all(FtTable table);
int32_t ft_table_get_row_count(FtTable table);

void ft_table_set_cell(FtTable table, int32_t row, int32_t col, const char* value);
const char* ft_table_get_cell(FtTable table, int32_t row, int32_t col);
void ft_table_set_cell_icon(FtTable table, int32_t row, int32_t col, FtBitmap icon);
FtBitmap ft_table_get_cell_icon(FtTable table, int32_t row, int32_t col);

void ft_table_set_selected_row(FtTable table, int32_t row);
int32_t ft_table_get_selected_row(FtTable table);
void ft_table_set_multi_select(FtTable table, int32_t enabled);
int32_t ft_table_get_multi_select(FtTable table);
int32_t ft_table_is_row_selected(FtTable table, int32_t row_idx);
void ft_table_set_row_selected(FtTable table, int32_t row_idx, int32_t selected);
void ft_table_select_all(FtTable table);
void ft_table_clear_selection(FtTable table);
int32_t ft_table_get_selected_row_count(FtTable table);
int32_t ft_table_get_selected_rows(FtTable table, int32_t* out_indices, int32_t max_count);

void ft_table_set_header_height(FtTable table, double height);
double ft_table_get_header_height(FtTable table);
void ft_table_set_row_height(FtTable table, double height);
double ft_table_get_row_height(FtTable table);

void ft_table_set_show_gridlines(FtTable table, int32_t show);
int32_t ft_table_get_show_gridlines(FtTable table);
void ft_table_set_zebra_striping(FtTable table, int32_t enabled);
int32_t ft_table_get_zebra_striping(FtTable table);

void ft_table_on_select_row(FtTable table, FtTableRowSelectCallback callback, void* user_data);
void ft_table_on_row_double_click(FtTable table, FtTableRowDoubleClickCallback callback, void* user_data);
void ft_table_on_draw_header(FtTable table, FtTableDrawHeaderCallback callback, void* user_data);
void ft_table_on_draw_cell(FtTable table, FtTableDrawCellCallback callback, void* user_data);

/* ─── File Dialogs ─────────────────────────────────────────────────────── */

typedef void* FtFileDialog;

/* Dialog types */
enum {
  FT_DIALOG_OPEN_FILE     = 0,
  FT_DIALOG_SAVE_FILE     = 1,
  FT_DIALOG_SELECT_FOLDER = 2
};

/* Handle-based object API */
FtFileDialog ft_file_dialog_create(int32_t dialog_type);
void         ft_file_dialog_set_directory(FtFileDialog dlg, const char* dir);
const char*  ft_file_dialog_get_directory(FtFileDialog dlg);
void         ft_file_dialog_set_default_name(FtFileDialog dlg, const char* name);
void         ft_file_dialog_set_filter(FtFileDialog dlg, const char* filter);
void         ft_file_dialog_set_show_hidden(FtFileDialog dlg, int32_t show_hidden);
int32_t      ft_file_dialog_show_modal(FtFileDialog dlg);
const char*  ft_file_dialog_get_selected_path(FtFileDialog dlg);
void         ft_file_dialog_destroy(FtFileDialog dlg);

/* Convenience one-shot functions (returns selected path or NULL on cancel) */
const char* ft_dialog_open_file(const char* title, const char* default_dir, const char* filter);
const char* ft_dialog_save_file(const char* title, const char* default_dir, const char* default_name, const char* filter);
const char* ft_dialog_select_folder(const char* title, const char* default_dir);

/* ─── Icons & Icon Theming ─────────────────────────────────────────────── */

/* Retrieve SVG markup by name. If dark_mode is non-zero, adapts monochrome strokes.
   Returns NULL if the icon name is not found. */
const char* ft_icon_get_svg(const char* name, int32_t dark_mode);

/* Render an icon directly to an FtBitmap image with the specified dimensions.
   Returns NULL on failure or if the icon is not found. */
FtBitmap    ft_icon_get_bitmap(const char* name, int32_t width, int32_t height, int32_t dark_mode);

/* Register or override an icon with SVG string content.
   svg_dark can be NULL to enable automatic dark mode monochrome stroke adaptation. */
void        ft_icon_register(const char* name, const char* svg_light, const char* svg_dark);

/* Check if an icon is registered (returns 1 if found, 0 otherwise) */
int32_t     ft_icon_has(const char* name);

/* Customize the monochrome stroke palette used for light and dark modes (hex colors, e.g. "#64748b") */
void        ft_icon_set_monochrome_colors(const char* light_color, const char* dark_color);

/* ─── Hardware Accelerated GPU Vector Core & Direct Rendering ─────────── */

typedef void* FtRenderBatch;
typedef void* FtGPUTessellator;
typedef void* FtTessMesh;
typedef void* FtGPURenderer;

typedef enum {
    FT_BLEND_SRCOVER    = 0,
    FT_BLEND_ADDITIVE   = 1,
    FT_BLEND_MULTIPLY   = 2,
    FT_BLEND_SCREEN     = 3,
    FT_BLEND_SRC        = 4
} FtBlendMode;

typedef enum {
    FT_JOIN_MITER       = 0,
    FT_JOIN_BEVEL       = 1,
    FT_JOIN_ROUND       = 2
} FtJoinStyle;

typedef enum {
    FT_CAP_BUTT         = 0,
    FT_CAP_SQUARE       = 1,
    FT_CAP_ROUND        = 2
} FtCapStyle;

typedef struct {
    float x;
    float y;
} FtPoint2D;

typedef struct {
    uint32_t draw_calls;
    uint32_t vertex_count;
} FtBatchStats;

/* Window Mouse, Key & Direct GPU Mode Callbacks */
typedef void (*FtWindowMouseCallback)(FtWidget window, int32_t x, int32_t y, int32_t button, void* user_data);
typedef void (*FtWindowMouseMoveCallback)(FtWidget window, int32_t x, int32_t y, void* user_data);
typedef void (*FtWindowKeyCallback)(FtWidget window, uint32_t key, int32_t is_down, void* user_data);

void ft_window_set_direct_gpu_mode(FtWidget window, int32_t direct_gpu);
void ft_window_on_mouse_down(FtWidget window, FtWindowMouseCallback callback, void* user_data);
void ft_window_on_mouse_up(FtWidget window, FtWindowMouseCallback callback, void* user_data);
void ft_window_on_mouse_move(FtWidget window, FtWindowMouseMoveCallback callback, void* user_data);
void ft_window_on_key(FtWidget window, FtWindowKeyCallback callback, void* user_data);

/* Global GPU Status */
int32_t ft_gpu_is_available(void);

/* Render Batch API */
FtRenderBatch ft_batch_create(void);
void          ft_batch_destroy(FtRenderBatch batch);
void          ft_batch_clear(FtRenderBatch batch);
void          ft_batch_get_stats(FtRenderBatch batch, FtBatchStats* stats);
void          ft_batch_emit_rect(FtRenderBatch batch, float x, float y, float w, float h,
                                 uint32_t color, int32_t blend_mode);
void          ft_batch_emit_textured_rect(FtRenderBatch batch, float x, float y, float w, float h,
                                          float u0, float v0, float u1, float v1,
                                          uint32_t tex_id, float opacity, int32_t blend_mode);
void          ft_batch_emit_rounded_rect(FtRenderBatch batch, float x, float y, float w, float h, float radius,
                                         uint32_t fill_color, uint32_t border_color, float border_width,
                                         int32_t blend_mode);
void          ft_batch_emit_box_shadow(FtRenderBatch batch, float x, float y, float w, float h, float radius,
                                       float offset_x, float offset_y, float blur_radius, float spread,
                                       uint32_t shadow_color, int32_t blend_mode);
void          ft_batch_emit_linear_gradient(FtRenderBatch batch, float x, float y, float w, float h,
                                            uint32_t color_start, uint32_t color_end, float angle_deg,
                                            int32_t blend_mode);
void          ft_batch_emit_path_mesh(FtRenderBatch batch, FtTessMesh mesh, uint32_t color, int32_t blend_mode);

/* Tessellator & Vector Geometry API */
FtTessMesh       ft_tessmesh_create(void);
void             ft_tessmesh_destroy(FtTessMesh mesh);
void             ft_tessmesh_clear(FtTessMesh mesh);
void             ft_tessmesh_get_counts(FtTessMesh mesh, int32_t* vertex_count, int32_t* index_count);

FtGPUTessellator ft_tessellator_create(void);
void             ft_tessellator_destroy(FtGPUTessellator tess);
void             ft_tessellator_stroke_polyline(FtGPUTessellator tess, FtTessMesh mesh,
                                                const FtPoint2D* points, int32_t count,
                                                int32_t closed, float stroke_width,
                                                int32_t join_style, int32_t cap_style,
                                                float miter_limit, int32_t aa_fringe);
void             ft_tessellator_stroke_bezier(FtGPUTessellator tess, FtTessMesh mesh,
                                              float p0x, float p0y, float p1x, float p1y,
                                              float p2x, float p2y, float p3x, float p3y,
                                              float stroke_width,
                                              int32_t join_style, int32_t cap_style,
                                              float miter_limit, int32_t aa_fringe);
void             ft_tessellator_fill_polygon(FtGPUTessellator tess, FtTessMesh mesh,
                                             const FtPoint2D* points, int32_t count,
                                             int32_t aa_fringe);

/* High-Level GPU Renderer API */
FtGPURenderer    ft_renderer_create(void);
void             ft_renderer_destroy(FtGPURenderer renderer);
void             ft_renderer_begin(FtGPURenderer renderer, int32_t viewport_w, int32_t viewport_h);
void             ft_renderer_end(FtGPURenderer renderer);
FtRenderBatch    ft_renderer_get_batch(FtGPURenderer renderer);
FtGPUTessellator ft_renderer_get_tessellator(FtGPURenderer renderer);

#ifdef __cplusplus
}
#endif

#endif /* FLORIA_TOOLKIT_H */
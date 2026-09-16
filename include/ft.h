#ifndef FLORIA_TOOLKIT_H
#define FLORIA_TOOLKIT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* FtWidget;

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
    FT_WINDOW_TYPE_UTILITY = 5
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

void ft_widget_show(FtWidget widget);
void ft_widget_hide(FtWidget widget);
void ft_widget_set_focus(FtWidget widget);
int32_t ft_widget_has_focus(FtWidget widget);
void ft_widget_set_focusable(FtWidget widget, int32_t focusable);
int32_t ft_widget_get_focusable(FtWidget widget);
void ft_widget_set_opacity(FtWidget widget, double opacity);
double ft_widget_get_opacity(FtWidget widget);

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
void ft_container_update_scrollbars(FtWidget container);

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

typedef void* FtBitmap;

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

/* Image Widget */
FtWidget ft_image_create(FtWidget parent, int32_t x, int32_t y, int32_t w, int32_t h, const char* filepath);
void ft_image_load_file(FtWidget image, const char* filepath);
void ft_image_load_memory(FtWidget image, const void* data, int32_t size);
void ft_image_set_bitmap(FtWidget image, FtBitmap bmp, int32_t owns_bitmap);
FtBitmap ft_image_get_bitmap(FtWidget image);
void ft_image_set_scale_mode(FtWidget image, int32_t mode);
int32_t ft_image_get_scale_mode(FtWidget image);
void ft_image_set_opacity(FtWidget image, double opacity);
double ft_image_get_opacity(FtWidget image);

/* Direct Canvas Image Drawing */
void ft_canvas_draw_image(void* canvas, double x, double y, FtBitmap bmp, double opacity);
void ft_canvas_draw_image_scaled(void* canvas, double x, double y, double w, double h, FtBitmap bmp, double opacity);
void ft_canvas_draw_image_part(void* canvas, double x, double y, double w, double h, FtBitmap bmp, int32_t src_x, int32_t src_y, int32_t src_w, int32_t src_h, double opacity);

/* Canvas Alpha Stack */
void ft_canvas_push_alpha(void* canvas, double alpha);
void ft_canvas_pop_alpha(void* canvas);
void ft_canvas_reset_alpha(void* canvas);
double ft_canvas_get_alpha(void* canvas);

#ifdef __cplusplus
}
#endif

#endif /* FLORIA_TOOLKIT_H */
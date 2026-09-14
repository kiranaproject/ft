# Theming & CSS Guide

Floria Toolkit (`Ft`) features a native CSS theming and styling engine powered by Free Pascal's `fcl-css` parser. All themes are defined as standard `.css` stylesheets with full support for element selectors, class selectors, ID selectors, state pseudo-classes, and CSS transitions.

---

## Table of Contents
1. [Theme Architecture](#theme-architecture)
2. [Built-in & Bundled Themes](#built-in--bundled-themes)
3. [CSS Selectors & Cascade](#css-selectors--cascade)
4. [Supported CSS Properties](#supported-css-properties)
5. [CSS Transitions & Animations](#css-transitions--animations)
6. [Dark Mode & Theme Switching](#dark-mode--theme-switching)
7. [Theme Discovery & Hot-Swapping](#theme-discovery--hot-swapping)
8. [Inline Styles](#inline-styles)

---

## Theme Architecture

Floria Toolkit's theming pipeline separates styling from widget logic:
- **Parser (`fcl-css`)**: Parses standards-compliant CSS grammar directly into a syntax tree (`TCSSDocument`).
- **Resolver (`Ft.Css`)**: Resolves widget styles by querying the document hierarchy with specific specificity rules (inline style > `#id` > `.class` > element type).
- **Renderer (`Ft.Canvas.Agg`)**: Converts resolved color tuples, borders, shadows, and radii into vector primitives rendered by Anti-Grain Geometry.
- **Animator (`Ft.Animation`)**: Intercepts style changes with active `transition` properties and animates them at 60 FPS.

---

## Built-in & Bundled Themes

Floria Toolkit comes bundled with 6 themes located in the [`themes/`](../themes) directory:

| Theme | File | Description |
|---|---|---|
| **Default** | `default.css` | Modern Breeze/Fusion flat vector look with vibrant blue accents and card elevation. |
| **Nord** | `nord.css` | Arctic frosty slate palette with polar cyan accents. |
| **Dracula** | `dracula.css` | Dark fantasy palette with neon pink, purple, and green highlights. |
| **Gruvbox** | `gruvbox.css` | Retro warm parchment / dark charcoal palette with golden accents. |
| **GTK2** | `gtk2.css` | Classic desktop industrial gray with crisp bevels. |
| **Classic** | `classic.css` | Elevated 3D slate with vibrant emerald accents. |

---

## CSS Selectors & Cascade

### 1. Element Type Selectors
Targets widgets based on their core type:
- `window`: Top-level native X11 window.
- `button`: Push buttons and toggle buttons.
- `switch`: Modern toggle switches.
- `entry`: Single-line text input fields (`TFtEntry`).
- `textarea`: Multi-line text input areas (`TFtTextArea`).
- `container`: Scrolled viewports and container boxes (`TFtContainer`).
- `label`: Static and selectable text widgets (`TFtText`).
- `scrollbar`: Horizontal and vertical scrollbars (`TFtScrollBar`).
- `menu`: Menu bars, dropdown items, and popup context menus.

### 2. State Pseudo-Classes
Widgets automatically apply pseudo-classes based on user interaction:
- `:hover`: Mouse cursor is over the widget bounds.
- `:active`: Mouse button is pressed down on the widget.
- `:focus`: Widget holds keyboard navigation focus.
- `:checked`: Toggle button or switch is in the active/ON state.
- `:disabled`: Widget is disabled (`Enabled = False`).

### 3. Class and ID Selectors
- **Class (`.classname`)**: Assigned via `ft_widget_set_style_class(widget, "danger rounded")`.
- **ID (`#idname`)**: Assigned via `ft_widget_set_style_id(widget, "submit-btn")`.

### 4. Cascade Specificity
Styles are resolved in order of ascending precedence:
1. Element selector: `button { ... }`
2. Element + Class: `button.danger { ... }`
3. Element + State: `button:hover { ... }`
4. Element + Class + State: `button.danger:hover { ... }`
5. ID selector: `#submit-btn { ... }`
6. Inline style: `ft_widget_set_style(btn, "background-color: #ef4444;")`

---

## Supported CSS Properties

| Property | Example | Supported Widgets | Description |
|---|---|---|---|
| `background-color` | `#ffffff`, `#3b82f6` | All | Background fill color (hex `#rgb`, `#rrggbb`, named colors). |
| `color` | `#0f172a`, `#f8f8f2` | Button, Text, Entry, TextArea, Menu | Text and foreground fill color. |
| `border-color` | `#cbd5e1`, `#6272a4` | Button, Switch, Entry, TextArea, Container, Menu | Outer border stroke color. |
| `border-width` | `1px`, `2px` | Button, Switch, Entry, TextArea, Container, Menu | Stroke line width in pixels. |
| `border-radius` | `4px`, `8px`, `12px` | Button, Switch, Entry, TextArea, Container, ScrollBar, Menu | Corner rounding radius. |
| `box-shadow` | `0` (off), `1` (on) | Button, Switch, Container, Window | Enables or disables vector 2D Gaussian drop shadow. |
| `transition` | `all 150ms ease` | Button, Switch, ScrollBar, Entry, TextArea | Declares properties, duration, and timing function for animations. |

---

## CSS Transitions & Animations

Floria Toolkit includes a native transition engine that smoothly interpolates properties between state changes (e.g. normal to hover, or light to dark).

### Syntax
```css
button {
    background-color: #3b82f6;
    border-radius: 6px;
    transition: all 180ms ease;
}

button:hover {
    background-color: #2563eb;
    border-radius: 12px;
}
```

### Supported Timing Functions
- **`linear`**: Constant speed throughout.
- **`ease`**: Standard CSS ease (starts fast, slows down gently).
- **`ease-in`**: Accelerates smoothly from start to end.
- **`ease-out`**: Decelerates smoothly towards the end.
- **`ease-in-out`**: Accelerates smoothly at start and decelerates smoothly at end.

### Animatable Properties
- **Colors**: `background-color`, `border-color`, `color` (smooth RGBA channel interpolation).
- **Geometry**: `border-radius`, `border-width`.

---

## Dark Mode & Theme Switching

### Built-in Dark Mode Rules
Floria Toolkit represents dark mode cleanly via the `.dark` class selector:
```css
window {
    background-color: #f0f2f5;
    color: #1e293b;
}

window.dark {
    background-color: #18181b;
    color: #f1f5f9;
}

container {
    background-color: #ffffff;
    border-color: #cbd5e1;
}

container.dark {
    background-color: #27272a;
    border-color: #3f3f46;
}
```

### Programmatic Dark Mode Switching
```c
// Toggle dark mode
int32_t is_dark = ft_theme_get_dark_mode();
ft_theme_set_dark_mode(!is_dark);
```
When `ft_theme_set_dark_mode()` is called, all open windows and popup menus automatically re-evaluate their CSS styles and repaint with animated transitions.

---

## Theme Discovery & Hot-Swapping

Floria Toolkit discovers CSS theme files automatically from the following locations:
1. Environment variable `FT_THEME_PATH` (colon-separated directories)
2. `~/.config/floria/themes`
3. `~/.local/share/floria/themes`
4. `/usr/share/floria/themes`
5. `/etc/floria/themes`
6. Local `./themes` and `../themes` directories

### Switching Themes at Runtime
```c
// Hot-swap theme by name
ft_theme_set("dracula");
ft_theme_set("nord");
ft_theme_set("gruvbox");
ft_theme_set("default");
```

---

## Inline Styles

For rapid prototyping or widget-specific visual customization without touching stylesheets, inline CSS can be set directly via the C API:

```c
FtWidget btn = ft_button_create(win, 30, 40, 200, 44, "Special Action");
ft_widget_set_style(btn, "background-color: #10b981; color: #ffffff; border-radius: 20px;");
```

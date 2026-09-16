# Floria Toolkit (`Ft`)

A lightweight, high-performance native GUI toolkit engineered with Free Pascal, Anti-Grain Geometry (`AGG`) subpixel vector rendering, modern CSS theming, smooth 60 FPS transitions, and a clean C ABI for universal language interoperability (C, C++, Python, Rust, Zig, Go).

> **Why "Floria"?**  
> The name **Floria** pays tribute to Free Pascal creator **Florian Klämpfl**.  
> The short moniker is **`Ft`**, pronounced **"Feat"**.

---

## Highlights

- **Subpixel Vector Rendering (AGG)**:
  - Subpixel-accurate antialiasing for vector curves, text, and surfaces.
  - True 2D Gaussian drop shadows with configurable offsets, blur, and opacity.
  - Subpixel gamma-corrected font rendering and native display DPI scaling.
- **Pure CSS Theming Engine**:
  - Standards-based `.css` stylesheets powered by Free Pascal's `fcl-css` parser.
  - Bundled themes: **Default** (Breeze/Fusion), **Nord**, **Dracula**, **Gruvbox**, **GTK2**, and **Classic**.
  - First-class **Light & Dark mode** with runtime hot-swapping and multi-window broadcasting.
  - Full support for element selectors, class selectors (`.dark`), ID selectors (`#id`), and pseudo-classes (`:hover`, `:active`, `:focus`, `:checked`).
- **CSS Transitions & Animation**:
  - Smooth 60 FPS state transitions (e.g. hover effects, dark mode switches) with easing functions (`ease`, `ease-in`, `ease-out`, `ease-in-out`, `linear`).
- **Modern Desktop Widgets**:
  - **Window**: Native X11 windows with double-buffered vector rendering.
  - **Button & Toggle Button**: Interactive push and latching buttons with hover transitions.
  - **Switch**: Modern toggle switch with circular thumb slider and accent highlights.
  - **CheckBox**: Crisp vector checkboxes with checkmark glyph and keyboard toggle.
  - **RadioButton**: Mutually exclusive options with grouping support and circular indicator.
  - **ComboBox**: Dropdown selection menu with popup list and optional editable entry.
  - **Slider**: Horizontal and vertical continuous or stepped sliders with dragging and keyboard arrows.
  - **ProgressBar**: Determinate percentage progress and 60 FPS indeterminate animated activity bar.
  - **Text / Label**: Dual-mode text with selectable mouse-drag highlight and clipboard copy.
  - **Entry**: Single-line text input with blinking caret, selection, and clipboard support.
  - **TextArea**: Multi-line text area with line navigation and dynamic scrollbars.
  - **ScrollBar**: Standalone vector scrollbars with proportional thumb sizing and drag physics.
  - **Container**: Scrolled viewport frame with automatic scrollbars and AGG scissor clipping.
  - **Menus**: Top-level Window Main Menu bar and floating popup context menus extending past window borders.
- **GTK-Style Keyboard Navigation**:
  - Full keyboard focus traversal (`Tab` / `Shift+Tab`) with theme focus rings.
- **Universal C ABI**:
  - Standalone shared library (`libft.so`) exposing a clean C interface via `include/ft.h`.

---

## Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

- 📖 **[C API Reference](docs/api-reference.md)**: Complete function listings, signatures, and descriptions for all toolkit APIs.
- 🎨 **[Theming & CSS Guide](docs/theming.md)**: Guide to writing CSS stylesheets, selectors, properties, transitions, and dark mode.
- 🧱 **[Widgets Architecture](docs/widgets.md)**: Widget hierarchy, coordinate systems, container clipping, and design patterns.
- 🏗️ **[Architecture & Internals](docs/architecture.md)**: Overview of the AGG graphics pipe, X11 backend, animation scheduler, and FFI layer.

---

## Visual Showcase

### Form Controls & Meters
![Form Controls & Meters Showcase](docs/screenshots/floria_form_controls.gif)
*Interactive CheckBoxes, RadioButtons, ComboBox dropdowns, live Slider dragging, and smooth 60 FPS indeterminate progress bar.*

### Window Main Menu & Pop-up Context Menus
![Window Main Menu & Pop-up Menu Showcase](docs/screenshots/floria_menus.gif)
*Window Main Menu bar with hover sweep tracking, cascading submenus, checkmarks, dynamic theming, and floating context menus.*

### Reusable Containers & Scrolled Viewports
![Reusable Container Showcase](docs/screenshots/floria_containers.gif)
*`TFtContainer` hosting heterogeneous child widgets with relative layout, auto scrollbars, and AGG viewport clipping.*

### Themes & Dynamic CSS Transitions
![Themes & CSS Transitions Showcase](docs/screenshots/floria_themes.gif)
*Pure CSS theming engine with runtime hot-swapping between Default, Dark Mode, Dracula, Nord, Gruvbox, GTK2, and Classic themes.*

---

## Quickstart

### C Example

```c
#include "ft.h"
#include <stdio.h>

static void on_btn_click(FtWidget widget, void* user_data) {
    printf("Button clicked! Data: %s\n", (const char*)user_data);
}

static void on_dark_toggle(FtWidget widget, int32_t checked, void* user_data) {
    ft_theme_set_dark_mode(checked);
}

int main(void) {
    ft_init();

    FtWidget win = ft_window_create(500, 320, "Floria Toolkit Quickstart");

    FtWidget btn = ft_button_create(win, 30, 40, 200, 44, "Click Me");
    ft_button_on_click(btn, on_btn_click, (void*)"SampleData");

    FtWidget sw = ft_switch_create(win, 30, 110, 200, 26, "Dark Mode");
    ft_switch_set_checked(sw, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw, on_dark_toggle, NULL);

    ft_widget_show(win);
    ft_main_loop();
    ft_quit();
    return 0;
}
```

### Python Example (`ctypes`)

```python
import ctypes

ft = ctypes.CDLL("./target/libft.so")
ft.ft_init()

win = ft.ft_window_create(400, 250, b"Python Floria App")
btn = ft.ft_button_create(win, 50, 50, 180, 40, b"Click Me")

# Hot-swap to Dracula theme with Dark Mode
ft.ft_theme_set(b"dracula")
ft.ft_theme_set_dark_mode(1)

ft.ft_widget_show(win)
ft.ft_main_loop()
ft.ft_quit()
```

---

## Building & Compiling

### Prerequisites
- **Free Pascal Compiler** (`fpc` 3.2.0+) or **PasBuild** / **Lazarus**
- **GCC** or **Clang** (for C examples)
- **Python 3** (for Python examples)
- **X11 Development Headers** (`libX11`, `libXext`)
- **fpgui-framework** (via PasBuild / fpcupdeluxe)

### 1. Build the Shared Library (`libft.so`)

Using **PasBuild**:
```bash
pasbuild compile
```
Or using **LazBuild**:
```bash
lazbuild src/main/pascal/ft.lpi
```

### 2. Build & Run C Examples

```bash
./build_examples.sh

# Run any example
./target/c_example
./target/example_menus
./target/example_containers
./target/css_button_demo
./target/css_animation_demo
```

### 3. Run Python Examples

```bash
python3 examples/python/app.py
```

---

## Directory Layout

```
floria-toolkit/
├── docs/                     # Detailed documentation & guides
│   ├── api-reference.md      # Full C API Reference
│   ├── theming.md            # CSS theming & transitions guide
│   ├── widgets.md            # Widget catalog & architecture
│   └── architecture.md       # Graphics pipe & backend design
├── include/
│   └── ft.h                  # C/C++ API header
├── src/main/pascal/
│   ├── ft.pas                # Library entry point & C exports
│   ├── ft.css.pas            # CSS stylesheet engine & cascade resolver
│   ├── ft.animation.pas      # Transition & animation interpolation engine
│   ├── ft.backend.x11.pas    # X11 window backend & 60 FPS event loop
│   ├── ft.canvas.agg.pas     # AGG 2D vector drawing & shadow pipeline
│   ├── ft.widget.pas         # Base widget abstraction
│   ├── ft.widget.buttons.pas # Button & toggle button
│   ├── ft.widget.switches.pas# Toggle switch
│   ├── ft.widget.texts.pas   # Selectable & static text labels
│   ├── ft.widget.entries.pas # Single-line text input
│   ├── ft.widget.textareas.pas# Multi-line text area
│   ├── ft.widget.scrollbars.pas# Scrollbar widget
│   ├── ft.widget.containers.pas# Container box & viewport
│   ├── ft.widget.menus.pas   # Main menu bar & popup menus
│   ├── ft.theme.pas          # Theme manager & stylesheet loader
│   └── ft.font.pas           # Font management & subpixel DPI scaling
├── themes/                   # Bundled CSS theme stylesheets (*.css)
│   ├── default.css           # Modern Breeze/Fusion theme
│   ├── nord.css              # Arctic frosty slate theme
│   ├── dracula.css           # Dracula dark theme
│   ├── gruvbox.css           # Retro warm Gruvbox theme
│   ├── gtk2.css              # Industrial GTK2 gray theme
│   └── classic.css           # Slate with emerald accents theme
├── 3rdparty/
│   └── fcl-css/              # Free Pascal CSS parser package
├── examples/
│   ├── c/                    # C demo applications
│   └── python/               # Python ctypes applications
└── project.xml               # PasBuild package manifest
```

---

## Roadmap

Floria Toolkit is continuously evolving. High-priority initiatives include:

- **Pluggable Graphics Architecture (`TFtCanvas`)**:
  - Abstracting the vector canvas to support **Hardware-Accelerated GPU backends** (OpenGL / Vulkan) alongside **AggPas as the premier Software Fallback & Reference Engine** (ensuring zero-driver reliability in VMs, headless CI, and remote sessions).
  - Dynamic runtime backend negotiation (`ft_init`) with transparent fallback.
- **Display Protocols**: Native Wayland (`xdg-shell`) backend, Windows (Win32), and macOS (Cocoa).
- **Advanced Controls**: DataGrids with virtual scrolling, TreeViews, Tabbed notebooks, and Splitter panes.
- **Typography & i18n**: HarfBuzz complex text shaping, BiDi support, and IME integration.

See the complete [ROADMAP.md](ROADMAP.md) for full architectural details and technical milestones.

---

## License

Floria Toolkit is licensed under the [Mozilla Public License 2.0 (MPL-2.0)](LICENSE).  
Copyright (c) Floria Project / Dio Affriza.

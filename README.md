# Floria Toolkit (`Ft`)

A lightweight, high-performance native GUI toolkit engineered with Free Pascal, Anti-Grain Geometry (`AGG`) subpixel vector rendering, modern widget styling, and a clean C ABI for multi-language interoperability (C, C++, Python, Rust, Zig, Go).

---

## Highlights

- **Anti-Grain Geometry (AGG) Rendering**:
  - Subpixel-accurate antialiasing for vector curves, text, and surfaces.
  - Smooth rounded rectangles and dynamic corner radiuses.
  - True 2D Gaussian drop shadows with configurable offsets, blur, and opacity.
  - Subpixel gamma-corrected font rendering and native display DPI scaling.

- **Modern Theming System**:
  - Built-in **`default`** theme featuring a modern Qt6 / Breeze-inspired flat vector look with vibrant blue accents, soft elevation shadows, and rounded corners.
  - Dynamic **`.theme`** file loader: Load community and custom themes from disk at runtime with hot-swapping (`themes/*.theme`).
  - First-class **Light & Dark mode** support with automatic desktop theme / environment detection (`FT_DARK_MODE`, `GTK_THEME`, `~/.config/floria/dark_mode`).
  - Global and per-widget customizable corner radiuses and drop shadows.

- **Widgets**:
  - **Window**: Native X11 windows with custom background rendering, resizable layout handling, and event dispatching.
  - **Push Button & Toggle Button**: Interactive states (Normal, Hovered, Pressed, Toggled) with smooth visual transitions, customizable corner radiuses, and shadows.
  - **Switch**: Modern toggle switch with circular thumb slider, customizable track radii, elevation shadows, active track accent glows, and automatic label positioning.

- **Universal C FFI**:
  - Packaged as a standalone shared library (`libft.so`) exposing a standard C ABI via `include/ft.h`.
  - Zero heavy external dependencies; easily integrated into any programming language.

---

## Directory Layout

```
floria-toolkit/
├── include/
│   └── ft.h                  # C/C++ API header
├── src/
│   └── main/pascal/
│       ├── ft.pas            # Shared library entry point & C exports
│       ├── ft.backend.x11.pas# X11 window backend & event dispatch loop
│       ├── ft.canvas.agg.pas # AGG 2D vector drawing & shadow pipeline
│       ├── ft.widget.pas     # Base widget abstraction
│       ├── ft.buttons.pas    # Button & Toggle Button implementations
│       ├── ft.switch.pas     # Modern Switch widget implementation
│       ├── ft.theme.pas      # Theme engine, default theme & file themes
│       └── ft.font.pas       # Font management, DPI scaling & gamma
├── themes/                   # Bundled community & style theme files
│   ├── classic.theme         # Elevated 3D slate with emerald green accents
│   ├── dracula.theme         # Dark fantasy palette with neon pink/purple
│   ├── gruvbox.theme         # Retro warm parchment / dark charcoal
│   ├── gtk2.theme            # Industrial slate & steel gray palette
│   └── nord.theme            # Arctic frosty slate & polar cyan palette
├── examples/
│   ├── c/
│   │   └── main.c            # Comprehensive C demonstration app
│   └── python/
│       └── app.py            # Python ctypes wrapper & interactive showcase
└── project.xml               # PasBuild package configuration
```

---

## Building & Compiling

### Prerequisites
- **Free Pascal Compiler** (`fpc` 3.2.0+)
- **GCC** or **Clang** (for compiling C examples)
- **Python 3** (for running Python examples)
- **X11 Development Headers** (`libX11`, `libXext`)
- **fpgui-framework** (installed via PasBuild / fpcupdeluxe)

### 1. Build the Shared Library (`libft.so`)

Using `fpc`:

```bash
mkdir -p target/bin/lib/x86_64-linux

fpc -Mobjfpc -Scghi -Cg -O1 -g -gl -vewnhibq \
  -Fi./target/bin/lib/x86_64-linux \
  -Fu./src/main/pascal/ \
  -Fu$HOME/.pasbuild/repository/fpgui-framework/2.2.0-SNAPSHOT/x86_64-linux-3.2.3/units \
  -FU./target/bin/lib/x86_64-linux/ \
  -FE./target/bin/ \
  -otarget/bin/libft.so src/main/pascal/ft.pas
```

### 2. Build the C Example

```bash
gcc -Iinclude -Ltarget/bin -Wl,-rpath,'$ORIGIN',-rpath,'$ORIGIN/..' \
    -o target/bin/c_example examples/c/main.c -lft
```

Run the C example:
```bash
./target/bin/c_example
```

### 3. Run the Python Example

```bash
python3 examples/python/app.py
```

---

## Quickstart

### C Example

```c
#include "ft.h"
#include <stdio.h>

void on_button_click(FtWidget widget, void* user_data) {
    printf("Button clicked! User data: %s\n", (char*)user_data);
}

void on_switch_toggle(FtWidget widget, int32_t checked, void* user_data) {
    printf("Dark Mode is now: %s\n", checked ? "ON" : "OFF");
    ft_theme_set_dark_mode(checked);
}

int main(void) {
    // 1. Initialize toolkit
    ft_init();

    // 2. Create main window (500x320)
    FtWidget win = ft_window_create(500, 320, "Floria Toolkit Quickstart");

    // 3. Add a Button
    FtWidget btn = ft_button_create(win, 30, 40, 200, 44, "Click Me");
    ft_button_on_click(btn, on_button_click, (void*)"MyButton");

    // 4. Add a Switch
    FtWidget sw = ft_switch_create(win, 30, 110, 200, 26, "Dark Mode");
    ft_switch_set_checked(sw, ft_theme_get_dark_mode());
    ft_switch_on_toggle(sw, on_switch_toggle, NULL);

    // 5. Show and start event loop
    ft_widget_show(win);
    ft_main_loop();

    return 0;
}
```

### Python Example (`ctypes`)

```python
import ctypes

# Load Floria Toolkit shared library
ft = ctypes.CDLL("./target/bin/libft.so")

ft.ft_init()
win = ft.ft_window_create(400, 250, b"Python Floria App")

# Create a toggle button
btn = ft.ft_toggle_button_create(win, 50, 50, 180, 40, b"Toggle Me")

# Hot-switch theme to Dracula or Nord
ft.ft_theme_set(b"nord")
ft.ft_theme_set_dark_mode(1)

ft.ft_widget_show(win)
ft.ft_main_loop()
```

---

## Theming System

### Built-in vs. File Themes

- **`default` (Built-in)**:
  - Hardcoded into `TFtThemeDefault` inside the binary for zero external asset requirements.
  - Implements the modern Qt6 / Breeze visual appearance.
  - Supports both Light Mode and Dark Mode.
  - Requesting `'qt6'` automatically resolves to `'default'`.

- **Dynamic Theme Files (`*.theme`)**:
  - Saved as INI-formatted text files inside `themes/` or standard configuration folders.
  - Hot-swappable at runtime without needing application restart.

### Theme File Format

Themes are plain text INI files structured as follows:

```ini
[Theme]
Name=nord
Author=Arctic Ice Studio / Floria Project
Description=Arctic frosty slate palette with polar cyan accents
Style=modern
CornerRadius=4.0
Shadow=true
ShadowOffsetY=2.0
ShadowBlur=4.0
ShadowOpacity=0.18

[Light]
window.bg = #ECEFF4
button.normal.plate = #E5E9F0
button.normal.border = #D8DEE9
button.normal.text = #2E3440
button.hover.plate = #ECEFF4
button.hover.border = #88C0D0
button.hover.text = #88C0D0
button.pressed.plate = #D8DEE9
button.pressed.border = #81A1C1
button.pressed.text = #2E3440
button.toggled.plate = #E5E9F0
button.toggled.border = #88C0D0
button.toggled.indicator = #88C0D0
button.toggled.text = #88C0D0

[Dark]
window.bg = #242933
button.normal.plate = #2E3440
button.normal.border = #3B4252
button.normal.text = #ECEFF4
button.hover.plate = #3B4252
button.hover.border = #88C0D0
button.hover.text = #88C0D0
button.pressed.plate = #242933
button.pressed.border = #81A1C1
button.pressed.text = #ECEFF4
button.toggled.plate = #2E3440
button.toggled.border = #88C0D0
button.toggled.indicator = #88C0D0
button.toggled.text = #88C0D0
```

### Theme Discovery Directories
Floria Toolkit automatically discovers `.theme` files from the following paths:
1. Paths in environment variable `FT_THEME_PATH` (colon separated)
2. `~/.config/floria/themes`
3. `~/.local/share/floria/themes`
4. `/usr/share/floria/themes`
5. `/etc/floria/themes`
6. Local `./themes` directory

---

## API Reference

### Core Lifecycle
| Function | Description |
|---|---|
| `void ft_init(void)` | Initializes the toolkit backend, font subsystem, and theme manager |
| `void ft_main_loop(void)` | Enters the event dispatch loop (blocks until all windows close or `ft_quit`) |
| `void ft_quit(void)` | Terminates the main loop and cleans up toolkit resources |

### Window Management
| Function | Description |
|---|---|
| `FtWidget ft_window_create(int32_t w, int32_t h, const char* title)` | Creates and returns a top-level native window |
| `void ft_window_set_title(FtWidget win, const char* title)` | Sets window title string |
| `void ft_widget_show(FtWidget widget)` | Maps and displays the widget/window on screen |

### Button Widgets
| Function | Description |
|---|---|
| `FtWidget ft_button_create(parent, x, y, w, h, caption)` | Creates a standard push button |
| `FtWidget ft_toggle_button_create(parent, x, y, w, h, caption)` | Creates a toggleable button |
| `void ft_button_set_toggle(FtWidget btn, int32_t can_toggle)` | Enables or disables toggle mode on a button |
| `void ft_button_set_toggled(FtWidget btn, int32_t toggled)` | Sets toggle state (0 = untoggled, 1 = toggled) |
| `int32_t ft_button_get_toggled(FtWidget btn)` | Queries whether button is toggled |
| `int32_t ft_button_get_state(FtWidget btn)` | Returns button interaction state (`NORMAL`, `HOVERED`, `PRESSED`) |
| `void ft_button_on_click(btn, callback, user_data)` | Registers click callback |
| `void ft_button_on_hover(btn, callback, user_data)` | Registers mouse enter/leave hover callback |
| `void ft_button_on_press(btn, callback, user_data)` | Registers mouse button down/up callback |
| `void ft_button_on_toggle(btn, callback, user_data)` | Registers toggle state change callback |
| `void ft_button_set_corner_radius(btn, double radius)` | Sets per-widget corner radius (`-1.0` to inherit theme) |
| `void ft_button_set_shadow(btn, int32_t enabled)` | Sets per-widget shadow (`-1` to inherit theme, `0` = off, `1` = on) |

### Switch Widgets
| Function | Description |
|---|---|
| `FtWidget ft_switch_create(parent, x, y, w, h, caption)` | Creates a toggle switch widget |
| `void ft_switch_set_checked(FtWidget sw, int32_t checked)` | Sets switch checked state |
| `int32_t ft_switch_get_checked(FtWidget sw)` | Returns 1 if checked, 0 if unchecked |
| `void ft_switch_toggle(FtWidget sw)` | Inverts the switch state |
| `void ft_switch_on_toggle(sw, callback, user_data)` | Registers callback invoked on switch toggle |
| `void ft_switch_set_corner_radius(sw, double radius)` | Sets per-widget corner radius |
| `void ft_switch_set_shadow(sw, int32_t enabled)` | Sets per-widget drop shadow |
| `void ft_switch_set_caption(sw, const char* caption)` | Sets adjacent label text |
| `const char* ft_switch_get_caption(FtWidget sw)` | Gets adjacent label text |

### Theme & Styling Management
| Function | Description |
|---|---|
| `int32_t ft_theme_set(const char* name)` | Switches active theme (`"default"`, `"nord"`, `"dracula"`, etc.) |
| `const char* ft_theme_get(void)` | Returns the name of the currently active theme |
| `const char* ft_theme_get_available(void)` | Returns comma-separated list of available themes |
| `void ft_theme_set_dark_mode(int32_t enabled)` | Sets dark mode state (0 = light, 1 = dark) |
| `int32_t ft_theme_get_dark_mode(void)` | Returns 1 if dark mode is active, 0 otherwise |
| `void ft_theme_set_corner_radius(double radius)` | Sets global theme corner radius (`-1.0` for theme preset) |
| `double ft_theme_get_corner_radius(void)` | Returns current global corner radius |
| `void ft_theme_set_shadow(int32_t enabled)` | Enables or disables drop shadows globally |
| `int32_t ft_theme_get_shadow(void)` | Returns 1 if shadows are enabled, 0 otherwise |
| `int32_t ft_theme_load_file(const char* filepath)` | Loads a `.theme` file directly |
| `int32_t ft_theme_load_dir(const char* dirpath)` | Loads all `.theme` files found in a directory |

### Typography & Display
| Function | Description |
|---|---|
| `const char* ft_system_font_get(void)` | Returns active system font name |
| `void ft_system_font_set(const char* font_desc)` | Sets font family and size |
| `double ft_screen_dpi_get(void)` | Returns detected or configured screen DPI |
| `void ft_screen_dpi_set(double dpi)` | Overrides screen DPI for scaling |
| `double ft_font_gamma_get(void)` | Returns current subpixel font gamma value |
| `void ft_font_gamma_set(double gamma)` | Configures font antialiasing gamma |

---

## License

Floria Toolkit is licensed under the [BSD-3-Clause License](LICENSE).
Copyright (c) Floria Project / Dio Affriza.

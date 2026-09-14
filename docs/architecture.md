# Floria Toolkit Architecture

Floria Toolkit (`Ft`) is engineered as a lightweight, modular desktop GUI framework combining the performance and memory efficiency of Free Pascal with subpixel Anti-Grain Geometry (`AGG`) vector graphics, modern CSS theming, and a universal C ABI.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│             Client Applications / Language Hosts             │
│            (C, C++, Python, Rust, Zig, Go, Pascal)          │
└──────────────────────────────┬──────────────────────────────┘
                               │ C ABI (include/ft.h)
┌──────────────────────────────▼──────────────────────────────┐
│                    Floria C FFI (ft.pas)                    │
├──────────────────────────────┬──────────────────────────────┤
│    Widget Engine             │    CSS & Theming Engine      │
│    - ft.widget.pas           │    - ft.css.pas (fcl-css)    │
│    - ft.widget.buttons.pas   │    - ft.theme.pas            │
│    - ft.widget.containers.pas│    - ft.animation.pas        │
│    - ft.widget.menus.pas     │                              │
├──────────────────────────────┴──────────────────────────────┤
│         AGG Vector Graphics Pipeline (ft.canvas.agg.pas)    │
│         - Subpixel Antialiasing & Curves                    │
│         - True 2D Gaussian Drop Shadows                     │
│         - DPI Scaling & Gamma-Corrected Font Glyphs         │
├─────────────────────────────────────────────────────────────┤
│         X11 Backend & Event Loop (ft.backend.x11.pas)       │
│         - Native Windows & Compositor-Friendly Menus        │
│         - 60 FPS Animation Frame Scheduler                  │
│         - Double-Buffered Shared Memory Render Surfaces     │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Vector Graphics Pipeline (`Ft.Canvas.Agg`)
Floria Toolkit bypasses traditional rasterization libraries in favor of Anti-Grain Geometry (`AGG`):
- **Subpixel Antialiasing**: Every line, curve, rounded rectangle, and text glyph is rasterized with subpixel precision.
- **Gaussian Drop Shadows**: Employs true 2D dual-pass Gaussian box blurs to create realistic elevation shadows under buttons, menus, and cards.
- **Scissor Clipping Stack**: Hierarchical scissor rectangles allow containers and viewports to nest arbitrarily with zero visual clipping artifacts.

### 2. X11 Backend & Event Loop (`Ft.Backend.X11`)
- **Native X11 Integration**: Manages `Display`, `Window`, `GC`, and `XImage` with double-buffered software rendering.
- **60 FPS Animation Scheduler**: The event dispatch loop measures frame delta times and advances active CSS animations with 16ms sleep pacing when active, reverting to event-driven idle sleeping when static.
- **Multi-Window Broadcaster**: Uses `TFtX11Broadcaster` to propagate global stylesheet updates, theme changes, and dark-mode toggles across all active main windows and popup menus simultaneously.

### 3. CSS & Theming Engine (`Ft.Css`, `Ft.Theme`)
- **Standards-Compliant Parser**: Uses Free Pascal's `fcl-css` parser to parse standard `.css` stylesheets into syntax trees.
- **Style Resolution & Specificity**: Evaluates element selectors, class selectors (`.dark`, `.danger`), ID selectors (`#name`), and state pseudo-classes (`:hover`, `:active`, `:focus`, `:checked`).
- **Dirty-Flag Invalidation**: Widgets cache their resolved styles in `FResolvedStyle` and only recompute when `InvalidateStyle()` is called (e.g. on state or theme change).

### 4. Transition & Animation Engine (`Ft.Animation`)
- **Property Transition Interception**: When a widget transitions between states (such as normal to hover), the animation engine detects differences in properties marked for transitions.
- **Timing Easing**: Animates properties according to cubic-bezier curves (`linear`, `ease`, `ease-in`, `ease-out`, `ease-in-out`).
- **Automatic Frame Refresh**: Notifies the X11 backend to schedule repaints until all active transitions complete.

### 5. Universal C FFI Layer (`ft.pas`, `include/ft.h`)
- **Opaque Pointers**: Widgets and menu items are represented as opaque handles (`FtWidget`, `FtMenuItem`), protecting internal Pascal objects.
- **ABI Stability**: Only standard C primitives (`int32_t`, `double`, `const char*`, `void*` function pointers) are exposed across the library boundary.
- **Zero Overhead**: Direct dynamic linking via `libft.so` allows seamless use from C, Python (`ctypes`), Rust, Zig, Go, and C++.

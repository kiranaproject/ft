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
┌─────────────────────────────────────────────────────────────┐
│                    Floria C FFI (ft.pas)                    │
├──────────────────────────────┬──────────────────────────────┤
│    Widget Engine             │    CSS & Theming Engine      │
│    - ft.widget.pas           │    - ft.css.pas (Floria.CSS) │
│    - ft.widget.buttons.pas   │    - ft.theme.pas            │
│    - ft.widget.containers.pas│    - ft.animation.pas        │
│    - ft.widget.tabs.pas      │                              │
│    - ft.widget.tables.pas    │                              │
│    - ft.widget.images.pas    │                              │
│    - ft.widget.menus.pas     │                              │
├──────────────────────────────┴──────────────────────────────┤
│               Window Abstraction (ft.window.pas)            │
│               - TFtWindow base class & Window Factory       │
│               - Dirty Rect Tracking, Repaint & Focus Mgmt   │
│               - Clipboard, Primary Selection & Input Grab   │
├─────────────────────────────────────────────────────────────┤
│      Vector Graphics Engine (florialib / Floria.Canvas.Agg) │
│      - Subpixel Antialiasing & Curves (AggPas)              │
│      - True 2D Gaussian Drop Shadows (Floria.Blur)          │
│      - DPI Scaling & Subpixel Fonts (Floria.Font)           │
│      - Pixel Buffers & SVG Renderer (Floria.Bitmap, .SVG)   │
├─────────────────────────────────────────────────────────────┤
│               Platform Backends & Event Loop                │
│   ┌────────────────────────┬──────────────┬─────────────┐   │
│   │ X11/XCB (ft.backend.x11)│ WinAPI (Win) │ Cocoa (macOS│   │
│   │ - Native XCB Windows   │ (In Roadmap) │ (In Roadmap)│   │
│   │ - 60 FPS Event Loop    │              │             │   │
│   └────────────────────────┴──────────────┴─────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Vector Graphics Pipeline (`Floria.Canvas.Agg` via `florialib`)
Floria Toolkit leverages Anti-Grain Geometry (`AGG`) vector primitives through `florialib`:
- **Subpixel Antialiasing**: Every line, curve, rounded rectangle, and text glyph is rasterized with subpixel precision.
- **Gaussian Drop Shadows**: Employs true 2D dual-pass Gaussian box blurs (`Floria.Blur`) to create realistic elevation shadows under buttons, menus, and cards.
- **Scissor Clipping Stack**: Hierarchical scissor rectangles allow containers and viewports to nest arbitrarily with zero visual clipping artifacts.
- **Font & Asset Management**: Uses `Floria.Font` for FreeType font management with DPI scaling and `Floria.Bitmap` / `Floria.SVG` for image and vector asset handling.
- **Pluggable Architecture (Roadmap)**: As hardware-accelerated GPU backends (OpenGL, Vulkan) are introduced via an abstract `TFtCanvas` interface, `AggPas` remains the primary zero-dependency **Software Reference and Fallback Engine** for headless CI, VMs, remote X11/VNC sessions, and pre-rasterization asset caching. See [ROADMAP.md](../ROADMAP.md) for details.

### 2. Window Abstraction Layer (`Ft.Window`)
Floria Toolkit decouples widgets and menus from specific windowing systems via `TFtWindow`:
- **Base Class `TFtWindow`**: Inherits from `TFtWidget` and encapsulates common top-level window logic:
  - **Agg Pixel Buffer & Canvas**: Double-buffered `FPixelBuffer` and `FCanvas: TFtCanvasAgg` allocation, surface lifecycle, and blitting.
  - **Dirty Rectangle Tracking**: Selective region invalidation (`InvalidateRect`) to minimize re-rasterization overhead.
  - **Focus & Selection Management**: Full keyboard traversal (`FocusNext`), active popup coordination, and abstract clipboard / primary selection APIs (`ClaimClipboard`, `FetchClipboardText`, `ClaimPrimarySelection`).
- **Factory Registration Pattern**: Backends register their native implementation class via `FtRegisterWindowClass()`. Calling `FtCreateWindow()` instantiates the registered platform backend transparently.
- **Multi-Backend Extensibility**: Enables introducing future native backends (WinAPI for Windows, Cocoa for macOS, Wayland) with zero changes to existing widgets or user application code.

### 3. X11/XCB Backend & Event Loop (`Ft.Backend.X11`, `TFtX11Window`)
- **Native X11/XCB Integration**: `TFtX11Window` inherits from `TFtWindow`, implementing native XCB window management, graphics context (`xcb_gcontext_t`), and surface blits.
- **60 FPS Animation Scheduler**: The event dispatch loop measures frame delta times and advances active CSS animations with 16ms sleep pacing when active, reverting to event-driven idle sleeping when static.
- **Compositor & Blur Integration**: Supports modern EWMH window types, window opacity, and KDE/KWin blur behind window hints (`_KDE_NET_WM_BLUR_BEHIND_REGION`).

### 4. CSS & Theming Engine (`Ft.Css`, `Ft.Theme`)
- **Standards-Compliant Parser**: Uses the Floria standard library's `Floria.CSS` engine (`florialib`) to parse standard `.css` stylesheets into syntax trees.
- **Style Resolution & Specificity**: Evaluates element selectors, class selectors (`.dark`, `.danger`), ID selectors (`#name`), and state pseudo-classes (`:hover`, `:active`, `:focus`, `:checked`).
- **Dirty-Flag Invalidation**: Widgets cache their resolved styles in `FResolvedStyle` and only recompute when `InvalidateStyle()` is called (e.g. on state or theme change).

### 5. Transition & Animation Engine (`Ft.Animation`)
- **Property Transition Interception**: When a widget transitions between states (such as normal to hover), the animation engine detects differences in properties marked for transitions.
- **Timing Easing**: Animates properties according to cubic-bezier curves (`linear`, `ease`, `ease-in`, `ease-out`, `ease-in-out`).
- **Automatic Frame Refresh**: Notifies the backend to schedule repaints until all active transitions complete.

### 6. Universal C FFI Layer (`ft.pas`, `include/ft.h`)
- **Opaque Pointers**: Widgets and menu items are represented as opaque handles (`FtWidget`, `FtMenuItem`), protecting internal Pascal objects.
- **ABI Stability**: Only standard C primitives (`int32_t`, `double`, `const char*`, `void*` function pointers) are exposed across the library boundary.
- **Zero Overhead**: Direct dynamic linking via `libft.so` allows seamless use from C, Python (`ctypes`), Rust, Zig, Go, and C++.

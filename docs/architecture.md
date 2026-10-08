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

### 1. Dual Graphics Pipeline: EGL GPU Acceleration & AggPas Reference Engine
Floria Toolkit provides a hybrid, polymorphic 2D graphics architecture through `florialib`:
- **Hardware-Accelerated GPU Canvas (`TFtHardwareCanvas` / `IFtHardwareCanvas`)**:
  - Powered by native **EGL 1.4/1.5** and **OpenGL ES 2.0** dynamic bindings (`floria.gl.pas`, `floria.gpu.context.pas`).
  - High-throughput draw-call batching (`TFloriaRenderBatch`) streaming 64-byte std140-aligned vertices directly to GPU VBOs.
  - Ahead-of-time (AOT) precompiled GLSL shaders (`floria.gpu.shaders.pas`) with zero runtime JIT compilation pauses.
  - Analytic Signed Distance Field (SDF) evaluation for rounded rectangles, borders, and capsule pills (`border-radius: 9999px`) with subpixel antialiasing.
  - Single-pass analytical Gaussian box shadows using error-function approximations.
- **AggPas as the Premier Software Fallback & Reference Engine**:
  - Decoupled Anti-Grain Geometry (`AggPas:2.4.0-SNAPSHOT`) CPU vector rasterization.
  - Subpixel-accurate antialiasing for vector curves, text, and surfaces.
  - True 2D dual-pass Gaussian box blurs (`Floria.Blur`) and elevation shadows.
  - Guarantees 100% deterministic pixel-accurate output across headless CI, virtual machines, and legacy hardware without graphics drivers.
- **Hierarchical Clipping & Asset Rendering**:
  - Analytical clip chains and scissor stacks nesting arbitrarily with zero edge artifacts.
  - FreeType font engine (`Floria.Font`) with subpixel gamma correction, HarfBuzz text shaping, and SVG vector asset decoding.

### 2. Window Abstraction Layer (`Ft.Window`)
Floria Toolkit decouples widgets and menus from specific windowing systems via `TFtWindow`:
- **Base Class `TFtWindow`**: Inherits from `TFtWidget` and encapsulates common top-level window logic:
  - **Polymorphic Canvas Binding**: Supports both software `TFtCanvasAgg` and hardware `TFtHardwareCanvas` with automatic runtime negotiation.
  - **Modal Event Loop**: Native `ShowModal` and `ft_window_show_modal` running an isolated event loop that stack windows on top and handle dialog results.
  - **Dirty Rectangle Tracking**: Selective region invalidation (`InvalidateRect`) to minimize re-rasterization overhead.
  - **Focus & Selection Management**: Full keyboard traversal (`FocusNext`), active popup coordination, and abstract clipboard / primary selection APIs (`ClaimClipboard`, `FetchClipboardText`, `ClaimPrimarySelection`).
- **Desktop Shell & EWMH Protocols**:
  - Panel and dock reservation via `_NET_WM_STRUT_PARTIAL` (`ft_window_set_strut_partial`).
  - Input grabbing (`ft_window_grab_pointer`) and low-level X11 event filtering hooks (`ft_window_install_event_filter`).
- **Factory Registration Pattern**: Backends register their native implementation class via `FtRegisterWindowClass()`. Calling `FtCreateWindow()` instantiates the registered platform backend transparently.
- **Multi-Backend Extensibility**: Enables introducing future native backends (WinAPI for Windows, Cocoa for macOS) with zero changes to existing widgets or user application code.

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
- **Rock-Solid ABI Stability (The Windows API Standard)**: Rejecting the frequent API/ABI breakage and deprecation churn common in modern toolkits (such as the transitions between GTK2, GTK3, and GTK4), Floria Toolkit treats its C ABI as frozen, permanent, and strictly append-only.
- **Opaque Pointers**: Widgets and menu items are represented as opaque handles (`FtWidget`, `FtMenuItem`), protecting internal Pascal objects and VMT layouts from leaking across the FFI boundary.
- **ABI Stability**: Only standard C primitives (`int32_t`, `double`, `const char*`, `void*` function pointers) and standard calling conventions (`cdecl`) are exposed.
- **Zero Overhead**: Direct dynamic linking via `libft.so` allows seamless, zero-bloat interoperability from C, Python (`ctypes`), Rust, Zig, Go, and C++.

---

## Further Reading

For an exhaustive analysis of engineering trade-offs, toolkit invariants, compositor cleanliness (avoiding double shadows & clipped corners under Picom/KWin), CSS cascade rules, zero-idle rendering, and FFI guidelines, consult:
- **[Design Rationale & Architectural Invariants](design-rationale.md)**
- **[Theming & CSS Architecture](theming.md)**
- **[Widget Catalog & Custom Widgets](widgets.md)**
- **[Full C API Reference](api-reference.md)**

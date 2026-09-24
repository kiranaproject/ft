# Floria Toolkit Design Rationale

This document captures the architectural decisions, design invariants, and lessons learned during the engineering of Floria Toolkit (`Ft`). It serves as an authoritative reference for contributors and developers extending the toolkit.

---

## Table of Contents
1. [Core Philosophy & Stability Guarantees](#1-core-philosophy--stability-guarantees)
   - [Desktop-First Priority: No Tablet/Hybrid Compromises](#11-desktop-first-priority-no-tablethybrid-compromises)
   - [First-Class X11 Commitment](#12-first-class-x11-commitment)
   - [Avoiding the GTK Churn: The Windows API Standard of Stability](#13-avoiding-the-gtk-churn-the-windows-api-standard-of-stability)
   - [Zero Heavy Runtime Dependencies](#14-zero-heavy-runtime-dependencies)
   - [Subpixel Vector Fidelity & Clean Separation](#15-subpixel-vector-fidelity--clean-separation)
2. [Native Windowing & Compositor Cleanliness](#2-native-windowing--compositor-cleanliness)
3. [Window Abstraction Layer (`TFtWindow`)](#3-window-abstraction-layer-tftwindow)
4. [Graphics Engine: AggPas as the Reference Standard](#4-graphics-engine-aggpas-as-the-reference-standard)
5. [CSS Engine, Specificity & Semantic Theming](#5-css-engine-specificity--semantic-theming)
6. [Rendering Pipeline & Partial Invalidation](#6-rendering-pipeline--partial-invalidation)
   - [Zero CPU Waste at Idle](#zero-cpu-waste-at-idle)
   - [Virtualized Data Grids & The "Cell Stamp" Flyweight Pattern](#virtualized-data-grids--the-cell-stamp-flyweight-pattern)
7. [Universal C ABI & Language Bindings](#7-universal-c-abi--language-bindings)
8. [Modularity & Linker Invariants](#8-modularity--linker-invariants)

---

## 1. Core Philosophy & Stability Guarantees

Floria Toolkit (`Ft`) is engineered to solve fundamental frustrations in modern desktop and cross-platform GUI development:

### 1.1 Desktop-First Priority: No Tablet/Hybrid Compromises
Modern UI design trends have repeatedly compromised desktop productivity by chasing unified phone/tablet "hybrid" interfaces. This trend has introduced oversized touch padding, drastically reduced information density, hidden or disappearing scrollbars, awkward hamburger menus, modal drawer navigations, and tablet gestures that handicap desktop mouse-and-keyboard workflows.

Floria Toolkit is **unapologetically desktop-first**:
- **High Information Density**: Built specifically for data-rich desktop applications requiring compact data grids, hierarchical trees, docking splitters, toolbars, and notebook tabs.
- **Precision Cursor Ergonomics**: Engineered for high-precision mouse pointer interactions, pixel-perfect hover states, instant tooltips, standard context menus, and mouse wheel navigation.
- **Comprehensive Keyboard Navigation**: Deep support for keyboard accessibility, including standard tab traversal (`FocusNext`), mnemonic accelerators, menu shortcuts, and directional navigation.
- **Traditional Desktop Paradigms**: Real menu bars, dockable toolbars, persistent scrollbars, status bars, and coordinated multi-window workflows are foundational, first-class features.

### 1.2 First-Class X11 Commitment
While providing a clean window abstraction layer for future backends (Wayland, WinAPI, Cocoa), **X11/XCB is treated as a premier, first-class citizen**—not a legacy burden slated for deprecation or treated with hostile neglect.

X11 has decades of proven stability, battle-tested network transparency, robust remote display protocols, comprehensive window management standards (ICCCM/EWMH), and an enormous installed base across technical, engineering, scientific, and enterprise environments. Floria Toolkit natively targets modern XCB (`libxcb`) with microsecond event dispatch, zero bloated intermediate libraries, and full support for EWMH window types, native window hints, and compositor blur protocols (`_KDE_NET_WM_BLUR_BEHIND_REGION`).

### 1.3 Avoiding the GTK Churn: The Windows API Standard of Stability
The Linux desktop development ecosystem has suffered from severe fragmentation and developer fatigue driven by the incessant churn, behavioral shifts, and architectural resets between GTK2, GTK3, and GTK4:
- **Frequent ABI & API Breakage**: Minor and major releases frequently altered function signatures, removed public APIs, broke language bindings, and required continuous application refactoring.
- **Disruption of Theming & Conventions**: Theme engines and CSS rules were repeatedly invalidated between point releases. Established desktop conventions (such as notification tray icons, submenus, standard file dialogs, and native window frame integration) were deprecated or stripped in favor of forced Client-Side Decorations (CSD).
- **The Windows API Standard**: In contrast, the classic Microsoft Windows API (Win32) established the industry standard for long-term binary stability: software compiled against Win32 decades ago continues to run, link, and render reliably on modern operating systems.
- **Floria Toolkit's Stability Invariant**: Floria Toolkit adopts the **Windows API standard of stability**. Our C ABI (`include/ft.h`, `libft.so`) is designed to be permanent, dependable, and strictly backward-compatible:
  - **No ABI churn**: We do not break binary or API compatibility every two minor releases.
  - **Opaque Handle Architecture**: All public entities ([`FtWidget`](file:///home/afumi/Documents/projects/floria-toolkit/include/ft.h), [`FtMenuItem`](file:///home/afumi/Documents/projects/floria-toolkit/include/ft.h)) are opaque handles. Internal Pascal classes, memory layouts, and virtual method tables remain hidden behind the C boundary.
  - **Append-Only Evolution**: New features and parameters are introduced through new, additive functions without altering or removing existing symbols.
  - **Reliable Long-Term Platform**: Developers writing software in C, C++, Python, Rust, Zig, Go, or Pascal can rely on `libft.so` as a rock-solid, permanent foundation that will not break underneath them.

### 1.4 Zero Heavy Runtime Dependencies
Unlike Web/Electron/Chromium wrappers (which consume hundreds of megabytes of memory and introduce noticeable event loop latency) or monolithic C++ frameworks (with fragile compiler-specific ABIs and gigabyte-scale toolchains), Floria Toolkit compiles down to a compact, standalone native shared object (`libft.so` / `libft.dll`) using modern Free Pascal. It starts up in microseconds and maintains a near-zero idle CPU and memory footprint.

### 1.5 Subpixel Vector Fidelity & Clean Separation
Rather than relying on lowest-common-denominator OS 2D drawing primitives, all curves, rounded corners, text glyphs, and elevation shadows are rendered with subpixel-accurate Anti-Grain Geometry (`AGG`). Widget mechanics (layout, focus traversal, event routing) are strictly decoupled from visual styling (CSS stylesheet engine) and windowing backends.

---

## 2. Native Windowing & Compositor Cleanliness

### The Problem: Double Shadows and Clipped Corners
Top-level popup menus (`TFtPopupMenu`), dropdown menus, and hint/tooltip windows (`TFtHintWindow`) are native operating system windows (e.g., setting `_NET_WM_WINDOW_TYPE_POPUP_MENU` and `_NET_WM_WINDOW_TYPE_TOOLTIP` in X11/XCB). 

When a toolkit renders internal software drop shadows (`Canvas.DrawShadow`) or software rounded corners (`Canvas.DrawRoundedRect`) inside these window buffers:
1. **Double Shadows**: Modern window managers and compositors (Picom, KWin, Mutter, Windows DWM, macOS WindowServer) automatically generate elevation shadows for windows based on their EWMH type. Drawing a software shadow inside the buffer creates a dark, muddy "double shadow" effect.
2. **Corner Clipping & Visual Artifacts**: Drawing a rounded rectangle inside a rectangular window buffer leaves the four outer corners visible (often as black or background-colored triangles) unless complex 32-bit ARGB shape masks are configured.
3. **Fragile User Hacks**: Users are forced to write fragile compositor configuration rules (e.g. `shadow-exclude = [ "_NET_WM_WINDOW_TYPE_TOOLTIP" ]` or custom `corner-radius-rules` in `picom.conf`).

### The Invariant: Flat Rectangular Plates for Native Popups
All native top-level popup surfaces (`TFtPopupMenu`, `TFtHintWindow`, `ftwtTooltip`, `ftwtPopupMenu`, `ftwtDropdownMenu`) **must render as clean flat rectangular plates**:
- **Zero Software Radius**: Pass `CustomRadius := 0.0`.
- **Zero Software Shadow**: Omit calls to `Canvas.DrawShadow`.
- **Clean 1px Border Outline**: Draw a flat filled rectangle with a 1px border outline (`Canvas.DrawRect` + `Canvas.DrawRoundedRectOutline(X, Y, W, H, 0.0, 1.0, ...)`).
- **Let the Compositor Work**: Allow the user's window manager and compositor to natively handle window-level corner radius, elevation drop shadows, and blur behind regions according to their system preferences.

---

## 3. Window Abstraction Layer (`TFtWindow`)

### Decoupling Widgets from Platform Backends
Initially, widgets and popup menus interacted directly with `Ft.Backend.X11` and `TFtX11Window`. To ensure straightforward adoption of new backends (WinAPI for Windows, Cocoa for macOS, and Wayland) without refactoring application or widget code, Floria Toolkit introduces the [`TFtWindow`](file:///home/afumi/Documents/projects/floria-toolkit/src/main/pascal/ft.window.pas) abstraction layer:
- **Encapsulated Surface Management**: `TFtWindow` holds the double-buffered software surface (`FPixelBuffer`) and the AggPas drawing interface (`FCanvas: TFtCanvasAgg`).
- **Standardized Focus & Popup Grab**: Focus traversal (`FocusNext`), focused widget notification, and grabbed popup dismissal logic reside in `TFtWindow`, independent of platform events.
- **Factory Registration Pattern**: Native backends register their implementation class using `FtRegisterWindowClass()`. Calling `FtCreateWindow()` instantiates the registered platform backend transparently.
- **Platform Hook Methods**: Backends implement clean virtual methods (`Show()`, `Hide()`, `Repaint()`, `Resize()`, `SetPosition()`, `ClientToScreen()`, `ClaimClipboard()`, etc.).

---

## 4. Graphics Engine: AggPas as the Reference Standard

### Subpixel Vector Accuracy & Drop Shadows
Floria Toolkit employs Anti-Grain Geometry (`AGG` / `AggPas`) via `florialib` for all vector rendering:
- **Subpixel Antialiasing**: Evaluates fractional coverage values for every pixel along vector boundaries, eliminating jagged stair-stepping.
- **2D Gaussian Drop Shadows**: Employs dual-pass separable Gaussian box blurs (`Floria.Blur`) to produce elevation drop shadows for in-window cards, buttons, and switches.
- **Zero-Driver Reliability**: As hardware-accelerated GPU backends (OpenGL, Vulkan) are introduced via `TFtCanvas`, AggPas remains the toolkit's primary zero-dependency **Software Reference and Fallback Engine**. This ensures flawless rendering in headless CI runners, containerized environments, remote X11/VNC sessions, and virtual machines without requiring 3D GPU drivers.

---

## 5. CSS Engine, Specificity & Semantic Theming

### Pure CSS Architecture (`Floria.CSS`)
Stylesheets are written in standard `.css` syntax and parsed directly into abstract syntax trees. Key rules govern theme resolution:
1. **Border Inheritance Guards**:
   In `ApplyBaselineDefaults`, never assign a baseline border color unless the widget style already has an active border width (`AStyle.HasBorderWidth and (AStyle.BorderWidth > 0.0)`). Non-bordered elements (like labels or flat containers) must not be forced to render outlines.
2. **Pure Token Blocks for `.dark`**:
   When declaring dark mode rules via `:root.dark, .dark`, restrict the block strictly to custom property definitions (`--token: #...;`). Never attach general element rules (like `background-color: var(--window-bg)`) inside `.dark`, as class specificity `(0, 1, 0)` will override base element selectors (`button`, `container`, etc.).
3. **Semantic Tokens Over Arithmetic Dimming**:
   Never apply fixed arithmetic multipliers (e.g., `Color * 0.6`) to darken or lighten text for disabled states. On light themes, multiplying dark text makes it darker and blacker instead of muted. Always query semantic tokens (`--text-disabled`, `--disabled-text-color`) and resolve `:disabled` pseudo-class styles.

---

## 6. Rendering Pipeline & Partial Invalidation

### Zero CPU Waste at Idle
Floria Toolkit is engineered to achieve 60 FPS fluidity when animated while dropping to 0% CPU consumption when idle:
- **Partial Invalidation**: Indeterminate progress bars, glowing buttons, and hover transitions only invalidate the bounding box of the active widget (`InvalidateRect`). The event loop blits only the damaged dirty region to the display.
- **Paced Event Loop**: The backend loop measures sub-millisecond delta times, sleeping for 16ms between frames while transitions are active, and falling back to kernel event blocking (`poll` / `epoll`) when no animations are running.
- **Hierarchical Scissor Clipping**: Nested containers maintain a scissor rectangle stack in `TFtCanvasAgg`. Child widgets outside container viewports are clipped mathematically with zero overdraw.

### Virtualized Data Grids & The "Cell Stamp" Flyweight Pattern
When rendering massive datasets (such as hundreds of thousands or millions of tabular rows):
- **0% Idle CPU Waste**: The grid does not poll or run continuous background render loops. It updates visible bounds only when scroll offsets change, window resizes occur, or explicit data mutations are signaled.
- **Visible Bounds Virtualization**: The grid never instantiates, measures, or tracks offscreen data cells. It strictly projects the row and column slice intersecting the current viewport based on scroll position (`ScrollX`, `ScrollY`).
- **Reusable "Cell Stamp" Flyweight Layout**: Rather than instantiating thousands of heavy `FtWidget` instances for every cell in a dataset, the grid utilizes a single reusable "Cell Stamp" layout and paints the data dynamically as the user scrolls. This maintains flat $O(1)$ memory overhead, eliminates allocation churn, and guarantees microsecond responsiveness even with 1,000,000+ data rows.

---

## 7. Universal C ABI & Language Bindings

### Clean FFI Interoperability
All toolkit capabilities are exposed across a standard C dynamic library ABI (`libft.so` / `libft.dll` / `include/ft.h`):
- **Opaque Pointers**: Widgets and menu items are passed as opaque handles (`FtWidget`, `FtMenuItem`), completely shielding foreign runtimes from internal Free Pascal object layouts and VMT tables.
- **C-Compatible Types**: All function signatures use fixed-width integer and floating-point primitives (`int32_t`, `double`, `const char*`).

### Python `ctypes` Binding Invariants
When authoring Python bindings:
- **Explicit UTF-8 Conversions**: Non-ASCII characters must never be placed inside raw byte literals (e.g. `b"..."` causes `SyntaxError`). Use a dedicated `to_bytes()` helper function.
- **Callback Retention**: Always store `CFUNCTYPE` instances in a persistent Python reference structure (e.g. `g_callbacks.append(cb)`). Otherwise, Python's garbage collector frees the closure while the C event loop holds the function pointer, leading to segmentation faults.
- **Explicit Float Casting**: Pass floating-point values explicitly as `ctypes.c_double(val)` to preserve 64-bit IEEE precision across the ABI.

---

## 8. Modularity & Linker Invariants

### Smart-Linking and Image Codecs
- **Explicit Codec Unit Import**: When utilizing `Floria.Image.Core` or image widgets (`TFtImage`, `ft_image_*`), consumer units (`ft.pas`, `ft.widget.images.pas`, `TestRunner.pas`) must explicitly list the desired codec units (`Floria.Image.PNG`, `Floria.Image.BMP`, `Floria.Image.JPEG`) in their `uses` clause.
- **Preventing Codec Pruning**: Pascal image codecs register their handlers dynamically in their unit `initialization` blocks. If the consumer does not explicitly import the codec units, Free Pascal's smart-linker strips them as dead code, triggering runtime `"Unsupported or unrecognized image format"` errors.
- **PasBuild Descriptor Invariant**: The single, authoritative configuration file for PasBuild is `project.xml`. No JSON or YAML config exists.

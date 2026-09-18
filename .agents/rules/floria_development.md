# Floria Toolkit (Ft) Development Guidelines

When developing or creating examples, widgets, and language bindings for Floria Toolkit (`libft.so`):

## 1. Python `ctypes` Bindings & Encoding Invariants
- **UTF-8 String Passing**: Never use non-ASCII characters inside Python byte literals (e.g., `b"..."` will raise `SyntaxError`). Always convert strings to UTF-8 bytes via an explicit helper:
  ```python
  def to_bytes(s):
      return s.encode("utf-8") if isinstance(s, str) else s
  ```
- **Avoid Helper Name Shadowing**: Avoid using single-character helper names like `b()` that collide with tuple unpacking variables such as `r, g, b` (color channels), which triggers `UnboundLocalError`.
- **Callback Retention**: Always store `CFUNCTYPE` instances in a persistent global list (e.g., `g_callbacks.append(cb)`) to prevent Python's garbage collector from freeing them while the C event loop is running.
- **Double Argument Precision**: Pass floating point values explicitly using `ctypes.c_double(val)` for progress bar values, ranges, and corner radii.

## 2. Rendering & Animation Performance
- **Partial Invalidation**: Rely on Floria Toolkit's dirty rectangle tracking and partial blitting engine. When animating indeterminate progress bars, spinners, or pulsing indicators, only invalidate the bounding box of the active widget rather than repainting the parent window or full screen backbuffer.

## 3. CSS Engine, `:root` Variables & Baseline Inheritance
- **Border Inheritance Guard**: In `ApplyBaselineDefaults`, never assign a baseline border color unless the widget style already has an active border width (`AStyle.HasBorderWidth and (AStyle.BorderWidth > 0.0)`). Non-bordered elements (like labels or plain containers) must not be given `HasBorderColor := True`.
- **Widget Outline Guards**: Widgets that support optional CSS borders (such as `TFtText` / `TFtLabel`) must strictly require `st.HasBorderWidth and (st.BorderWidth > 0.0) and st.HasBorderColor` before drawing an outline. Never default border width to `1.0` merely because a border color exists.
- **Pure Token Blocks for `.dark`**: When providing dark mode overrides via `:root.dark, .dark`, restrict the block strictly to custom property definitions (`--...`). Never attach general element rules (like `background-color: var(--window-bg)`) inside `.dark`, as class specificity `(0, 1, 0)` will override element selectors (`button`, `container`, etc.).

## 4. Widget State & Semantic Theming
- **No Arithmetic Dimming for Disabled Text**: Never apply fixed multipliers (e.g., `txt * 0.6`) to darken or lighten text for disabled states. On light themes, multiplying dark text makes it darker/blacker instead of muted. Always query semantic tokens (`--text-disabled`, `--disabled-text-color`) and resolve `:disabled` pseudo-class styles.
- **Dependency Cleanliness**: When an internal subsystem (like `Floria.CSS` from `florialib`) fully supersedes a third-party package (like `3rdparty/fcl-css`), immediately purge the obsolete package files, unused directories, and documentation references to maintain a zero-bloat repository.

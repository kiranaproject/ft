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

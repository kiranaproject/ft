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

## 5. Build, Dependency & Packaging Workflows
- **Installing FloriaLib Modifications**: `florialib` is consumed by `floria-toolkit` via PasBuild package management (`project.xml`). Whenever modifying, updating, or fixing code inside the `florialib` workspace (`/home/afumi/Documents/projects/kirana/florialib`), **always immediately run `pasbuild install` inside the `florialib` directory** before compiling or testing downstream projects (`floria-toolkit`) to ensure the latest artifacts are published to the local PasBuild cache.
- **PasBuild Descriptor Invariant (`project.xml`)**: In PasBuild, the project configuration and dependency descriptor is strictly `project.xml`. There is no `pasbuild.json` or YAML file. Never search for, reference, or attempt to generate `pasbuild.json`. All project metadata, build settings, source paths, and package dependencies must be inspected and edited in `project.xml`.

## 6. Image Codecs & Modular Unit Import Invariants
- **Explicit Image Codec Import**: When using `Floria.Image.Core` or image-related widgets (`TFtImage`, `ft_image_*`, `ft_bitmap_*`), the main library (`ft.pas`), widget unit (`ft.widget.images.pas`), and test runner (`TestRunner.pas`) must explicitly include the desired codec units (`Floria.Image.PNG`, `Floria.Image.BMP`, `Floria.Image.JPEG`) in their `uses` clause.
- **Initialization Retention**: Pascal image codecs register their handlers dynamically in their unit `initialization` sections. Because `Floria.Image.Core` does not import codecs directly (preventing circular initialization wipes), omitting codec units from consumer `uses` clauses results in smart-linking dropping them, raising `"Unsupported or unrecognized image format"` at runtime.

## 7. Native Popup Surfaces (Tooltips, Menus, Hints) & Compositor Cleanliness
- **No Software Drop Shadows or Rounded Corners for Native Popups**:
  Any top-level popup, menu, hint, or tooltip window (`TFtPopupMenu`, `TFtHintWindow`, `ftwtPopupMenu`, `ftwtTooltip`, `ftwtDropdownMenu`) must render as a flat rectangular plate with a 1px border outline (`Canvas.DrawRect` + `Canvas.DrawRoundedRectOutline(..., 0.0, 1.0, ...)`), strictly passing `CustomRadius := 0.0` and never drawing a software drop shadow (`Canvas.DrawShadow`).
- **Compositor Responsibility**:
  Modern window managers and compositors (Picom, KWin, Mutter, macOS WindowServer, Windows DWM) already manage window drop shadows and window corner radii natively based on EWMH window types (`_NET_WM_WINDOW_TYPE_POPUP_MENU`, `_NET_WM_WINDOW_TYPE_TOOLTIP`). Rendering software shadows or rounded corners inside the window buffer creates unsightly double shadows, dark corner artifacts, and requires users to write complex compositor hacks.

## 8. Desktop-First Priority & Rock-Solid ABI Stability (Win32 Standard vs. GTK Churn)
- **Desktop-First Ergonomics**:
  Prioritize dense desktop layouts, precise mouse interactions, keyboard navigation, mnemonic accelerators, menu bars, persistent scrollbars, and multi-window workflows. Never compromise desktop usability for tablet/mobile hybrid conventions (e.g., avoid oversized touch padding, disappearing scrollbars, or forced mobile modals).
- **First-Class X11 Commitment**:
  Treat X11/XCB as a premier, first-class citizen with microsecond event dispatch and full EWMH support, not a legacy target slated for deprecation.
- **The Windows API Standard of Stability**:
  Strictly avoid the churn, breakage, and ecosystem disruptions seen across GTK2, GTK3, and GTK4. Maintain long-term binary stability modeled after the Windows API (Win32):
  - Never break or mutate existing exported C function signatures in `include/ft.h` and `ft.pas`.
  - Evolution must be strictly additive (new APIs/functions added, never altered or removed).
  - All public entities must remain opaque handles (`FtWidget`, `FtMenuItem`), safeguarding foreign language bindings and downstream binary compatibility across releases.

## 9. Multilingual Typography, Script Endonyms & Geopolitical Neutrality
- **Native Script Endonyms for Language Samples**:
  - In multilingual demos, samples, language selectors, and documentation, always identify languages using their authentic native script endonyms alongside their English name:
    - `Japanese (日本語)`
    - `Chinese Simp (简体中文)` / `Chinese Trad (繁體中文)`
    - `Korean (한국어)`
    - `Thai (ภาษาไทย)`
    - `Hindi (हिन्दी)`
    - `Arabic (العربية)`
    - `Hebrew (עברית)`
    - `Russian (Русский)`
    - `Greek (Ελληνικά)`
  - Never substitute country names (e.g., "Israel", "Thailand"), geographical regions (e.g., "Middle East"), or script names (e.g., "Devanagari") in place of the language's own endonym.
- **Geopolitical Neutrality & Sensitivity**:
  - Strictly avoid politically sensitive or controversial state/country names (specifically "Israel", which carries strong political sensitivities and potential controversy in Indonesian and Malaysian developer ecosystems where the author resides).
  - Always maintain strictly linguistic and cultural nomenclature (e.g., `Hebrew (עברית)` / `Ivrit` for the Hebrew language, `Arabic (العربية)` for Arabic, `Thai (ภาษาไทย)` for Thai).
- **IME Awareness & Transliterated User Input**:
  - When the user types an endonym in Latin transliteration (e.g., "Nihongo", "Phasa Thai", "Ivrit"), recognize that the user may lack an input method editor (IME) on their machine to type non-Latin scripts directly.
  - Always translate and expand the transliterated name into its authentic native script (e.g., "Nihongo" -> `日本語`, "Phasa Thai" -> `ภาษาไทย`, "Ivrit" -> `עברית`, "Al-Arabiyyah" -> `العربية`, "Hindi" -> `हिन्दी`) when generating code, UI text, or documentation.
- **Label Widget Font Inheritance**:
  - When a label or header widget includes non-Latin native script characters (CJK, Thai, Devanagari, Arabic, Hebrew), always set the corresponding font family on the label widget itself (`ft_widget_set_font(lbl, font_name)`).
  - Standard system fonts (like `Ubuntu` or `DejaVu Sans`) often lack glyphs for CJK or complex scripts; assigning the targeted Noto font (`Noto Sans CJK`, `Noto Sans Thai`, `Noto Sans Devanagari`, `Noto Sans Arabic`, `Noto Sans Hebrew`) ensures crisp rendering of both the English label and the native script glyphs without blank or missing character artifacts.

## 10. Tool Call Schema Invariants
- **`find_by_name` Mandatory `Pattern`**: Always supply `Pattern: "*"` when calling `find_by_name` with `Extensions` or `Type`. The tool schema strictly enforces `Pattern` as a required parameter (`required: ["SearchDirectory", "Pattern", "toolSummary", "toolAction"]`), regardless of documentation text.




# Widgets Architecture & Guide

Floria Toolkit provides a rich suite of native desktop widgets designed with object-oriented Pascal principles, subpixel Anti-Grain Geometry (`AGG`) vector graphics, and standard desktop UX conventions (GTK, Qt, Lazarus LCL).

---

## Table of Contents
1. [Widget Hierarchy](#widget-hierarchy)
2. [Base Widget (`TFtWidget`)](#base-widget-tftwidget)
3. [Top-Level Window (`TFtX11Window`)](#top-level-window-tftx11window)
4. [Push & Toggle Buttons (`TFtButton`)](#push--toggle-buttons-tftbutton)
5. [Toggle Switch (`TFtSwitch`)](#toggle-switch-tftswitch)
6. [Text / Label (`TFtText`)](#text--label-tfttext)
7. [Container Box & Viewport (`TFtContainer`)](#container-box--viewport-tftcontainer)
8. [Single-Line Text Entry (`TFtEntry`)](#single-line-text-entry-tftentry)
9. [Multi-Line Text Area (`TFtTextArea`)](#multi-line-text-area-tfttextarea)
10. [Vector ScrollBar (`TFtScrollBar`)](#vector-scrollbar-tftscrollbar)
11. [Main Menu & Popup Context Menus](#main-menu--popup-context-menus)

---

## Widget Hierarchy

```
TFtWidget (Ft.Widget)
├── TFtX11Window (Ft.Backend.X11)
├── TFtButton (Ft.Widget.Buttons)
├── TFtSwitch (Ft.Widget.Switches)
├── TFtText (Ft.Widget.Texts)
├── TFtScrollBar (Ft.Widget.ScrollBars)
├── TFtContainer (Ft.Widget.Containers)
│   ├── TFtEntry (Ft.Widget.Entries)
│   └── TFtTextArea (Ft.Widget.TextAreas)
├── TFtMainMenu (Ft.Widget.Menus)
└── TFtPopupMenu (Ft.Widget.Menus)
```

---

## Base Widget (`TFtWidget`)

All visual elements inherit from `TFtWidget`:
- **Geometry**: `X`, `Y`, `Width`, `Height`, `Visible`, `Enabled`.
- **Tree Hierarchy**: Parent/child relationships with automatic coordinate propagation.
- **Event Dispatching**: `MouseDown`, `MouseUp`, `MouseMove`, `MouseEnter`, `MouseLeave`, `KeyDown`, `KeyUp`.
- **CSS Styling**: `StyleClass`, `StyleId`, `InlineStyle`, and cached style resolution via `GetResolvedStyle()`.
- **Focus Ring**: Manages keyboard focus state and renders theme-aware focus outlines.
- **Context Menu**: Attachable `TFtPopupMenu` triggered on right-click events.

---

## Top-Level Window (`TFtX11Window`)

Native X11 window wrapper providing:
- Double-buffered AGG software rendering pipe.
- Modern EWMH title, icon, and window type management (`_NET_WM_WINDOW_TYPE_NORMAL`, `DIALOG`, `POPUP_MENU`, etc.).
- Borderless and taskbar-skipping options.
- 60 FPS event and animation dispatch loop.

---

## Push & Toggle Buttons (`TFtButton`)

- **Interactive States**: `Normal`, `Hovered`, `Pressed`, and `Toggled`.
- **Modes**: Standard push-button or latching toggle button (`ft_button_set_toggle`).
- **Vector Styling**: Customizable corner radii, 2D drop shadows, and theme accent colors.
- **Transitions**: Smooth color and geometry interpolation between states via CSS transitions.

---

## Toggle Switch (`TFtSwitch`)

A modern toggle switch inspired by modern mobile and desktop operating systems:
- Circular thumb slider with elevation drop shadow.
- Pill-shaped track with accent highlight when active.
- Keyboard support (`Left`/`Right` arrow keys to switch, `Space`/`Enter` to toggle).
- Integrated side caption label.

---

## Text / Label (`TFtText`)

- **Dual Modes**:
  - **Static Label**: Lightweight immutable text display (skips keyboard focus).
  - **Selectable Text**: Full desktop text selection support (mouse drag, double-click word selection, `Ctrl+A`, `Ctrl+C` clipboard copy, I-beam cursor).
- **Internationalization**: Full UTF-8 Unicode rendering across complex writing systems (Latin, Cyrillic, Greek, CJK, Thai, Devanagari, Arabic, Hebrew).

---

## Container Box & Viewport (`TFtContainer`)
*Equivalent to `GtkScrolledWindow` in GTK, `QScrollArea` in Qt, and `TScrollBox` in Lazarus LCL.*

- **Scrolled Viewport**: Hosts child widgets placed with relative coordinates.
- **Auto ScrollBars**: Integrated vertical and horizontal `TFtScrollBar` instances with dynamic policy (`None`, `HorizontalOnly`, `VerticalOnly`, `AutoBoth`).
- **AGG Scissor Clipping**: Stacked scissor clipping rects ensure children never bleed outside the container plate.
- **Mouse Wheel**: Smooth wheel scrolling with automatic child event bubbling.

---

## Single-Line Text Entry (`TFtEntry`)
*Equivalent to `GtkEntry` in GTK and `QLineEdit` in Qt.*

Inherits from `TFtContainer`:
- Blinking insertion cursor (caret) with smooth timing.
- Text selection (mouse drag, shift+arrows, double-click, `Ctrl+A`).
- Standard clipboard shortcuts (`Ctrl+X`, `Ctrl+C`, `Ctrl+V`).
- Horizontal text scrolling when content exceeds entry width.
- Placeholder text support.
- Enter/Return submit callback and live text modification notifications.

---

## Multi-Line Text Area (`TFtTextArea`)
*Equivalent to `GtkTextView` in GTK and `QTextEdit` in Qt.*

Inherits from `TFtContainer`:
- Multi-line text layout and editing with arbitrary dimensions.
- Line navigation via `Up`/`Down`/`Home`/`End`/`PageUp`/`PageDown`.
- Dynamic vertical and horizontal scrolling with automatic scrollbars.
- Built-in right-click context menu (Select All, Cut, Copy, Paste, Delete).

---

## Vector ScrollBar (`TFtScrollBar`)

- Standalone draggable scrollbar widget supporting Horizontal and Vertical orientations.
- Proportional thumb sizing calculated dynamically from page size and total content range.
- Track clicking for page jumping and smooth mouse drag tracking.
- Styled according to active theme palette and CSS transitions.

---

## Main Menu & Popup Context Menus

- **Window Main Menu (`TFtMainMenu`)**: Horizontal menu bar attached to the top of a window. Supports click-to-open dropdowns, sweep tracking across open menus, and keyboard navigation.
- **Popup & Context Menu (`TFtPopupMenu`)**: Independent borderless top-level windows (`_NET_WM_WINDOW_TYPE_POPUP_MENU`) that can extend outside the parent window boundary unconstrained.
- **Cascading Submenus**: Infinite nesting depth with automatic screen edge clamping (`▶`).
- **Toggle Items**: Checkable menu items with crisp vector checkmarks (`✓`).
- **Context Menus**: Right-click context menus attachable to any widget or top-level window.

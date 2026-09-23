# Widgets Architecture & Guide

Floria Toolkit provides a rich suite of native desktop widgets designed with object-oriented Pascal principles, subpixel Anti-Grain Geometry (`AGG`) vector graphics, and standard desktop UX conventions (GTK, Qt, Lazarus LCL).

---

## Table of Contents
1. [Widget Hierarchy](#widget-hierarchy)
2. [Base Widget (`TFtWidget`)](#base-widget-tftwidget)
3. [Top-Level Window (`TFtX11Window`)](#top-level-window-tftx11window)
4. [Push & Toggle Buttons (`TFtButton`)](#push--toggle-buttons-tftbutton)
5. [Window Caption Button (`TFtWindowButton`)](#window-caption-button-tftwindowbutton)
6. [Toggle Switch (`TFtSwitch`)](#toggle-switch-tftswitch)
7. [CheckBox (`TFtCheckBox`)](#checkbox-tftcheckbox)
8. [RadioButton (`TFtRadioButton`)](#radiobutton-tftradiobutton)
9. [ComboBox Dropdown (`TFtComboBox`)](#combobox-dropdown-tftcombobox)
10. [Slider (`TFtSlider`)](#slider-tftslider)
11. [ProgressBar (`TFtProgressBar`)](#progressbar-tftprogressbar)
12. [Text / Label (`TFtText`)](#text--label-tfttext)
13. [Container Box & Viewport (`TFtContainer`)](#container-box--viewport-tftcontainer)
14. [Single-Line Text Entry (`TFtEntry`)](#single-line-text-entry-tftentry)
15. [Multi-Line Text Area (`TFtTextArea`)](#multi-line-text-area-tfttextarea)
16. [Notebook & Tabs (`TFtNotebook`, `TFtTabs`)](#notebook--tabs-tftnotebook-tfttabs)
17. [Dual-Pane Splitter (`TFtSplitter`)](#dual-pane-splitter-tftsplitter)
18. [TreeView (`TFtTreeView`)](#treeview-tfttreeview)
19. [Table & DataGrid (`TFtTable`, `TFtGrid`)](#table--datagrid-tfttable-tftgrid)
20. [Image & SVG Viewer (`TFtImage`)](#image--svg-viewer-tftimage)
21. [Vector ScrollBar (`TFtScrollBar`)](#vector-scrollbar-tftscrollbar)
22. [Main Menu & Popup Context Menus](#main-menu--popup-context-menus)

---

## Widget Hierarchy

```
TFtWidget (Ft.Widget)
├── TFtX11Window (Ft.Backend.X11)
├── TFtButton (Ft.Widget.Buttons)
│   └── TFtWindowButton (Ft.Widget.Buttons)
├── TFtSwitch (Ft.Widget.Switches)
├── TFtCheckBox (Ft.Widget.Selectors)
├── TFtRadioButton (Ft.Widget.Selectors)
├── TFtComboBox (Ft.Widget.Selectors)
├── TFtSlider (Ft.Widget.Meters)
├── TFtProgressBar (Ft.Widget.Meters)
├── TFtText / TFtLabel (Ft.Widget.Texts)
├── TFtScrollBar (Ft.Widget.ScrollBars)
├── TFtContainer (Ft.Widget.Containers)
│   ├── TFtEntry (Ft.Widget.Entries)
│   ├── TFtTextArea (Ft.Widget.TextAreas)
│   ├── TFtNotebook (Ft.Widget.Tabs)
│   ├── TFtSplitter (Ft.Widget.Splitters)
│   └── TFtTable / TFtGrid (Ft.Widget.Tables)
├── TFtTabs (Ft.Widget.Tabs)
├── TFtTreeView (Ft.Widget.TreeViews)
├── TFtImage (Ft.Widget.Images)
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

## Window Caption Button (`TFtWindowButton`)

Specialized titlebar and tab caption button derived from `TFtButton`:
- **Kinds**: `wbkClose` (✕), `wbkMinimize` (─), `wbkMaximize` (□), `wbkRestore` (❐), `wbkCustom`.
- **Operating System Styles**: `wbsMac` (traffic lights), `wbsGtk` (subtle flat circles), `wbsWindows` (clean rectangular symbols).
- **Glow & Halo Transitions**: 60 FPS smooth radial halo on hover with dark mode adaptation.
- **Auto Hints**: Displays default localized hints on hover with custom developer override capability.

---

## Toggle Switch (`TFtSwitch`)

A modern toggle switch inspired by modern mobile and desktop operating systems:
- Circular thumb slider with elevation drop shadow.
- Pill-shaped track with accent highlight when active.
- Keyboard support (`Left`/`Right` arrow keys to switch, `Space`/`Enter` to toggle).
- Integrated side caption label.

---

## CheckBox (`TFtCheckBox`)
*Equivalent to `GtkCheckButton` in GTK, `QCheckBox` in Qt, and `TCheckBox` in Lazarus LCL.*

- **Visuals**: Crisp vector square plate with customizable corner radius, theme-reactive borders, and anti-aliased vector checkmark (`✓`).
- **Interaction**: Mouse clicks or keyboard activation (`Space` / `Return`).
- **Events**: `OnToggle` callback receiving checked state (`1` / `0`).
- **CSS Selectors**: Styled via `checkbox` element selector with `:hover`, `:active`, `:checked`, `:focus`, and `:disabled` pseudo-classes.

---

## RadioButton (`TFtRadioButton`)
*Equivalent to `GtkRadioButton` in GTK, `QRadioButton` in Qt, and `TRadioButton` in Lazarus LCL.*

- **Mutual Exclusivity**: Automatic mutual exclusivity among sibling radio buttons in the same parent container, with optional custom `GroupId` grouping.
- **Visuals**: Subpixel vector circular plate with crisp centered bullet when selected.
- **Interaction**: Keyboard navigation (`Space`/`Enter` to select, `Up`/`Down` arrows to navigate options).
- **CSS Selectors**: Styled via `radio` element selector with pseudo-classes.

---

## ComboBox Dropdown (`TFtComboBox`)
*Equivalent to `GtkComboBoxText` in GTK, `QComboBox` in Qt, and `TComboBox` in Lazarus LCL.*

- **Dropdown Popup**: Native borderless X11 popup window displaying selectable items with elevation drop shadow.
- **Modes**: Read-only dropdown selection plate with integrated chevron dropdown indicator (`▼`), plus optional editable text entry mode.
- **Keyboard Navigation**: `Space` or `Return` opens dropdown; `Up`/`Down` arrow keys step through options or navigate popup list.
- **Events**: `OnChange` callback passing selected index and text string.
- **CSS Selectors**: Styled via `combobox` element selector with full pseudo-class cascade.

---

## Slider (`TFtSlider`)
*Equivalent to `GtkScale` in GTK, `QSlider` in Qt, and `TTrackBar` in Lazarus LCL.*

- **Orientations**: Supports both Horizontal (`FT_SLIDER_HORIZONTAL`) and Vertical (`FT_SLIDER_VERTICAL`).
- **Visuals**: Rounded track plate with filled active track segment and circular thumb with subtle elevation shadow.
- **Range & Stepping**: Configurable floating-point `Min`, `Max`, and optional discrete `Step` increments.
- **Mouse & Keyboard Tracking**: Continuous smooth mouse dragging, track-jump clicks, and keyboard arrow adjustments (`Left`/`Down` to decrement, `Right`/`Up` to increment).
- **Events**: `OnChange` callback emitting updated floating-point values in real-time.
- **CSS Selectors**: Styled via `slider` element selector.

---

## ProgressBar (`TFtProgressBar`)
*Equivalent to `GtkProgressBar` in GTK, `QProgressBar` in Qt, and `TProgressBar` in Lazarus LCL.*

- **Orientations**: Supports Horizontal (`FT_PROGRESS_HORIZONTAL`) and Vertical (`FT_PROGRESS_VERTICAL`).
- **Dual Modes**:
  - **Determinate**: Displays progress ratio between `Min` and `Max` (e.g., `0.0`..`100.0`), with optional centered percentage text readout (e.g., `45%`, `100%`) with automatic theme contrast.
  - **Indeterminate**: Animated 60 FPS sweeping pulse oscillating smoothly back and forth across the track using smooth cosine easing.
- **CSS Selectors**: Styled via `progressbar` element selector.

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

## Notebook & Tabs (`TFtNotebook`, `TFtTabs`)
*Equivalent to `GtkNotebook` in GTK, `QTabWidget` in Qt, and `TPageControl` in Lazarus LCL.*

- **Multi-Page Management**: Container hosting multiple pages with tab bar header.
- **Tab Customization**: Close buttons, icons, custom indicators, and glowing active selection halos.
- **Dynamic Insertion & Removal**: Add, remove, and switch pages at runtime.

---

## Dual-Pane Splitter (`TFtSplitter`)
*Equivalent to `GtkPaned` in GTK, `QSplitter` in Qt, and `TSplitter` in Lazarus LCL.*

- **Orientations**: Horizontal (left/right panes) and Vertical (top/bottom panes).
- **Live Dragging**: Smooth interactive mouse dragging with minimum pane size constraints.
- **Visuals**: Center grip handle with theme-aware hover transitions.

---

## TreeView (`TFtTreeView`)
*Equivalent to `GtkTreeView` in GTK, `QTreeView` in Qt, and `TTreeView` in Lazarus LCL.*

- **Hierarchical Nodes**: Arbitrary nesting depth with parent-child relationships.
- **Vector Carets**: Anti-aliased expand and collapse arrow glyphs (`▶`, `▼`).
- **Selection Tracking**: Single-item click selection with theme accent highlights.

---

## Table & DataGrid (`TFtTable`, `TFtGrid`)
*Equivalent to `GtkTreeView` (list mode) in GTK, `QTableView` in Qt, and `TStringGrid` in Lazarus LCL.*

- **Multi-Column Grid**: Configurable column headers, widths, and text alignments (`taLeft`, `taCenter`, `taRight`).
- **Styling**: Zebra-striped rows, hover rows, and active cell/row selection highlighting.
- **Scrolling**: Built-in automatic horizontal and vertical viewport scrollbars.

---

## Image & SVG Viewer (`TFtImage`)
*Equivalent to `GtkImage` in GTK and `QLabel` (pixmap mode) in Qt.*

- **Format Decoding**: Decodes raster bitmaps (BMP, PNG, JPEG) and vector SVG documents.
- **Scaling Modes**: `fit`, `fill`, `stretch`, `center`, and `none`.
- **HiDPI Scaling**: Vector SVG scales losslessly at any monitor DPI or widget dimension.

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

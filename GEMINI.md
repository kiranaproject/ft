# floria-toolkit — Project Rules

## Build & Test Workflow

1. **Compile shared library (`libft.so`)**: `pasbuild compile` or `./build.sh`
2. **Run tests**: `pasbuild test` or `./build.sh test`
3. **Build C examples**: `./build_examples.sh` or `./build.sh examples`
4. **Compile with Blaise**: `./build.sh blaise`

## Dependencies

- **`aggpas:2.4.0-SNAPSHOT`**: Independent 2D vector graphics rendering engine (decoupled from fpGUI).
- **`florialib:0.0.1-SNAPSHOT`**: Floria core library (CSS, SVG, HTML, Image, Canvas, XCB, HarfBuzz, BiDi).
- **`fpgui-framework` is not used**. Do not add `fpgui-framework` as a dependency.

## Pasbuild Configuration File

- **`project.xml`** is the only project descriptor configuration file used by Pasbuild.
- **`pasbuild.json` does not exist**. Never look for, reference, create, or expect `pasbuild.json`.

## Tool Call Schema Invariants

- **`find_by_name` Requires `Pattern`**: In `find_by_name`, the `Pattern` property is strictly required by the tool validator schema (`required: ["SearchDirectory", "Pattern", "toolSummary", "toolAction"]`). Never omit `Pattern`, even when specifying `Extensions` or `Type`. When searching by extension or listing directory contents, always explicitly set `Pattern: "*"`.
- **Required Metadata**: Every tool call must include both `toolSummary` (2–5 word noun phrase) and `toolAction` (2–5 word verb phrase).

## GUI Test Execution & Process Lifecycles

- **Guaranteed Termination for Subprocesses**: Never issue a bare `wait $PID` when running interactive GUI programs, X11 apps, or modal dialogs in background subshells. Always ensure guaranteed termination:
  1. Follow interactions/screenshots immediately with `kill -9 $PID 2>/dev/null || true` before issuing `wait $PID 2>/dev/null || true`.
  2. Or wrap commands in `timeout <N>s`.
- **Process Pattern Matching (`pkill -f`)**: Standard `pkill <name>` limits process name matching to 15 characters, causing hard failures on longer binary or script names. Always use `pkill -f <pattern>` when terminating test scripts or binaries by name.

## Pascal Widget Unit Naming Invariant

- **Pluralized Widget Filenames**: In `src/main/pascal/`, widget implementation units are strictly pluralized:
  `ft.widget.buttons.pas`, `ft.widget.containers.pas`, `ft.widget.entries.pas`, `ft.widget.meters.pas`, `ft.widget.pathbars.pas`, `ft.widget.selectors.pas`, `ft.widget.splitters.pas`, `ft.widget.switches.pas`, `ft.widget.tables.pas`, `ft.widget.tabs.pas`, `ft.widget.textareas.pas`, `ft.widget.texts.pas`, `ft.widget.treeviews.pas`, `ft.widget.urlentries.pas`.
  Never look for or target singular filenames like `ft.widget.treeview.pas` or `ft.widget.splitter.pas`.

## GUI Interaction Invariants

- **Button Click Lifecycle (Release-Within-Bounds)**:
  - All interactive buttons must trigger their primary action on **mouse button release within the control bounds**, never on mouse down.
  - Mouse down activates the pressed visual state.
  - Pointer motion leaving the control area during hold must visually un-press the control and cancel action execution on release.

## Container Styling & Border Invariants

- **Container Border Outline Mechanics**:
  - `TFtContainer` draws a uniform 4-sided rounded rectangle outline (`DrawRoundedRectOutline`) whenever `st.HasBorderColor` is active.
  - Because CSS property resolution falls back to `cpiBorderTopColor` and `cpiBorderTopWidth`, declaring directional borders such as `border-top: 1px solid ...` on a container triggers a full 4-sided outline box around the entire container perimeter.
  - To remove borders, explicitly declare `border: none;` in CSS. If a single-edge divider is required, use a discrete 1px height/width divider container rather than a directional CSS border on a content container.

## FTML Layout & Navigation Invariants

- **Responsive Width Tracking via Margins**:
  - Content cards and panels nested in resizable containers must specify symmetrical horizontal margins (e.g. `anchors.leftMargin: 32; anchors.rightMargin: 32;` with `padding: 0;`) rather than hardcoded widths, ensuring fluid adaptation to window resizing.
  - Interactive navigation pills inside fixed-width sidebars must use symmetrical horizontal margins (e.g. `anchors.leftMargin: 12; anchors.rightMargin: 12; width: 216;` inside a 240px sidebar) to avoid clipping rounded corners (`border-radius: 8px`).

- **Vertical Scrollable Containers & State Reset**:
  - Vertical scrolling on content decks and sidebars must be configured with `scrollBarMode: "vertical";` in FTML (`ftsbmVerticalOnly` in Pascal).
  - Multi-step wizards and deck containers must reset scroll offset to zero (`ResetPageScroll()`) upon step or page switching to prevent newly activated pages from appearing pre-scrolled.

## Linux Windowing & Display Server Policy

- **Strictly X11/XCB Only (No Wayland)**:
  - All Linux windowing, event handling, clipboard management, and compositor integration strictly target native **X11/XCB** (`libxcb`, EWMH, ICCCM).
  - **Never reference, propose, design for, or insert Wayland** into code, configuration, architectural documentation, roadmaps, or README files.
  - Engineering focus is dedicated to premier native X11 desktop support, with optional non-Linux platform abstractions (WinAPI for Windows, Cocoa for macOS).


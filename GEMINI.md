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


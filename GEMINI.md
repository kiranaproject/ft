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

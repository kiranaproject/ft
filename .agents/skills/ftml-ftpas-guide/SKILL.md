---
name: ftml-ftpas-guide
description: Comprehensive reference and runbook for PasBuild, Floria Toolkit (libft.so), ftpas (Object Pascal OOP binding), and FTML declarative markup language. Use when creating, modifying, building, or debugging Floria/Kirana desktop applications.
---

# Floria Ecosystem Developer Guide: PasBuild, Floria Toolkit, ftpas, and FTML

This skill documents the build processes, runtime architecture, Object Pascal OOP bindings (`ftpas`), and declarative markup (`FTML`) used across Floria and Kirana desktop applications.

---

## 1. PasBuild Workflow & Lifecycle

PasBuild is the native build system for Free Pascal projects in the Floria ecosystem.

### Configuration (`project.xml`)
- `project.xml` is the sole project descriptor. Never search for, create, or reference `pasbuild.json`.
- Standard project structure:
  ```
  project.xml
  src/main/pascal/     # Application or library Pascal sources
  src/main/ftml/       # Declarative FTML markup
  src/test/pascal/     # FPCUnit tests and TestRunner.pas
  target/              # Compiler outputs, ppu, o, and final binaries
  ```

### Lifecycle Commands
- **Compile project**:
  ```bash
  pasbuild compile
  # or
  ./build.sh
  ```
- **Run test suite**:
  ```bash
  pasbuild test
  # or
  ./build.sh test
  ```
- **Install library to local cache**:
  ```bash
  pasbuild install
  ```
  *Rule*: When modifying core libraries (`florialib`, `ftpas`), run `pasbuild install` inside their directory before compiling downstream projects (`floria-toolkit`, `configsama`, `bawana`).
- **Clean build**:
  ```bash
  pasbuild clean
  ```

---

## 2. Floria Toolkit Architecture (`libft.so`)

- **Rendering Engine**: Decoupled 2D vector graphics powered by AggPas (`aggpas:2.4.0-SNAPSHOT`) and X11/XCB.
- **Display Server Target**: Strictly native X11/XCB with EWMH/ICCCM. Never introduce or target Wayland.
- **Pascal Unit Filenames**: Implementation units under `src/main/pascal/` are strictly pluralized:
  `ft.widget.buttons.pas`, `ft.widget.containers.pas`, `ft.widget.entries.pas`, `ft.widget.meters.pas`, `ft.widget.selectors.pas`, `ft.widget.splitters.pas`, `ft.widget.switches.pas`, `ft.widget.tables.pas`, `ft.widget.tabs.pas`, `ft.widget.textareas.pas`, `ft.widget.texts.pas`, `ft.widget.treeviews.pas`.
- **C ABI Interface**: Exported routines in `ft.pas` match `include/ft.h` using `cdecl; export;`.
- **Button Lifecycle Invariant**: Mouse down sets the pressed visual state. Primary actions execute strictly on mouse button release within the control bounds.

---

## 3. `ftpas` Object Pascal OOP Binding

`ftpas` wraps the C ABI into strongly typed Object Pascal classes and records.

### Core Units & Classes
| Unit | Key Classes | Description |
| :--- | :--- | :--- |
| `ftpas.app` | `TFtApp`, `FtApp()` | Main application loop, clipboard, theme management, `AppendCssString()` |
| `ftpas.window` | `TFtWindow` | Top-level X11 window base class |
| `ftpas.ftml` | `TFtFTMLWindow`, `TFtFTMLHost` | Base window for loading and binding FTML markup |
| `ftpas.controls` | `TFtButton`, `TFtEntry`, `TFtSwitch`, `TFtCheckBox`, `TFtComboBox` | Standard interactive widgets |
| `ftpas.layouts` | `TFtContainer`, `TFtHBox`, `TFtVBox`, `TFtNotebook` | Layout and containment widgets |
| `ftpas.views` | `TFtTable`, `TFtTreeView`, `TFtIconView` | Structured data presentation views |
| `ftpas.types` | `TFtRect`, `TFtColor`, `TFtAnchorMode`, `TFtScrollBarMode` | Enums and geometry types |

### Object Pascal Coding Invariants
1. **Mandatory Empty Parameter Parentheses `()`**:
   All 0-parameter procedures, functions, constructors, destructors, and call sites must include `()`:
   ```pascal
   procedure Show(); override;
   destructor Destroy(); override;
   // Call sites:
   MyWidget.Invalidate();
   inherited Destroy();
   ```
2. **C-Compatible Constants**: Constants use `ALL_CAPS_WITH_UNDERSCORES`.
3. **Memory Ownership**: Pair local object allocations with `try..finally Object.Free()`. Parent windows/containers automatically manage child widget lifecycles.

---

## 4. FTML (Floria Toolkit Markup Language)

FTML is a declarative markup language for structuring Floria user interfaces, bridging `floriajs` layout concepts to native `ftpas` widgets.

### Syntax & Header
```ftml
// @form TBawanaWindow
// Form header maps markup to the target TFtFTMLWindow class

Window {
  id: mainWindow;
  title: "Application Title";
  extendedClientArea: true;  // ECA: Client area extends through titlebar
  width: 960;
  height: 640;

  Container {
    id: sidebar;
    anchors.top: parent.top;
    anchors.left: parent.left;
    anchors.bottom: parent.bottom;
    width: 240;
    drawFrame: false;
    padding: 0;
    scrollBarMode: "vertical";

    Text {
      id: lblTitle;
      anchors.top: parent.top;
      anchors.topMargin: 18;
      anchors.left: parent.left;
      anchors.leftMargin: 20;
      text: "App Title";
      font: "Sans:bold 14";
      selectable: false;
    }
  }

  Container {
    id: contentArea;
    anchors.top: parent.top;
    anchors.left: sidebar.right;
    anchors.right: parent.right;
    anchors.bottom: parent.bottom;
    drawFrame: false;
    padding: 0;
  }
}
```

### Layout Engine & Anchors
- **Anchor Properties**: `anchors.top`, `anchors.bottom`, `anchors.left`, `anchors.right`, `anchors.horizontalCenter`, `anchors.verticalCenter`.
- **Anchor Margins**: `anchors.topMargin`, `anchors.bottomMargin`, `anchors.leftMargin`, `anchors.rightMargin`.
- **Responsive Width Tracking**: Never hardcode widths on main content cards. Anchor both left and right margins to parent bounds:
  ```ftml
  Container {
    id: cardDetails;
    anchors.top: parent.top;
    anchors.left: parent.left;
    anchors.right: parent.right;
    anchors.leftMargin: 32;
    anchors.rightMargin: 32;
    height: 180;
  }
  ```
- **Navigation Item Alignment**: Inside sidebars, use symmetrical horizontal margins for selection pills:
  ```ftml
  Container {
    id: stepPill1;
    anchors.top: parent.top;
    anchors.left: parent.left;
    anchors.right: parent.right;
    anchors.leftMargin: 12;
    anchors.rightMargin: 12;
    height: 36;
  }
  ```

### Container Scrolling
- Set `scrollBarMode: "vertical";` (`ftsbmVerticalOnly`) to activate native AggPas scrollbars when children exceed container height.
- Set `padding: 0;` and `drawFrame: false;` on scrolling container views.
- In Pascal window code, reset scroll offset upon page switching:
  ```pascal
  procedure TMainWindow.ResetPageScroll();
  begin
    if Assigned(FCurrentPageContainer) then
      FCurrentPageContainer.ScrollOffsetY := 0.0;
  end;
  ```

### Container Styling & CSS
- Apply styles via `FtApp().AppendCssString(CSS)`.
- Use `border: none;` on container panels to suppress outline drawing.
- Avoid directional border properties (`border-top`, `border-bottom`) on full container components.

### Embedding FTML into Binaries
FTML files are converted into compiled Pascal resource units during build via `ftml_embed`:
```pascal
unit myapp.ftml.embed;
// Generated by ftml_embed tool
```
The window subclasses `TFtFTMLWindow`, which parses the embedded string resource on initialization, instantiates native widgets matching declared element IDs, and wires up event handlers.

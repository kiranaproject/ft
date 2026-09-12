---
name: ft-builder
description: Compiles and verifies Floria Toolkit (Ft) as a modern dotted-namespace Free Pascal shared object (libft.so) with X11 and AggPas.
version: 1.2.0
triggers:
  - build floria
  - build ft
  - compile ft toolkit
  - test ft bindings
---

# Floria Toolkit (Ft) Build & Test Skill

Orchestrates the build pipeline for Floria Toolkit (`libft.so`) using FPC dotted unit names, validates C ABI symbols, and tests foreign language integration.

## Prerequisites
- Free Pascal Compiler (`fpc` >= 3.2.0)
- X11 Development libraries (`libx11-dev`, `libxext-dev`)
- Standard build tools (`make`, `gcc`)
- Python 3 (`ctypes`)

---

## Coding Style & Language Rules

### 1. Mandatory Empty Parameter Parentheses `()`
To clearly distinguish methods, procedures, and functions from variables, properties, or constants:
- **Declarations**: Any procedure, function, constructor, or destructor taking zero parameters **MUST** include empty parentheses `()`.
  ```pascal
  // Correct
  procedure Click(); virtual;
  procedure Invalidate(); virtual;
  procedure MouseEnter(); virtual;
  procedure MouseLeave(); virtual;
  procedure Repaint();
  procedure Show();
  function GetFont(): TFtFont; virtual;
  destructor Destroy(); override;
  
  // Incorrect (DO NOT USE)
  procedure Click; virtual;
  procedure Invalidate; virtual;
  function GetFont: TFtFont;
  destructor Destroy; override;
  ```
- **Call Sites**: Any call to a zero-parameter procedure, function, or method **MUST** include empty parentheses `()`.
  ```pascal
  // Correct
  Target.Click();
  Invalidate();
  Repaint();
  inherited Destroy();
  FtBackendInit();
  FtBackendQuit();
  Children.Free();
  
  // Incorrect (DO NOT USE)
  Target.Click;
  Invalidate;
  Repaint;
  inherited Destroy;
  ```
- **Properties & Variables**: Properties and variables do **not** use parentheses:
  ```pascal
  // Property accesses remain without parentheses
  btn.Visible := True;
  f := btn.Font;
  s := btn.State;
  ```
  This ensures an immediate, unambiguous visual distinction: `item.Name` is a property or field, whereas `item.Action()` is a callable routine.

### 2. Dotted Namespaces
All units in Floria Toolkit follow dotted Pascal namespaces (e.g., `Ft.Widget`, `Ft.Buttons`, `Ft.Backend.X11`, `Ft.Font`, `Ft.Canvas.Agg`).

### 3. C ABI Compatibility
- Shared library export routines must use `cdecl; export;`.
- Types exposed across the ABI boundary should use standard C types (`cint32`, `Double`, `PChar`, `Pointer`).
- Keep function signatures mirrored in `include/ft.h`.

---

## Build Workflow

### Step 1: Toolchain Validation
```bash
which fpc || (echo "Error: fpc not installed" && exit 1)
pkg-config --exists x11 || (echo "Error: libx11-dev missing" && exit 1)
```

### Step 2: Compile Shared Library
```bash
lazbuild -B src/main/pascal/ft.lpi
```

### Step 3: Compile and Run C Example
```bash
gcc -Iinclude examples/c/main.c target/bin/libft.so -Wl,-rpath,'$ORIGIN/.' -o target/bin/c_example
./target/bin/c_example
```

### Step 4: Run Python Host Test
```bash
python3 examples/python/app.py
```
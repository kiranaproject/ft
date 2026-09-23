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

# Object Pascal System Rules & Coding Style

This document defines the strict architectural and formatting rules required for generating clean, maintainable, and interoperable Object Pascal source code.

---

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
  Btn.Visible := True;
  F := Btn.Font;
  S := Btn.State;
  ```
  This ensures an immediate, unambiguous visual distinction: `Item.Name` is a property or field, whereas `Item.Action()` is a callable routine.

### 2. Dotted Namespaces
All units in Floria Toolkit follow dotted Pascal namespaces (e.g., `Ft.Widget`, `Ft.Widget.Buttons`, `Ft.Backend.X11`, `Ft.Font`, `Ft.Canvas.Agg`).

### 3. C ABI Compatibility
- Shared library export routines must use `cdecl; export;`.
- Types exposed across the ABI boundary should use standard C types (`cint32`, `Double`, `PChar`, `Pointer`).
- Keep function signatures mirrored in `include/ft.h`.


### 4. Identifier Casing & Naming Conventions

Object Pascal relies primarily on **PascalCase** for structural entities, but adopts **ALL_CAPS** for constants to ensure seamless interoperability and naming uniformity when compiling shared libraries (`.dll` / `.so` / `.dylib`) accessed by C applications.

| Identifier Type | Case Style | Prefix / Rule | Example |
| :--- | :--- | :--- | :--- |
| **Variables (Local)** | PascalCase | No prefix | `UserCount`, `TotalAmount` |
| **Variables (Private Fields)** | PascalCase | Prefix with `F` (Field) | `FUserName`, `FAge` |
| **Constants** | **ALL_CAPS** | **Separated by underscores; matches C-API standards** | `MAX_USERS`, `DEFAULT_TIMEOUT`, `MB_OK` |
| **Types (Classes/Records)** | PascalCase | Prefix with `T` (Type) | `TUserAccount`, `TCustomerRecord` |
| **Interfaces** | PascalCase | Prefix with `I` (Interface) | `IWebClient`, `IDataRepository` |
| **Properties** | PascalCase | No prefix; usually maps to an `F` field | `property UserName: string read FUserName;` |
| **Method Parameters** | PascalCase | Frequently prefixed with `A` (Argument) | `procedure SetAge(const AValue: Integer);` |

#### Core Casing Rules:
* **The Interop Constant Rule:** All constants must be written in **ALL_CAPS_WITH_UNDERSCORES** (`MAX_CONNECTIONS = 100;`). This ensures definitions export cleanly and align visually with native C headers.
* **Strict PascalCase:** Do not use `snake_case` or `camelCase` for variable, type, or property names.
* **Property Mapping:** Properties must always be in clean PascalCase, while the private fields they read or write to must have the `F` prefix.
* **Keywords:** Always keep standard language keywords entirely lowercase (`begin`, `end`, `var`, `const`, `type`, `property`).

---

### 5. Enumerated Types Rules
Enumerated type definitions follow standard `T` prefix casing, but their internal values must use a **2 or 3 letter lowercase prefix** derived from the type's name. This avoids namespace pollution in the global unit scope.

```pascal
type
  // The type starts with T, prefix for values is 'bk' (Button Kind)
  TButtonKind = (bkOk, bkCancel, bkHelp, bkCustom);

  // Prefix for values is 'ut' (User Type)
  TUserType = (utGuest, utStandard, utAdmin);
```

---

### 6. Block Formatting & Indentation
To maintain absolute consistency across the codebase, structure nested code blocks according to these layout boundaries:

#### Indentation
* Use exactly **2 spaces** per indentation level.
* **Never use tab characters** (`0x09`). Configure the IDE to convert tabs to spaces.

#### `begin..end` Alignment
* The opening `begin` keyword must appear on a new line, aligned directly beneath the statement that controls it (like `if`, `while`, or `for`).
* The closing `end` keyword must align vertically with its corresponding `begin`.

```pascal
// Correct Block Formatting
if UserCount > MAX_USERS then
begin
  ShowWarning;
  LogEvent('Capacity reached');
end;

// Incorrect (Same-line begin or improper indentation)
if UserCount > MAX_USERS then begin
    ShowWarning;
end;
```

#### Single-Statement Omission
If a conditional controlling statement executes exactly one action, omit the `begin` and `end` keywords entirely. Indent the single trailing statement by 2 spaces.

```pascal
if IsValidated then
  AllowAccess
else
  DenyAccess;
```

---

### 7. Exception Handling Block Formatting (`try..finally` / `try..except`)

Object Pascal enforces a strict separation between **resource cleanup** (`finally`) and **error handling** (`except`). Because a single `try` block cannot contain both statements, nesting them properly is mandatory.

#### Resource Allocation (`try..finally`)
Always wrap resource allocations (objects, handles, memory) in a `try..finally` block immediately after creation to guarantee the resource is destroyed, even if an unexpected crash occurs.

```pascal
MyList := TStringList.Create;
try
  MyList.Add('Processing data...');
  SaveToLibrary(MyList);
finally
  MyList.Free; // Runs absolutely every time, preventing leaks
end;
```

#### Error Trapping (`try..except`)
Use `try..except` blocks to gracefully intercept errors, log runtime context, or raise user-friendly alternatives. Always trap specific exception classes rather than using blank handlers.

```pascal
try
  Result := CoreLibraryCalculation(ValueA, ValueB);
except
  on E: EDivByZero do
  begin
    LogLibraryError('Attempted to divide by zero.');
    Result := 0;
  end;
  on E: Exception do
  begin
    LogLibraryError('Unexpected FFI Failure: ' + E.Message);
    raise; 
  end;
end;
```

#### Dual-Purpose Nesting (The "Double Try" Rule)
When a routine needs to both safely clean up memory **and** handle potential runtime failures for the C-shared layer, you must **nest the `finally` block completely inside the `except` block**.

```pascal
// Correct Layout for Combined Cleanup and Error Interception
try
  ClientRecord := TCustomerRecord.Create;
  try
    ClientRecord.PopulateFromCData(RawBuffer);
    ExecuteTransaction(ClientRecord);
  finally
    ClientRecord.Free; // Guaranteed to fire first
  end;
except
  on E: Exception do
  begin
    HandleSharedLibraryCrash(E.Message);
    // Suppress or translate the exception so it doesn't crash the host C app
  end;
end;
```

#### Key Rules for Exception Handling:
* **The Interop Boundary Exception Rule:** Because exceptions thrown across FFI/C-library boundaries can destabilize foreign runtime environments (causing undefined behaviors or segmentation faults in C host apps), the outer wrapper of all exported routines must always safely catch and absorb/translate Pascal exceptions using a top-level `try..except` wrapper.
* **Keyword Alignment:** The `try`, `finally`, `except`, and `end` keywords must all align to the exact same vertical indentation column.


---

## Build Workflow

### Step 1: Toolchain Validation
```bash
which fpc || (echo "Error: fpc not installed" && exit 1)
pkg-config --exists x11 || (echo "Error: libx11-dev missing" && exit 1)
```

### Step 2: Compile Shared Library
```bash
pasbuild compile
# or: lazbuild -B src/main/pascal/ft.lpi
```

### Step 3: Compile and Run C Example
```bash
gcc -Iinclude examples/c/main.c target/libft.so -Wl,-rpath,'$ORIGIN/.' -o target/c_example
./target/c_example
```

### Step 4: Run Python Host Test
```bash
python3 examples/python/app.py
```
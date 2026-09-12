---
name: ft-builder
description: Compiles and verifies Floria Toolkit (Ft) as a modern dotted-namespace Free Pascal shared object (libft.so) with X11 and AggPas.
version: 1.1.0
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

## Build Workflow

### Step 1: Toolchain Validation
```bash
which fpc || (echo "Error: fpc not installed" && exit 1)
pkg-config --exists x11 || (echo "Error: libx11-dev missing" && exit 1)
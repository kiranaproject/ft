#!/usr/bin/env bash
set -euo pipefail

# Build script for floria-toolkit supporting FPC, Blaise, tests, and examples

TARGET="${1:-fpc}"

# Locate Blaise binary
BLAISE_BIN="$(which blaise 2>/dev/null || true)"
if [ -z "${BLAISE_BIN}" ] || [ ! -x "${BLAISE_BIN}" ]; then
  if [ -x "${HOME}/blaise/files/releases/v0.15.0-pre/blaise" ]; then
    BLAISE_BIN="${HOME}/blaise/files/releases/v0.15.0-pre/blaise"
  fi
fi

case "${TARGET}" in
  blaise)
    if [ -z "${BLAISE_BIN}" ]; then
      echo "Error: Blaise compiler binary not found in PATH or ~/blaise/files/releases/v0.15.0-pre/blaise" >&2
      exit 1
    fi
    echo "==> Compiling with Blaise Compiler (${BLAISE_BIN})..."
    shift 1 || true
    pasbuild compile --compiler "${BLAISE_BIN}" "$@"
    ;;
  test)
    echo "==> Running tests with FPC..."
    shift 1 || true
    pasbuild test "$@"
    ;;
  examples)
    echo "==> Building C examples..."
    shift 1 || true
    ./build_examples.sh "$@"
    ;;
  clean)
    echo "==> Cleaning target artifacts..."
    shift 1 || true
    pasbuild clean "$@"
    ;;
  fpc|*)
    echo "==> Compiling with Free Pascal Compiler (FPC)..."
    if [ "${TARGET}" = "fpc" ]; then
      shift 1 || true
    fi
    pasbuild compile "$@"
    ;;
esac

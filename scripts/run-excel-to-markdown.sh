#!/usr/bin/env bash
# Run scripts/excel_to_markdown.py against a .xlsx workbook.
# On first use: ensures Python ≥3.10 exists, creates .venv/, installs deps, then runs.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY_SCRIPT="$ROOT_DIR/scripts/excel_to_markdown.py"
VENV_PYTHON="$ROOT_DIR/.venv/bin/python"

if [ ! -f "$PY_SCRIPT" ]; then
    echo "ERROR: Missing $PY_SCRIPT" >&2
    exit 1
fi

BOOTSTRAP_PY=""
for cmd in python3 python; do
    if command -v "$cmd" >/dev/null 2>&1; then
        BOOTSTRAP_PY="$(command -v "$cmd")"
        break
    fi
done

if [ -z "$BOOTSTRAP_PY" ]; then
    echo "ERROR: Python is not installed or not on PATH (looked for: python3, python)." >&2
    echo "Install Python 3.10 or newer from https://www.python.org/downloads/ or your package manager." >&2
    exit 1
fi

if ! "$BOOTSTRAP_PY" - <<'VERS' >/dev/null 2>&1; then
import sys
if sys.version_info < (3, 10):
    raise SystemExit(1)
VERS
    echo "ERROR: Need Python ≥3.10; found $($BOOTSTRAP_PY - <<'VV'
import sys
print("%d.%d" % sys.version_info[:2])
VV
)." >&2
    exit 1
fi

needs_venv=0
if [ ! -x "$VENV_PYTHON" ]; then
    needs_venv=1
fi

if [ "$needs_venv" -eq 1 ]; then
    echo "==> Creating $ROOT_DIR/.venv (first-time setup, needs network for pip …)"
    if ! "$BOOTSTRAP_PY" -m venv "$ROOT_DIR/.venv"; then
        echo "ERROR: 'python -m venv' failed. On Debian/Ubuntu install: sudo apt install python3-venv" >&2
        exit 1
    fi
fi

if ! "$VENV_PYTHON" - <<'VERS' >/dev/null 2>&1; then
import sys
if sys.version_info < (3, 10):
    raise SystemExit(1)
VERS
    echo "ERROR: $ROOT_DIR/.venv must use Python ≥3.10. Remove it and re-run:" >&2
    echo "  rm -rf $ROOT_DIR/.venv" >&2
    exit 1
fi

_have_packages() {
    "$VENV_PYTHON" - <<'CHECK' >/dev/null 2>&1
import importlib.util
for name in ("pandas", "tabulate", "openpyxl"):
    if importlib.util.find_spec(name) is None:
        raise SystemExit(1)
CHECK
}

if ! _have_packages; then
    echo "==> Installing pandas, tabulate, openpyxl into .venv (first-time setup …)"
    "$VENV_PYTHON" -m pip install --upgrade pip
    "$VENV_PYTHON" -m pip install pandas tabulate openpyxl
fi

if ! _have_packages; then
    echo "ERROR: Packages missing after pip install." >&2
    exit 1
fi

cd "$ROOT_DIR"
exec "$VENV_PYTHON" "$PY_SCRIPT" "$@"

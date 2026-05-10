#!/usr/bin/env bash
# Build the package, inspect contents, smoke-test in a fresh venv.
# Run from repo root. Exits non-zero on any check failure.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Prefer project venv so pip install build/twine works under PEP 668 (Homebrew).
if [ -x "$ROOT/.venv/bin/python" ]; then
    PYTHON="$ROOT/.venv/bin/python"
elif command -v python >/dev/null 2>&1; then
    PYTHON=python
elif command -v python3 >/dev/null 2>&1; then
    PYTHON=python3
else
    echo "FAIL: need .venv/bin/python, python, or python3 on PATH"
    exit 1
fi

SMOKE_VENV="/tmp/rck-smoke-$$"
SMOKE_FILE="/tmp/rck-smoke-$$.robot"

cleanup() {
    deactivate 2>/dev/null || true
    rm -rf "$SMOKE_VENV" "$SMOKE_FILE"
}
trap cleanup EXIT

echo "==> Step 1: Clean stale build artifacts"
rm -rf dist/ build/ src/*.egg-info/ *.egg-info/

echo "==> Step 2: Ensure build tooling"
if ! "$PYTHON" -m pip install --upgrade --quiet build twine; then
    echo "FAIL: could not install build + twine. Hint: python3 -m venv .venv && .venv/bin/pip install -U pip build twine"
    exit 1
fi

echo "==> Step 3: Build sdist + wheel"
"$PYTHON" -m build

echo "==> Step 4: Verify .resource count parity"
src_count=$(find src/robot_common_keywords -name '*.resource' | wc -l | tr -d ' ')
whl_count=$(unzip -l dist/*.whl | grep -c '\.resource$' || true)
if [ "$src_count" -ne "$whl_count" ]; then
    echo "FAIL: wheel has $whl_count .resource files, source has $src_count"
    echo "Check [tool.setuptools.package-data] glob in pyproject.toml"
    exit 1
fi
echo "    OK: $src_count .resource files in source and wheel"

echo "==> Step 5: Verify YAML and JSON files included"
src_data_count=$(find src/robot_common_keywords \( -name '*.yaml' -o -name '*.json' \) | wc -l | tr -d ' ')
whl_data_count=$(unzip -l dist/*.whl | grep -cE '\.(yaml|json)$' || true)
if [ "$src_data_count" -ne "$whl_data_count" ]; then
    echo "FAIL: wheel has $whl_data_count yaml/json files, source has $src_data_count"
    exit 1
fi
echo "    OK: $src_data_count yaml/json files in source and wheel"

echo "==> Step 6: twine check"
"$PYTHON" -m twine check dist/*

echo "==> Step 7: Smoke test in a fresh venv"
"$PYTHON" -m venv "$SMOKE_VENV"
# shellcheck disable=SC1091
source "$SMOKE_VENV/bin/activate"
pip install --quiet dist/*.whl
# After activate, `python` resolves to the smoke venv.
version=$(python -c "import robot_common_keywords; print(robot_common_keywords.__version__)")
echo "    Installed version: $version"

cat > "$SMOKE_FILE" <<'EOF'
*** Settings ***
Resource    robot_common_keywords/form_validation/required_field.resource
Library     robot_common_keywords.libraries.phone_helpers

*** Test Cases ***
Smoke
    Log    Smoke OK
EOF

robot --dryrun "$SMOKE_FILE"

echo ""
echo "==> Build and verification PASSED"
echo "    sdist: $(ls dist/*.tar.gz)"
echo "    wheel: $(ls dist/*.whl)"

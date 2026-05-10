#!/usr/bin/env bash
# Upload built artifacts in dist/ to TestPyPI, smoke-test, then PyPI.
# Requires ~/.pypirc with token credentials and dist/ produced by
# scripts/build-and-verify.sh. Run from repo root.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

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

# Read version from the package (single source of truth)
VERSION=$(PYTHONPATH=src "$PYTHON" -c "from robot_common_keywords import __version__; print(__version__)")
SDIST="dist/robotframework_common_keywords-$VERSION.tar.gz"
WHEEL="dist/robotframework_common_keywords-$VERSION-py3-none-any.whl"

if [ ! -f "$SDIST" ] || [ ! -f "$WHEEL" ]; then
    echo "FAIL: missing $SDIST or $WHEEL"
    echo "Run scripts/build-and-verify.sh first"
    exit 1
fi

echo "==> Publishing version: $VERSION"
echo "    sdist: $SDIST"
echo "    wheel: $WHEEL"

# ------- Stage 1: TestPyPI upload -------
echo ""
echo "==> Stage 1: Upload to TestPyPI"
"$PYTHON" -m twine upload --repository testpypi "$SDIST" "$WHEEL"

echo ""
echo "==> Verify the TestPyPI page renders correctly:"
echo "    https://test.pypi.org/project/robotframework-common-keywords/$VERSION/"
echo "Press Enter to continue with the TestPyPI install smoke test, Ctrl-C to abort."
read -r

# ------- Stage 2: Install from TestPyPI and smoke -------
echo "==> Stage 2: Install from TestPyPI in a fresh venv"
TESTPYPI_VENV="/tmp/rck-testpypi-$$"
TESTPYPI_FILE="/tmp/rck-testpypi-$$.robot"
trap 'deactivate 2>/dev/null || true; rm -rf "$TESTPYPI_VENV" "$TESTPYPI_FILE"' EXIT

"$PYTHON" -m venv "$TESTPYPI_VENV"
# shellcheck disable=SC1091
source "$TESTPYPI_VENV/bin/activate"
pip install --quiet \
    --index-url https://test.pypi.org/simple/ \
    --extra-index-url https://pypi.org/simple/ \
    "robotframework-common-keywords==$VERSION"

cat > "$TESTPYPI_FILE" <<'EOF'
*** Settings ***
Resource    robot_common_keywords/form_validation/required_field.resource
Library     robot_common_keywords.libraries.phone_helpers

*** Test Cases ***
Smoke
    Log    Smoke OK
EOF
robot --dryrun "$TESTPYPI_FILE"
deactivate
rm -rf "$TESTPYPI_VENV" "$TESTPYPI_FILE"
trap - EXIT

# ------- Stage 3: Confirmation gate -------
echo ""
echo "================================================================"
echo "  About to upload version $VERSION to **PRODUCTION PyPI**."
echo "  This is irreversible. Once uploaded, you cannot replace files."
echo "  To replace a bad release you must bump version and yank the old."
echo "================================================================"
read -p "Type 'publish' to confirm, anything else to abort: " confirm
if [ "$confirm" != "publish" ]; then
    echo "Aborted."
    exit 0
fi

# ------- Stage 4: PyPI upload -------
echo ""
echo "==> Stage 4: Upload to PyPI"
"$PYTHON" -m twine upload "$SDIST" "$WHEEL"

# ------- Stage 5: Final smoke against PyPI -------
echo ""
echo "==> Stage 5: Smoke test against PyPI"
PYPI_VENV="/tmp/rck-pypi-$$"
PYPI_FILE="/tmp/rck-pypi-$$.robot"
trap 'deactivate 2>/dev/null || true; rm -rf "$PYPI_VENV" "$PYPI_FILE"' EXIT

"$PYTHON" -m venv "$PYPI_VENV"
# shellcheck disable=SC1091
source "$PYPI_VENV/bin/activate"
pip install --quiet "robotframework-common-keywords==$VERSION"

cat > "$PYPI_FILE" <<'EOF'
*** Settings ***
Resource    robot_common_keywords/form_validation/required_field.resource
Library     robot_common_keywords.libraries.phone_helpers

*** Test Cases ***
Smoke
    Log    Smoke OK
EOF
robot --dryrun "$PYPI_FILE"
deactivate

echo ""
echo "================================================================"
echo "  Published $VERSION to PyPI successfully."
echo "    https://pypi.org/project/robotframework-common-keywords/$VERSION/"
echo ""
echo "  Next:"
echo "    git tag -a v$VERSION -m 'Release $VERSION'"
echo "    git push origin v$VERSION"
echo "    Draft a GitHub release at the new tag."
echo "================================================================"

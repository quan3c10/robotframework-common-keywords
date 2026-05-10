# PyPI Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish `robotframework-common-keywords` 0.1.0 to PyPI so consumers can `pip install robotframework-common-keywords` and import the existing `Resource` and `Library` keyword modules.

**Architecture:** Manual two-stage publish (TestPyPI → PyPI) driven by two checked-in shell scripts. `scripts/build-and-verify.sh` cleans, builds, inspects, and smoke-tests the wheel in a fresh venv. `scripts/publish.sh` uploads to TestPyPI, smoke-tests against TestPyPI, then prompts for explicit confirmation before pushing to production PyPI. Single-source versioning via `pyproject.toml` `dynamic = ["version"]` reading from `src/robot_common_keywords/__version__.py`.

**Tech Stack:** Python `build` (PEP 517), `twine`, `setuptools` (already configured), Robot Framework dryrun for smoke testing, `~/.pypirc` for token storage.

**Spec:** `docs/superpowers/specs/2026-05-10-pypi-publishing-design.md` (commit `cb37f23`)

---

## File Structure

| File | Operation | Responsibility |
|---|---|---|
| `pyproject.toml` | Modify | Author identity, `[project.urls]`, dynamic versioning |
| `README.md` | Modify | Installation section rewrite (lines 23–87); add PyPI/Python badges at top |
| `scripts/build-and-verify.sh` | Create | Clean → build → inspect → smoke-test pipeline |
| `scripts/publish.sh` | Create | TestPyPI upload + smoke + confirmation gate + PyPI upload + smoke |
| `CHANGELOG.md` | Modify (post-publish) | Date-stamp the 0.1.0 section |
| `~/.pypirc` | Manual | Token credentials (mode 600) — outside repo |
| GitHub repo Settings | Manual | Visibility → Public |
| Git tag `v0.1.0` | Create | Released-version marker |
| GitHub Release for `v0.1.0` | Create | Release notes from CHANGELOG |

No changes to keyword `.resource` files, Python `libraries/`, tests, or `PROJECT_CONTEXT.md`.

---

## Phase 1 — Repo prep (code changes)

### Task 1: Update `pyproject.toml` — author, URLs, dynamic version

**Files:**
- Modify: `pyproject.toml`

- [ ] **Step 1: Update author block (line 13–15)**

Open `pyproject.toml`, replace:

```toml
authors = [
    { name = "Keyword-Driven Framework PoC" },
]
```

with:

```toml
authors = [
    { name = "QuanUH", email = "quan3c10@gmail.com" },
]
```

- [ ] **Step 2: Switch `version` to dynamic**

In the `[project]` table, replace `version = "0.1.0"` with `dynamic = ["version"]`.

Then add this new table immediately after `[tool.setuptools.packages.find]` (or any place in the file — just keep it grouped with other `[tool.setuptools...]` tables):

```toml
[tool.setuptools.dynamic]
version = { attr = "robot_common_keywords.__version__" }
```

- [ ] **Step 3: Add `[project.urls]` section**

Add this block immediately after the `classifiers` list (i.e., after the closing `]` on the classifiers, before `dependencies`):

```toml
[project.urls]
Homepage   = "https://github.com/quan3c10/robotframework-common-keywords"
Repository = "https://github.com/quan3c10/robotframework-common-keywords"
Issues     = "https://github.com/quan3c10/robotframework-common-keywords/issues"
Changelog  = "https://github.com/quan3c10/robotframework-common-keywords/blob/main/CHANGELOG.md"
```

- [ ] **Step 4: Verify by building and inspecting metadata**

Run:

```bash
rm -rf dist/ build/ src/*.egg-info/
python -m pip install --upgrade build twine
python -m build
unzip -p dist/*.whl '*/METADATA' | head -40
```

Expected output must contain:
- `Name: robotframework-common-keywords`
- `Version: 0.1.0` (read dynamically from `__version__.py`)
- `Author: QuanUH`
- `Author-email: quan3c10@gmail.com`
- `Project-URL: Homepage, https://github.com/quan3c10/robotframework-common-keywords`
- `Project-URL: Repository, ...`
- `Project-URL: Issues, ...`
- `Project-URL: Changelog, ...`

If `Version` shows `0.0.0` or is missing, the dynamic-version `attr` lookup failed — re-check Step 2.

- [ ] **Step 5: Run `twine check`**

```bash
python -m twine check dist/*
```

Expected: both files report `PASSED`. Any `FAILED` output names a metadata field — fix in `pyproject.toml`.

- [ ] **Step 6: Commit**

```bash
git add pyproject.toml
git commit -m "$(cat <<'EOF'
build: prepare pyproject.toml for PyPI publish

- Set author to QuanUH <quan3c10@gmail.com>
- Add [project.urls] for Homepage / Repository / Issues / Changelog
- Switch to dynamic versioning so __version__.py is the single source

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Rewrite README Installation section + add badges

**Files:**
- Modify: `README.md` (lines 23–87 replaced; badges added near top)

- [ ] **Step 1: Add badges at the top**

Open `README.md`. After line 1 (the `# common-keywords —` title), insert a blank line, then this badge block, then another blank line:

```markdown
[![PyPI](https://img.shields.io/pypi/v/robotframework-common-keywords)](https://pypi.org/project/robotframework-common-keywords/)
[![Python](https://img.shields.io/pypi/pyversions/robotframework-common-keywords)](https://pypi.org/project/robotframework-common-keywords/)
```

The badges show "no version" / nothing until the first PyPI publish, then auto-populate.

- [ ] **Step 2: Replace the Installation section**

Delete the existing block that spans:
- `## Installation` (line 23) through
- `## Quick start` (line 99, **exclusive** — keep "## Quick start" intact)

Wait — re-check before deleting. The existing structure has:
- `## Installation` (line 23)
- `### Option A — Git submodule` (line 25)
- `### Option B — Pip install (preferred long-term)` (line 47)
- `#### Editable installs (\`pip install -e\`)` (line 67)
- `### Browser Library` (line 88) — **KEEP THIS** as a subsection of Installation
- `## Quick start` (line 99) — **KEEP THIS**

Replace lines 23 through 87 (everything from `## Installation` through the end of the editable-installs subsection, **stopping just before `### Browser Library`**) with:

```markdown
## Installation

```bash
pip install robotframework-common-keywords
```

For pre-release or development installs from a Git ref:

```bash
pip install git+https://github.com/quan3c10/robotframework-common-keywords.git
```

Imports after install use the package path:

```robot
*** Settings ***
Resource    robot_common_keywords/form_validation/email_field.resource
Library     robot_common_keywords.libraries.phone_helpers
```

### Editable installs for contributors

Code lives under `src/robot_common_keywords/`. From a clone of this repo:

```bash
pip install -e .
robot --dryrun tests/
```

Playwright browsers must be installed separately (`rfbrowser init`) to run the Browser-driven self-tests.
```

- [ ] **Step 3: Sanity-check the file**

Run:

```bash
grep -n '^##\|^###' README.md | head -20
```

Expected headers in order:
- `## Installation`
- `### Editable installs for contributors`
- `### Browser Library`
- `## Quick start`
- (rest unchanged)

If `### Option A` or `### Option B` still appears, the deletion was incomplete — re-do Step 2.

- [ ] **Step 4: Rebuild and re-check long-description renders**

```bash
rm -rf dist/ build/ src/*.egg-info/
python -m build
python -m twine check dist/*
```

Expected: both `PASSED`. `twine check` validates that the README markdown is valid for PyPI's renderer. Any failure points to specific markdown that PyPI rejects.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs(readme): lead Installation with pip install; add PyPI badges

- Drop the git-submodule + monorepo install variants in favor of
  pip install robotframework-common-keywords as the primary path
- Keep editable-install instructions for contributors
- Add PyPI version + supported-Python badges at the top

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Create `scripts/build-and-verify.sh`

**Files:**
- Create: `scripts/build-and-verify.sh`

- [ ] **Step 1: Write the script**

Create `scripts/build-and-verify.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Build the package, inspect contents, smoke-test in a fresh venv.
# Run from repo root. Exits non-zero on any check failure.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

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
python -m pip install --upgrade --quiet build twine

echo "==> Step 3: Build sdist + wheel"
python -m build

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
python -m twine check dist/*

echo "==> Step 7: Smoke test in a fresh venv"
python -m venv "$SMOKE_VENV"
# shellcheck disable=SC1091
source "$SMOKE_VENV/bin/activate"
pip install --quiet dist/*.whl
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/build-and-verify.sh
```

- [ ] **Step 3: Run it on the current project**

```bash
./scripts/build-and-verify.sh
```

Expected: ends with `==> Build and verification PASSED` and lists the produced sdist + wheel paths. All seven step headers print without any `FAIL:` line.

If `Step 4` fails with a count mismatch, that means the `package-data` glob in `pyproject.toml` isn't matching — investigate before proceeding.

- [ ] **Step 4: Negative-path sanity check (optional but recommended)**

Temporarily break the package-data glob to confirm the script catches mismatches. Edit `pyproject.toml` and remove the `"**/*.resource",` line from the `[tool.setuptools.package-data]` `robot_common_keywords` list. Then run:

```bash
./scripts/build-and-verify.sh
```

Expected: exits non-zero at Step 4 with `FAIL: wheel has 0 .resource files, source has <N>`. Restore the line in `pyproject.toml` and re-run — should pass again.

- [ ] **Step 5: Commit**

```bash
git add scripts/build-and-verify.sh
git commit -m "$(cat <<'EOF'
build: add scripts/build-and-verify.sh for repeatable local builds

Runs clean → build → metadata check → smoke install → robot dryrun
in a fresh venv. Used as the pre-publish gate before any twine upload.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Create `scripts/publish.sh`

**Files:**
- Create: `scripts/publish.sh`

- [ ] **Step 1: Write the script**

Create `scripts/publish.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Upload built artifacts in dist/ to TestPyPI, smoke-test, then PyPI.
# Requires ~/.pypirc with token credentials and dist/ produced by
# scripts/build-and-verify.sh. Run from repo root.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Read version from the package (single source of truth)
VERSION=$(PYTHONPATH=src python -c "from robot_common_keywords import __version__; print(__version__)")
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
python -m twine upload --repository testpypi "$SDIST" "$WHEEL"

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

python -m venv "$TESTPYPI_VENV"
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
python -m twine upload "$SDIST" "$WHEEL"

# ------- Stage 5: Final smoke against PyPI -------
echo ""
echo "==> Stage 5: Smoke test against PyPI"
PYPI_VENV="/tmp/rck-pypi-$$"
PYPI_FILE="/tmp/rck-pypi-$$.robot"
trap 'deactivate 2>/dev/null || true; rm -rf "$PYPI_VENV" "$PYPI_FILE"' EXIT

python -m venv "$PYPI_VENV"
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/publish.sh
```

- [ ] **Step 3: Lint with shellcheck (if available, otherwise read-through review)**

```bash
shellcheck scripts/publish.sh || echo "shellcheck not installed; manual review only"
```

If shellcheck reports any errors (not warnings), fix them. Warnings about quoting / heredoc handling are acceptable as long as the script behaves as documented.

- [ ] **Step 4: Read-through review (do not run yet — destructive)**

Open `scripts/publish.sh` and confirm:
- Stage 1 uploads to `testpypi` (not PyPI)
- Stage 3 has a confirmation gate that exits unless the user types literally `publish`
- Stage 4 has no `--repository` flag (defaults to PyPI)
- Both smoke-test stages clean up their temporary venv via `trap`

- [ ] **Step 5: Commit**

```bash
git add scripts/publish.sh
git commit -m "$(cat <<'EOF'
build: add scripts/publish.sh for TestPyPI -> PyPI publish

Stage 1 uploads to TestPyPI; Stage 2 installs from TestPyPI and runs
robot --dryrun against a smoke fixture; Stage 3 prompts the operator
to type 'publish' before any PyPI upload; Stage 4 uploads to PyPI;
Stage 5 verifies the PyPI install path. Reads version from
robot_common_keywords.__version__ (single source of truth).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase 2 — Pre-publish manual prep

### Task 5: Make GitHub repo public + secret audit

**Files:**
- External: GitHub repository settings

- [ ] **Step 1: Audit git history for accidentally-committed secrets**

Run:

```bash
git log -p --all -- .pypirc 2>/dev/null | head -5
git log -p --all | grep -iE 'password|secret|token|api[_-]?key' | head -20
```

Expected: no real credentials surface. If any match looks like a real token (e.g., `pypi-...`, `ghp_...`), STOP and rotate that credential before making the repo public. Tokens visible in git history remain visible after a public flip even if you delete the file in HEAD.

- [ ] **Step 2: Audit the working tree for stray credential files**

```bash
ls -la | grep -iE '\.env|\.pypirc|credentials'
find . -name '.env*' -not -path './.venv/*' -not -path './.git/*'
```

Expected: no files match. If any do, add to `.gitignore` and confirm they're not tracked (`git ls-files --error-unmatch <file>` returns non-zero).

- [ ] **Step 3: Flip repo visibility to Public**

Browser:
1. Go to `https://github.com/quan3c10/robotframework-common-keywords/settings`
2. Scroll to "Danger Zone" at the bottom
3. Click "Change repository visibility" → "Make public"
4. Type the repo name to confirm

- [ ] **Step 4: Verify all four URLs in `[project.urls]` resolve**

```bash
for url in \
    https://github.com/quan3c10/robotframework-common-keywords \
    https://github.com/quan3c10/robotframework-common-keywords/issues \
    https://github.com/quan3c10/robotframework-common-keywords/blob/main/CHANGELOG.md ; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    echo "$code $url"
done
```

Expected: all three return `200`. If any return `404`, double-check the URL in `pyproject.toml`.

---

### Task 6: Verify `~/.pypirc` and 2FA

**Files:**
- External: `~/.pypirc` (user's home directory; not in repo)

- [ ] **Step 1: Confirm 2FA is enabled on PyPI**

Browser → `https://pypi.org/manage/account/` → confirm a 2FA method (TOTP or hardware key) is registered. Without 2FA, uploads will fail with a permissions error.

- [ ] **Step 2: Confirm 2FA is enabled on TestPyPI**

Browser → `https://test.pypi.org/manage/account/` → same check.

- [ ] **Step 3: Confirm `~/.pypirc` exists with mode 600**

```bash
ls -la ~/.pypirc
```

Expected: `-rw-------` (mode 600). If permissions are looser, run `chmod 600 ~/.pypirc`.

If the file does not exist, create it with these contents (replacing the placeholder tokens with the actual `pypi-...` strings copied from the PyPI / TestPyPI account-token-creation pages — see the spec §7.C1 for the bootstrap-token recipe):

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-YOUR-PYPI-ACCOUNT-SCOPED-TOKEN

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-YOUR-TESTPYPI-ACCOUNT-SCOPED-TOKEN
```

Then `chmod 600 ~/.pypirc`.

- [ ] **Step 4: Verify the file parses as expected by twine**

```bash
python -c "
import configparser, os
c = configparser.ConfigParser()
c.read(os.path.expanduser('~/.pypirc'))
for section in ('pypi', 'testpypi'):
    assert section in c.sections(), f'missing [{section}] section'
    assert c[section]['username'] == '__token__', f'[{section}] username must be __token__'
    assert c[section]['password'].startswith('pypi-'), f'[{section}] password must start with pypi-'
print('~/.pypirc looks correct')
"
```

Expected: `~/.pypirc looks correct`. Any assertion failure tells you which section/field is wrong.

---

## Phase 3 — Execute first publish

### Task 7: Build and verify locally

**Files:**
- Output: `dist/robotframework_common_keywords-0.1.0.tar.gz`, `dist/robotframework_common_keywords-0.1.0-py3-none-any.whl`

- [ ] **Step 1: Run the build-and-verify script**

```bash
./scripts/build-and-verify.sh
```

Expected: ends with `==> Build and verification PASSED` and lists `dist/robotframework_common_keywords-0.1.0.tar.gz` and `dist/robotframework_common_keywords-0.1.0-py3-none-any.whl`.

- [ ] **Step 2: Manually inspect the wheel one more time**

```bash
unzip -p dist/*.whl '*/METADATA' | head -50
```

Confirm:
- `Version: 0.1.0` (not `0.0.0`)
- `Author: QuanUH`
- `Author-email: quan3c10@gmail.com`
- All four `Project-URL:` lines present
- Description (long-description) renders below

If any of these are wrong, abort and fix in `pyproject.toml`. Re-run Step 1.

---

### Task 8: Publish to TestPyPI (Stages 1–2 of `publish.sh`)

**Files:**
- External: TestPyPI

- [ ] **Step 1: Run the publish script**

```bash
./scripts/publish.sh
```

The script will execute Stage 1 (TestPyPI upload), then pause asking you to verify the page.

- [ ] **Step 2: Verify the TestPyPI page renders correctly**

Open: `https://test.pypi.org/project/robotframework-common-keywords/0.1.0/`

Confirm:
- Long description (README) renders
- "Project links" sidebar shows Homepage, Repository, Issues, Changelog
- "Author" shows `QuanUH`
- "Files" tab lists both `.tar.gz` and `.whl`

If anything renders wrong: hit Ctrl-C, fix in `pyproject.toml` / `README.md`, bump `__version__.py` to `0.1.0a1` (TestPyPI won't let you re-upload `0.1.0`), rebuild via `scripts/build-and-verify.sh`, re-run `scripts/publish.sh`.

- [ ] **Step 3: Confirm to proceed to Stage 2 smoke test**

Press Enter at the script's prompt. Watch:
- Stage 2 creates `/tmp/rck-testpypi-*` venv
- `pip install` succeeds (with both `--index-url testpypi` and `--extra-index-url pypi` for runtime deps)
- `robot --dryrun` exits 0 (the script doesn't print this explicitly but a non-zero exit will halt the script)

If Stage 2 fails, the script halts before the confirmation gate — meaning you have NOT published to PyPI yet. Investigate (most likely a missing `.resource` file in the wheel) and fix.

---

### Task 9: Publish to PyPI (Stages 3–5 of `publish.sh`)

**Files:**
- External: PyPI

- [ ] **Step 1: Confirm the gate**

The script prompts:

```
About to upload version 0.1.0 to **PRODUCTION PyPI**.
...
Type 'publish' to confirm, anything else to abort:
```

Type `publish` and press Enter.

- [ ] **Step 2: Watch Stage 4 upload to PyPI**

Expected: progress bars per file, then no error. The script proceeds directly into Stage 5.

- [ ] **Step 3: Watch Stage 5 install + smoke**

Expected:
- `pip install robotframework-common-keywords==0.1.0` (no `--index-url`) succeeds
- `robot --dryrun` exits 0
- Final block prints with the PyPI URL and the `git tag` next-step command

- [ ] **Step 4: Verify the PyPI page renders correctly**

Open: `https://pypi.org/project/robotframework-common-keywords/0.1.0/`

Same checks as Task 8 Step 2 (description, project links, author, files). The page may take 30–60 seconds to fully render badges.

- [ ] **Step 5: Verify the README badge auto-populates**

Open the GitHub repo's README (refresh if recently viewed). The PyPI badge near the top should now show `pypi 0.1.0`. The Python-versions badge should show `python 3.10 | 3.11 | 3.12 | 3.13`. If either still shows "no version" after 5 minutes, troubleshoot via `https://shields.io/badges/py-pi-version` (less likely a real bug, more likely badge-cache lag).

---

## Phase 4 — Post-publish

### Task 10: Tag and create GitHub release

**Files:**
- Create: git tag `v0.1.0` (local + origin)
- Create: GitHub Release at the new tag

- [ ] **Step 1: Create the annotated tag**

```bash
git tag -a v0.1.0 -m "Release 0.1.0 — initial PyPI publish"
```

- [ ] **Step 2: Push the tag**

```bash
git push origin v0.1.0
```

- [ ] **Step 3: Draft the GitHub release**

Browser:
1. `https://github.com/quan3c10/robotframework-common-keywords/releases/new`
2. "Choose a tag" → `v0.1.0`
3. "Release title" → `0.1.0 — initial PyPI publish`
4. "Describe this release" → paste the entire 0.1.0 / Unreleased section content from `CHANGELOG.md` (the bullet list under `## Unreleased`)
5. Check "Set as the latest release"
6. Click "Publish release"

- [ ] **Step 4: Verify the release is visible**

Open: `https://github.com/quan3c10/robotframework-common-keywords/releases/tag/v0.1.0`

Confirm the release notes appear and the auto-generated source archives (`Source code (zip)` / `Source code (tar.gz)`) are downloadable.

---

### Task 11: Rotate to project-scoped tokens

**Files:**
- External: PyPI account, TestPyPI account, `~/.pypirc`

- [ ] **Step 1: Generate a project-scoped token on PyPI**

Browser:
1. `https://pypi.org/manage/account/` → "API tokens" → "Add API token"
2. Token name: `robotframework-common-keywords-prod`
3. Scope: select "Project: robotframework-common-keywords" (now visible because the project exists)
4. Click "Create token"
5. Copy the `pypi-...` value immediately

- [ ] **Step 2: Update `~/.pypirc` `[pypi]` password**

Replace the `password = pypi-YOUR-PYPI-ACCOUNT-SCOPED-TOKEN` line with the new project-scoped token. Keep `username = __token__`.

- [ ] **Step 3: Delete the old account-scoped bootstrap token on PyPI**

Browser → PyPI → "API tokens" → delete the `robotframework-common-keywords-bootstrap` (account-scoped) entry.

- [ ] **Step 4: Repeat Steps 1–3 for TestPyPI**

Same flow at `https://test.pypi.org/manage/account/`. Update `~/.pypirc` `[testpypi]` password.

- [ ] **Step 5: Sanity-check `~/.pypirc` parses**

```bash
python -c "
import configparser, os
c = configparser.ConfigParser()
c.read(os.path.expanduser('~/.pypirc'))
for section in ('pypi', 'testpypi'):
    assert c[section]['password'].startswith('pypi-')
print('~/.pypirc still parses OK')
"
```

Expected: `~/.pypirc still parses OK`.

---

### Task 12: Date-stamp the CHANGELOG

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Move the Unreleased entries under a dated 0.1.0 heading**

Open `CHANGELOG.md`. The current top reads:

```markdown
## Unreleased

- Sources live under `src/robot_common_keywords/`; ...
- Extend `src/robot_common_keywords/form_validation/number_field.resource` ...
... (more bullets)
```

Replace `## Unreleased` with `## 0.1.0 — 2026-05-10` (today's date). Then add a new empty `## Unreleased` section above it for future changes:

```markdown
## Unreleased

## 0.1.0 — 2026-05-10

- Sources live under `src/robot_common_keywords/`; ...
- Extend `src/robot_common_keywords/form_validation/number_field.resource` ...
... (the rest of the existing bullets, unchanged)
```

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "$(cat <<'EOF'
docs(changelog): date-stamp 0.1.0 release

Move Unreleased entries under a dated 0.1.0 heading; add an empty
Unreleased section above for future changes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push origin main
```

- [ ] **Step 3: Verify the release is fully shipped**

Final checklist (from spec §10):

```bash
# 1. PyPI page exists and shows 0.1.0
curl -s -o /dev/null -w "%{http_code}\n" https://pypi.org/pypi/robotframework-common-keywords/0.1.0/json
# Expect: 200

# 2. Fresh-venv install + dryrun smoke
python -m venv /tmp/rck-final
source /tmp/rck-final/bin/activate
pip install --quiet robotframework-common-keywords==0.1.0
python -c "import robot_common_keywords; print(robot_common_keywords.__version__)"
# Expect: 0.1.0
deactivate && rm -rf /tmp/rck-final

# 3. Tag exists locally and on origin
git tag --list 'v0.1.0'
# Expect: v0.1.0
git ls-remote --tags origin v0.1.0
# Expect: a SHA + refs/tags/v0.1.0

# 4. ~/.pypirc references project-scoped tokens (verified manually in Task 11)

# 5. __version__.py is the only place version is declared
grep -rn '0\.1\.0' pyproject.toml
# Expect: no match (dynamic version reads from __version__.py)
grep -n '__version__' src/robot_common_keywords/__version__.py
# Expect: __version__ = "0.1.0"
```

If all five checks pass, the publish is complete.

---

## Self-review

**1. Spec coverage — every section/requirement maps to a task:**

| Spec § | Task |
|---|---|
| §5.A1 (pyproject author/URLs/dynamic) | Task 1 |
| §5.A2 (README install rewrite) | Task 2 |
| §5.A3 (README badges) | Task 2 Step 1 |
| §5.A4 (make repo public) | Task 5 |
| §6 (build-and-verify.sh) | Task 3 |
| §7 (accounts & tokens) | Task 6 (verify; setup is prerequisite per spec assumptions) |
| §8 (publish.sh + TestPyPI→PyPI) | Tasks 4, 7, 8, 9 |
| §9.E1 (tag + GitHub release) | Task 10 |
| §9.E2 (rotate to project-scoped) | Task 11 |
| §9.E3 (date-stamp CHANGELOG) | Task 12 |
| §9.E4 (re-release loop) | Documented in spec; not a first-publish task |
| §9.E5 (yank safety net) | Documented in spec; only invoked if a release is broken |
| §10 verification protocol | Task 12 Step 3 |

**2. Placeholder scan:** No "TBD" / "TODO" / "implement later" / "similar to Task N" markers. Every shell script content is given in full. Every diff includes the exact lines to change.

**3. Type / signature consistency:** Version comes from `robot_common_keywords.__version__` everywhere (Task 1 Step 2 sets it; Task 4 reads it; Task 7 verifies it). Author identity is `QuanUH <quan3c10@gmail.com>` everywhere. Repo URL is `https://github.com/quan3c10/robotframework-common-keywords` consistently. Smoke `.robot` file content is identical in `build-and-verify.sh`, `publish.sh`'s two stages, and Task 12's final check.

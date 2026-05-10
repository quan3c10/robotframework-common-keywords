# Src layout & package-style test imports — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move installable keyword package under `src/robot_common_keywords/`, simplify setuptools config, rewrite `tests/*.robot` to package-style `Resource`/`Library`, update tooling/docs, preserve behaviour and Robot pass counts.

**Architecture:** Physical `git mv` keeps history; setuptools `packages.find` discovers `robot_common_keywords` under `src/`. Consumers and CI resolve keywords via **`pip install -e .`**. Relative `Resource`/`Library` chains **within** `.resource` files remain valid (`../libraries/*.py`, `${CURDIR}/../test_data/...`) because domain folders stay siblings under the package root.

**Tech Stack:** Python ≥3.10, setuptools ≥68, Robot Framework ≥7, `robotframework-browser`, optional `pytest` for `tests/test_new_keyword_script.py`; `pip install build` / `python -m build` for artefacts.

**Authoritative refs:** [`2026-05-09-restructure-project.md`](../specs/2026-05-09-restructure-project.md), [`2026-05-09-restructure-project-design.md`](../specs/2026-05-09-restructure-project-design.md).

---

## File inventory (creates / modifies)

| Responsibility | Paths |
|----------------|-------|
| **New directory** | `src/robot_common_keywords/` (package root after mv) |
| **Moved trees** | `form_validation/`, `api_validation/`, `ui_validation/`, `data_generators/`, `libraries/`, `test_data/`, `__init__.py`, `__version__.py` → under `src/robot_common_keywords/` |
| **Build config** | `pyproject.toml` — replace `[tool.setuptools]` + `packages` + `package-dir` + granular `package-data` with `find` + glob `package-data` |
| **Robot self-tests** | All `tests/test_*.robot` that declare `Resource ../…` or `Library ../libraries/…` (see grep in Task 7); `tests/test_sunid_register_flow.robot` unchanged (Browser only) |
| **Pytest unit test** | `tests/test_new_keyword_script.py` — seed dirs + asserted paths + self-test substring |
| **Scaffolder** | `scripts/new_keyword.py` — `cwd / "src/robot_common_keywords" / …`; templates `_SELF_TEST_TEMPLATE`, `_checklist` strings |
| **Catalog shell** | `scripts/generate-keyword-catalog.sh` — `find` roots + `OUT_DIR` |
| **One bugfix in tree** | `form_validation/email_field.resource` — `../../libraries/yaml_loader.py` → `../libraries/yaml_loader.py` so it resolves after move |
| **Docs** | `PROJECT_CONTEXT.md`, `README.md`, `docs/COVERAGE.md`, `docs/INTEGRATION.md`, `docs/EXAMPLES.md`, `CHANGELOG.md` if paths appear |
| **Untouched (do not mv)** | `browser/`, `tests/common_testcases/`, `tests/phone_validation/`, `scripts/excel_to_markdown.py`, `scripts/run-excel-to-markdown.sh`, `docs/EXCEL_TO_MARKDOWN.md`, loose untracked assets per requirements spec |

---

### Task 0: Prerequisites and baseline counters

**Files:** none (read-only measurement).

- [ ] **Step 1: Activate venv and ensure editable install of current layout**

Run (from repo root):

```bash
cd /Users/quanuh/Projects/robotframework-common-keywords
source .venv/bin/activate
pip install -e .
```

Expected: installs without error (captures today’s wiring before move).

- [ ] **Step 2: Dry-run Robot — record counts**

Run:

```bash
robot --dryrun tests/
```

Capture from summary line: **`X tests, Y passed`** (expect `Y == X`; note `X`).

Run:

```bash
rm -rf results
robot -d results --exclude network tests/
```

Capture **`X tests, Y passed, Z failed`** — expect `Z == 0`. Save these three numbers in commit message notes or `/tmp/rfbaseline.txt`.

- [ ] **Step 3: Resource file count baseline**

Run:

```bash
find form_validation api_validation ui_validation data_generators -name '*.resource' 2>/dev/null | wc -l
find libraries -maxdepth 1 -name '*.py' ! -name '__init__.py' | wc -l
```

Hold for comparison after move under `src/robot_common_keywords/`.

- [ ] **Step 4: Commit checkpoint (optional)**

If you maintain a baseline branch/tag only for comparison: `git tag pre-src-layout-baseline`.

---

### Task 1: Create `src` package root and git-mv payload

**Files:** Moves only (no edits inside keyword bodies).

- [ ] **Step 1: Create target and move package payload**

Run from repo root:

```bash
mkdir -p src/robot_common_keywords
git mv __init__.py __version__.py src/robot_common_keywords/
git mv form_validation api_validation ui_validation data_generators libraries test_data src/robot_common_keywords/
```

Expected: `git status` lists renames under `src/robot_common_keywords/`. No duplicate top-level domains left.

- [ ] **Step 2: Smoke list tree**

Run:

```bash
find src/robot_common_keywords -maxdepth 2 -type d
```

Expect: `.../form_validation`, `.../libraries`, `.../test_data`, etc.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: move package source under src/robot_common_keywords/"
```

---

### Task 2: Fix broken `yaml_loader` library path

**Files:** Modify `src/robot_common_keywords/form_validation/email_field.resource`.

- [ ] **Step 1: One-line correction**

From `src/robot_common_keywords/form_validation/`, `../libraries/` is correct. Replace the erroneous `../../` prefix.

Locate line (approx. line 7):

```robot
Library          ../../libraries/yaml_loader.py
```

Replace with:

```robot
Library          ../libraries/yaml_loader.py
```

Do not change `${CURDIR}/../test_data/...` variable paths (still valid siblings).

- [ ] **Step 2: Commit**

```bash
git commit -am "fix: correct yaml_loader path in email_field.resource for src layout"
```

---

### Task 3: Replace setuptools layout in `pyproject.toml`

**Files:** Modify `pyproject.toml` — delete **`[tool.setuptools]`** through end of **`[tool.setuptools.package-data]`** (the explicit `packages`, `package-dir`, and per-subpackage lists). Insert the block below immediately after **`[project.optional-dependencies]`** (or after `excel-markdown` block) — keep **`[tool.pytest.ini_options]`** unchanged except confirm it still reads:

```toml
pythonpath = ["scripts"]
```

Insert:

```toml
[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
robot_common_keywords = [
    "**/*.resource",
    "**/*.yaml",
    "**/*.json",
    "test_data/sample_files/*",
]
```

- [ ] **Step 1:** Apply replacement; verify no duplicate `[tool.setuptools]` keys.

- [ ] **Step 2:** Commit

```bash
git commit -am "build: setuptools src layout via packages.find + glob package-data"
```

---

### Task 4: Rewrite `tests/*.robot` imports (Resource + Library)

**Files:** All `tests/test_*.robot` that matched `Resource ../…` or `Library ../libraries/…` (24 files with `Resource` from earlier inventory; `Library` lines only in subset — script below covers both).

**Mechanism:** Run a small Python rewriter once from repo root (idempotent if re-run).

- [ ] **Step 1: Create `/tmp/update_test_imports.py` with exactly this content**

```python
"""Rewrite tests/*.robot to package-style imports. Run from repo root. Idempotent."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path.cwd()
TESTS = ROOT / "tests"

RESOURCE_REPLACEMENTS: list[tuple[str, str]] = [
    (r"^Resource(\s+)\.\./form_validation/", r"Resource\1robot_common_keywords/form_validation/"),
    (r"^Resource(\s+)\.\./api_validation/", r"Resource\1robot_common_keywords/api_validation/"),
    (r"^Resource(\s+)\.\./ui_validation/", r"Resource\1robot_common_keywords/ui_validation/"),
    (r"^Resource(\s+)\.\./data_generators/", r"Resource\1robot_common_keywords/data_generators/"),
]

# Library ../libraries/foo.py -> robot_common_keywords.libraries.foo (no suffix)
_LIBRARY_LINE = re.compile(
    r"^Library(\s+)\.\./libraries/([a-zA-Z0-9_]+)\.py\s*$",
    re.MULTILINE,
)


def main() -> None:
    for path in sorted(TESTS.glob("test_*.robot")):
        text = path.read_text(encoding="utf-8")
        orig = text
        for pattern, repl in RESOURCE_REPLACEMENTS:
            text = re.sub(pattern, repl, text, flags=re.MULTILINE)

        def _lib_sub(match: re.Match[str]) -> str:
            ws, stem = match.group(1), match.group(2)
            return f"Library{ws}robot_common_keywords.libraries.{stem}"

        text = _LIBRARY_LINE.sub(_lib_sub, text)
        if text != orig:
            path.write_text(text, encoding="utf-8")
            print("updated:", path)


if __name__ == "__main__":
    main()
```

**Important:** Copy this file to **`scripts/`** as `scripts/_rewrite_test_imports_after_src_layout.py` (or keep under `/tmp`); if stored in repo for the MR, delete it after CI green or retain as dev utility — prefer **run from `/tmp`** and discard to avoid committing throwaway tooling.

Run:

```bash
cd /Users/quanuh/Projects/robotframework-common-keywords
python3 /tmp/update_test_imports.py
```

Expected stdout lists every modified `tests/test_*.robot` (approximately the files that previously had `../` imports).

Manual spot-check:

```bash
grep -n '^\(Resource\|Library\).*\.\.' tests/*.robot || true
```

Expected: **no hits** (`|| true` ignores grep exit code 1 when empty).

- [ ] **Step 2: Commit**

```bash
git add tests/
git commit -m "test: use package Resource and Library paths (robot_common_keywords.*)"
```

---

### Task 5: Update `scripts/new_keyword.py` for src paths and stub Resource

**Files:** Modify `scripts/new_keyword.py`.

- [ ] **Step 1: Introduce package root constant and use it in `main()`**

Near the top (after imports), add:

```python
PACKAGE_ROOT = Path("src") / "robot_common_keywords"
```

Replace `cwd / args.domain` with `cwd / PACKAGE_ROOT / args.domain`.

Replace Python-mode `cwd / "libraries"` with `cwd / PACKAGE_ROOT / "libraries"`.

Concrete replacements inside `main()`:

```python
    if args.python:
        target = cwd / PACKAGE_ROOT / "libraries" / f"{args.module}.py"
```

and in the `.resource` branch:

```python
        resource = cwd / PACKAGE_ROOT / args.domain / f"{args.module}.resource"
```

`self_test = cwd / "tests" / f"test_{args.module}.robot"` stays at repo root.

- [ ] **Step 2: Update `_SELF_TEST_TEMPLATE`**

Change the Resource line inside `_SELF_TEST_TEMPLATE` from:

```robot
Resource         ../{domain}/{module}.resource
```

to:

```robot
Resource         robot_common_keywords/{domain}/{module}.resource
```

- [ ] **Step 3: Update `_checklist` strings**

In `_checklist()`, change human-readable paths:

```python
        return (
            f"\nScaffolded src/robot_common_keywords/libraries/{module}.py.\n"
```

and

```python
        return (
            f"\nScaffolded src/robot_common_keywords/{domain}/{module}.resource and tests/test_{module}.robot.\n"
```

- [ ] **Step 4: Update module docstring** first line mention if it still says `<domain>/<module>` only — clarify `src/robot_common_keywords/…`.

- [ ] **Step 5: Commit**

```bash
git add scripts/new_keyword.py
git commit -m "tooling: point new_keyword scaffolder at src/robot_common_keywords"
```

---

### Task 6: Align `tests/test_new_keyword_script.py` with src layout

**Files:** Modify `tests/test_new_keyword_script.py`.

- [ ] **Step 1: Update `render_self_test` assertion**

Replace:

```python
    assert "../form_validation/postal_code_field.resource" in rendered
```

with:

```python
    assert "robot_common_keywords/form_validation/postal_code_field.resource" in rendered
```

- [ ] **Step 2: Rewrite `_seed_minimal_layout`**

Replace body with:

```python
def _seed_minimal_layout(repo_root: Path) -> None:
    pkg = repo_root / "src" / "robot_common_keywords"
    (pkg / "form_validation").mkdir(parents=True, exist_ok=True)
    (pkg / "libraries").mkdir(parents=True, exist_ok=True)
    (repo_root / "tests").mkdir(parents=True, exist_ok=True)
    (repo_root / "docs").mkdir(parents=True, exist_ok=True)
    (repo_root / "docs" / "COVERAGE.md").write_text(
        "# Coverage\n\n| Keyword | Test | Coverage |\n|---|---|---|\n"
    )
```

- [ ] **Step 3: Update path assertions in integration tests**

In `test_main_creates_resource_test_and_coverage`, replace:

```python
    assert (tmp_path / "form_validation" / "postal_code_field.resource").is_file()
```

with:

```python
    assert (tmp_path / "src" / "robot_common_keywords" / "form_validation" / "postal_code_field.resource").is_file()
```

In `test_main_python_mode_creates_library`, replace:

```python
    library = (tmp_path / "libraries" / "postal_code_helpers.py").read_text()
```

with:

```python
    library = (tmp_path / "src" / "robot_common_keywords" / "libraries" / "postal_code_helpers.py").read_text()
```

- [ ] **Step 4: Run pytest**

```bash
cd /Users/quanuh/Projects/robotframework-common-keywords
source .venv/bin/activate
pytest tests/test_new_keyword_script.py -v
```

Expected: all tests **passed**.

- [ ] **Step 5: Commit**

```bash
git add tests/test_new_keyword_script.py
git commit -m "test: adapt new_keyword pytest fixtures to src layout"
```

---

### Task 7: Fix `scripts/generate-keyword-catalog.sh` scan paths

**Files:** Modify `scripts/generate-keyword-catalog.sh`.

- [ ] **Step 1: Replace `find` roots**

Change the `find` block from `common-keywords/form_validation` etc. to:

```bash
    find src/robot_common_keywords/form_validation \
         src/robot_common_keywords/api_validation \
         src/robot_common_keywords/ui_validation \
         src/robot_common_keywords/data_generators \
         src/robot_common_keywords/libraries \
```

- [ ] **Step 2: Fix `OUT_DIR`**

Set:

```bash
OUT_DIR="docs/keyword-catalog"
```

(remove any `common-keywords/docs/...` prefix).

- [ ] **Step 3: Fix `ROOT_DIR` depth:** the script uses `$(dirname "${BASH_SOURCE[0]}")/../..` which climbs **two** levels from `scripts/` and leaves the repo; use **one** level to the repo root.

Replace:

```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
```

with:

```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

- [ ] **Step 4: Optional dry run**

```bash
./scripts/generate-keyword-catalog.sh
```

Expected: regenerates HTML under `docs/keyword-catalog/` without `find: … No such file` errors.

- [ ] **Step 5: Commit** (include regenerated HTML if your team commits catalog artefacts)

```bash
git add scripts/generate-keyword-catalog.sh docs/keyword-catalog/
git commit -m "tooling: scan src/robot_common_keywords for keyword catalog"
```

---

### Task 8: Verify Python libraries have no bad `libraries.` imports

**Files:** read-only grep (no `from libraries` today).

- [ ] **Step 1: Grep**

```bash
grep -rn '^from libraries\|^import libraries' src/robot_common_keywords --include='*.py' || true
```

Expected: no matches.

- [ ] **Step 2:** If any appear later, convert to package-relative imports (`from robot_common_keywords.libraries.foo import …`). Current codebase: empty.

---

### Task 9: Documentation path sweep

**Files:** `PROJECT_CONTEXT.md`, `README.md`, `docs/COVERAGE.md`, `docs/INTEGRATION.md`, `docs/EXAMPLES.md`, examples inside `CHANGELOG.md`.

- [ ] **Step 1: Discover hits**

Run:

```bash
grep -rn 'form_validation/\|api_validation/\|ui_validation/\|data_generators/\|libraries/\|test_data/' \
  --include='*.md' --include='*.toml' --include='*.sh' pyproject.toml README.md docs PROJECT_CONTEXT.md CHANGELOG.md 2>/dev/null | head -80
```

- [ ] **Step 2:** For each hit **outside** `src/robot_common_keywords/`, update prose to reference:

  - on-disk paths as `src/robot_common_keywords/...`, and/or
  - installed usage `Resource robot_common_keywords/form_validation/email_field.resource`

Update **`PROJECT_CONTEXT.md` § Module Dictionary table** paths if they show filesystem paths.

- [ ] **Step 3: Add README “Developers” snippet** one paragraph:

> Run `pip install -e .` before `robot tests/…` — self-tests import `robot_common_keywords/...`.

- [ ] **Step 4: Commit**

```bash
git add PROJECT_CONTEXT.md README.md docs CHANGELOG.md
git commit -m "docs: path examples for src layout and package imports"
```

---

### Task 10: Verification protocol (requirements spec §)

**Files:** none (commands only).

- [ ] **Step 1: Fresh editable install**

```bash
python3 -m venv .venv-verify
source .venv-verify/bin/activate
pip install -U pip
pip install -e .
```

- [ ] **Step 2: Robot dry-run — match Task 0**

```bash
robot --dryrun tests/
```

Counts must equal Task 0 `X tests / Y passed` pattern (**no new failures**).

- [ ] **Step 3: Full suite excluding network**

```bash
rm -rf results
robot -d results --exclude network tests/
```

Expect **same pass/fail pattern** as baseline (`Z failed` unchanged, ideally 0).

- [ ] **Step 4: Build artefacts**

```bash
pip install build
python -m build
```

Expected: creates `dist/*.whl` and `dist/*.tar.gz` without traceback.

- [ ] **Step 5: Tarball `.resource` count**

```bash
RES_SRC=$(find src/robot_common_keywords -name '*.resource' | wc -l | tr -d ' ')
RES_TGZ=$(tar -tzf dist/*.tar.gz | grep -E '\.resource$' | wc -l | tr -d ' ')
echo "src=$RES_SRC tarball=$RES_TGZ"
```

Expected: **`RES_SRC` equals `RES_TGZ`** (unless packaging explicitly excludes helpers — helpers `_helpers.resource` may differ; reconcile by listing tarball — adjust expectation if `_helpers.resource` deliberately excluded).

If counts mismatch, inspect tarball:

```bash
tar -tzf dist/*.tar.gz | grep '\.resource$'
```

until policy clear (all shipped `.resource` files should appear).

- [ ] **Step 6: Fresh venv smoke (wheel)**

```bash
python3 -m venv /tmp/restructure-smoke
source /tmp/restructure-smoke/bin/activate
pip install "$(ls dist/*.whl | head -1)"

python -c "import robot_common_keywords; print(robot_common_keywords.__version__)"
```

Expected: prints version (`0.1.0` today).

Write `/tmp/smoke.robot`:

```robot
*** Settings ***
Documentation    Packaging smoke — install resolves package resources/libraries.
Library          Browser
Resource         robot_common_keywords/form_validation/required_field.resource
Library          robot_common_keywords.libraries.phone_helpers

*** Test Cases ***
Smoke
    Log    Smoke OK
```

Run:

```bash
robot --dryrun /tmp/smoke.robot
```

Expected: exit code **0**.

- [ ] **Step 7: Final stale-path grep**

```bash
grep -rn 'form_validation/\|api_validation/\|ui_validation/\|data_generators/\|libraries/\|test_data/' \
  --include='*.md' --include='*.toml' --include='*.sh' --include='*.py' \
  . 2>/dev/null | grep -v '^\./src/robot_common_keywords/' | grep -v '^\./\.git/' | head -50
```

Manually classify remaining hits — each should intentionally reference old layout in historical notes or need a fix.

---

## Plan self-review

| Requirement (spec/design) | Task coverage |
|---------------------------|---------------|
| `git mv` trees + meta into `src/robot_common_keywords/` | Task 1 |
| `pyproject.toml` `find` + glob `package-data` | Task 3 |
| Internal `.resource` relative imports preserved; fix stray `../../` yaml_loader | Tasks 2 + implicit (no blanket rewrite of `.resource`) |
| Tests Option A (`robot_common_keywords/…`, `libraries` dot modules + `pip install -e`) | Tasks 4, 10 |
| `new_keyword.py` + pytest | Tasks 5–6 |
| `generate-keyword-catalog.sh` | Task 7 |
| No bad `libraries` imports in Python | Task 8 |
| Docs stale paths | Task 9 |
| Verification protocol + wheel smoke | Task 10 |
| Untracked paths not moved | Stated in inventory; **no task touches them** |

**Placeholder scan:** No TBD/TODO tasks; each step names files or shells.

**Consistency:** Package root `src/robot_common_keywords`; Robot `Library` uses `robot_common_keywords.libraries.foo` matching editable install namespace.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-09-src-layout-restructure.md`.

**Two execution options:**

1. **Subagent-driven (recommended)** — Dispatch a fresh subagent per task, review between tasks, iterate quickly (`superpowers:subagent-driven-development`).

2. **Inline execution** — Run tasks in order in one session with checkpoints (`superpowers:executing-plans`).

Which approach do you want to use?

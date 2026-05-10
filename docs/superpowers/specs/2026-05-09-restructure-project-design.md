# Design: `src/` layout + package-style test imports

**Requirements source:** [`2026-05-09-restructure-project.md`](./2026-05-09-restructure-project.md)  
**Status:** Approved decision on test import strategy (§4 below).  
**Related:** PROJECT_CONTEXT.md §§2–4; `pyproject.toml`.

---

## Purpose

Finalize how `robotframework-common-keywords` moves packaged keyword domains under **`src/robot_common_keywords/`** without changing behaviour or public keyword surface. PyPI publishing is explicitly **out of scope**.

---

## Resolved decision (formerly open)

### § Test suite `Resource` / `Library` paths — **Option A (locked)**

- Self-tests use **install-style** imports:
  - `Resource    robot_common_keywords/form_validation/email_field.resource`
  - `Library    robot_common_keywords.libraries.phone_helpers`
- Developers and CI run **`pip install -e .`** from the repo root (clean venv per verification protocol) before executing Robot against `tests/`.
- **Rationale:** Matches consumer resolution; validates packaging continuously; aligns with restructuring motivation (“on-disk matches installed path once built”).

Does **not** introduce a second parallel scheme (no `../src/...` Robot paths).

---

## Architecture

```
robotframework-common-keywords/
├── src/
│   └── robot_common_keywords/     # setuptools package root (find-packages)
│       ├── __init__.py
│       ├── __version__.py
│       ├── form_validation/
│       ├── api_validation/
│       ├── ui_validation/
│       ├── data_generators/
│       ├── libraries/
│       └── test_data/
├── tests/                           # Robot + pytest; Resource/Library → package paths
├── docs/
├── scripts/
└── pyproject.toml
```

Data flow for test execution:

1. `pip install -e .` exposes `robot_common_keywords` (and package data) on `sys.path`.
2. Robot resolves `Resource robot_common_keywords/...` via the same mechanism as downstream projects.
3. Internal `.resource` relative `Resource ../other.resource` stays valid **within** the moved tree (topology preserved).

---

## Components and change surface

| Area | Action |
|------|--------|
| Git | `git mv` of listed trees and `__init__.py` / `__version__.py` into `src/robot_common_keywords/`. |
| `pyproject.toml` | Remove explicit `packages` list and `[tool.setuptools.package-dir]`. Add `[tool.setuptools.packages.find]` with `where = ["src"]`. Replace `package-data` with glob strategy per requirements doc (`.resource`, `.yaml`, `.json`, sample files). Confirm `[tool.pytest.ini_options]` `pythonpath`: keep `scripts` for pytest-only helpers; Robot does not rely on this for package imports. |
| `tests/*.robot` | Replace `../form_validation/...` (and similar) with `robot_common_keywords/...`; update `Library` lines to `robot_common_keywords.libraries...`. |
| `tests/test_new_keyword_script.py` | Expectations for generated paths / strings must match `new_keyword.py` output and new layout. |
| `libraries/*.py` | Eliminate any `from libraries` / `import libraries` imports; use package-relative imports under `robot_common_keywords.libraries`. |
| `scripts/new_keyword.py` | Emit files under `src/robot_common_keywords/<domain>/`; stub test uses package `Resource` lines. |
| `scripts/generate-keyword-catalog.sh` | Repoint `find` roots to `src/robot_common_keywords/...` (and fix any stale `common-keywords/` prefixes if still present in-repo). Repoint `OUT_DIR` if catalog lives under `docs/` in this repo. |
| Docs | PROJECT_CONTEXT module table, COVERAGE, INTEGRATION, EXAMPLES, README — path examples reflect `src/` and install-style `Resource`. |
| Untracked exclusions | Per requirements doc: do not move browser scratch, `tests/common_testcases/`, `tests/phone_validation/`, excel tooling, etc. |

---

## Invariants (non-negotiable)

- Refactor only: no keyword-body or behaviour changes.
- `robot_common_keywords` public layout in PROJECT_CONTEXT §4 unchanged in meaning (paths in docs update to installed form).
- `_helpers.resource` remain underscore-internal; project-agnosticism gate preserved.

---

## Verification protocol

Mirror the requirements document:

1. Capture baseline: `robot --dryrun tests/` and `robot -d results --exclude network tests/` before refactors; record pass counts.
2. Implement move + config + test path updates.
3. `pip install -e .` in a clean venv.
4. Repeat Robot commands; counts must match baseline.
5. `python -m build` produces sdist + wheel.
6. Resource count in sdist matches `.resource` files under `src/robot_common_keywords/`.
7. Fresh-venv smoke: `pip install dist/*.whl`, import + `robot --dryrun` on external `smoke.robot` using package paths (as in requirements doc).
8. Stale-path grep over docs/toml/sh/py; hits must be intentional or under `src/`.

**Prerequisite call-out:** Step 4+ assume **editable install** whenever running the full `tests/` Robot suite locally (Option A).

---

## Suggested commit sequence

1. `refactor: move package source under src/robot_common_keywords/`
2. `build: simplify pyproject.toml for src layout`
3. `test: use package Resource/Library paths (pip install -e .)`
4. `tooling: update new_keyword and catalog scripts for src layout`
5. `docs: update path references`

---

## Spec self-review checklist

| Check | Result |
|-------|--------|
| Placeholders / TBD | None. |
| Internal consistency | Matches requirements doc; §4 closed on A. |
| Scope | Single focused restructure; publishing deferred. |
| Ambiguity | Clarifications only: catalog script must scan `src/robot_common_keywords/` and emit to `docs/keyword-catalog/` (this repo’s layout; drop stale `common-keywords/` roots if still in script). Playwright/Robot Browser prerequisites for full suite unchanged. |

---

## Next step

After you confirm this design doc is acceptable, use **writing-plans** to produce an ordered implementation checklist (file-by-filegrep, move order, verification gates).

# Design: Publish `robotframework-common-keywords` to PyPI

**Date:** 2026-05-10
**Status:** Approved (pending implementation plan)
**Author:** QuanUH (`quan3c10@gmail.com`)
**Repo:** `https://github.com/quan3c10/robotframework-common-keywords`

---

## 1. Goal & motivation

Publish the existing `robotframework-common-keywords` library to PyPI
so consuming Robot Framework projects can install it with
`pip install robotframework-common-keywords` and import keywords
without copy-pasting or vendoring the source.

After publish, consumers will use the public API as designed in
`PROJECT_CONTEXT.md` §2:

```robot
*** Settings ***
Resource    robot_common_keywords/form_validation/email_field.resource
Library     robot_common_keywords.libraries.phone_helpers
```

This design covers metadata polish, build verification, account &
token setup, the TestPyPI-then-PyPI upload workflow, and the recurring
release loop. CI/Trusted-Publishing automation is **out of scope** —
deferred to a follow-up cycle once the manual workflow is proven.

The `src/` layout restructure (prerequisite) is already done —
`src/robot_common_keywords/` exists with all six domain directories,
`pyproject.toml` uses `[tool.setuptools.packages.find] where = ["src"]`.

## 2. Scope

### In scope

- Update `pyproject.toml` author block & add `[project.urls]`
- Adopt dynamic versioning (single source of truth in `__version__.py`)
- Edit README "Installation" section to lead with `pip install`
- Add PyPI version badge to README
- Make GitHub repo public (external action by user)
- Add a `scripts/build-and-verify.sh` for repeatable local builds
- Add a `scripts/publish.sh` for the TestPyPI → PyPI upload sequence
- Document the build → verify → publish → tag → release flow
- Document token rotation (account-scoped → project-scoped) post-first-publish
- Document the re-release loop for future versions

### Out of scope

- GitHub Actions / Trusted Publishing automation (next cycle)
- Adding new keywords or features
- Restructuring the `src/` layout (already done in a prior cycle)
- Modifying any keyword bodies, public API names, or test files
- Migrating untracked work directories (`browser/`, `tests/common_testcases/`,
  `tests/phone_validation/`, `scripts/excel_to_markdown.py`,
  `scripts/run-excel-to-markdown.sh`, `playwright-log.txt`,
  `docs/EXCEL_TO_MARKDOWN.md`)

## 3. Decisions log

| Decision | Choice | Rationale |
|---|---|---|
| Import pattern for consumers | `Resource` for `.resource` files **and** `Library` for Python `@keyword` modules | Matches PROJECT_CONTEXT §2 design; no `__init__.py` re-exports needed (Robot Framework imports modules by dotted path, not via `__init__`) |
| Repo visibility | Make public before first upload | PyPI page links to `Repository` URL; private 404s look broken to consumers |
| Workflow shape | Manual TestPyPI → PyPI from laptop, documented as shell scripts | First-publish risk is small; CI complexity is unjustified until release cadence increases |
| First-publish tokens | Account-scoped, then rotate to project-scoped after publish | Project doesn't exist on either index until first upload; can only narrow scope post-publish |
| Token storage | `~/.pypirc` mode 600 | Simpler than env vars for a solo laptop workflow; survives shell restart |
| Versioning | Dynamic — `pyproject.toml` reads from `__version__.py` | Single source of truth; eliminates the two-place-bump footgun |
| README scope | Edit Installation section only | Minimize churn; existing usage examples and architecture docs still apply |
| Layout | `src/` layout (already in place) | Standard, lets `setuptools` auto-discovery work, on-disk path matches install path |
| Author identity | `QuanUH <quan3c10@gmail.com>` | User-provided |
| Package name on PyPI | `robotframework-common-keywords` | Matches RF community convention (e.g., `robotframework-browser`); already configured; verified available on both PyPI and TestPyPI (HTTP 404 on `/pypi/.../json`) |

## 4. Workflow shape

The publish pipeline has five sections, executed sequentially the
first time and re-run for every subsequent release:

| # | Section | One-line summary |
|---|---|---|
| A | Metadata & repo prep | `pyproject.toml` updates; README install rewrite; make repo public |
| B | Build & local verification | `scripts/build-and-verify.sh` — clean, build, inspect, smoke-test in fresh venv |
| C | Accounts & API tokens | PyPI + TestPyPI accounts, 2FA, account-scoped tokens, `~/.pypirc` |
| D | TestPyPI → PyPI upload | `scripts/publish.sh` — upload to TestPyPI, install + smoke, upload to PyPI, install + smoke |
| E | Post-publish & re-release loop | Tag, GitHub release, rotate to project-scoped tokens, document the bump-and-republish loop, yanking |

## 5. Section A — Metadata & repo prep

### A1. `pyproject.toml` — author + URLs + dynamic version

Replace author placeholder:

```diff
 authors = [
-    { name = "Keyword-Driven Framework PoC" },
+    { name = "QuanUH", email = "quan3c10@gmail.com" },
 ]
```

Switch to dynamic versioning. Replace the static `version = "0.1.0"`
line with `dynamic = ["version"]` and add a `[tool.setuptools.dynamic]`
table:

```toml
[project]
# version removed from here
dynamic = ["version"]

[tool.setuptools.dynamic]
version = { attr = "robot_common_keywords.__version__" }
```

Add a `[project.urls]` section after `classifiers`:

```toml
[project.urls]
Homepage   = "https://github.com/quan3c10/robotframework-common-keywords"
Repository = "https://github.com/quan3c10/robotframework-common-keywords"
Issues     = "https://github.com/quan3c10/robotframework-common-keywords/issues"
Changelog  = "https://github.com/quan3c10/robotframework-common-keywords/blob/main/CHANGELOG.md"
```

### A2. README — Installation section rewrite

Edit the existing "Installation" section (only this section — leave
the rest of the README intact). Lead with `pip install`:

```markdown
## Installation

```bash
pip install robotframework-common-keywords
```

For pre-release / development installs, point pip at a Git ref:

```bash
pip install git+https://github.com/quan3c10/robotframework-common-keywords.git
```
```

Drop the placeholder `yourcompany/robot-common-keywords` reference and
the "Option A submodule" / "Option B pip install" framing.

Confirm the existing usage example shows both import patterns (it
already does — verified during exploration).

### A3. README — PyPI version badge

Add at the very top of the README (above the title or just under it):

```markdown
[![PyPI](https://img.shields.io/pypi/v/robotframework-common-keywords)](https://pypi.org/project/robotframework-common-keywords/)
[![Python](https://img.shields.io/pypi/pyversions/robotframework-common-keywords)](https://pypi.org/project/robotframework-common-keywords/)
```

The badges show "no version" until first publish, then auto-populate.

### A4. Make GitHub repo public (external action)

Before any `twine upload`: GitHub repo Settings → "Change repository
visibility" → Public. Doing this before publish ensures the URLs in
`pyproject.toml` resolve immediately when consumers visit the PyPI
page.

## 6. Section B — Build & local verification

Codified as `scripts/build-and-verify.sh`. The script must be
idempotent (safe to re-run) and must fail loudly if any step's check
returns a wrong count.

### B1. Pre-build cleanup

```bash
rm -rf dist/ build/ src/*.egg-info/ *.egg-info/
```

### B2. Ensure build tooling

```bash
python -m pip install --upgrade build twine
```

### B3. Build

```bash
python -m build
```

Produces `dist/robotframework_common_keywords-X.Y.Z.tar.gz` and
`dist/robotframework_common_keywords-X.Y.Z-py3-none-any.whl`.

### B4. Inspect contents

Three checks; each must pass:

1. **`.resource` count parity**: count `.resource` files in source vs
   in wheel. If they differ, `package-data` glob is wrong.
   ```bash
   src_count=$(find src/robot_common_keywords -name '*.resource' | wc -l)
   whl_count=$(unzip -l dist/*.whl | grep -c '\.resource$')
   [ "$src_count" -eq "$whl_count" ] || { echo "FAIL: resource count $whl_count != $src_count"; exit 1; }
   ```

2. **YAML/JSON included**: every `test_data/**/*.yaml` and
   `test_data/**/*.json` must be in the wheel.

3. **`twine check`**: `twine check dist/*` returns `PASSED` for both
   files.

### B5. Smoke test in fresh venv

```bash
python -m venv /tmp/rck-smoke
source /tmp/rck-smoke/bin/activate
pip install dist/*.whl
python -c "import robot_common_keywords; print(robot_common_keywords.__version__)"
```

Then a tiny `/tmp/smoke.robot`:

```robot
*** Settings ***
Resource    robot_common_keywords/form_validation/required_field.resource
Library     robot_common_keywords.libraries.phone_helpers

*** Test Cases ***
Smoke
    Log    Smoke OK
```

```bash
robot --dryrun /tmp/smoke.robot
deactivate
rm -rf /tmp/rck-smoke /tmp/smoke.robot
```

`robot --dryrun` exit 0 → wheel install path works end-to-end.

## 7. Section C — Accounts & API tokens

User has accounts on both PyPI and TestPyPI; 2FA must be enabled on
both before upload (PyPI requires it for uploads since 2024).

### C1. Generate account-scoped tokens (bootstrap)

For first publish, project doesn't exist yet, so account-scoped tokens
are required.

On each service:
- Account Settings → "API tokens" → "Add API token"
- Name: `robotframework-common-keywords-bootstrap`
- Scope: "Entire account"
- Copy the `pypi-...` token immediately (shown once)

Result: two tokens — one PyPI, one TestPyPI.

### C2. Configure `~/.pypirc`

Mode 600. Contents:

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-<your-pypi-token>

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-<your-testpypi-token>
```

```bash
chmod 600 ~/.pypirc
```

The literal string `__token__` is correct — it tells PyPI to use
token auth.

## 8. Section D — TestPyPI → PyPI upload

Codified as `scripts/publish.sh`. The script is **destructive**
(uploads are irreversible) and must require explicit confirmation
before the PyPI upload step.

> **Irreversibility:** Once a version is uploaded to PyPI, it cannot
> be overwritten or re-uploaded — only **yanked** (hidden from default
> resolution but still installable for existing pins). To replace a
> bad release, bump to a new version. TestPyPI eventually wipes old
> uploads, so don't rely on it as durable storage.

### D1. Pre-flight

`scripts/publish.sh` must check that `dist/` contains a recent build
matching the current `__version__.py`. If not, exit and tell the user
to run `scripts/build-and-verify.sh` first.

### D2. Upload to TestPyPI

```bash
twine upload --repository testpypi dist/*
```

Expected: progress bar, then the
`https://test.pypi.org/project/robotframework-common-keywords/X.Y.Z/`
URL. Failure modes: `403` (token wrong / no 2FA), `400 File already
exists` (re-upload of existing version — bump and rebuild).

### D3. Manual verification of TestPyPI page

User opens the URL and confirms:
- README renders
- Project links sidebar shows Homepage / Repository / Issues / Changelog
- Author = QuanUH
- Both `.tar.gz` and `.whl` listed under "Files"

If anything wrong: don't proceed. Bump to `X.Y.Za1` (alpha — TestPyPI
won't let you re-upload `X.Y.Z`), fix, rebuild, re-upload to TestPyPI.

### D4. Install from TestPyPI in fresh venv

TestPyPI doesn't host the runtime deps (`robotframework`, `faker`,
etc.). They live on real PyPI. So both indices required:

```bash
python -m venv /tmp/rck-testpypi
source /tmp/rck-testpypi/bin/activate
pip install \
    --index-url https://test.pypi.org/simple/ \
    --extra-index-url https://pypi.org/simple/ \
    robotframework-common-keywords==X.Y.Z
```

### D5. Smoke test against TestPyPI install

Same `/tmp/smoke.robot` as B5. `robot --dryrun` must exit 0.

```bash
deactivate && rm -rf /tmp/rck-testpypi
```

### D6. Upload to PyPI (with explicit confirmation)

`scripts/publish.sh` prompts: "About to upload to **production
PyPI**. This is irreversible. Confirm? [y/N]". Only on `y`:

```bash
twine upload dist/*
```

(No `--repository` flag → defaults to PyPI.)

Expected URL: `https://pypi.org/project/robotframework-common-keywords/X.Y.Z/`.

### D7. Verify PyPI page

Same checks as D3 against real PyPI URL.

### D8. Final smoke test against PyPI install

```bash
python -m venv /tmp/rck-pypi
source /tmp/rck-pypi/bin/activate
pip install robotframework-common-keywords==X.Y.Z
robot --dryrun /tmp/smoke.robot
deactivate && rm -rf /tmp/rck-pypi
```

If this exits 0, the package is shipped.

## 9. Section E — Post-publish & re-release loop

### E1. Tag and GitHub release

```bash
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin vX.Y.Z
```

On GitHub: Releases → "Draft a new release" → choose tag `vX.Y.Z` →
paste the relevant `CHANGELOG.md` section as the body.

### E2. Rotate to project-scoped tokens (one-time, after first publish)

Now that the project exists on both indices:
1. PyPI Account Settings → API tokens → "Add API token" → scope =
   "Project: robotframework-common-keywords" → name
   `robotframework-common-keywords-prod`
2. Update `~/.pypirc` `[pypi].password` to the new token
3. Delete the old `robotframework-common-keywords-bootstrap`
   (account-scoped) token from PyPI
4. Repeat all four steps for TestPyPI

### E3. Update CHANGELOG

Move the just-released version's entries from "Unreleased" to a
date-stamped section. Standard Keep-a-Changelog convention; the
existing `CHANGELOG.md` already follows it.

### E4. Re-release loop (for `0.1.1`, `0.2.0`, ...)

1. Land all changes on `main` via PRs
2. Bump `src/robot_common_keywords/__version__.py` (only one place to
   edit, thanks to dynamic versioning from §5.A1)
3. Update `CHANGELOG.md` — move "Unreleased" entries under the new
   version with today's date
4. Commit: `git commit -m "release: X.Y.Z"`
5. Run `scripts/build-and-verify.sh`
6. Run `scripts/publish.sh` (prompts for confirmation before PyPI)
7. Tag and GitHub release (E1)

### E5. Yanking a bad release (safety net)

If a release ships broken: PyPI project page → Manage → Releases →
X.Y.Z → "Yank". Yanked versions stay installable for existing pins
but `pip install robotframework-common-keywords` (no version) skips
them. Bump to X.Y.(Z+1), fix, re-publish, then yank X.Y.Z.

## 10. Verification protocol

The publish is "done" when all of the following hold:

1. `https://pypi.org/project/robotframework-common-keywords/0.1.0/`
   loads and renders correctly (README, links, author, files).
2. In a fresh venv on a clean machine, `pip install
   robotframework-common-keywords==0.1.0` succeeds, all runtime deps
   resolve, and `robot --dryrun /tmp/smoke.robot` (the canonical
   smoke test) exits 0.
3. The PyPI version badge in the repo README shows `0.1.0` (auto-pulled
   from PyPI within minutes).
4. Git tag `v0.1.0` exists locally and on `origin`.
5. GitHub release page for `v0.1.0` shows the changelog body.
6. `~/.pypirc` references project-scoped tokens (E2 done).
7. `robot_common_keywords/__version__.py` is the only place version
   is declared (no `version = "..."` in `pyproject.toml`).

## 11. Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Wrong `package-data` glob → `.resource` files missing from wheel | Medium | Section B4 check 1 (resource count parity) catches this before any upload |
| Metadata wrong (description, classifiers) → ugly PyPI page | Low | `twine check` (B4) + manual TestPyPI page review (D3) before PyPI |
| Bad release reaches PyPI under final version number | Low | TestPyPI dry run (D2–D5) catches install-path bugs; explicit confirmation (D6) on PyPI upload |
| Token leak | Low | Project-scoped rotation (E2) limits blast radius after first publish |
| Two-place version bump goes stale | High (without dynamic) | Adopt dynamic versioning (§5.A1) so `__version__.py` is the only source |
| TestPyPI version `0.1.0` burned by mistake before PyPI | Medium | If `0.1.0` is on TestPyPI but you want to re-test, bump to `0.1.0a1` for the next TestPyPI cycle and reserve `0.1.0` for the actual PyPI release; or accept and move directly to PyPI if you've already validated |
| Repo public exposes secrets accidentally | Low | Audit before flipping visibility — `git log -p` for `.env`, tokens, etc.; no `~/.pypirc` is tracked (it's outside the repo) |

## 12. Implementation file map

The plan that follows this spec will touch these files:

| File | Change |
|---|---|
| `pyproject.toml` | Author block, `[project.urls]`, dynamic version |
| `README.md` | Installation section rewrite, badges at top |
| `scripts/build-and-verify.sh` | New file — codifies §6 |
| `scripts/publish.sh` | New file — codifies §8 with confirmation gate |
| `~/.pypirc` (user's home, not repo) | New file — token storage (manual step) |
| `CHANGELOG.md` | Date-stamp the 0.1.0 section after release |
| `src/robot_common_keywords/__version__.py` | (Untouched for 0.1.0; bumped for future releases) |
| GitHub repo settings | Visibility → Public (manual step) |

No `MANIFEST.in` needed — `package-data` globs cover everything.
No changes to keyword `.resource` files, Python `libraries/`, tests,
or `PROJECT_CONTEXT.md`.

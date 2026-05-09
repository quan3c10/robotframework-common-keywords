# PROJECT_CONTEXT.md + new_keyword.py Scaffolder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a single self-documenting `PROJECT_CONTEXT.md` at the repo root (architecture, conventions, module dictionary, workflow, extensibility rules) plus a Python scaffolder `scripts/new_keyword.py` (with pytest coverage) that mechanically reproduces the "create a new keyword" workflow described in the doc.

**Architecture:** Pure additions — one Markdown doc, one Python script, one pytest file, and a small `pyproject.toml` dev-dep update. No existing files change behavior. The scaffolder uses argparse + triple-quoted templates inside the script itself (no separate template files); it is TDD'd one render-function at a time.

**Tech Stack:** Python 3.10+, argparse (stdlib), pytest (added as dev dep), Robot Framework (only for the smoke test of generated output).

**Spec:** `docs/superpowers/specs/2026-05-09-project-context-design.md`

---

## File Structure

| Path | Status | Responsibility |
|---|---|---|
| `pyproject.toml` | modify | Add `pytest>=7.0` to `[project.optional-dependencies] dev` |
| `scripts/new_keyword.py` | create | CLI scaffolder — renders `.resource` (default) or Python `@keyword` (`--python`) keyword files plus self-test stub; appends placeholder COVERAGE row; refuses to overwrite |
| `tests/test_new_keyword_script.py` | create | Pytest suite covering each render function and `main()` end-to-end against `tmp_path` |
| `PROJECT_CONTEXT.md` | create | Six-section authoritative architecture & contribution doc, with AI-assistant callout |

The scaffolder is intentionally a single file. Render functions live as module-level `def`s; templates as module-level constants. `main()` is the only entry point that touches the filesystem.

---

## Task 1: Add `pytest` to dev dependencies

**Files:**
- Modify: `pyproject.toml`

- [ ] **Step 1: Update `[project.optional-dependencies] dev`**

Open `pyproject.toml`. Find the `dev = [...]` block (currently lines 44–47). Add `"pytest>=7.0",` to the list. After the change it should read:

```toml
[project.optional-dependencies]
dev = [
    "robotframework-pabot>=4.0",
    "robotframework-datadriver>=1.11",
    "pytest>=7.0",
]
```

- [ ] **Step 2: Install the dev extra into the local venv**

Run:
```bash
source .venv/bin/activate
pip install -e ".[dev]"
```
Expected: pytest installs without error. Run `pytest --version` to confirm.

- [ ] **Step 3: Commit**

```bash
git add pyproject.toml
git commit -m "build: add pytest to dev dependencies"
```

---

## Task 2: Scaffolder — render the `.resource` keyword template

TDD: write the failing test for `render_resource()` first, then the minimal template constant + function.

**Files:**
- Create: `scripts/new_keyword.py`
- Create: `tests/test_new_keyword_script.py`

- [ ] **Step 1: Write the failing test**

Create `tests/test_new_keyword_script.py`:

```python
"""Pytest coverage for scripts/new_keyword.py.

This is the only Python unit test in the repo (other tests are Robot
self-tests). pytest is used here to avoid pulling the Browser stack into
a file-generator test.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import new_keyword  # noqa: E402


def test_render_resource_substitutes_name_module_and_domain():
    rendered = new_keyword.render_resource(
        name="Validate Postal Code Field",
        module="postal_code_field",
        domain="form_validation",
    )
    assert "Validate Postal Code Field" in rendered
    assert "*** Keywords ***" in rendered
    assert "[Documentation]" in rendered
    assert "[Arguments]    ${field_locator}" in rendered
    assert "TODO(new_keyword.py)" in rendered
    # Settings imports the internal helpers and Browser library.
    assert "Library          Browser" in rendered
    assert "Resource         _helpers.resource" in rendered
```

- [ ] **Step 2: Run test to verify it fails**

```bash
pytest tests/test_new_keyword_script.py::test_render_resource_substitutes_name_module_and_domain -v
```
Expected: `ModuleNotFoundError: No module named 'new_keyword'` (FAIL).

- [ ] **Step 3: Write minimal implementation**

Create `scripts/new_keyword.py`:

```python
"""Scaffolder for new common-keywords.

Generates `.resource` (default) or Python `@keyword` (`--python`) keyword
files plus a self-test stub, and appends a placeholder row to
docs/COVERAGE.md.

See PROJECT_CONTEXT.md §5.2 for the manual checklist that follows the
scaffold.
"""

from __future__ import annotations


_RESOURCE_TEMPLATE = """\
*** Settings ***
Documentation    {name}. TODO(new_keyword.py): one-line summary of what
...              this keyword validates.
Library          Browser
Resource         _helpers.resource


*** Keywords ***
{name}
    [Documentation]    TODO(new_keyword.py): describe what is checked.
    ...                When composing multiple checks, list them in a
    ...                numbered sequence.
    ...
    ...                Arguments:
    ...                - ``field_locator``  — Playwright selector of the input.
    ...                - ``error_message``  — substring of the visible error text.
    ...                - ``error_locator``  — optional selector for the error element.
    ...                - ``trigger``        — ``blur`` (default) or ``submit``.
    ...                - ``submit_locator`` — required when ``trigger=submit``.
    [Arguments]    ${{field_locator}}
    ...            ${{error_message}}=TODO(new_keyword.py): default error text
    ...            ${{error_locator}}=${{EMPTY}}
    ...            ${{trigger}}=blur
    ...            ${{submit_locator}}=${{EMPTY}}

    # TODO(new_keyword.py): replace this body with the validation steps.
    Fill Text    ${{field_locator}}    ${{EMPTY}}
    Trigger Field Validation    ${{field_locator}}    ${{trigger}}    ${{submit_locator}}
    Validation Error Should Be Visible
    ...    error_message=${{error_message}}
    ...    error_locator=${{error_locator}}
"""


def render_resource(name: str, module: str, domain: str) -> str:
    """Return the body of a new <domain>/<module>.resource file."""
    return _RESOURCE_TEMPLATE.format(name=name, module=module, domain=domain)
```

Note the doubled `{{ }}` in the template to escape Robot's `${...}` syntax against `str.format`.

- [ ] **Step 4: Run test to verify it passes**

```bash
pytest tests/test_new_keyword_script.py::test_render_resource_substitutes_name_module_and_domain -v
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/new_keyword.py tests/test_new_keyword_script.py
git commit -m "feat(scaffolder): render .resource keyword template"
```

---

## Task 3: Scaffolder — render the self-test stub

- [ ] **Step 1: Write the failing test**

Append to `tests/test_new_keyword_script.py`:

```python
def test_render_self_test_links_back_to_module_under_test():
    rendered = new_keyword.render_self_test(
        name="Validate Postal Code Field",
        module="postal_code_field",
        domain="form_validation",
    )
    assert "../form_validation/postal_code_field.resource" in rendered
    assert "Validate Postal Code Field Smoke" in rendered
    assert "fixtures/text_form.html" in rendered
    assert "Set Up Browser" in rendered
    assert "TODO(new_keyword.py)" in rendered
    # Stub must fail until edited — protects against silently-passing tests.
    assert "Fail    TODO(new_keyword.py)" in rendered
```

- [ ] **Step 2: Run test to verify it fails**

```bash
pytest tests/test_new_keyword_script.py::test_render_self_test_links_back_to_module_under_test -v
```
Expected: FAIL — `AttributeError: module 'new_keyword' has no attribute 'render_self_test'`.

- [ ] **Step 3: Write minimal implementation**

Append to `scripts/new_keyword.py` (after `_RESOURCE_TEMPLATE` and before `render_resource`):

```python
_SELF_TEST_TEMPLATE = """\
*** Settings ***
Documentation    Self-test for {name}. TODO(new_keyword.py): describe
...              the fixture interaction this exercises.
Library          Browser
Resource         ../{domain}/{module}.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${{FIXTURE_URL}}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${{True}}


*** Variables ***
${{BROWSER}}        chromium
${{HEADLESS}}       ${{True}}
${{FIXTURE_URL}}    file://${{CURDIR}}/fixtures/text_form.html


*** Test Cases ***
{name} Smoke
    [Tags]    todo    {domain}
    # TODO(new_keyword.py): call {name} with a fixture-appropriate selector.
    Fail    TODO(new_keyword.py): replace this stub with a real assertion.


*** Keywords ***
Set Up Browser
    New Browser    browser=${{BROWSER}}    headless=${{HEADLESS}}
    New Context
    New Page
"""
```

Then add the function (after `render_resource`):

```python
def render_self_test(name: str, module: str, domain: str) -> str:
    """Return the body of a new tests/test_<module>.robot self-test stub."""
    return _SELF_TEST_TEMPLATE.format(name=name, module=module, domain=domain)
```

- [ ] **Step 4: Run test to verify it passes**

```bash
pytest tests/test_new_keyword_script.py::test_render_self_test_links_back_to_module_under_test -v
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/new_keyword.py tests/test_new_keyword_script.py
git commit -m "feat(scaffolder): render Robot self-test stub"
```

---

## Task 4: Scaffolder — render the Python `@keyword` library template

- [ ] **Step 1: Write the failing test**

Append to `tests/test_new_keyword_script.py`:

```python
def test_render_python_library_uses_keyword_decorator():
    rendered = new_keyword.render_python_library(
        name="Compute Postal Code Region",
        module="postal_code_helpers",
    )
    # Decorator preserves the human keyword name.
    assert '@keyword("Compute Postal Code Region")' in rendered
    # Function name is snake_case derived from the keyword name.
    assert "def compute_postal_code_region(" in rendered
    # Mandatory module-level scaffolding.
    assert 'ROBOT_LIBRARY_SCOPE = "GLOBAL"' in rendered
    assert "from robot.api.deco import keyword" in rendered
    # Stub raises until edited.
    assert "raise NotImplementedError" in rendered
    assert "TODO(new_keyword.py)" in rendered


def test_python_function_name_lowercases_and_underscores_keyword_name():
    # Internal helper exposed for the renderer.
    assert new_keyword.keyword_to_function_name("Validate Email Field") == "validate_email_field"
    assert new_keyword.keyword_to_function_name("Response Status Should Be") == "response_status_should_be"
    # Already-snake input must round-trip cleanly.
    assert new_keyword.keyword_to_function_name("foo bar") == "foo_bar"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
pytest tests/test_new_keyword_script.py -v -k "python_library or function_name"
```
Expected: FAIL — both `render_python_library` and `keyword_to_function_name` missing.

- [ ] **Step 3: Write minimal implementation**

Append to `scripts/new_keyword.py`:

```python
_PYTHON_LIBRARY_TEMPLATE = '''\
"""TODO(new_keyword.py): one-line module description."""

from __future__ import annotations

from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"


@keyword("{name}")
def {func_name}() -> None:
    """TODO(new_keyword.py): describe what this keyword returns or does.

    Predicate keywords (``Is X``, ``Has X``) should return ``False`` on
    bad input rather than raising. Imperative keywords (``Format X``,
    ``Compute X``) may raise; let the underlying library exception
    propagate rather than swallowing it.
    """
    raise NotImplementedError("TODO(new_keyword.py)")
'''


def keyword_to_function_name(name: str) -> str:
    """Convert a Title Case keyword name to a snake_case function name."""
    return "_".join(token.lower() for token in name.split())


def render_python_library(name: str, module: str) -> str:
    """Return the body of a new libraries/<module>.py file."""
    return _PYTHON_LIBRARY_TEMPLATE.format(
        name=name,
        func_name=keyword_to_function_name(name),
    )
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/test_new_keyword_script.py -v
```
Expected: 4 PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/new_keyword.py tests/test_new_keyword_script.py
git commit -m "feat(scaffolder): render Python @keyword library template"
```

---

## Task 5: Scaffolder — append a placeholder COVERAGE row

- [ ] **Step 1: Write the failing test**

Append to `tests/test_new_keyword_script.py`:

```python
def test_coverage_row_format():
    row = new_keyword.coverage_row(
        name="Validate Postal Code Field",
        module="postal_code_field",
    )
    # Markdown table row, terminating newline.
    assert row.endswith("\n")
    assert row.startswith("| `Validate Postal Code Field` |")
    assert "test_postal_code_field.robot" in row
    assert "TODO" in row


def test_append_coverage_row_appends_to_existing_file(tmp_path):
    coverage = tmp_path / "COVERAGE.md"
    coverage.write_text("# Coverage\n\n| Keyword | Test | Coverage |\n|---|---|---|\n")
    new_keyword.append_coverage_row(
        coverage_path=coverage,
        name="Validate Postal Code Field",
        module="postal_code_field",
    )
    contents = coverage.read_text()
    assert contents.count("Validate Postal Code Field") == 1
    assert contents.endswith("\n")
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_new_keyword_script.py -v -k "coverage"
```
Expected: FAIL — `coverage_row` and `append_coverage_row` missing.

- [ ] **Step 3: Write minimal implementation**

Add the `Path` import at the top of `scripts/new_keyword.py` (in the imports section, after `from __future__ import annotations`):

```python
from pathlib import Path
```

Then append these functions to the end of `scripts/new_keyword.py`:

```python
def coverage_row(name: str, module: str) -> str:
    """Return a single Markdown table row to append to docs/COVERAGE.md."""
    return f"| `{name}` | `test_{module}.robot` (TODO) | TODO |\n"


def append_coverage_row(coverage_path: Path, name: str, module: str) -> None:
    """Append a placeholder row to the given COVERAGE.md path.

    Idempotent only via filesystem state — call sites are responsible for
    not double-invoking. The scaffolder's overwrite check (Task 6)
    guards against re-running on the same module.
    """
    row = coverage_row(name=name, module=module)
    with coverage_path.open("a", encoding="utf-8") as fp:
        fp.write(row)
```

(Move the `from pathlib import Path` to the top of the file with the other imports.)

- [ ] **Step 4: Run tests to verify they pass**

```bash
pytest tests/test_new_keyword_script.py -v
```
Expected: 6 PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/new_keyword.py tests/test_new_keyword_script.py
git commit -m "feat(scaffolder): append placeholder COVERAGE row"
```

---

## Task 6: Scaffolder — `main()` with argparse, file writes, refuse-overwrite

- [ ] **Step 1: Write the failing tests**

Add `import subprocess` and `from pathlib import Path` to the imports
section at the top of `tests/test_new_keyword_script.py` (alongside
the existing `import sys` / `from pathlib import Path`; deduplicate if
needed). Then append these helpers and tests to the end of the file:

```python
def _run_scaffolder(repo_root: Path, *args: str) -> subprocess.CompletedProcess:
    """Invoke scripts/new_keyword.py inside ``repo_root`` as cwd."""
    return subprocess.run(
        [sys.executable, str(REPO_ROOT / "scripts" / "new_keyword.py"), *args],
        cwd=repo_root,
        capture_output=True,
        text=True,
    )


def _seed_minimal_layout(repo_root: Path) -> None:
    (repo_root / "form_validation").mkdir()
    (repo_root / "libraries").mkdir()
    (repo_root / "tests").mkdir()
    (repo_root / "docs").mkdir()
    (repo_root / "docs" / "COVERAGE.md").write_text(
        "# Coverage\n\n| Keyword | Test | Coverage |\n|---|---|---|\n"
    )


def test_main_creates_resource_test_and_coverage(tmp_path):
    _seed_minimal_layout(tmp_path)
    result = _run_scaffolder(
        tmp_path,
        "--domain", "form_validation",
        "--name", "Validate Postal Code Field",
        "--module", "postal_code_field",
    )
    assert result.returncode == 0, result.stderr
    assert (tmp_path / "form_validation" / "postal_code_field.resource").is_file()
    assert (tmp_path / "tests" / "test_postal_code_field.robot").is_file()
    coverage = (tmp_path / "docs" / "COVERAGE.md").read_text()
    assert "Validate Postal Code Field" in coverage
    # Manual checklist printed to stdout.
    assert "TODO" in result.stdout


def test_main_refuses_to_overwrite(tmp_path):
    _seed_minimal_layout(tmp_path)
    args = (
        "--domain", "form_validation",
        "--name", "Validate Postal Code Field",
        "--module", "postal_code_field",
    )
    first = _run_scaffolder(tmp_path, *args)
    assert first.returncode == 0
    second = _run_scaffolder(tmp_path, *args)
    assert second.returncode != 0
    assert "exists" in second.stderr.lower()


def test_main_python_mode_creates_library(tmp_path):
    _seed_minimal_layout(tmp_path)
    result = _run_scaffolder(
        tmp_path,
        "--domain", "form_validation",
        "--name", "Compute Postal Code Region",
        "--module", "postal_code_helpers",
        "--python",
    )
    assert result.returncode == 0, result.stderr
    library = (tmp_path / "libraries" / "postal_code_helpers.py").read_text()
    assert '@keyword("Compute Postal Code Region")' in library
    # Python mode skips the Robot self-test stub but prints a reminder.
    assert not (tmp_path / "tests" / "test_postal_code_helpers.robot").exists()
    assert "consuming" in result.stdout.lower() or "test" in result.stdout.lower()


def test_main_rejects_unknown_domain(tmp_path):
    _seed_minimal_layout(tmp_path)
    result = _run_scaffolder(
        tmp_path,
        "--domain", "not_a_real_domain",
        "--name", "Foo",
        "--module", "foo",
    )
    assert result.returncode != 0
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
pytest tests/test_new_keyword_script.py -v -k "main_"
```
Expected: FAIL — script has no `if __name__ == "__main__"` entry yet.

- [ ] **Step 3: Write minimal implementation**

Add these imports at the top of `scripts/new_keyword.py`, alongside the
existing `from pathlib import Path`:

```python
import argparse
import sys
from typing import Sequence
```

Then append to the end of `scripts/new_keyword.py`:

```python
_DOMAINS = ("form_validation", "api_validation", "ui_validation", "data_generators")


def _checklist(domain: str, module: str, python_mode: bool) -> str:
    """Return the manual checklist printed after a successful scaffold."""
    if python_mode:
        return (
            f"\nScaffolded libraries/{module}.py.\n"
            "Next steps:\n"
            "  1. Replace TODO(new_keyword.py) markers with real implementation.\n"
            "  2. Add coverage in the consuming .resource file's self-test\n"
            "     (Python @keyword libraries are tested transitively).\n"
            "  3. Update docs/COVERAGE.md row with the actual self-test name.\n"
            "  4. Regenerate libdoc: ./scripts/generate-keyword-catalog.sh\n"
        )
    return (
        f"\nScaffolded {domain}/{module}.resource and tests/test_{module}.robot.\n"
        "Next steps:\n"
        "  1. Replace TODO(new_keyword.py) markers in Documentation, Arguments, body.\n"
        "  2. Add YAML test data under test_data/ if needed.\n"
        f"  3. Run dryrun: robot --dryrun tests/test_{module}.robot\n"
        "  4. Implement the keyword body until the self-test passes.\n"
        f"  5. Run full suite: robot -d results --exclude network tests/\n"
        "  6. Regenerate libdoc: ./scripts/generate-keyword-catalog.sh\n"
        "  7. Update docs/COVERAGE.md row with the actual self-test name.\n"
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Scaffold a new common-keyword (.resource by default, "
                    "or Python @keyword library with --python).",
    )
    parser.add_argument("--domain", required=True, choices=_DOMAINS)
    parser.add_argument("--name", required=True,
                        help='Title-Case keyword name, e.g. "Validate Postal Code Field"')
    parser.add_argument("--module", required=True,
                        help="snake_case basename (no extension), e.g. postal_code_field")
    parser.add_argument("--python", action="store_true",
                        help="Generate a Python @keyword library under libraries/ "
                             "instead of a .resource file.")
    args = parser.parse_args(argv)

    cwd = Path.cwd()
    coverage_path = cwd / "docs" / "COVERAGE.md"

    if args.python:
        target = cwd / "libraries" / f"{args.module}.py"
        if target.exists():
            print(f"error: {target} already exists; refusing to overwrite.",
                  file=sys.stderr)
            return 1
        target.write_text(render_python_library(name=args.name, module=args.module))
    else:
        resource = cwd / args.domain / f"{args.module}.resource"
        self_test = cwd / "tests" / f"test_{args.module}.robot"
        if resource.exists() or self_test.exists():
            print(f"error: {resource} or {self_test} already exists; "
                  "refusing to overwrite.", file=sys.stderr)
            return 1
        resource.write_text(render_resource(
            name=args.name, module=args.module, domain=args.domain))
        self_test.write_text(render_self_test(
            name=args.name, module=args.module, domain=args.domain))

    if coverage_path.exists():
        append_coverage_row(coverage_path=coverage_path,
                            name=args.name, module=args.module)

    print(_checklist(domain=args.domain, module=args.module,
                     python_mode=args.python))
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run all tests to verify they pass**

```bash
pytest tests/test_new_keyword_script.py -v
```
Expected: 10 PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/new_keyword.py tests/test_new_keyword_script.py
git commit -m "feat(scaffolder): main() with argparse, file writes, overwrite guard"
```

---

## Task 7: Smoke run — scaffold a real keyword, verify dryrun, revert

This step proves the scaffolder works against the real repo layout, not just a tmp_path. Output is reverted at the end so the repo stays clean.

- [ ] **Step 1: Run the scaffolder against the real form_validation directory**

```bash
python scripts/new_keyword.py \
    --domain form_validation \
    --name "Validate Demo Field" \
    --module demo_field
```
Expected: stdout prints the manual checklist; three files appear:
- `form_validation/demo_field.resource`
- `tests/test_demo_field.robot`
- new row in `docs/COVERAGE.md`

- [ ] **Step 2: Robot dryrun should accept the scaffolded resource**

```bash
robot --dryrun tests/test_demo_field.robot
```
Expected: dryrun reports "1 critical test" with no parse errors. (The test is a `Fail TODO(...)` stub — that's fine for dryrun, which doesn't execute keywords.)

- [ ] **Step 3: Revert the smoke-test artifacts**

```bash
rm form_validation/demo_field.resource tests/test_demo_field.robot
git checkout docs/COVERAGE.md
```
Verify with `git status` that no smoke artifacts remain.

- [ ] **Step 4: No commit needed**

This task verifies but does not change the repo. Skip the commit step.

---

## Task 8: PROJECT_CONTEXT.md — header, callout, sections 1–2

**Files:**
- Create: `PROJECT_CONTEXT.md`

- [ ] **Step 1: Create the file with the header, AI callout, Overview, and Layers sections**

Write `PROJECT_CONTEXT.md` with this content:

````markdown
# Project Knowledge & Architecture Context

> **For AI assistants**: read §3 (Conventions) and §5.4 (Backward
> Compatibility) before generating any keyword. Use
> [`scripts/new_keyword.py`](scripts/new_keyword.py) for scaffolding,
> not freehand. Never call underscore-prefixed `_helpers.resource`
> files from tests. The project-agnosticism gate (§2) is hard — no
> app-specific selectors, URLs, error strings, or business rules.

This document is the source of truth for how `robotframework-common-keywords`
is structured and how to extend it. Companion docs:
[`README.md`](README.md) (install + quick start),
[`docs/COVERAGE.md`](docs/COVERAGE.md) (keyword → self-test mapping),
[`docs/EXAMPLES.md`](docs/EXAMPLES.md) (real-world scenarios),
[`docs/INTEGRATION.md`](docs/INTEGRATION.md) (how project-specific
keywords call into common ones),
[`docs/keyword-catalog/`](docs/keyword-catalog/) (auto-generated libdoc
HTML — full keyword signatures), [`CHANGELOG.md`](CHANGELOG.md).

---

## 1. System Overview

`robotframework-common-keywords` is a **reusable validation-keyword
library** for Robot Framework. It is *not* an end-to-end test project:
it ships project-agnostic keywords that consuming test projects import
and call against their own application under test. Selectors come in
as arguments; country / policy / schema rules come from YAML.

### Tech stack

| Layer | Tool |
|---|---|
| Test runner | Robot Framework ≥ 7.0 |
| Browser automation | `robotframework-browser` (Playwright) ≥ 18.0 |
| HTTP client (self-tests) | `robotframework-requests` ≥ 0.9.7 |
| Phone validation | `phonenumbers` ≥ 8.13 |
| JSON Schema | `jsonschema` ≥ 4.0 (Draft 2020-12) |
| Fake data | `faker` ≥ 25.0 |
| YAML loading | `pyyaml` ≥ 6.0 |
| Python runtime | ≥ 3.10 |
| Packaging | `pyproject.toml` (setuptools) |

Distributed as a pip-installable library or as a git submodule. See
[`README.md`](README.md) for installation details.

### Architecture pattern

**Keyword-Driven, three-layer.** Not Page Object Model — locators are
caller-supplied arguments, never encapsulated.

```
Test (.robot)
   └─► Public Keyword (.resource)
         └─► Internal Helper (_helpers.resource — underscore-prefixed)
               └─► Python Library (libraries/*.py via @keyword)
```

Four keyword domains sit on top of `libraries/` + `test_data/`:

```
form_validation/   api_validation/   ui_validation/   data_generators/
        │                  │                 │                │
        └──────────────────┴─────────────────┴────────────────┘
                                  │
                          libraries/  +  test_data/
```

---

## 2. Architectural Layers & Boundaries

### Layer rules

| Layer | Lives in | Calls down to | Public API? | Example |
|---|---|---|---|---|
| Test | `tests/*.robot` | Public keywords | n/a | `test_email_field.robot` |
| Public keyword | `form_validation/*.resource`, `api_validation/*.resource`, `ui_validation/*.resource`, `data_generators/*.resource` | Helpers, Python libs | **Yes** | `Validate Email Field` |
| Internal helper | `*/_helpers.resource` | Python libs | **No** | `Trigger Field Validation` |
| Python library | `libraries/*.py` (via `@keyword`) | Third-party SDKs | **Yes** | `Is Valid Phone Number For Country` |

### `.resource` vs Python `@keyword` — decision rule

Use a `.resource` file when the keyword is **orchestration**: composing
existing keywords, looping over Robot variables, branching on Robot
state, or driving Browser Library.

Use a Python library (`libraries/*.py`) when the keyword needs **pure
computation, third-party SDK wrapping, exception handling, or
non-trivial data manipulation**. Examples in this repo: parsing phone
numbers via `phonenumbers`, validating JSON Schema, generating dates.

### Underscore-prefix convention

Files named `_helpers.resource` are **internal-only**. Tests must call
public keywords; they must not import or call into a `_helpers.resource`
file directly. This is enforced by code review.

### Project-agnosticism gate (hard rule)

Before merging any keyword, ask: **"Would Team B, working on a totally
different product, use this keyword as-is?"**

- Yes → it belongs here.
- No (it references a specific URL, field name, business rule, or
  validation message unique to one app) → it does **not**. Such
  keywords belong in the consuming project's `keywords/business/`
  directory.

No hard-coded URLs, labels, error messages, country codes, or business
rules. Lift to YAML under `test_data/` or to a keyword argument with a
sensible default.
````

- [ ] **Step 2: Verify the file renders**

Open the file in any Markdown viewer (or `cat PROJECT_CONTEXT.md | head -60`). Confirm the callout blockquote appears, tables render, and the diagrams are intact.

- [ ] **Step 3: Commit**

```bash
git add PROJECT_CONTEXT.md
git commit -m "docs: add PROJECT_CONTEXT.md header, callout, and sections 1-2"
```

---

## Task 9: PROJECT_CONTEXT.md — section 3 (Conventions Reference)

- [ ] **Step 1: Append the Conventions section**

Append to `PROJECT_CONTEXT.md`:

````markdown

---

## 3. Conventions Reference

### Naming and arguments

| Convention | Rule | Example |
|---|---|---|
| Keyword naming | Title Case, verb-first, domain-noun ending | `Validate Email Field`, `Response Status Should Be` |
| Argument naming | snake_case; required positional first; locator args end in `_locator` | `${field_locator}`, `${error_locator}=${EMPTY}` |
| Required defaults | Every public keyword callable as `Keyword Name    ${locator}` | All other params have defaults |
| File naming | One domain per file; snake_case `.resource` filename matches keyword family | `email_field.resource` |
| Internal-only marker | Filename prefixed with `_` | `_helpers.resource` |
| Python `@keyword` | `@keyword("Title Case Name")`; `ROBOT_LIBRARY_SCOPE = "GLOBAL"`; module docstring | See `libraries/phone_helpers.py` |

### Documentation

Every public keyword has a `[Documentation]` block with:

1. A one-line summary on the first line.
2. When the keyword composes multiple checks, a numbered list of what
   runs in order.
3. An `Arguments:` section describing each parameter when the parameter
   list is non-trivial.

`Validate Email Field` in
[`form_validation/email_field.resource`](form_validation/email_field.resource)
is the canonical pattern.

### Error messages

Every assertion in a public keyword uses `msg=...` and quotes:

- The expected value.
- The actual value.
- The locator (when relevant).
- What was attempted.

Never let a failure say only `Assertion failed`. Examples:

```robot
Should Be True    200 <= ${code} < 300
...    msg=Expected a 2xx response, got ${code}.

Should Be True    ${truncated} or ${error_shown}
...    msg=Expected email field to reject ${max_length + 1}-char email; got length ${final_len}, no error.
```
````

- [ ] **Step 2: Commit**

```bash
git add PROJECT_CONTEXT.md
git commit -m "docs: PROJECT_CONTEXT.md section 3 — Conventions"
```

---

## Task 10: PROJECT_CONTEXT.md — section 4 (Module Dictionary)

- [ ] **Step 1: Append the Module Dictionary section**

Append to `PROJECT_CONTEXT.md`:

````markdown

---

## 4. Module Dictionary

### Top-level table

| Module | Path | Public Keywords | Key Deps | Purpose |
|---|---|---:|---|---|
| Required field | `form_validation/required_field.resource` | 1 | Browser, `_helpers` | Empty-input rejection |
| Text field | `form_validation/text_field.resource` | 7 | Browser, `_helpers`, `boundary_generator` | Length / character / whitespace / case rules |
| Email field | `form_validation/email_field.resource` | 1 | Browser, `_helpers`, `text_field`, `required_field`, `boundary_generator`, `yaml_loader` | Composite email validation (~28 internal assertions) |
| Phone field | `form_validation/phone_field.resource` | 2 | Browser, `_helpers`, `phone_helpers` | Country-aware phone validation |
| URL field | `form_validation/url_field.resource` | 1 | Browser, `_helpers` | URL format + optional `require_https` |
| Number field | `form_validation/number_field.resource` | 5 | Browser, `_helpers` | Range / integer / positive / currency / percentage |
| Date field | `form_validation/date_field.resource` | 4 | Browser, `_helpers`, `date_helpers` | Format / future / past / range |
| Password field | `form_validation/password_field.resource` | 3 | Browser, `_helpers`, `password_helpers` | Policy-driven |
| File upload | `form_validation/file_upload.resource` | 3 | Browser, `_helpers`, `file_helpers` | Type / size / multi-file |
| Dropdown field | `form_validation/dropdown_field.resource` | 4 | Browser, `_helpers` | Exact / any-order / default / required / searchable |
| (internal) Form helpers | `form_validation/_helpers.resource` | 4 | Browser | Trigger / error visibility / read value (**internal**) |
| Status codes | `api_validation/status_codes.resource` | 4 | `api_validation_helpers` | 2xx / 4xx / 5xx + exact match |
| Response schema | `api_validation/response_schema.resource` | 3 | `api_validation_helpers` | JSON Schema + required fields + field types |
| Response time | `api_validation/response_time.resource` | 1 | `api_validation_helpers` | Threshold check |
| Pagination | `api_validation/pagination.resource` | 2 | `api_validation_helpers` | Envelope + metadata consistency |
| Error responses | `api_validation/error_responses.resource` | 2 | `api_validation_helpers` | Standard format + field mention |
| Element state | `ui_validation/element_state.resource` | 7 | Browser | Enabled / disabled / readonly / visible / hidden / focused / placeholder |
| Form behavior | `ui_validation/form_behavior.resource` | 3 | Browser | Submit gate / inline blur / data preservation |
| Accessibility | `ui_validation/accessibility.resource` | 3 | Browser | Aria-label / tab order / label association |
| Invalid data | `data_generators/invalid_data.resource` | (variables) | — | `@{INVALID_EMAILS}`, SQL/XSS probes |
| API helpers | `libraries/api_validation_helpers.py` | 6+ | `jsonschema` | Schema validation, mock responses, field types |
| Boundary generator | `libraries/boundary_generator.py` | 1 | — | `Generate String With Length` |
| Date helpers | `libraries/date_helpers.py` | 5 | — | Today / future / past / relative / format |
| Faker wrapper | `libraries/faker_wrapper.py` | 4 | `faker` | Fake email / name / phone / address |
| File helpers | `libraries/file_helpers.py` | 3 | — | Sample paths / oversize file / delete |
| Password helpers | `libraries/password_helpers.py` | 3 | — | Load policy / generate compliant / serialize |
| Phone helpers | `libraries/phone_helpers.py` | 2 | `phonenumbers` | Validate / format E.164 |

### Per-module keyword names

`form_validation/required_field.resource`
- `Validate Required Field`

`form_validation/text_field.resource`
- `Validate Max Length`
- `Validate Min Length`
- `Validate Length Range`
- `Validate Allowed Characters Only`
- `Validate Forbidden Characters`
- `Validate Whitespace Trimmed`
- `Validate Case Sensitivity`

`form_validation/email_field.resource`
- `Validate Email Field`

`form_validation/phone_field.resource`
- `Validate Phone Field`
- `Validate Country Code Prefix`

`form_validation/url_field.resource`
- `Validate URL Field`

`form_validation/number_field.resource`
- `Validate Number Field`
- `Validate Integer Only`
- `Validate Positive Number`
- `Validate Currency Field`
- `Validate Percentage Field`

`form_validation/date_field.resource`
- `Validate Date Field`
- `Validate Date Is Future`
- `Validate Date Is Past`
- `Validate Date Range`

`form_validation/password_field.resource`
- `Validate Password Field`
- `Validate Password Confirmation Match`
- `Validate Password Not Equal To Username`

`form_validation/file_upload.resource`
- `Validate File Type Restriction`
- `Validate File Size Limit`
- `Validate Multiple Files Allowed`

`form_validation/dropdown_field.resource`
- `Validate Dropdown Options Exactly`
- `Validate Dropdown Default Selection`
- `Validate Dropdown Is Required`
- `Validate Dropdown Is Searchable`

`form_validation/_helpers.resource` (**internal — do not call from tests**)
- `Trigger Field Validation`
- `Validation Error Should Be Visible`
- `Validation Error Should Not Be Visible`
- `Read Field Value`

`api_validation/status_codes.resource`
- `Response Should Be Success`
- `Response Should Be Client Error`
- `Response Should Be Server Error`
- `Response Status Should Be`

`api_validation/response_schema.resource`
- `Response Should Match Schema`
- `Response Should Contain Required Fields`
- `Response Field Should Be Type`

`api_validation/response_time.resource`
- `Response Time Should Be Below`

`api_validation/pagination.resource`
- `Response Should Be Paginated`
- `Pagination Metadata Should Be Valid`

`api_validation/error_responses.resource`
- `Error Response Should Follow Standard Format`
- `Validation Error Should Mention Field`

`ui_validation/element_state.resource`
- `Validate Element Is Enabled`
- `Validate Element Is Disabled`
- `Validate Element Is Readonly`
- `Validate Element Is Visible`
- `Validate Element Is Hidden`
- `Validate Element Has Focus`
- `Validate Element Has Placeholder`

`ui_validation/form_behavior.resource`
- `Validate Submit Button Disabled Until Form Valid`
- `Validate Inline Validation Triggers On Blur`
- `Validate Form Preserves Data On Navigation`

`ui_validation/accessibility.resource`
- `Validate Element Has Aria Label`
- `Validate Tab Order`
- `Validate Form Fields Have Labels`

`libraries/api_validation_helpers.py`
- `Response Status Code`
- `Response Body`
- `Response Elapsed Seconds`
- `Validate JSON Schema`
- `Check Required Fields`
- `Get JSON Field Type`
- `Assert Response Field Type`
- `Error Response Mentions Field`
- `Create Mock Response`

`libraries/boundary_generator.py`
- `Generate String With Length`

`libraries/date_helpers.py`
- `Today As Date`
- `Future Date`
- `Past Date`
- `Date Relative To Today`
- `Format Date`

`libraries/faker_wrapper.py`
- `Generate Fake Email`
- `Generate Fake Name`
- `Generate Fake Phone`
- `Generate Fake Address`

`libraries/file_helpers.py`
- `Sample File Path`
- `Create Oversize File`
- `Delete File If Exists`

`libraries/password_helpers.py`
- `Load Password Policy`
- `Generate Compliant Password`
- `Policy As JSON`

`libraries/phone_helpers.py`
- `Is Valid Phone Number For Country`
- `Format Phone Number As E164`

> Full keyword signatures (arguments, defaults, types) live in
> [`docs/keyword-catalog/`](docs/keyword-catalog/) — regenerate via
> `./scripts/generate-keyword-catalog.sh` after adding or renaming
> keywords.
````

- [ ] **Step 2: Cross-check counts**

Run a quick sanity check against the existing COVERAGE document:
```bash
grep -c '^| `' docs/COVERAGE.md
```
The number reported in `docs/COVERAGE.md` ("62 public keywords") is the
authoritative count; the per-module names above are derived from it. If
the count in COVERAGE has changed since 2026-05-09, update both.

- [ ] **Step 3: Commit**

```bash
git add PROJECT_CONTEXT.md
git commit -m "docs: PROJECT_CONTEXT.md section 4 — Module Dictionary"
```

---

## Task 11: PROJECT_CONTEXT.md — sections 5–6 (Workflow + Extensibility)

- [ ] **Step 1: Append the Workflow and Extensibility sections**

Append to `PROJECT_CONTEXT.md`:

````markdown

---

## 5. Development Workflow

### 5.1 Check if a keyword already exists

Run these in order before creating anything new:

1. Search resource keyword names:
   ```bash
   grep -rn "^Keyword Name" form_validation api_validation ui_validation data_generators
   ```
2. Search Python `@keyword` decorators:
   ```bash
   grep -rn '@keyword("Keyword Name")' libraries/
   ```
3. Browse the libdoc HTML at [`docs/keyword-catalog/`](docs/keyword-catalog/)
   for full signatures.
4. Cross-reference §4 Module Dictionary above.
5. Run a Robot dryrun — undefined keywords surface immediately:
   ```bash
   robot --dryrun tests/
   ```

### 5.2 Create a new common-keyword

Use the scaffolder. From the repo root:

```bash
python scripts/new_keyword.py \
    --domain form_validation \
    --name "Validate Postal Code Field" \
    --module postal_code_field
```

Generates:
- `form_validation/postal_code_field.resource` — annotated boilerplate
  (Settings, Documentation, Arguments, composite step pattern).
- `tests/test_postal_code_field.robot` — self-test stub against
  `tests/fixtures/text_form.html`.
- A placeholder row appended to `docs/COVERAGE.md`.

For a Python `@keyword` library instead, add `--python`:

```bash
python scripts/new_keyword.py \
    --domain form_validation \
    --name "Compute Postal Code Region" \
    --module postal_code_helpers \
    --python
```

The script prints a manual checklist on success. The full sequence is:

1. Replace every `TODO(new_keyword.py)` marker in the generated files
   (Documentation, Arguments, body).
2. If the keyword needs reference data (valid samples, invalid samples,
   country rules), add a YAML file under `test_data/`.
3. Dryrun the new self-test:
   ```bash
   robot --dryrun tests/test_postal_code_field.robot
   ```
4. Implement the keyword body; iterate until the self-test passes.
5. Run the full offline suite:
   ```bash
   robot -d results --exclude network tests/
   ```
6. Regenerate the keyword catalog:
   ```bash
   ./scripts/generate-keyword-catalog.sh
   ```
7. Update the placeholder COVERAGE row with the actual self-test name.
8. Add a CHANGELOG entry.

### 5.3 Boilerplate templates

The scaffolder is the source of truth for templates. Reproduced here for
quick reference:

**`.resource` keyword template** (what the scaffolder writes):

```robot
*** Settings ***
Documentation    {Keyword Name}. One-line summary.
Library          Browser
Resource         _helpers.resource


*** Keywords ***
{Keyword Name}
    [Documentation]    Describe what is checked.
    ...                When composing multiple checks, list them in a
    ...                numbered sequence.
    ...
    ...                Arguments:
    ...                - ``field_locator``  — Playwright selector of the input.
    ...                - ``error_message``  — substring of the visible error text.
    ...                - ``error_locator``  — optional selector for the error element.
    ...                - ``trigger``        — ``blur`` (default) or ``submit``.
    ...                - ``submit_locator`` — required when ``trigger=submit``.
    [Arguments]    ${field_locator}
    ...            ${error_message}=Default error text
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    Fill Text    ${field_locator}    ${EMPTY}
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}
    ...    error_locator=${error_locator}
```

**Python `@keyword` library template**:

```python
"""One-line module description."""

from __future__ import annotations

from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"


@keyword("Keyword Name")
def keyword_name() -> None:
    """Describe what this keyword returns or does.

    Predicate keywords return False on bad input; imperative keywords
    let exceptions from the underlying library propagate.
    """
    raise NotImplementedError
```

**Self-test template** (deterministic, against the local fixture):

```robot
*** Settings ***
Documentation    Self-test for {Keyword Name}.
Library          Browser
Resource         ../{domain}/{module}.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
{Keyword Name} Smoke
    [Tags]    {domain}
    {Keyword Name}    [data-test='some-input']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page
```

### 5.4 Maintain & update without breaking backward compatibility

| Change | Compatible? | Required action |
|---|---|---|
| Add new optional argument with a default | Yes | Append after existing args; do not insert in the middle |
| Add new required argument | **No** | Add as optional with a default; promote to required only via deprecation cycle |
| Rename an argument | **No** | Add new name as optional alias; warn when old name is used; remove after 2 minor versions |
| Rename a keyword | **No** | Keep old keyword as a one-line wrapper that calls the new one + logs a deprecation message |
| Tighten a default (e.g., `max_length` 255 → 100) | **No** | Treat as breaking; bump minor version; CHANGELOG entry |
| Add a new internal helper | Yes | Underscore prefix; never call from tests |
| Loosen validation (accept previously rejected input) | Yes (caller-visible) | CHANGELOG entry; ensure self-test covers the new acceptance |
| Add a new public keyword | Yes | New self-test required; CHANGELOG; regenerate catalog |
| Remove a keyword | **No** | Deprecate first (one minor version), then remove |

---

## 6. Extensibility Rules

### 6.1 Error handling

- Every public-keyword assertion uses `msg=...` and quotes the expected
  value, the actual value, the locator (when relevant), and what was
  attempted. Never let a failure say only `Assertion failed`.
- Python predicate keywords (`Is X`, `Has X`) return `False` on bad
  input rather than raising. Python imperative keywords (`Format X`,
  `Compute X`) let exceptions from the underlying library propagate;
  do not swallow them.
- For composite keywords with branching success conditions
  (e.g. "either truncate input *or* show an error"), use
  `Run Keyword And Return Status` and assert the disjunction
  explicitly:
  ```robot
  ${error_shown}=    Run Keyword And Return Status
  ...    Validation Error Should Be Visible    error_message=...
  Should Be True    ${truncated} or ${error_shown}
  ...    msg=Expected ... ; got length ${final_len}, no error.
  ```
  See `Validate Email Field` step 4 for the canonical pattern.

### 6.2 Logging

- Use Robot's built-in `Log` keyword. No custom loggers in this
  package.
- In long FOR loops over data tables, log only on failure or on
  entries that materially change behavior. Avoid per-iteration `Log`.
- Self-tests must be reproducible without `--loglevel DEBUG`.

### 6.3 Performance

- `Type Text` always uses `delay=0 ms    clear=True` in composite
  keywords. Never leave per-keystroke delay in shipped code.
- `Load YAML` once per keyword execution; do not reload inside a FOR
  loop.
- Composite keywords should run in under 10 seconds against the local
  fixture (`tests/fixtures/text_form.html`). Flag slower keywords in
  PR review.

### 6.4 Project-agnosticism (hard rule, restated)

Never hard-code an URL, label, error message, country, or business
rule. Lift to YAML under `test_data/` or to a keyword argument with a
sensible default. The merge gate is the question from §2:
**"Would Team B use this as-is?"**
````

- [ ] **Step 2: Final Markdown sanity check**

Run a quick check that every relative link in the doc resolves:
```bash
grep -oE '\]\(([^)]+)\)' PROJECT_CONTEXT.md | sed -E 's/\]\(([^)]+)\)/\1/' | while read -r link; do
    case "$link" in
        http*) ;;
        *) [ -e "$link" ] || echo "missing: $link" ;;
    esac
done
```
Expected: no `missing:` lines, except possibly `docs/keyword-catalog/`
(which depends on whether the catalog has been generated locally).

- [ ] **Step 3: Commit**

```bash
git add PROJECT_CONTEXT.md
git commit -m "docs: PROJECT_CONTEXT.md sections 5-6 — Workflow and Extensibility"
```

---

## Task 12: Final verification

- [ ] **Step 1: Run the full pytest suite**

```bash
pytest tests/test_new_keyword_script.py -v
```
Expected: 10 PASS.

- [ ] **Step 2: Run the existing Robot self-test suite to confirm no regression**

```bash
source .venv/bin/activate
robot -d results --exclude network tests/
```
Expected: same pass count as before this work (the new files don't
register as tests since `tests/test_new_keyword_script.py` is `.py`,
not `.robot`).

- [ ] **Step 3: Confirm deliverables exist**

```bash
ls -la PROJECT_CONTEXT.md scripts/new_keyword.py tests/test_new_keyword_script.py
git log --oneline -15
```
Expected: all three files present; the last 9 commits cover dev-dep,
six scaffolder TDD steps, and four PROJECT_CONTEXT.md sections.

- [ ] **Step 4: No commit**

This task verifies but does not change the repo.

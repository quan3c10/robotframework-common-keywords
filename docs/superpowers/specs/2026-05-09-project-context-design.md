# Design Spec — `PROJECT_CONTEXT.md` and `scripts/new_keyword.py`

**Date**: 2026-05-09
**Status**: Approved (pending user spec review)
**Owner**: Senior Automation Architect (brainstorming session)

## 1. Goal

Produce a single, self-documenting source-of-truth file at the repository
root — `PROJECT_CONTEXT.md` — that two audiences can use:

1. **Human engineers** onboarding to or contributing to the
   `robotframework-common-keywords` package.
2. **AI coding assistants** (Claude Code, Copilot, Cursor, etc.) generating
   or extending keywords without violating the package's conventions.

Add a small Python scaffolder (`scripts/new_keyword.py`) that makes the
"create a new keyword" workflow described in `PROJECT_CONTEXT.md`
mechanically reproducible.

## 2. Non-goals

- Replacing `README.md`, `docs/COVERAGE.md`, `docs/EXAMPLES.md`,
  `docs/INTEGRATION.md`, or the auto-generated `docs/keyword-catalog/`.
  `PROJECT_CONTEXT.md` complements them and links out where they are
  authoritative.
- Auto-generating keyword signatures inside `PROJECT_CONTEXT.md` itself.
  `docs/keyword-catalog/` (libdoc) remains the source for full signatures.
- Restructuring the package layout, renaming keywords, or introducing new
  validation domains.

## 3. Audience profile

- **Audience C** from brainstorming: written for humans, structured for AI
  consumption. Concrete rules, fenced templates, decision tables, no
  implicit knowledge. Section anchors are stable for cross-linking from
  other docs and from CLAUDE.md / agent prompts.

## 4. Architectural understanding (informs the doc)

The package is a **Keyword-Driven, three-layer library**:

```
Test (.robot)
  -> Public Keyword (.resource in form_validation/api_validation/ui_validation/data_generators)
       -> Internal Helper (_helpers.resource — underscore-prefixed)
            -> Python Library (libraries/*.py via @keyword)
```

It is *not* a Page Object Model project — locators are caller-supplied
arguments, never encapsulated. It is *not* an end-to-end test project —
it ships reusable validation primitives.

Existing strong conventions (already present in code and `README.md`):

- One file per validation domain.
- Public keyword callable as `Keyword Name    ${locator}` (all other args
  default).
- `[Documentation]` block enumerates composed checks.
- Errors quote expected, actual, locator, and what was attempted.
- `_helpers.resource` is internal-only; tests call public keywords.
- "Would Team B use this as-is?" — project-agnosticism gate.
- Every public keyword has a self-test in `tests/`.

`PROJECT_CONTEXT.md` codifies these so they are explicit, table-form, and
LLM-greppable.

## 5. Output: `PROJECT_CONTEXT.md` structure

Approach **B** from brainstorming: logical narrative flow, six sections,
plus a top-of-file AI-assistant callout.

### Top-of-file callout (blockquote)

> **For AI assistants**: read §3 (Conventions) and §5.4 (Backward
> Compatibility) before generating any keyword. Use
> `scripts/new_keyword.py` for scaffolding, not freehand. Never call
> underscore-prefixed resources from tests. The
> project-agnosticism gate (§2.4) is hard — no app-specific selectors,
> URLs, error strings, or business rules.

### Section 1 — System Overview

- Tech stack: Robot Framework >= 7.0; Browser Library (Playwright);
  `robotframework-requests`; Python >= 3.10 with `phonenumbers`,
  `jsonschema`, `faker`, `pyyaml`. Packaged via `pyproject.toml`
  (setuptools); installable as pip package or git submodule.
- What it is / what it isn't: reusable validation library, not an E2E
  test project. No app-specific anything.
- Architecture diagram (ASCII or Mermaid) showing the three-layer flow
  and the four keyword domains sitting on `libraries/` + `test_data/`.

### Section 2 — Architectural Layers & Boundaries

| Layer | Lives in | Calls down to | Public? | Example |
|---|---|---|---|---|
| Test | `tests/*.robot` | Public keywords | n/a | `test_email_field.robot` |
| Public keyword | `form_validation/*.resource`, `api_validation/*.resource`, `ui_validation/*.resource`, `data_generators/*.resource` | Helpers, Python libs | Yes | `Validate Email Field` |
| Internal helper | `*/_helpers.resource` | Python libs | **No** | `Trigger Field Validation` |
| Python library | `libraries/*.py` (via `@keyword`) | Third-party SDKs | Yes (for use by .resource files) | `Is Valid Phone Number For Country` |

Subsections:

- **`.resource` vs Python `@keyword` decision rule.** Orchestration /
  Robot-flow logic in `.resource`; pure-Python computation, third-party
  SDK wrapping, or anything needing exception handling in `libraries/`.
- **Underscore-prefix convention.** `_helpers.resource` files are
  internal; tests call public keywords only.
- **Project-agnosticism gate.** Promote README's "Would Team B use this
  as-is?" check to a one-line rule.

### Section 3 — Conventions Reference

Single table consolidating naming, argument handling, defaults, docs,
errors:

| Convention | Rule | Example |
|---|---|---|
| Keyword naming | Title Case, verb-first, domain-noun ending | `Validate Email Field`, `Response Status Should Be` |
| Argument naming | snake_case; required positional first; locator args end in `_locator` | `${field_locator}`, `${error_locator}=${EMPTY}` |
| Required defaults | Every public keyword callable as `Keyword Name    ${locator}` | All other params default |
| Documentation | `[Documentation]` block with 1-line summary + numbered list when composing checks | See `Validate Email Field` |
| Error messages | Quote expected, actual, locator, and what was attempted | `msg=Expected status ${expected_code}, got ${code}.` |
| File naming | One domain per file; snake_case `.resource` filename matches keyword family | `email_field.resource` |
| Python `@keyword` | `@keyword("Title Case Name")`; `ROBOT_LIBRARY_SCOPE = "GLOBAL"`; module docstring | See `phone_helpers.py` |
| Internal-only marker | Filename prefixed with `_` | `_helpers.resource` |

### Section 4 — Module Dictionary (Hybrid)

Top-level table (~18 rows — every `.resource` and Python library file):

| Module | Path | Public Keywords | Key Deps | Purpose |
|---|---|---:|---|---|

Per-module name lists below the table — keyword names only, no
signatures, grouped by file. Footer: full signatures live in
`docs/keyword-catalog/` (libdoc HTML); regenerate via
`scripts/generate-keyword-catalog.sh`.

### Section 5 — Development Workflow

#### 5.1 Check if a keyword already exists

Numbered, command-form:

1. `grep -rn "^Keyword Name" form_validation api_validation ui_validation data_generators`
2. `grep -rn '@keyword("Keyword Name")' libraries/`
3. Browse `docs/keyword-catalog/` for full signatures.
4. Cross-reference §4 Module Dictionary table.
5. `robot --dryrun tests/` — undefined keywords surface immediately.

#### 5.2 Create a new common-keyword

Run `scripts/new_keyword.py` (see §7 below). Generates a `.resource`
file, a self-test stub, and appends a placeholder row to
`docs/COVERAGE.md`. Then complete the printed manual checklist (replace
TODOs, add YAML test data if needed, dryrun, implement, full test run,
regenerate catalog, finalize COVERAGE row).

#### 5.3 Boilerplate templates

Three fenced code blocks, copy-pasteable:

- `.resource` keyword (Settings, Documentation, Arguments, composite
  step pattern).
- Python `@keyword` library (`ROBOT_LIBRARY_SCOPE`, decorator,
  docstring).
- Self-test (deterministic fixture, positive + negative case).

#### 5.4 Maintain & update without breaking backward compatibility

| Change | Compatible? | Required action |
|---|---|---|
| Add new optional arg with default | Yes | Append after existing args; do not insert in middle |
| Add new required arg | **No** | Add as optional with default; promote via deprecation cycle |
| Rename an argument | **No** | Add new name as optional alias; warn when old name used; remove after 2 minor versions |
| Rename a keyword | **No** | Keep old keyword as a one-line wrapper that calls new one + logs deprecation |
| Tighten a default (e.g., `max_length` 255 -> 100) | **No** | Treat as breaking; minor version bump; CHANGELOG |
| Add new internal helper | Yes | Underscore prefix; never call from tests |
| Loosen validation (accept previously rejected input) | Yes (caller-visible) | CHANGELOG entry; ensure self-test covers new acceptance |
| Add new public keyword | Yes | New self-test required; CHANGELOG; regenerate catalog |
| Remove a keyword | **No** | Deprecate first (one minor version), then remove |

### Section 6 — Extensibility Rules

#### 6.1 Error handling

- Public keyword failures must use `msg=...` with expected, actual,
  locator, and what was attempted. Never let a failure say only
  "Assertion failed."
- Python predicate keywords (`Is X`, `Has X`) return `False` rather than
  raising on bad input.
- Python imperative keywords (`Format X`, `Compute X`) may raise; raise
  exceptions from the underlying library rather than swallowing.
- Composite keywords with branching success conditions (e.g.,
  truncate-or-error) use `Run Keyword And Return Status` and `Should Be
  True ${a} or ${b}` to express the disjunction explicitly.

#### 6.2 Logging

- Use Robot's built-in `Log` keyword; no custom loggers.
- In long FOR loops over data tables, log only on failure or on entries
  that materially change behavior. Avoid per-iteration `Log`.
- Self-tests must pass without `--loglevel DEBUG`.

#### 6.3 Performance

- `Type Text` always uses `delay=0 ms    clear=True` in composite
  keywords.
- Load YAML once per keyword execution; do not reload inside a FOR.
- Composite keywords should run in < 10s on the local fixture
  (`tests/fixtures/text_form.html`); flag slower in PR review.

#### 6.4 Project-agnosticism (hard rule)

- Never hard-code an URL, label, error message, country, or business
  rule. Lift to YAML under `test_data/` or to an argument with a default.
- "Would Team B use this as-is?" is the merge gate.

## 6. Cross-link map

`PROJECT_CONTEXT.md` links to:

- `README.md` (install, quick start)
- `docs/COVERAGE.md` (keyword -> self-test mapping)
- `docs/EXAMPLES.md` (real-world scenarios)
- `docs/INTEGRATION.md` (project-specific business keywords calling in)
- `docs/keyword-catalog/` (libdoc HTML — full signatures)
- `CHANGELOG.md` (version history)

`README.md` will eventually be updated to link back to
`PROJECT_CONTEXT.md` from its "Contributing" section, but that update is
out of scope for this spec.

## 7. Output: `scripts/new_keyword.py`

Python (matches existing `scripts/excel_to_markdown.py` convention).

### CLI

```
python scripts/new_keyword.py \
    --domain {form_validation|api_validation|ui_validation|data_generators} \
    --name "Validate Postal Code Field" \
    --module postal_code_field \
    [--python]
```

- `--domain` is required and validated against the four directories.
- `--name` is the human keyword name (Title Case).
- `--module` is the snake_case basename for the file (no extension).
- `--python` switches output from a `.resource` template to a Python
  `@keyword` template under `libraries/`. Default: `.resource`.

### Behavior

1. Validate `--domain` exists.
2. Refuse to overwrite if the target file exists.
3. Render the appropriate template into `<domain>/<module>.resource` (or
   `libraries/<module>.py` with `--python`).
4. Render `tests/test_<module>.robot` self-test stub against
   `tests/fixtures/text_form.html`. With `--python`, the Robot self-test
   stub is omitted (Python `@keyword` libraries are exercised through
   the consuming `.resource` file's self-test); the script prints a
   reminder to add coverage there.
5. Append a TODO row to `docs/COVERAGE.md`.
6. Print a manual checklist to stdout (steps from §5.2 of the doc).

### Templates

Stored as triple-quoted strings inside the script (no separate template
files). Each contains explicit `# TODO(new_keyword.py):` markers for
fields the developer must replace.

### Tests for the scaffolder

A small `tests/test_new_keyword_script.py` (pytest) that:

- Runs the script in a `tmp_path` against a copied minimal layout.
- Asserts the three output files exist with the expected substitutions.
- Asserts a re-run refuses to overwrite.

(This is the only Python unit test in the repo; existing tests are Robot
self-tests. Keeping it pytest avoids reusing the Browser stack to test a
file generator. `pytest` is added to `[project.optional-dependencies]
dev` in `pyproject.toml` as part of this work.)

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| `PROJECT_CONTEXT.md` drifts as keywords are added | The Module Dictionary section instructs running `scripts/generate-keyword-catalog.sh` and gives a `grep` recipe; the dictionary lists module names only (slow-changing) |
| Scaffolder boilerplate diverges from real conventions | Templates are derived directly from `email_field.resource` (the canonical composite pattern) and `phone_helpers.py`; the scaffolder test pins the rendered output |
| AI assistants ignore the callout and freehand a keyword | The doc states the rule plainly and the scaffolder is the path of least resistance; CLAUDE.md (if present) can pin the rule |

## 9. Acceptance criteria

- `PROJECT_CONTEXT.md` exists at the repo root with all six sections and
  the AI-assistant callout.
- All conventions in §3 are taken from real examples in the repo (no
  invented rules).
- §4 Module Dictionary lists every `.resource` file under
  `form_validation/`, `api_validation/`, `ui_validation/`,
  `data_generators/`, and every non-dunder `.py` file under
  `libraries/`. The author surveys `libraries/` directly when writing
  the doc and includes whatever Python helpers are present (current
  set: `api_validation_helpers.py`, `boundary_generator.py`,
  `date_helpers.py`, `faker_wrapper.py`, `file_helpers.py`,
  `password_helpers.py`, `phone_helpers.py`).
- `scripts/new_keyword.py` runs without arguments printing usage,
  scaffolds a `.resource` keyword + self-test stub when given valid args,
  and refuses to overwrite existing files.
- `tests/test_new_keyword_script.py` passes.
- A run of `scripts/new_keyword.py --domain form_validation --name
  "Validate Demo Field" --module demo_field` produces files that pass
  `robot --dryrun` (the self-test will fail at runtime — that is
  expected for a stub).

## 10. Out of scope

- Auto-deprecation tooling (e.g., a decorator that emits warnings when
  renamed args are passed).
- Updating `README.md` to link back to `PROJECT_CONTEXT.md`.
- Generating `PROJECT_CONTEXT.md` content from libdoc; the doc is
  hand-maintained.

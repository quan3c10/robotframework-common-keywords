---
name: extend-common-keywords
description: Use this when extending the robotframework-common-keywords library with new validation keywords driven by a test-cases markdown file. Trigger phrases include "add keywords from <file>.md", "extend the library with these test cases", "implement validation keywords for these specs", "scaffold keywords from this MD". Enforces PROJECT_CONTEXT.md conventions, project-agnosticism gate, scripts/new_keyword.py scaffolding, and TDD workflow.
---

# Extending common-keywords from a test-cases file

Use this skill when the user wants to add or extend validation keywords in
`robotframework-common-keywords` based on a markdown file that describes
test cases.

## Source of truth

`PROJECT_CONTEXT.md` at the repo root is authoritative. Read these sections
before generating any code:

- §2 Architectural Layers & Boundaries (decision rule + agnosticism gate)
- §3 Conventions Reference (naming, args, defaults, docstrings, errors)
- §4 Module Dictionary (check what already exists)
- §5 Development Workflow (existence check → scaffold → maintain)
- §5.4 Backward compatibility table
- §6 Extensibility Rules (errors, logging, performance)

If `PROJECT_CONTEXT.md` is missing, stop and report — the skill assumes it.

## Hard rules (do not violate)

1. **Project-agnosticism gate (§2).** No hard-coded URLs, labels, error
   messages, country codes, or business rules. Lift to YAML under
   `test_data/` or to a keyword argument with a sensible default. If a
   test case is app-specific, **stop and tell the user**; do not generate
   the keyword.
2. **Use the scaffolder.** `python scripts/new_keyword.py --domain
   <domain> --name "<Title Case>" --module <snake>` (add `--python` for
   Python `@keyword`). Never freehand a new resource or library file.
3. **Never call `_helpers.resource` from tests.** Tests call public
   keywords only.
4. **Every public keyword is callable as `Keyword Name    ${locator}`.**
   All other arguments default.
5. **Every assertion uses `msg=...`** and quotes expected, actual,
   locator, and what was attempted. Never let a failure say only
   "Assertion failed."
6. **Backward compatibility.** Apply §5.4's table — never rename
   arguments, tighten defaults, or remove keywords without a deprecation
   path.

## Input format

The user provides a path to a markdown file. The recommended shape is one
H2 per test case with bulleted attributes:

```markdown
## Validate Postal Code Field

- **Domain**: form_validation
- **Input shape**: text input, max 10 chars
- **Validation rules**:
  - Required (empty rejected)
  - Format: `\d{5}(-\d{4})?` (US ZIP) — keep extensible per country via YAML
  - Reject letters
- **Error surface**: visible element with text "Invalid ZIP" OR `error_locator` arg
- **Trigger**: blur (default), submit (optional)
- **Reference data**: `test_data/postal_codes.yaml` already exists — reuse if shape fits

## Validate Password Strength Meter

- **Domain**: ui_validation
- ...
```

If the file uses a different but reasonable structure, work with it.
If it's ambiguous, ask before generating code.

## Workflow

Follow these steps in order. Do not skip ahead.

### 1. Read the test-cases file

Read the markdown file the user pointed at. Summarize back the test cases
you found (one line each: candidate keyword name, domain, one-line
purpose). Confirm with the user before proceeding if the count is large
(> 5) or if any case looks app-specific.

### 2. Existence check (per case)

For each candidate keyword:

```bash
# Resource keywords:
grep -rn "^<Candidate Name>" form_validation api_validation ui_validation data_generators

# Python @keyword decorators:
grep -rn '@keyword("<Candidate Name>")' libraries/
```

Cross-reference §4 Module Dictionary in `PROJECT_CONTEXT.md`. If a
suitable keyword exists, **propose extending or composing with it**
instead of creating a new one — and stop to confirm with the user.

### 3. Pick the layer (per case)

Per §2 decision rule:

- Orchestration / Robot flow / Browser interaction → `.resource` under
  the right domain (`form_validation/`, `api_validation/`,
  `ui_validation/`, `data_generators/`).
- Pure computation / SDK wrap / exception handling / non-trivial data
  manipulation → Python `@keyword` in `libraries/*.py`.

State the choice in one sentence.

### 4. Scaffold

Run the scaffolder:

```bash
python scripts/new_keyword.py \
    --domain <domain> \
    --name "<Title Case Keyword Name>" \
    --module <snake_case_module>
```

Add `--python` for a Python helper. Confirm the three artifacts appear:
the `.resource` (or `.py`), `tests/test_<module>.robot`, and a new row
in `docs/COVERAGE.md`.

### 5. Write the self-test FIRST (TDD)

Replace the `Fail TODO(...)` stub in `tests/test_<module>.robot` with:

- At least one positive case (valid input, error must NOT be visible).
- At least one negative case per validation rule (each invalid input
  surfaces the expected error).
- A `Run Keyword And Expect Error    *` wrapper around a deliberately
  wrong call to prove the keyword can fail (see existing
  `test_required_field.robot :: Non-Required Field Raises A Clear
  Failure` for the canonical pattern).

Then:
```bash
robot --dryrun tests/test_<module>.robot   # parse-check
robot tests/test_<module>.robot            # must FAIL — no impl yet
```

If the test passes before you've implemented anything, the test is wrong.
Stop and fix the test.

### 6. Implement the keyword

Fill in the generated `.resource` (or `.py`):

- Replace every `TODO(new_keyword.py)` marker.
- Compose existing keywords where possible (e.g. call `Validate
  Required Field`, `Validate Max Length` rather than re-implementing).
- For composite keywords with branching success conditions
  (truncate-or-error), use `Run Keyword And Return Status` and an
  explicit `Should Be True ${a} or ${b}` — see `Validate Email Field`
  step 4.
- If the keyword needs reference data, add a YAML file under
  `test_data/` (per §6.4 — never inline app-specific values).

Iterate until the self-test passes.

### 7. Run the full offline suite

```bash
robot -d results --exclude network tests/
```

The new test must pass. Pre-existing tests must still pass — if any
regress, you broke something.

### 8. Regenerate the keyword catalog

```bash
./scripts/generate-keyword-catalog.sh
```

Commit the updated HTML alongside the keyword change.

### 9. Update `docs/COVERAGE.md`

Replace the placeholder TODO row the scaffolder appended with the real
self-test name(s). Match the existing table format (see how other rows
are written).

### 10. Add a CHANGELOG entry

Under "Unreleased" in `CHANGELOG.md`, add a one-line entry describing
the new keyword(s).

### 11. Commit

One commit per keyword family, message style matching existing history:

```
feat(<domain>): add Validate <Thing> Field

Co-Authored-By: <agent identifier>
```

If you added a new YAML file, include it in the same commit.

## Reporting back

For each keyword, report:

- Existence-check result (commands run + output).
- Layer chosen (one sentence).
- Files created / modified.
- Test commands run + output (dryrun, full suite).
- Commit SHA.
- Any open concerns or follow-ups.

If you stopped at the agnosticism gate, report the case, the
app-specific concern, and a proposed generic alternative.

## Reference

- `tests/test_required_field.robot` — minimal self-test pattern.
- `tests/test_email_field.robot` — composite keyword self-test.
- `form_validation/email_field.resource` — composite keyword pattern.
- `libraries/phone_helpers.py` — Python `@keyword` pattern.
- `.claude/skills/extend-common-keywords/test-cases-template.md` — the
  recommended input file format.

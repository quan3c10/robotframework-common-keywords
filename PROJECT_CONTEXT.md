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

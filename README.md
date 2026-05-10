# common-keywords — Reusable Validation Keyword Package for Robot Framework

**One-line validations for complete scenarios.** A call like
`Validate Email Field    ${locator}    max_length=100` runs **28+ internal
assertions** (required, 23 invalid formats, max-length boundary, valid case).
The package ships 40+ project-agnostic keywords across three categories:

- **Form validation** — required / text length / character class / email /
  phone (country-aware via `phonenumbers`) / URL / number / date / password
  (policy-driven) / file upload / dropdown.
- **API validation** — status codes, JSON Schema (Draft 2020-12) via
  `jsonschema`, response time, pagination envelopes, error-response format.
- **UI validation** — element state (enabled / disabled / readonly / visible /
  focused / placeholder), form behaviour (submit gating, inline blur
  validation, data preservation across navigation), accessibility (aria-label,
  tab order, label association).

No project coupling — selectors come in as arguments, country / policy /
schema rules come from YAML, nothing is hard-coded to any specific app.

---

## Installation

### Option A — Git submodule (current default)

```bash
git submodule add https://github.com/yourcompany/robot-common-keywords common-keywords
git submodule update --init --recursive
```

Add the Python dependencies to your project's `requirements.txt`:

```
faker>=25.0
jsonschema>=4.0
phonenumbers>=8.13
robotframework-browser>=18.0   # for form_validation and ui_validation
robotframework-requests>=0.9.7 # for api_validation self-tests
pyyaml>=6.0
```

Then run `pip install -r requirements.txt`.

### Option B — Pip install (preferred long-term)

The package ships with a `pyproject.toml` so it installs with stock pip.
Until we publish to PyPI, install from a local path or git URL:

```bash
# From a local clone:
pip install /path/to/keyword-driven-framework/common-keywords

# Or from GitHub (subdirectory):
pip install "git+https://github.com/yourcompany/keyword-driven-framework.git#subdirectory=common-keywords"
```

After installation, imports work via the package path:

```robot
Resource    robot_common_keywords/form_validation/email_field.resource
Resource    robot_common_keywords/api_validation/status_codes.resource
```

#### Editable installs (`pip install -e`)

Code and packaged data live under `src/robot_common_keywords/` and install as
namespace `robot_common_keywords`. Run from the repo root:

```bash
pip install -e .
robot --dryrun tests/
```

Self-tests resolve `Resource robot_common_keywords/…` like consumers; avoid
suite-level `Library` declarations that duplicate a `.resource` which already
imports the same Python helper (Robot would register duplicate keyword names).

Rule of thumb:

- **Developing this repo** → `pip install -e .` then `robot tests/…`; Playwright
  must be installed locally (`rfbrowser init`).
- **Downstream consumers** → `pip install` from wheel/sdist as usual unless you
  choose editable for debugging.

### Browser Library

Form-validation and UI-validation keywords drive pages via Browser Library
(Playwright). One-time per machine:

```bash
rfbrowser init
```

---

## Quick start

Save this file, point it at a form on your app, run it. **15 lines, 6
validation families covered.**

```robot
*** Settings ***
Library     Browser
Resource    common-keywords/form_validation/required_field.resource
Resource    common-keywords/form_validation/email_field.resource
Resource    common-keywords/form_validation/phone_field.resource
Resource    common-keywords/form_validation/password_field.resource
Suite Setup       New Browser  chromium  headless=${True}
Suite Setup       New Context
Suite Setup       New Page

*** Test Cases ***
Registration Form Validates All Inputs
    Go To    https://your.app/register
    Validate Required Field    [data-test='first-name']
    Validate Email Field       [data-test='email']       max_length=100
    Validate Phone Field       [data-test='phone']       country=US
    Validate Password Field    [data-test='password']    policy=strong
```

That one test drives **60+ internal assertions**. Change `country=US` to
`country=VN` and the same test runs against Vietnamese phone-number rules
with zero code changes.

For more realistic examples, see [`docs/EXAMPLES.md`](docs/EXAMPLES.md).

---

## Documentation

| Doc | What it covers |
|---|---|
| [`docs/EXAMPLES.md`](docs/EXAMPLES.md) | Five real-world scenarios: registration, login, checkout, API validation, dropdown-heavy filter UI. |
| [`docs/INTEGRATION.md`](docs/INTEGRATION.md) | How project-specific business keywords (Phase 1 style) call into common keywords. Before/after diff. |
| [`docs/COVERAGE.md`](docs/COVERAGE.md) | Every public keyword → its self-test. Hand-maintained. |
| [`docs/keyword-catalog/`](docs/keyword-catalog/) | Auto-generated HTML docs (via `libdoc`) for every resource + Python library. One file per module. |

### Regenerate the keyword catalog

After adding or editing a keyword:

```bash
./common-keywords/scripts/generate-keyword-catalog.sh
```

The script overwrites every file in `docs/keyword-catalog/` with fresh
libdoc output. Commit the updated HTML alongside your keyword change.

---

## Directory layout

```
common-keywords/
├── form_validation/                      # 10 resources, 31 public keywords
│   ├── required_field.resource
│   ├── text_field.resource               # max/min/range length, char classes,
│   │                                     # whitespace, case sensitivity
│   ├── email_field.resource
│   ├── phone_field.resource              # country-aware
│   ├── url_field.resource                # optional require_https
│   ├── number_field.resource             # min/max/decimals, integer,
│   │                                     # positive, currency, percentage
│   ├── date_field.resource               # format/range/future/past/range
│   ├── password_field.resource           # policy-driven
│   ├── file_upload.resource              # type / size / multi-file
│   ├── dropdown_field.resource           # exact/any order, default, required,
│   │                                     # searchable
│   └── _helpers.resource                 # internal — don't call from tests
│
├── api_validation/                       # 5 resources, 12 public keywords
│   ├── status_codes.resource             # 2xx/4xx/5xx + exact
│   ├── response_schema.resource          # Draft 2020-12 + field-type checks
│   ├── response_time.resource
│   ├── pagination.resource               # envelope + metadata consistency
│   └── error_responses.resource          # standard format + field-mention
│
├── ui_validation/                        # 3 resources, 13 public keywords
│   ├── element_state.resource            # 7 states + placeholder
│   ├── form_behavior.resource            # submit gate, inline blur, preservation
│   └── accessibility.resource            # aria-label, tab order, labels
│
├── data_generators/
│   └── invalid_data.resource             # @{INVALID_EMAILS}, SQL/XSS probes
│
├── test_data/
│   ├── valid_emails.yaml                 # 12 positive samples
│   ├── invalid_emails.yaml               # 23 malformed samples
│   ├── phone_formats.yaml                # VN / US / JP / UK
│   ├── password_policies.yaml            # basic / strong / banking
│   ├── boundary_strings.yaml             # curated edge cases
│   ├── schemas/                          # JSON Schemas (Draft 2020-12)
│   │   ├── user.schema.json
│   │   ├── error.schema.json
│   │   └── paginated_users.schema.json
│   └── sample_files/                     # 5 tiny files for file-upload tests
│
├── libraries/                            # 7 Python libraries, 26 keywords
│   ├── api_validation_helpers.py
│   ├── boundary_generator.py
│   ├── date_helpers.py
│   ├── faker_wrapper.py                  # wraps `faker` for 15 locales
│   ├── file_helpers.py
│   ├── password_helpers.py
│   └── phone_helpers.py                  # wraps `phonenumbers`
│
├── tests/                                # 86 self-tests across 17 files
│   └── fixtures/text_form.html           # single deterministic HTML fixture
│
└── docs/                                 # this README's friends
```

---

## Running the self-tests

From the project root:

```bash
source .venv/bin/activate

# Offline (no network) — 77 tests:
robot -d results --exclude network common-keywords/tests/

# Full suite including jsonplaceholder.com integration (4 tests) — 86 tests:
robot -d results common-keywords/tests/
```

All 86 self-tests pass with every run. See [`docs/COVERAGE.md`](docs/COVERAGE.md)
for the full keyword → test mapping.

---

## Contributing

### When does a keyword belong in `common-keywords`?

Ask: *"Would Team B, working on a totally different product, use this
keyword as-is?"* If yes, it's common. If it references a specific URL,
field name, business rule, or validation message unique to your app, it's
**project-specific** and belongs in `keywords/business/` — not here.

### How to add a new validation keyword

1. **Pick the right resource file.** One file per domain — see the directory
   layout above. If your keyword doesn't fit, open a discussion before
   creating a new resource.
2. **Give the keyword sensible defaults.** A tester should be able to call
   it with just a locator: `Validate Foo Field    ${locator}`. All other
   parameters should have sensible defaults.
3. **Error messages must be descriptive.** Never let a failure say only
   "Assertion failed" — quote the expected and actual values, the field
   locator, and what was tried.
4. **Write a self-test.** Every new keyword requires one in
   `common-keywords/tests/`. We use a deterministic local HTML fixture
   (`tests/fixtures/text_form.html`) for flake-free runs; extend it if
   your keyword needs new behaviour.
5. **Update the coverage report.** Add a row to
   [`docs/COVERAGE.md`](docs/COVERAGE.md).
6. **Regenerate the keyword catalog** via
   `./scripts/generate-keyword-catalog.sh` and commit the updated HTML.

### How to add a new country / policy / schema

No code changes required.

- **Phone country**: add an entry under `countries:` in
  `test_data/phone_formats.yaml`. See existing VN / US / JP / UK entries
  for the shape.
- **Password policy**: add an entry under `policies:` in
  `test_data/password_policies.yaml`.
- **JSON Schema**: drop a new `.schema.json` into `test_data/schemas/`.
  Pass its path via the keyword's `schema_path` argument.

### Self-test requirement (no self-test = not merged)

Every PR that adds or changes a keyword must include a self-test that
**fails** on the old code and **passes** on the new code. The CI runs
both `robot --dryrun common-keywords/tests/` and the full live suite.

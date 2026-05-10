# Changelog

All notable changes to `robotframework-common-keywords` are recorded here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## Unreleased

Nothing yet on top of **0.1.1** — add bullets here while developing the next version.

## [0.1.1] — 2026-05-10

Layout, packaging, expanded form/UI validation, and phone rules. After `pip install` or
`pip install -e .`, use `Resource robot_common_keywords/...` and `Library robot_common_keywords.libraries...`.

### Packaging & PyPI

- Move package sources under `src/robot_common_keywords/` with setuptools **`package-data`** so
  `.resource`, YAML, and JSON ship in the wheel and resolve from the **`robot_common_keywords`**
  import path.
- **`pyproject.toml`**: author **QuanUH**, **`[project.urls]`** (Homepage / Repository / Issues /
  Changelog), **dynamic `version`** from `robot_common_keywords.__version__.__version__`.
- **`README`**: PyPI + Python-version badges; primary install **`pip install robotframework-common-keywords`**;
  contributor **`pip install -e .`** flow.
- **`scripts/build-and-verify.sh`**: clean → build → **twine check** → wheel **`.resource` / YAML+JSON count**
  parity vs source → smoke install → **`robot --dryrun`** (uses project **`.venv`** when present).
- **`scripts/publish.sh`**: TestPyPI upload → install smoke → **`publish`** confirmation → PyPI upload → smoke.

### BREAKING CHANGE — `Validate Email Field`

- Default **`max_length`** is **`${None}`** (skip max-length assertions). Default **`min_length`** is
  **`${None}`** (skip min-length assertions). Callers who need the RFC-style ceiling must pass **`max_length=254`** (or your product limit).
- Passing **`min_length`** now requires **`> 6`** for the synthesized **`<prefix>u@a.co`** probe; otherwise
  the keyword **`Fail`**s with guidance to omit **`min_length`** to skip min checking.
- **Self-test**: `tests/test_email_field.robot` passes **`max_length=254`** for the full-suite case.

### Changed — `Validate Email Field`

- Invalid-format loop: **`Run Keyword And Continue On Failure`** so every **`invalid_emails.yaml`**
  sample runs; failures aggregate instead of stopping at the first miss.
- Min-length probe: prefix length **`min_length - 7`** so total address length is **`min_length − 1`**
  (one under threshold).
- **`Library robot_common_keywords.libraries.yaml_loader`** for YAML loading (`Load YAML`, **`DotDict`**).

### Added — Form validation

- **`datepicker.resource`** — searchable datepicker filtering + selection populates field.
- **`text_area.resource`** — multiline content preserved round-trip.
- Extend **`number_field.resource`** — rounding rule on blur + leading-zero handling.
- Extend **`tests/fixtures/text_form.html`** — price/quantity, country picker, notes textarea.

### Added — Phone validation & data

- **`Validate Phone Boundary Length`** and **`Validate Phone Country Rule Violations`** (YAML-driven **`country_rule_invalid_samples`**).
- **`include_universal=${True}`** on **`Validate Phone Field`** cycles **`universal_invalid_samples`** when present.
- **`phone_formats.yaml`** — 32-country expansion; **`universal_invalid_samples`** & per-country **`country_rule_invalid_samples`** (e.g. VN / US / UK).
- Stricter **`text_form.html`** phone fixture (digit-count cap; strict-VN field for country-rule tests).

### Added — UI validation

- **`checkbox.resource`** — default/toggle/check-all/indeterminate/auto-check-all.
- **`radio.resource`** — default selection + mutual exclusion.
- **`button.resource`** — conditional visibility + debounced rapid clicks.
- **`link.resource`** — navigates via URL / anchor target assertion.
- **`text_form.html`** — radio/debounce/link/conditional-button fixtures supporting the above.

### Libraries

- **`yaml_loader.py`** — **`Load YAML`**, **`DotDict`** (`${data.countries.VN}`\_-style attribute access).

## [0.1.0] — 2026-04-25 — Initial release

First public version. Ships the full **Phase 2** validation keyword set
delivered alongside the Phase 1 PoC.

### Added — form validation (10 resources, 31 public keywords)

- `required_field.resource` — `Validate Required Field` (blur or submit
  trigger, configurable error message or locator).
- `text_field.resource` — `Validate Max Length`, `Validate Min Length`,
  `Validate Length Range`, `Validate Allowed Characters Only`,
  `Validate Forbidden Characters`, `Validate Whitespace Trimmed`,
  `Validate Case Sensitivity`.
- `email_field.resource` — `Validate Email Field` (one-line composition
  of required + 23 invalid formats + max-length boundary + valid case).
- `phone_field.resource` — `Validate Phone Field` (country-aware via
  YAML), `Validate Country Code Prefix`. Bundled countries: VN, US, JP, UK.
- `url_field.resource` — `Validate URL Field` with `require_https` toggle.
- `number_field.resource` — `Validate Number Field`, `Validate Integer Only`,
  `Validate Positive Number`, `Validate Currency Field`,
  `Validate Percentage Field`.
- `date_field.resource` — `Validate Date Field` (formats: YYYY-MM-DD,
  YY-MM-DD, MM/DD/YYYY, DD/MM/YYYY), `Validate Date Is Future`,
  `Validate Date Is Past`, `Validate Date Range`.
- `password_field.resource` — `Validate Password Field` (policy-driven:
  basic / strong / banking presets), `Validate Password Confirmation Match`,
  `Validate Password Not Equal To Username`.
- `file_upload.resource` — `Validate File Type Restriction`,
  `Validate File Size Limit`, `Validate Multiple Files Allowed`.
- `dropdown_field.resource` — `Validate Dropdown Options Exactly`
  (with `exact_order` toggle), `Validate Dropdown Default Selection`,
  `Validate Dropdown Is Required`, `Validate Dropdown Is Searchable`.

### Added — API validation (5 resources, 12 public keywords)

- `status_codes.resource` — `Response Should Be Success` / `Client Error` /
  `Server Error`, `Response Status Should Be`.
- `response_schema.resource` — `Response Should Match Schema` (Draft 2020-12
  via `jsonschema`), `Response Should Contain Required Fields`,
  `Response Field Should Be Type` (with type aliases).
- `response_time.resource` — `Response Time Should Be Below`.
- `pagination.resource` — `Response Should Be Paginated`,
  `Pagination Metadata Should Be Valid`.
- `error_responses.resource` — `Error Response Should Follow Standard Format`,
  `Validation Error Should Mention Field`.

### Added — UI validation (3 resources, 13 public keywords)

- `element_state.resource` — `Validate Element Is Enabled` / `Disabled` /
  `Readonly` / `Visible` / `Hidden` / `Has Focus` / `Has Placeholder`.
- `form_behavior.resource` — `Validate Submit Button Disabled Until Form Valid`,
  `Validate Inline Validation Triggers On Blur`,
  `Validate Form Preserves Data On Navigation`.
- `accessibility.resource` — `Validate Element Has Aria Label`,
  `Validate Tab Order` (works for any focusable element),
  `Validate Form Fields Have Labels` (checks 4 label mechanisms).

### Added — Python helper libraries

- `boundary_generator.py` — `Generate String With Length` (5 charsets).
- `faker_wrapper.py` — `Generate Fake Email / Name / Phone / Address`
  (15-country locale map).
- `phone_helpers.py` — `Is Valid Phone Number For Country`,
  `Format Phone Number As E164` (wraps `phonenumbers`).
- `date_helpers.py` — `Today As Date`, `Future Date`, `Past Date`,
  `Date Relative To Today`, `Format Date`.
- `password_helpers.py` — `Load Password Policy`,
  `Generate Compliant Password` (up-to-100-retry loop), `Policy As JSON`.
- `file_helpers.py` — `Sample File Path`, `Create Oversize File`
  (tempfile-based), `Delete File If Exists`.
- `api_validation_helpers.py` — Response accessors + schema/required-fields/
  type validators + `Create Mock Response` (for self-tests).

### Added — bundled data

- `test_data/valid_emails.yaml` — 12 positive samples.
- `test_data/invalid_emails.yaml` — 23 malformed samples.
- `test_data/phone_formats.yaml` — VN / US / JP / UK rules with min/max
  length, prefix, valid + invalid samples.
- `test_data/password_policies.yaml` — basic / strong / banking presets.
- `test_data/boundary_strings.yaml` — curated edge-case strings (whitespace,
  unicode, injection probes, fixed-length references).
- `test_data/schemas/` — `user.schema.json`, `error.schema.json`,
  `paginated_users.schema.json` (all Draft 2020-12).
- `test_data/sample_files/` — 5 100-byte files (jpg / png / pdf / exe / txt)
  for file-upload tests.

### Added — package infrastructure

- `pyproject.toml` (setuptools) — package name `robotframework-common-keywords`,
  importable as `robot_common_keywords`.
- `LICENSE` (MIT).
- `README.md` with quick-start, install (git-submodule + pip), contributing.
- `docs/EXAMPLES.md` (5 real-world scenarios).
- `docs/INTEGRATION.md` (how Phase 1 business keywords compose with this package).
- `docs/COVERAGE.md` (every public keyword → its self-test).
- `docs/keyword-catalog/` — 27 auto-generated libdoc HTML pages.
- `scripts/generate-keyword-catalog.sh` — regenerator for the catalog.
- `examples/external-project/` — standalone consumer that imports via the
  pip-installed package path.

### Self-tests

- 86 self-tests across 17 files. All pass (`robot --dryrun` and live).
- `tests/fixtures/text_form.html` — single deterministic HTML fixture
  driving every form/UI validation.

### Known limitations (carried into 0.1.x)

- `pip install -e` (PEP 660 editable) does not expose `.resource` files via
  the package path; use a regular `pip install` for external consumers.
- No cross-schema `$ref` support in JSON Schema validation
  (`paginated_users.schema.json` uses `items: {type: object}` rather than
  `$ref: user.schema.json`).
- Date format support is limited to YYYY-MM-DD / YY-MM-DD / MM/DD/YYYY /
  DD/MM/YYYY — no month-name formats, no timezone-aware comparisons.
- Accessibility checks are **discrete assertions**, not WCAG compliance.
  Use axe-core for full compliance auditing.

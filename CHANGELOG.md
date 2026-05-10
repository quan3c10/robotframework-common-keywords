# Changelog

All notable changes to `robotframework-common-keywords` are recorded here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## Unreleased

- Extend `form_validation/number_field.resource` with 2 keywords:
  rounding-rule check and leading-zero handling (strip-or-error).
- Add `form_validation/datepicker.resource` (2 keywords: search filtering,
  selection populates field).
- Add `form_validation/text_area.resource` (1 keyword: multiline content
  preserved through round-trip).
- Extend `tests/fixtures/text_form.html` with price/quantity inputs,
  country picker widget, and notes textarea.
- Add `ui_validation/checkbox.resource` with 5 keywords for checkbox group
  validation (default state, toggle, check-all, indeterminate state,
  auto-check-all on full selection). Self-tests use new checkbox fixture
  in `tests/fixtures/text_form.html`.
- Add `ui_validation/radio.resource` (2 keywords: default selection, single
  selection).
- Add `ui_validation/button.resource` (2 keywords: conditional visibility,
  debounce on rapid clicks).
- Add `ui_validation/link.resource` (1 keyword: navigates to target via
  URL change).
- Extend `tests/fixtures/text_form.html` with priority/severity radio groups,
  conditional button, debounced button + counter, anchor link + scroll target.
- Extend `form_validation/phone_field.resource` with 2 keywords:
  `Validate Phone Boundary Length` (E.164 min/max digit-count boundaries) and
  `Validate Phone Country Rule Violations` (cycles per-country
  `country_rule_invalid_samples` for apps that enforce R007/R008/R009).
- Add `include_universal=${True}` argument to `Validate Phone Field` so the
  keyword also cycles a top-level `universal_invalid_samples` block (letters,
  SQLi/XSS payloads, Unicode digit variants). Backward-compatible: empty
  list when the YAML doesn't define the block.
- Expand `test_data/phone_formats.yaml` from 4 to 32 countries with rich
  valid samples drawn from the phone-validation test plan; add
  `universal_invalid_samples` and per-country `country_rule_invalid_samples`
  for VN / US / UK.
- Tighten phone fixture validator in `tests/fixtures/text_form.html` to also
  reject digit counts > 15 (E.164 R003); add new strict-VN phone input for
  the country-rule self-test.
- Add `libraries/yaml_loader.py` providing `Load YAML` (returns a recursive
  `DotDict` so callers can use `${data.countries.VN}` attribute syntax). Fix
  pre-existing wrong relative path in `form_validation/phone_field.resource`
  (`../../libraries/...` → `../libraries/...`).

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

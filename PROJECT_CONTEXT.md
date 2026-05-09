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

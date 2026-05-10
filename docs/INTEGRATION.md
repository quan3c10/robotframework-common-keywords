# Integrating `robot_common_keywords` with a Phase 1 Project

How project-specific business keywords (the Phase-1 layer in
`keywords/business/`) compose with the project-agnostic keywords in this
package (install with `pip install -e path/to/robotframework-common-keywords`
or from a published wheel).

- [The layering model](#the-layering-model)
- [The locator boundary](#the-locator-boundary)
- [Before / after: adding form validation to Phase 1](#before--after-adding-form-validation-to-phase-1)
- [The bridge pattern](#the-bridge-pattern)
- [When to fold an assertion into `robot_common_keywords`](#when-to-fold-an-assertion-into-robot_common_keywords)

---

## The layering model

Phase 1's original three-layer architecture:

```
Test Case (Layer 1) — manual testers write here
    ↓ uses
Business Keywords (Layer 2, project-specific)   ← keywords/business/
    ↓ uses
Technical Keywords (Layer 3, project-specific)  ← keywords/technical/
```

With `robot_common_keywords` installed, the picture becomes:

```
Test Case (Layer 1)
    ↓ uses
Business Keywords (Layer 2, project-specific)
    ↓ uses
    ├── Common validation keywords (Layer 2.5, project-agnostic)  ← `robot_common_keywords`
    │       ↓ uses
    │       ├── Python helpers (jsonschema, phonenumbers, faker)
    │       └── Browser Library / RequestsLibrary directly
    │
    └── Technical Keywords (Layer 3, project-specific)
```

**Layer 2 stays project-specific.** The shared validation layer sits *under*
project business keywords — testers still write domain verbs like
`Registration Form Should Validate All Inputs`; the business keyword
delegates the heavy lifting to `robot_common_keywords`.

---

## The locator boundary

Phase 1's business keywords pass **dotted locator names** (`login_page.username_field`)
to their technical layer, which resolves them against a YAML map.

`robot_common_keywords` is agnostic — it takes **raw CSS / Playwright selectors**
as arguments, because it can't know about your project's locator map.

So the boundary crossing is:

```
business/registration_keywords.resource  (uses dotted names)
    ↓ resolves locator via the project's technical layer
    ↓ passes raw selector
robot_common_keywords/form_validation/email_field.resource  (raw selector)
```

Concretely:

```robot
# keywords/business/web/registration_keywords.resource
Email Field Should Pass Full Validation
    ${selector}=    Resolve Locator    register_page.email_field
    Validate Email Field    ${selector}    max_length=100
```

Where `Resolve Locator` is Phase 1's own helper. If you need a shortcut,
define a tiny project-specific wrapper:

```robot
Validate Email Field By Name
    [Arguments]    ${locator_name}    &{kwargs}
    ${selector}=    Resolve Locator    ${locator_name}
    Validate Email Field    ${selector}    &{kwargs}
```

Now tests read `Validate Email Field By Name    register_page.email_field`.

---

## Before / after: adding form validation to Phase 1

> **Note**: Phase 1's shipping login flow doesn't need form-validation
> coverage — saucedemo just validates on submit with a single error
> message. This before/after shows **what the project would have to write
> if it did add a registration form**, with and without `robot_common_keywords`.

### Scenario

A new `/register` page on saucedemo. The team needs to verify:

- First name & last name are required.
- Email field rejects 20+ malformed formats and enforces 100-char max.
- Phone field validates per country.
- Password field enforces the "strong" policy.

### Before — writing it manually at the project layer

```robot
# keywords/business/web/registration_keywords.resource
*** Settings ***
Resource    ../../technical/web_common.resource
Library     Collections
Library     String


*** Keywords ***
First Name Field Should Be Required
    Clear Text    ${REGISTER.first_name}
    Press Keys    ${REGISTER.first_name}    Tab
    Element Should Be Visible    ${REGISTER.first_name_error}

Last Name Field Should Be Required
    Clear Text    ${REGISTER.last_name}
    Press Keys    ${REGISTER.last_name}    Tab
    Element Should Be Visible    ${REGISTER.last_name_error}

Email Field Should Reject Invalid Formats
    @{bad_emails}=    Create List
    ...    plainaddress
    ...    @missing.com
    ...    missing@tld
    ...    spaces in@email.com
    ...    double@@domain.com
    ...    trailing.dot.@domain.com
    ...    <script>@evil.com
    # ...and 15+ more; maintained by hand in THIS project's resource
    FOR    ${bad}    IN    @{bad_emails}
        Clear Text    ${REGISTER.email}
        Type Text     ${REGISTER.email}    ${bad}    delay=0 ms
        Press Keys    ${REGISTER.email}    Tab
        Element Should Be Visible    ${REGISTER.email_error}
    END

Email Field Should Enforce Max Length
    ${boundary}=    Generate Long Alpha    94
    ${valid}=    Set Variable    ${boundary}@a.co
    Clear Text    ${REGISTER.email}
    Type Text    ${REGISTER.email}    ${valid}    delay=0 ms
    Press Keys    ${REGISTER.email}    Tab
    Element Should Not Be Visible    ${REGISTER.email_error}
    ${too_long}=    Generate Long Alpha    95
    ${over}=    Set Variable    ${too_long}@a.co
    Clear Text    ${REGISTER.email}
    Type Text    ${REGISTER.email}    ${over}    delay=0 ms
    Press Keys    ${REGISTER.email}    Tab
    # Either truncated or error visible
    ${value}=    Get Property    ${REGISTER.email}    value
    ${truncated}=    Evaluate    len($value) <= 100
    ${error_shown}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${REGISTER.email_error}
    Should Be True    ${truncated} or ${error_shown}

# Similar 30-line keywords for Phone and Password — each project reinvents
# them. Rough count: ~180 lines to cover the 4 fields.
```

### After — using `robot_common_keywords`

```robot
# keywords/business/web/registration_keywords.resource
# Requires: pip install of this repo (editable or wheel) so Robot resolves
# the package resource paths below.
*** Settings ***
Resource    ../../technical/web_common.resource
Resource    robot_common_keywords/form_validation/required_field.resource
Resource    robot_common_keywords/form_validation/email_field.resource
Resource    robot_common_keywords/form_validation/phone_field.resource
Resource    robot_common_keywords/form_validation/password_field.resource


*** Keywords ***
Registration Form Should Validate All Inputs
    [Documentation]    Applies our org's phone country and password policy
    ...                to the registration form. One business keyword, four
    ...                validations, ~60 assertions under the hood.
    Validate Required Field    ${REGISTER.first_name}
    Validate Required Field    ${REGISTER.last_name}
    Validate Email Field       ${REGISTER.email}       max_length=100
    Validate Phone Field       ${REGISTER.phone}       country=${PHONE_COUNTRY}
    Validate Password Field    ${REGISTER.password}    policy=${PASSWORD_POLICY}
```

### Diff summary

| Concern | Before | After |
|---|---:|---:|
| Lines in business keyword | ~180 | 6 |
| Invalid-email list maintained | by this project | by `robot_common_keywords` (shared across projects) |
| Phone country support | hand-coded per country | YAML entry — zero code |
| Password policy | hard-coded | policy preset (basic/strong/banking) — swap one arg |
| Total assertions fired | ~50 (subset of edge cases) | ~60 (every edge case shipped in `robot_common_keywords`) |

The test case that calls it stays identical:

```robot
# tests/web/registration.robot
*** Test Cases ***
New User Registration Validates All Inputs
    [Tags]    web    registration
    Navigate To Registration Page
    Registration Form Should Validate All Inputs
```

---

## The bridge pattern

When you want to call a common keyword from a business keyword, follow
this shape:

```robot
# keywords/business/web/<feature>_keywords.resource

*** Settings ***
Resource    ../../technical/web_common.resource
Resource    robot_common_keywords/form_validation/email_field.resource


*** Keywords ***
# Wrap the common keyword with project-specific defaults baked in.
Registration Email Should Be Valid
    ${selector}=    Resolve Locator    register_page.email_field
    Validate Email Field
    ...    ${selector}
    ...    max_length=100
    ...    error_locator=[data-test='email-error']
```

Three responsibilities in this wrapper:

1. **Resolve the locator.** Use the project's Phase-1 Resolve Locator to
   turn a dotted name into a raw selector.
2. **Apply project defaults.** Bake in the app's max-email-length,
   error-locator pattern, and any app-specific trigger mode.
3. **Give it a domain name.** `Registration Email Should Be Valid` reads
   like prose in a test case; `Validate Email Field    [data-test='email']    max_length=100`
   is descriptive but not project-domain.

---

## When to fold an assertion into `robot_common_keywords`

Ask, in order:

1. **Is it project-agnostic?** If the keyword references a specific URL,
   selector, error message, or business rule, it stays project-side.
2. **Would another team use it as-is?** If yes, push it down. If no,
   keep it in `keywords/business/`.
3. **Does it exercise a validation-family concept?** Length range,
   character class, date range, status-code family — yes, that's
   `robot_common_keywords` territory.
4. **Does it tie two domain actions together?** E.g. "Fill the checkout
   form and submit it" — that's project-side. It uses common keywords
   internally but the composition is specific to this app.

If you find yourself copy-pasting a keyword between two projects, that's
the signal it belongs in `robot_common_keywords`.

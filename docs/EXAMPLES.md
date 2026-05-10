# Real-world Examples

Five paste-ready scenarios showing `robot_common_keywords` applied to the most
common validation patterns. Each scenario stands alone — copy, swap the
selectors for your app, adjust the data files, run.

- [1. Full user registration form](#1-full-user-registration-form)
- [2. Login form with edge cases](#2-login-form-with-edge-cases)
- [3. Checkout form (address + phone + payment)](#3-checkout-form-address--phone--payment)
- [4. API endpoint full validation](#4-api-endpoint-full-validation)
- [5. Dropdown-heavy filter UI](#5-dropdown-heavy-filter-ui)

---

## 1. Full user registration form

**The scenario**: a sign-up form with name, email, phone, password,
birthdate, country, and avatar upload. One test case, 10 validation calls,
**70+ internal assertions** covered.

```robot
*** Settings ***
Library     Browser
Resource    robot_common_keywords/form_validation/required_field.resource
Resource    robot_common_keywords/form_validation/text_field.resource
Resource    robot_common_keywords/form_validation/email_field.resource
Resource    robot_common_keywords/form_validation/phone_field.resource
Resource    robot_common_keywords/form_validation/password_field.resource
Resource    robot_common_keywords/form_validation/date_field.resource
Resource    robot_common_keywords/form_validation/dropdown_field.resource
Resource    robot_common_keywords/form_validation/file_upload.resource


*** Test Cases ***
Registration Form Full Validation
    [Tags]    registration    regression
    Navigate To Registration Page
    Validate Required Field            [data-test='first-name']
    Validate Length Range              [data-test='first-name']    min=2    max=50
    Validate Email Field               [data-test='email']         max_length=100
    Validate Phone Field               [data-test='phone']         country=VN
    Validate Password Field            [data-test='password']      policy=strong
    Validate Password Confirmation Match    [data-test='password']    [data-test='password-confirm']
    Validate Date Field                [data-test='birthdate']     format=YYYY-MM-DD
    @{countries}=    Create List    Vietnam    United States    Japan    United Kingdom
    Validate Dropdown Options Exactly  [data-test='country']       ${countries}    exact_order=${False}
    @{allowed}=     Create List    jpg    png
    @{rejected}=    Create List    exe    pdf
    Validate File Type Restriction     [data-test='avatar']        allowed_types=${allowed}    rejected_types=${rejected}
    Validate File Size Limit           [data-test='avatar']        max_size_mb=5
```

**What this drives under the hood** — non-exhaustive:

- First name: empty ⇒ error, too short ⇒ error, too long ⇒ error, 49 chars ⇒ OK.
- Email: 1 valid + 23 invalid formats + 254-char boundary + 1-char-over.
- Phone: 3 valid VN samples + 3 invalid + required-when-empty.
- Password: compliant sample accepted + 6 policy-rule violations rejected.
- Birthdate: valid + malformed + far-past + far-future.
- Country: all 4 options present, order-tolerant.
- Avatar: 2 allowed + 2 rejected extensions + 6 MB file rejected.

**~70 assertions in 10 visible lines of test body.**

---

## 2. Login form with edge cases

**The scenario**: a login form where both fields are required, password is
long-capped, and the submit button is gated on both fields having content.
Inline validation fires on blur.

```robot
*** Settings ***
Library     Browser
Resource    robot_common_keywords/form_validation/required_field.resource
Resource    robot_common_keywords/form_validation/text_field.resource
Resource    robot_common_keywords/ui_validation/element_state.resource
Resource    robot_common_keywords/ui_validation/form_behavior.resource


*** Test Cases ***
Login Form Covers Every Edge Case
    [Tags]    login    regression
    Open Login Page

    # Both fields are required — blur-triggered error.
    Validate Required Field    [data-test='username']
    Validate Required Field    [data-test='password']

    # Length caps per security policy.
    Validate Max Length        [data-test='username']    50
    Validate Max Length        [data-test='password']    128

    # Password input is the right type (hides characters).
    Validate Element Has Placeholder    [data-test='password']    Enter your password

    # The submit button is disabled until BOTH fields have content.
    Validate Submit Button Disabled Until Form Valid
    ...    [data-test='submit']
    ...    [data-test='username']
    ...    [data-test='password']

    # Inline format validation fires on blur (not only at submit time).
    Validate Inline Validation Triggers On Blur
    ...    [data-test='username']
    ...    valid_value=admin
    ...    invalid_value=${EMPTY}
    ...    error_locator=[data-test='username-error']
```

---

## 3. Checkout form (address + phone + payment)

**The scenario**: a three-section checkout. Address section has required
fields and a constrained postal-code. Phone validates country-specifically.
Payment section validates card format, CVV, and expiry date.

```robot
*** Settings ***
Library     Browser
Resource    robot_common_keywords/form_validation/required_field.resource
Resource    robot_common_keywords/form_validation/text_field.resource
Resource    robot_common_keywords/form_validation/phone_field.resource
Resource    robot_common_keywords/form_validation/number_field.resource
Resource    robot_common_keywords/form_validation/date_field.resource
Resource    robot_common_keywords/form_validation/dropdown_field.resource


*** Test Cases ***
Checkout Form Complete Validation
    [Tags]    checkout    regression
    Navigate To Checkout

    # Address section
    Validate Required Field      [data-test='street']
    Validate Required Field      [data-test='city']
    Validate Length Range        [data-test='postal-code']    min=5    max=10
    @{countries}=    Create List    United States    Canada    Mexico
    Validate Dropdown Options Exactly    [data-test='country']    ${countries}

    # Contact info — country passed as a parameter; run the same test from
    # Canada by changing this one argument.
    Validate Phone Field         [data-test='phone']    country=US

    # Payment — card rules, CVV, expiry.
    Validate Length Range        [data-test='card-number']    min=13    max=19
    Validate Number Field        [data-test='card-number']    allow_decimal=${False}    allow_negative=${False}
    Validate Integer Only        [data-test='cvv']
    Validate Length Range        [data-test='cvv']    min=3    max=4
    Validate Date Field          [data-test='expiry']    format=MM/YYYY
```

**To run the same test for a Canadian checkout**: change exactly one line
(`country=US` → `country=CA`). No other changes. Add a `CA` entry to
`src/robot_common_keywords/test_data/phone_formats.yaml` (or your installed package copy) and you're done.

---

## 4. API endpoint full validation

**The scenario**: a `GET /users/:id` endpoint. Assert status, response
time, full JSON Schema match, required fields present, and field types.
All in one test, no hidden state.

```robot
*** Settings ***
Library     RequestsLibrary
Resource    robot_common_keywords/api_validation/status_codes.resource
Resource    robot_common_keywords/api_validation/response_schema.resource
Resource    robot_common_keywords/api_validation/response_time.resource
Suite Setup    Create Session    api    https://your.api.example.com    verify=${True}


*** Variables ***
${USER_SCHEMA}    ${CURDIR}/schemas/user.schema.json


*** Test Cases ***
Full User Endpoint Validation
    [Tags]    api    regression
    ${r}=    GET On Session    api    /users/42

    Response Should Be Success          ${r}
    Response Status Should Be           ${r}    200
    Response Time Should Be Below       ${r}    2
    Response Should Match Schema        ${r}    ${USER_SCHEMA}
    Response Should Contain Required Fields    ${r}    id    email    name    role
    Response Field Should Be Type       ${r}    id             integer
    Response Field Should Be Type       ${r}    email          string
    Response Field Should Be Type       ${r}    address        object
    Response Field Should Be Type       ${r}    address.city   string

Unknown User Returns A Standard Error
    [Tags]    api    regression
    ${r}=    GET On Session    api    /users/9999    expected_status=any

    Response Should Be Client Error                ${r}
    Response Status Should Be                      ${r}    404
    Error Response Should Follow Standard Format   ${r}
    Validation Error Should Mention Field          ${r}    user_id
```

The schema file (`user.schema.json`) can live next to the test or in a
shared fixtures folder — pass its path via `schema_path` / the
`Response Should Match Schema` argument.

---

## 5. Dropdown-heavy filter UI

**The scenario**: a search / filter UI where the filter options are
themselves the behaviour under test. Four dropdowns: status, category, year,
region. Year is required. Region is searchable.

```robot
*** Settings ***
Library     Browser
Resource    robot_common_keywords/form_validation/dropdown_field.resource


*** Test Cases ***
Filter UI Has Correct Dropdowns
    [Tags]    filters    regression
    Navigate To Search Page

    # Status filter — ordered list.
    @{statuses}=    Create List    Any    Active    Paused    Archived
    Validate Dropdown Options Exactly    [data-test='status-filter']    ${statuses}
    Validate Dropdown Default Selection   [data-test='status-filter']    Any

    # Category filter — content matters, order doesn't.
    @{categories}=    Create List    All    Electronics    Books    Clothing    Food
    Validate Dropdown Options Exactly    [data-test='category-filter']    ${categories}
    ...                                  exact_order=${False}

    # Year filter is required (business rule).
    Validate Dropdown Is Required        [data-test='year-filter']
    ...    error_locator=[data-test='year-filter-error']

    # Region filter is a searchable combobox, not a plain <select>.
    Validate Dropdown Is Searchable
    ...    search_input_locator=[data-test='region-search']
    ...    options_container_locator=[data-test='region-options']
    ...    sample_query=eur
```

---

## Composition notes

These examples show **package keywords used directly from tests** (after
`pip install -e .` or installing the wheel). In a
real project, wrap them in project-specific business keywords under
`keywords/business/` to capture org-level defaults (password policy, phone
country, schema path locations). See
[`INTEGRATION.md`](INTEGRATION.md) for the bridge pattern.

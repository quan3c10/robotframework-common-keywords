*** Settings ***
Documentation    Country-aware phone-field validation. Country rules live in
...              ``test_data/phone_formats.yaml``. Adding a new country is a
...              YAML edit — zero keyword changes.
Library          Browser
Library          Collections
Library          String
Library          ../libraries/yaml_loader.py
Library          ../libraries/phone_helpers.py
Resource         _helpers.resource
Resource         required_field.resource


*** Variables ***
${PHONE_FORMATS_PATH}    ${CURDIR}/../test_data/phone_formats.yaml


*** Keywords ***
Validate Phone Field
    [Documentation]    Exercises every sample (valid and invalid) listed for
    ...                ``${country}`` against the target phone input.
    ...
    ...                Same test, different ``country`` → different samples,
    ...                zero code changes. ``country`` is the ISO 3166-1
    ...                alpha-2 code (``VN``, ``US``, ``JP``, ``UK``, ...).
    ...
    ...                When ``include_universal=${True}`` (default) the
    ...                top-level ``universal_invalid_samples`` block from the
    ...                YAML is also cycled — letters, SQLi/XSS payloads,
    ...                Unicode digits, etc. Set ``${False}`` to skip those
    ...                (e.g. for a smoke test or when the field intentionally
    ...                accepts unusual input).
    [Arguments]    ${field_locator}
    ...            ${country}=US
    ...            ${required}=${True}
    ...            ${required_error}=This field is required
    ...            ${invalid_format_error}=valid phone
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}
    ...            ${include_universal}=${True}

    ${country_data}=    Load Phone Format For Country    ${country}

    # Valid samples — each must be accepted.
    FOR    ${good}    IN    @{country_data.valid_samples}
        Type Text    ${field_locator}    ${good}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Not Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}
    END

    # Required check.
    IF    ${required}
        Validate Required Field    ${field_locator}
        ...    error_message=${required_error}
        ...    error_locator=${error_locator}
        ...    trigger=${trigger}
        ...    submit_locator=${submit_locator}
    END

    # Invalid samples — each must be rejected.
    FOR    ${bad}    IN    @{country_data.invalid_samples}
        Type Text    ${field_locator}    ${bad}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}
    END

    # Universal cross-cutting negatives — letters, SQLi, Unicode digits, …
    IF    ${include_universal}
        ${universal}=    Load Universal Invalid Phone Samples
        FOR    ${bad}    IN    @{universal}
            Type Text    ${field_locator}    ${bad}    delay=0 ms    clear=True
            Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
            Validation Error Should Be Visible
            ...    error_message=${invalid_format_error}    error_locator=${error_locator}
        END
    END

Validate Country Code Prefix
    [Documentation]    Asserts that a number starting with ``${prefix}`` is
    ...                accepted by the field. Uses a 9-digit body.
    [Arguments]    ${field_locator}    ${prefix}
    ...            ${error_message}=${EMPTY}
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}
    Type Text    ${field_locator}    ${prefix}123456789    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

Validate Phone Boundary Length
    [Documentation]    Asserts that the field accepts numbers at the minimum
    ...                and maximum digit-count boundaries and rejects one
    ...                position past each. Defaults are E.164: 7 digits min,
    ...                15 digits max (R002 + R003).
    ...
    ...                Pass tighter limits to model an app that enforces a
    ...                narrower range — e.g. ``min_digits=10  max_digits=10``
    ...                for a strict 10-digit US-only field. The fixture under
    ...                test must enforce the same bounds, otherwise the
    ...                keyword fails for the wrong reason.
    ...
    ...                Behavior:
    ...                1. Type ``min_digits`` digits → no error.
    ...                2. Type ``min_digits-1`` digits → error visible.
    ...                3. Type ``max_digits`` digits → no error.
    ...                4. Type ``max_digits+1`` digits → error visible.
    [Arguments]    ${field_locator}
    ...            ${min_digits}=7
    ...            ${max_digits}=15
    ...            ${error_locator}=${EMPTY}
    ...            ${error_message}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    ${at_min}=         Build Digit String    ${min_digits}
    ${below_min}=      Build Digit String    ${{int($min_digits) - 1}}
    ${at_max}=         Build Digit String    ${max_digits}
    ${above_max}=      Build Digit String    ${{int($max_digits) + 1}}

    Type Text    ${field_locator}    ${at_min}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    Type Text    ${field_locator}    ${below_min}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    Type Text    ${field_locator}    ${at_max}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    Type Text    ${field_locator}    ${above_max}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

Validate Phone Country Rule Violations
    [Documentation]    Cycles ``country_rule_invalid_samples`` for ``${country}``
    ...                and asserts each is rejected. Use against an app that
    ...                enforces stricter, country-specific patterns (R007
    ...                Vietnam, R008 NANP, R009 UK mobile).
    ...
    ...                Skipped silently if the YAML entry has no
    ...                ``country_rule_invalid_samples`` block — most apps
    ...                only enforce shape rules, so the absence is normal,
    ...                not an error.
    [Arguments]    ${field_locator}    ${country}
    ...            ${error_message}=${EMPTY}
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    ${country_data}=    Load Phone Format For Country    ${country}
    ${rules}=    Run Keyword And Return Status
    ...    Get From Dictionary    ${country_data}    country_rule_invalid_samples
    IF    not ${rules}    RETURN

    ${samples}=    Get From Dictionary    ${country_data}    country_rule_invalid_samples
    FOR    ${bad}    IN    @{samples}
        Type Text    ${field_locator}    ${bad}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${error_message}    error_locator=${error_locator}
    END


# --- Internal -----------------------------------------------------------------

Load Phone Format For Country
    [Arguments]    ${country}
    ${all}=         Load YAML    ${PHONE_FORMATS_PATH}
    ${upper}=       Convert To Upper Case    ${country}
    ${countries}=   Get From Dictionary    ${all}    countries
    ${has}=         Run Keyword And Return Status    Get From Dictionary    ${countries}    ${upper}
    Should Be True    ${has}
    ...    msg=No entry for country '${upper}' in ${PHONE_FORMATS_PATH}. Add it under 'countries:'.
    ${data}=    Get From Dictionary    ${countries}    ${upper}
    RETURN    ${data}

Load Universal Invalid Phone Samples
    [Documentation]    Returns the top-level ``universal_invalid_samples``
    ...                list, or an empty list if the YAML doesn't define one.
    ${all}=    Load YAML    ${PHONE_FORMATS_PATH}
    ${has}=    Run Keyword And Return Status
    ...    Get From Dictionary    ${all}    universal_invalid_samples
    IF    not ${has}    RETURN    ${{ [] }}
    ${samples}=    Get From Dictionary    ${all}    universal_invalid_samples
    RETURN    ${samples}

Build Digit String
    [Documentation]    Returns a string of ``${count}`` ASCII digits suitable
    ...                for typing into a phone field (cycles 0-9). Used by
    ...                ``Validate Phone Boundary Length``.
    [Arguments]    ${count}
    ${result}=    Evaluate    "".join(str(i % 10) for i in range(int(${count})))
    RETURN    ${result}

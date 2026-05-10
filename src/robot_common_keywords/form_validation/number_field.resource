*** Settings ***
Documentation    Numeric-field validations: range, decimals / integers,
...              positive / negative, currency format, percentage. All
...              project-agnostic.
Library          Browser
Library          String
Library          Collections
Resource         _helpers.resource


*** Keywords ***
Validate Number Field
    [Documentation]    Exercises min / max / decimal / negative rules.
    ...
    ...                - Fills with ``${min}`` (if set) — must be accepted.
    ...                - Fills with ``${max}`` (if set) — must be accepted.
    ...                - Fills with ``${min} - 1`` (if set) — must be rejected.
    ...                - Fills with ``${max} + 1`` (if set) — must be rejected.
    ...                - If ``${allow_decimal}=${False}``, fills ``1.5`` — rejected.
    ...                - If ``${allow_negative}=${False}``, fills ``-1`` — rejected.
    ...                - Fills ``abc`` — rejected.
    ...
    ...                Pass ``min=${None}`` or ``max=${None}`` to skip a bound.
    [Arguments]    ${field_locator}
    ...            ${min}=${None}    ${max}=${None}
    ...            ${allow_decimal}=${True}    ${allow_negative}=${False}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}

    # Happy samples on the bounds.
    IF    $min is not None
        Accept Sample    ${field_locator}    ${min}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END
    IF    $max is not None
        Accept Sample    ${field_locator}    ${max}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END

    # Off-by-one rejections.
    IF    $min is not None
        ${under}=    Evaluate    ${min} - 1
        Reject Sample    ${field_locator}    ${under}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END
    IF    $max is not None
        ${over}=    Evaluate    ${max} + 1
        Reject Sample    ${field_locator}    ${over}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END

    # Decimal gate.
    IF    not ${allow_decimal}
        Reject Sample    ${field_locator}    1.5    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END

    # Negative gate.
    IF    not ${allow_negative}
        Reject Sample    ${field_locator}    -1    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END

    # Non-numeric junk.
    Reject Sample    ${field_locator}    abc    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

Validate Integer Only
    [Documentation]    Accepts ``42``, rejects ``1.5``.
    [Arguments]    ${field_locator}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Accept Sample    ${field_locator}    42    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    1.5    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

Validate Positive Number
    [Documentation]    Accepts ``1``, rejects ``-1`` and ``0``.
    [Arguments]    ${field_locator}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Accept Sample    ${field_locator}    1    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    -1    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    0    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

Validate Currency Field
    [Documentation]    Accepts ``$12.34`` / ``$100``, rejects ``12.34`` / ``$1.2`` / ``abc``.
    ...                ``currency`` is informational — kept in the signature for
    ...                the plan's API and to future-proof against multi-currency apps.
    [Arguments]    ${field_locator}    ${currency}=USD
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Accept Sample    ${field_locator}    $12.34    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Accept Sample    ${field_locator}    $100    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    12.34    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    $1.2    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    abc    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

Validate Percentage Field
    [Documentation]    Accepts 0 / 50 / 100, rejects -1 / 101.
    [Arguments]    ${field_locator}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Validate Number Field    ${field_locator}    min=0    max=100
    ...    allow_decimal=${True}    allow_negative=${False}
    ...    error_message=${error_message}    error_locator=${error_locator}
    ...    trigger=${trigger}    submit_locator=${submit_locator}

Validate Number Rounding Rule
    [Documentation]    Types ``${raw_value}`` into the field, triggers validation,
    ...                then reads the field's current value and asserts it equals
    ...                ``${expected_rounded_value}``.
    ...
    ...                Behavior:
    ...                1. Types ``${raw_value}`` into the field (clears first).
    ...                2. Triggers validation via ``${trigger}``.
    ...                3. Reads the field's ``value`` property after the trigger fires.
    ...                4. Asserts it equals ``${expected_rounded_value}`` (exact string match).
    ...
    ...                Useful for fields that apply server-side or JS rounding on
    ...                blur (e.g. toFixed(2) for price inputs). The assertion is
    ...                string-equal so "1.23" != "1.230" — pass the exact formatted
    ...                string the field emits.
    [Arguments]    ${field_locator}    ${raw_value}    ${expected_rounded_value}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Type Text    ${field_locator}    ${raw_value}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    ${actual}=    Read Field Value    ${field_locator}
    Should Be Equal    ${actual}    ${expected_rounded_value}
    ...    msg=Rounding check failed: typed '${raw_value}', expected '${expected_rounded_value}', got '${actual}'.

Validate Number Disallows Leading Zero
    [Documentation]    Types ``007`` into the field, triggers validation, then
    ...                checks whether the field value was normalised to ``7``
    ...                (strip path) OR whether an error element became visible
    ...                (error path). Passes when either condition is true so
    ...                both fix-in-place and reject-with-message implementations
    ...                satisfy the keyword.
    ...
    ...                Behavior:
    ...                1. Types ``007`` into the field.
    ...                2. Triggers validation via ``${trigger}``.
    ...                3. Reads the field's ``value`` after the trigger.
    ...                4. Asserts ONE of:
    ...                   - the value was normalized to ``7`` (leading zeros stripped), OR
    ...                   - a validation error became visible (matching
    ...                     ``${error_message}`` or ``${error_locator}``).
    ...
    ...                Arguments:
    ...                - ``field_locator``  — Playwright selector of the numeric input.
    ...                - ``trigger``        — ``blur`` (default) or ``submit``.
    ...                - ``submit_locator`` — required when ``trigger=submit``.
    ...                - ``error_message``  — expected error text (used in error-path check).
    ...                - ``error_locator``  — selector for the error element (used in error-path check).
    [Arguments]    ${field_locator}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    Type Text    ${field_locator}    007    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    ${actual}=    Read Field Value    ${field_locator}
    ${stripped}=    Run Keyword And Return Status
    ...    Should Be Equal    ${actual}    7
    ...    msg=Expected leading zeros stripped to '7', got '${actual}'.
    ${error_visible}=    Run Keyword And Return Status
    ...    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}    timeout=2s
    Should Be True    ${stripped} or ${error_visible}
    ...    msg=Leading-zero check failed: value is '${actual}' and no error is visible.


# --- Internal ---

Accept Sample
    [Arguments]    ${field_locator}    ${sample}    ${trigger}    ${submit_locator}
    ...            ${error_locator}    ${error_message}
    Type Text    ${field_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

Reject Sample
    [Arguments]    ${field_locator}    ${sample}    ${trigger}    ${submit_locator}
    ...            ${error_locator}    ${error_message}
    Type Text    ${field_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

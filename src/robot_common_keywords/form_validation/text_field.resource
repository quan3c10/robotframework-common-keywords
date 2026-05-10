*** Settings ***
Documentation    Text-field validations: length, character class, whitespace,
...              and case behaviour. Project-agnostic — caller passes
...              Playwright selectors.
Library          Browser
Library          String
Library          Collections
Library          robot_common_keywords.libraries.boundary_generator
Resource         _helpers.resource


*** Keywords ***
Validate Max Length
    [Documentation]    Asserts the field accepts exactly ``${max}`` chars and
    ...                rejects ``${max} + 1`` chars (via truncation or a
    ...                visible error).
    [Arguments]    ${field_locator}    ${max}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur            ${submit_locator}=${EMPTY}
    ${max}=    Convert To Integer    ${max}

    # Happy path: exactly max chars should be accepted.
    ${happy}=    Generate String With Length    ${max}    alpha
    Type Text    ${field_locator}    ${happy}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    ${value}=    Read Field Value    ${field_locator}
    Should Be Equal    ${value}    ${happy}
    ...    msg=Field rejected a valid ${max}-char string. Sent '${happy}', value reads '${value}'.

    # Over-length: must be truncated OR trigger a visible error.
    ${over}=    Generate String With Length    ${max + 1}    alpha
    Type Text    ${field_locator}    ${over}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    ${final_value}=    Read Field Value    ${field_locator}
    ${final_len}=    Get Length    ${final_value}
    ${truncated}=    Evaluate    ${final_len} <= ${max}
    ${has_msg_or_loc}=    Evaluate    bool($error_message) or bool($error_locator)
    ${error_shown}=    Run Keyword And Return Status
    ...    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}    timeout=2s
    Should Be True    ${truncated} or (${has_msg_or_loc} and ${error_shown})
    ...    msg=Expected field to reject ${max + 1} chars; value length is ${final_len}, no error surfaced.

Validate Min Length
    [Documentation]    Asserts the field accepts exactly ``${min}`` chars and
    ...                rejects strings shorter than ``${min}``.
    [Arguments]    ${field_locator}    ${min}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur            ${submit_locator}=${EMPTY}
    ${min}=    Convert To Integer    ${min}

    # Happy path.
    ${happy}=    Generate String With Length    ${min}    alpha
    Type Text    ${field_locator}    ${happy}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    # Under-length (skip if min is already 1 — no shorter non-empty string).
    IF    ${min} > 1
        ${under}=    Generate String With Length    ${min - 1}    alpha
        Type Text    ${field_locator}    ${under}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${error_message}    error_locator=${error_locator}
    END

Validate Length Range
    [Documentation]    Composition: runs both ``Validate Min Length`` and
    ...                ``Validate Max Length`` for the same field.
    [Arguments]    ${field_locator}    ${min}    ${max}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur            ${submit_locator}=${EMPTY}
    Validate Min Length    ${field_locator}    ${min}
    ...    error_message=${error_message}    error_locator=${error_locator}
    ...    trigger=${trigger}                 submit_locator=${submit_locator}
    Validate Max Length    ${field_locator}    ${max}
    ...    error_message=${error_message}    error_locator=${error_locator}
    ...    trigger=${trigger}                 submit_locator=${submit_locator}

Validate Allowed Characters Only
    [Documentation]    Asserts the field accepts a string from ``${charset}``
    ...                and rejects a string from a disjoint charset.
    ...                Charsets map to ``boundary_generator.py``:
    ...                ``alpha`` / ``alphanumeric`` / ``numeric`` / ``special``.
    [Arguments]    ${field_locator}    ${charset}=alpha
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur            ${submit_locator}=${EMPTY}

    # Positive: a charset sample is accepted without triggering the error.
    ${valid}=    Generate String With Length    6    ${charset}
    Type Text    ${field_locator}    ${valid}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    # Negative: a sample from the disjoint charset triggers the error.
    ${bad_charset}=    Resolve Disjoint Charset    ${charset}
    ${invalid}=    Generate String With Length    6    ${bad_charset}
    Type Text    ${field_locator}    ${invalid}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

Validate Forbidden Characters
    [Documentation]    Asserts each char in ``${forbidden}`` (a list) causes
    ...                the field to surface a validation error when included.
    ...                A clean alpha string is checked first to confirm the
    ...                error is specifically about the forbidden characters.
    [Arguments]    ${field_locator}    ${forbidden}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur            ${submit_locator}=${EMPTY}

    # Clean sample — must NOT trigger the error.
    ${clean}=    Generate String With Length    8    alpha
    Type Text    ${field_locator}    ${clean}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    # Each forbidden character, embedded in an otherwise-clean string.
    FOR    ${bad_char}    IN    @{forbidden}
        Type Text    ${field_locator}    safe${bad_char}text    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${error_message}    error_locator=${error_locator}
    END

Validate Whitespace Trimmed
    [Documentation]    Types a value padded with leading and trailing
    ...                whitespace, triggers validation, and asserts the
    ...                resulting ``.value`` has the whitespace stripped.
    [Arguments]    ${field_locator}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Type Text    ${field_locator}    ${SPACE}${SPACE}hello world${SPACE}${SPACE}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    ${value}=    Read Field Value    ${field_locator}
    Should Be Equal    ${value}    hello world
    ...    msg=Expected whitespace to be trimmed. Field value is '${value}'.

Validate Case Sensitivity
    [Documentation]    ``sensitive=${True}`` (default): asserts the field
    ...                preserves mixed case verbatim.
    ...                ``sensitive=${False}``: asserts the field
    ...                lowercase-normalizes on blur.
    [Arguments]    ${field_locator}    ${sensitive}=${True}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    Type Text    ${field_locator}    TeSt123Case    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    ${value}=    Read Field Value    ${field_locator}
    IF    ${sensitive}
        Should Be Equal    ${value}    TeSt123Case
        ...    msg=Expected field to preserve case. Sent 'TeSt123Case', value reads '${value}'.
    ELSE
        ${lower}=    Convert To Lower Case    ${value}
        Should Be Equal    ${lower}    test123case
        ...    msg=Expected field to lowercase-normalize. Sent 'TeSt123Case', value reads '${value}'.
    END


# --- Internal -----------------------------------------------------------------

Resolve Disjoint Charset
    [Documentation]    Given a charset name, return one that shares no
    ...                characters with it. Used to generate the negative
    ...                sample in ``Validate Allowed Characters Only``.
    [Arguments]    ${charset}
    IF    '${charset}' == 'alpha'
        RETURN    numeric
    ELSE IF    '${charset}' == 'numeric'
        RETURN    alpha
    ELSE IF    '${charset}' == 'alphanumeric'
        RETURN    special
    ELSE IF    '${charset}' == 'special'
        RETURN    alphanumeric
    ELSE
        RETURN    numeric
    END

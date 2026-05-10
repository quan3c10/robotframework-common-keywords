*** Settings ***
Documentation    Email-field validation. The single public keyword
...              ``Validate Email Field`` composes five checks so a tester
...              can cover a whole field in one line.
Library          Browser
Library          Collections
Library          robot_common_keywords.libraries.yaml_loader
Library          robot_common_keywords.libraries.boundary_generator
Resource         _helpers.resource
Resource         required_field.resource
Resource         text_field.resource


*** Variables ***
${VALID_EMAILS_PATH}      ${CURDIR}/../test_data/valid_emails.yaml
${INVALID_EMAILS_PATH}    ${CURDIR}/../test_data/invalid_emails.yaml


*** Keywords ***
Validate Email Field
    [Documentation]    One-line full validation of an email input.
    ...
    ...                Runs, in order:
    ...                1. Valid case — an RFC-safe email must be accepted.
    ...                2. Required — if ``required=${True}`` (default), empty
    ...                   value must surface the required error.
    ...                3. Invalid-format loop — every entry in
    ...                   ``test_data/invalid_emails.yaml`` must be rejected.
    ...                   Uses ``Run Keyword And Continue On Failure`` so **all**
    ...                   samples are exercised and every failure is reported.
    ...                4. Max length *(optional)* — default ``max_length=${None}`` skips
    ...                   this check. When an integer is given, an email of exactly
    ...                   that many chars is accepted and one char longer is rejected
    ...                   (truncation or error).
    ...                5. Min length *(optional)* — default ``min_length=${None}`` skips
    ...                   this check. When an integer is given, a well-formed email
    ...                   one character under that length is rejected. The built-in
    ...                   probe uses a ``<prefix>u@a.co`` pattern and only runs when
    ...                   ``min_length > 6`` so the address stays syntactically plausible.
    ...
    ...                ``error_locator`` is preferred over ``error_message``
    ...                when the app has a single error span per field — it
    ...                avoids accidental text collisions with field labels.
    [Arguments]    ${field_locator}
    ...            ${max_length}=${None}
    ...            ${min_length}=${None}
    ...            ${required}=${True}
    ...            ${required_error}=This field is required
    ...            ${invalid_format_error}=valid email
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    ${max_is_none}=    Run Keyword And Return Status    Should Be Equal    ${max_length}    ${None}
    ${has_max}=    Set Variable If    ${max_is_none}    ${False}    ${True}
    ${min_is_none}=    Run Keyword And Return Status    Should Be Equal    ${min_length}    ${None}
    ${has_min}=    Set Variable If    ${min_is_none}    ${False}    ${True}

    # 1. Valid case.
    Type Text    ${field_locator}    test.user@example.com    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${invalid_format_error}    error_locator=${error_locator}

    # 2. Required.
    IF    ${required}
        Validate Required Field    ${field_locator}
        ...    error_message=${required_error}
        ...    error_locator=${error_locator}
        ...    trigger=${trigger}
        ...    submit_locator=${submit_locator}
    END

    # 3. Invalid-format loop — continue through all samples so every failure surfaces.
    ${invalid}=    Load YAML    ${INVALID_EMAILS_PATH}
    FOR    ${bad_email}    IN    @{invalid.invalid_emails}
        Type Text    ${field_locator}    ${bad_email}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Run Keyword And Continue On Failure
        ...    Validation Error Should Be Visible
        ...    error_message=${invalid_format_error}
        ...    error_locator=${error_locator}
    END

    # 4. Max length — only when caller passes ``max_length`` (not ``${None}``).
    IF    ${has_max}
        ${max_length}=    Convert To Integer    ${max_length}
        ${domain}=         Set Variable    @a.co
        ${local_len}=      Evaluate    ${max_length} - len("${domain}")
        Should Be True     ${local_len} >= 1
        ...    msg=max_length (${max_length}) too small to fit "${domain}"
        ${local}=          Generate String With Length    ${local_len}    alpha
        ${happy_email}=    Set Variable    ${local}${domain}
        Type Text    ${field_locator}    ${happy_email}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Not Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}

        ${over_local}=    Generate String With Length    ${local_len + 1}    alpha
        ${over_email}=    Set Variable    ${over_local}${domain}
        Type Text    ${field_locator}    ${over_email}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        ${final_value}=    Read Field Value    ${field_locator}
        ${final_len}=      Get Length    ${final_value}
        ${truncated}=      Evaluate    ${final_len} <= ${max_length}
        ${error_shown}=    Run Keyword And Return Status
        ...    Validation Error Should Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}    timeout=2s
        Should Be True    ${truncated} or ${error_shown}
        ...    msg=Expected email field to reject ${max_length + 1}-char email; got length ${final_len}, no error.
    END

    # 5. Min length — only when caller passes ``min_length`` (not ``${None}``) and ``> 6``
    #    so prefix + ``u@a.co`` (6 chars) can form a probe one byte under the threshold.
    IF    ${has_min}
        ${min_length}=    Convert To Integer    ${min_length}
        IF    ${min_length} <= 6
            Fail    min_length (${min_length}) must be greater than 6 for this keyword's synthesized short-email probe, or omit min_length (default) to skip min-length checking.
        END
        ${prefix_len}=    Evaluate    int(${min_length}) - 7
        Should Be True    ${prefix_len} >= 0
        ...    msg=Internal: expected prefix_len >= 0 for min_length (${min_length})
        ${short_local}=    Generate String With Length    ${prefix_len}    alpha
        ${short_email}=    Set Variable    ${short_local}u@a.co
        Type Text    ${field_locator}    ${short_email}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}
    END

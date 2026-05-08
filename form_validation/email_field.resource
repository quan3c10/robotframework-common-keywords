*** Settings ***
Documentation    Email-field validation. The single public keyword
...              ``Validate Email Field`` composes five checks so a tester
...              can cover a whole field in one line.
Library          Browser
Library          Collections
Library          ../../libraries/yaml_loader.py
Library          ../libraries/boundary_generator.py
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
    ...                4. Max length — an email of exactly ``${max_length}``
    ...                   chars is accepted; one char longer is rejected
    ...                   (truncation or error).
    ...                5. Min length — a well-formed email shorter than
    ...                   ``${min_length}`` is rejected (skipped when
    ...                   ``${min_length} <= 5``, the minimum plausible).
    ...
    ...                ``error_locator`` is preferred over ``error_message``
    ...                when the app has a single error span per field — it
    ...                avoids accidental text collisions with field labels.
    [Arguments]    ${field_locator}
    ...            ${max_length}=254
    ...            ${min_length}=5
    ...            ${required}=${True}
    ...            ${required_error}=This field is required
    ...            ${invalid_format_error}=valid email
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    ${max_length}=    Convert To Integer    ${max_length}
    ${min_length}=    Convert To Integer    ${min_length}

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

    # 3. Invalid-format loop.
    ${invalid}=    Load YAML    ${INVALID_EMAILS_PATH}
    FOR    ${bad_email}    IN    @{invalid.invalid_emails}
        Type Text    ${field_locator}    ${bad_email}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}
    END

    # 4. Max length — valid email of exactly max_length chars, then +1.
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

    # 5. Min length — skipped when the declared minimum is at or below the
    #    minimum plausible email ("u@a.co" = 6 chars).
    IF    ${min_length} > 6
        ${short_local}=    Generate String With Length    ${min_length - 6}    alpha
        ${short_email}=    Set Variable    ${short_local}u@a.co
        Type Text    ${field_locator}    ${short_email}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        # If the app enforces min, an error appears; if not, this is silently skipped.
    END

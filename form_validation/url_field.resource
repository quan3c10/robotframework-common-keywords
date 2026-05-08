*** Settings ***
Documentation    URL-field validation.
Library          Browser
Library          Collections
Resource         _helpers.resource
Resource         required_field.resource


*** Keywords ***
Validate URL Field
    [Documentation]    Asserts URL validation on the field.
    ...
    ...                ``require_https=${True}``: a plain ``http://`` URL must
    ...                be rejected; only ``https://`` is accepted.
    ...                ``require_https=${False}`` (default): any parseable
    ...                URL is accepted, malformed strings are rejected.
    [Arguments]    ${field_locator}
    ...            ${require_https}=${False}
    ...            ${required}=${True}
    ...            ${required_error}=This field is required
    ...            ${invalid_format_error}=valid URL
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    ${valid}=    Set Variable If    ${require_https}    https://example.com    http://example.com
    Type Text    ${field_locator}    ${valid}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${invalid_format_error}    error_locator=${error_locator}

    # Always-valid https URL passes regardless of the require_https mode.
    Type Text    ${field_locator}    https://www.example.com/path?query=1    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${invalid_format_error}    error_locator=${error_locator}

    # If require_https is on, a plain http URL must be rejected.
    IF    ${require_https}
        Type Text    ${field_locator}    http://insecure.example.com    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
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

    # Malformed URLs — all must be rejected.
    @{invalid_urls}=    Create List
    ...    not-a-url
    ...    just text with spaces
    ...    ://no-scheme
    ...    http://
    ...    https://
    FOR    ${bad}    IN    @{invalid_urls}
        Type Text    ${field_locator}    ${bad}    delay=0 ms    clear=True
        Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
        Validation Error Should Be Visible
        ...    error_message=${invalid_format_error}    error_locator=${error_locator}
    END

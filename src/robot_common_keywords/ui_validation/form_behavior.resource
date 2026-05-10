*** Settings ***
Documentation    Project-agnostic form-behaviour assertions: submit-gating,
...              blur-triggered inline validation, data preservation across
...              caller-defined navigation.
Library          Browser
Library          Collections
Resource         ../form_validation/_helpers.resource


*** Variables ***
${FORM_DEFAULT_TIMEOUT}    3s


*** Keywords ***
Validate Submit Button Disabled Until Form Valid
    [Documentation]    Verifies the three-state lifecycle:
    ...                1. All required fields empty  → submit **disabled**.
    ...                2. All required fields filled → submit **enabled**.
    ...                3. One required field cleared → submit **disabled** again.
    [Arguments]    ${submit_locator}    @{required_field_locators}

    Should Not Be Empty    ${required_field_locators}
    ...    msg=required_field_locators list cannot be empty.

    # Step 1: everything empty.
    FOR    ${loc}    IN    @{required_field_locators}
        Clear Text    ${loc}
    END
    Wait For Elements State    ${submit_locator}    disabled    timeout=${FORM_DEFAULT_TIMEOUT}
    ...    message=Expected submit disabled when required fields are empty.

    # Step 2: everything filled.
    FOR    ${idx}    ${loc}    IN ENUMERATE    @{required_field_locators}
        Type Text    ${loc}    filled_${idx}    delay=0 ms    clear=True
    END
    Wait For Elements State    ${submit_locator}    enabled    timeout=${FORM_DEFAULT_TIMEOUT}
    ...    message=Expected submit enabled once all required fields have values.

    # Step 3: clear one — gate should close again.
    ${first}=    Get From List    ${required_field_locators}    0
    Clear Text    ${first}
    Wait For Elements State    ${submit_locator}    disabled    timeout=${FORM_DEFAULT_TIMEOUT}
    ...    message=Expected submit disabled after clearing a required field.


Validate Inline Validation Triggers On Blur
    [Documentation]    Asserts the field validates on blur, not only on
    ...                submit. Types a valid value → Tab → no error; types
    ...                ``invalid_value`` → Tab → error appears.
    [Arguments]    ${field_locator}
    ...            ${valid_value}=valid
    ...            ${invalid_value}=${EMPTY}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}

    # Valid path: error must NOT appear after blur.
    Type Text    ${field_locator}    ${valid_value}    delay=0 ms    clear=True
    Press Keys    ${field_locator}    Tab
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}    timeout=2s

    # Invalid path: error MUST appear after blur.
    Clear Text    ${field_locator}
    Type Text    ${field_locator}    ${invalid_value}    delay=0 ms    clear=True
    Press Keys    ${field_locator}    Tab
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}    timeout=2s


Validate Form Preserves Data On Navigation
    [Documentation]    Fills each field with a unique marker
    ...                (``preserve_<index>``), invokes ``navigate_action``
    ...                (a user-defined keyword that takes a trip away and
    ...                back — e.g. hide/show a section, click back/forward),
    ...                then reads each field's value back and asserts it
    ...                survived.
    [Arguments]    ${navigate_action}    @{field_locators}

    Should Not Be Empty    ${field_locators}
    ...    msg=field_locators list cannot be empty.

    FOR    ${idx}    ${loc}    IN ENUMERATE    @{field_locators}
        Type Text    ${loc}    preserve_${idx}    delay=0 ms    clear=True
    END

    Run Keyword    ${navigate_action}

    FOR    ${idx}    ${loc}    IN ENUMERATE    @{field_locators}
        ${current}=    Get Property    ${loc}    value
        Should Be Equal    ${current}    preserve_${idx}
        ...    msg=Field '${loc}' lost its value. Expected 'preserve_${idx}', got '${current}'.
    END

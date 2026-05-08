*** Settings ***
Documentation    Country-aware phone-field validation. Country rules live in
...              ``test_data/phone_formats.yaml``. Adding a new country is a
...              YAML edit — zero keyword changes.
Library          Browser
Library          Collections
Library          String
Library          ../../libraries/yaml_loader.py
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
    [Arguments]    ${field_locator}
    ...            ${country}=US
    ...            ${required}=${True}
    ...            ${required_error}=This field is required
    ...            ${invalid_format_error}=valid phone
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

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


# --- Internal -----------------------------------------------------------------

Load Phone Format For Country
    [Arguments]    ${country}
    ${all}=      Load YAML    ${PHONE_FORMATS_PATH}
    ${upper}=    Convert To Upper Case    ${country}
    ${has}=      Run Keyword And Return Status    Get From Dictionary    ${all.countries}    ${upper}
    Should Be True    ${has}
    ...    msg=No entry for country '${upper}' in ${PHONE_FORMATS_PATH}. Add it under 'countries:'.
    ${data}=    Get From Dictionary    ${all.countries}    ${upper}
    RETURN    ${data}

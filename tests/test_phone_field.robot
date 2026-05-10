*** Settings ***
Documentation    Self-tests for Validate Phone Field. Same keyword, two
...              countries — proves the country parameter is all you need.
Library          Browser
Resource         robot_common_keywords/form_validation/phone_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Phone Field Works For Vietnam
    [Tags]    p2    form-validation    phone    country-VN
    Validate Phone Field    [data-test='phone-input']
    ...    country=VN
    ...    required=${False}
    ...    error_locator=[data-test='phone-error']

Phone Field Works For US Without Code Change
    [Tags]    p2    form-validation    phone    country-US
    Validate Phone Field    [data-test='phone-input']
    ...    country=US
    ...    required=${False}
    ...    error_locator=[data-test='phone-error']

Phone Field Works For Japan
    [Tags]    p2    form-validation    phone    country-JP
    Validate Phone Field    [data-test='phone-input']
    ...    country=JP
    ...    required=${False}
    ...    error_locator=[data-test='phone-error']

Phone Field Works For United Kingdom
    [Tags]    p2    form-validation    phone    country-UK
    Validate Phone Field    [data-test='phone-input']
    ...    country=UK
    ...    required=${False}
    ...    error_locator=[data-test='phone-error']

Phone Field Works For Germany Smoke
    [Tags]    p2    form-validation    phone    country-DE    smoke
    Validate Phone Field    [data-test='phone-input']
    ...    country=DE
    ...    required=${False}
    ...    include_universal=${False}
    ...    error_locator=[data-test='phone-error']

Country Code Prefix Is Accepted
    [Tags]    p2    form-validation    phone    prefix
    Validate Country Code Prefix    [data-test='phone-input']    +84
    ...    error_locator=[data-test='phone-error']

Universal Invalid Samples Are Cycled By Default
    [Tags]    p2    form-validation    phone    universal
    # The VN entry's country invalid_samples are minimal — this test fails if
    # the universal block stops being applied (e.g. include_universal logic
    # regresses) because the default expects letters/SQLi/Unicode to also
    # surface the error.
    Validate Phone Field    [data-test='phone-input']
    ...    country=VN
    ...    required=${False}
    ...    error_locator=[data-test='phone-error']

Universal Invalid Samples Skipped When Opted Out
    [Tags]    p2    form-validation    phone    universal
    Validate Phone Field    [data-test='phone-input']
    ...    country=VN
    ...    required=${False}
    ...    include_universal=${False}
    ...    error_locator=[data-test='phone-error']

Phone Boundary Length Holds At E164 Limits
    [Tags]    p2    form-validation    phone    boundary
    Validate Phone Boundary Length    [data-test='phone-input']
    ...    error_locator=[data-test='phone-error']

VN Strict Field Rejects Country Rule Violations
    [Tags]    p2    form-validation    phone    country-rule
    Validate Phone Country Rule Violations    [data-test='phone-strict-vn-input']
    ...    country=VN
    ...    error_locator=[data-test='phone-strict-vn-error']

Country Rule Violations Skipped When Country Has No Strict Rules
    [Tags]    p2    form-validation    phone    country-rule
    # DE has no country_rule_invalid_samples — keyword must early-return
    # without typing anything.
    Validate Phone Country Rule Violations    [data-test='phone-input']
    ...    country=DE
    ...    error_locator=[data-test='phone-error']

Phonenumbers Library Cross-Check Agrees With Our Samples
    [Tags]    p2    form-validation    phone    libphonenumber
    ${is_valid}=    Is Valid Phone Number For Country    +14155552671    US
    Should Be True    ${is_valid}
    ${e164}=    Format Phone Number As E164    (415) 555-2671    US
    Should Be Equal    ${e164}    +14155552671


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

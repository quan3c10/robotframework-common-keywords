*** Settings ***
Documentation    Self-tests for Validate Phone Field. Same keyword, two
...              countries — proves the country parameter is all you need.
Library          Browser
Resource         ../form_validation/phone_field.resource
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

Country Code Prefix Is Accepted
    [Tags]    p2    form-validation    phone    prefix
    Validate Country Code Prefix    [data-test='phone-input']    +84
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

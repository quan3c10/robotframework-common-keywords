*** Settings ***
Documentation    Self-tests for every keyword in form_validation/number_field.resource.
Library          Browser
Resource         ../form_validation/number_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Number Field Enforces Range And Rejects Non-Numeric
    [Tags]    p2    form-validation    number    range
    Validate Number Field    [data-test='number-input']    min=0    max=100
    ...    error_locator=[data-test='number-error']

Integer Only Field Rejects Decimals
    [Tags]    p2    form-validation    number    integer
    Validate Integer Only    [data-test='integer-input']
    ...    error_locator=[data-test='integer-error']

Positive Number Field Rejects Zero And Negatives
    [Tags]    p2    form-validation    number    positive
    Validate Positive Number    [data-test='positive-input']
    ...    error_locator=[data-test='positive-error']

Currency Field Enforces Dollar Format
    [Tags]    p2    form-validation    number    currency
    Validate Currency Field    [data-test='currency-input']
    ...    error_locator=[data-test='currency-error']

Percentage Field Enforces 0-100
    [Tags]    p2    form-validation    number    percentage
    Validate Percentage Field    [data-test='percentage-input']
    ...    error_locator=[data-test='percentage-error']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

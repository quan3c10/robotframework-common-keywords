*** Settings ***
Documentation    Self-tests for every keyword in form_validation/date_field.resource.
Library          Browser
Resource         ../form_validation/date_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Date Field Accepts Well-Formed And Rejects Malformed Input
    [Tags]    p2    form-validation    date    format
    Validate Date Field    [data-test='date-input']    format=YYYY-MM-DD
    ...    error_locator=[data-test='date-error']

Future Date Field Accepts Future And Rejects Past
    [Tags]    p2    form-validation    date    future
    Validate Date Is Future    [data-test='future-date-input']
    ...    error_locator=[data-test='future-date-error']

Past Date Field Accepts Past And Rejects Future
    [Tags]    p2    form-validation    date    past
    Validate Date Is Past    [data-test='past-date-input']
    ...    error_locator=[data-test='past-date-error']

Date Range Enforces Start Before End
    [Tags]    p2    form-validation    date    range
    Validate Date Range
    ...    [data-test='start-date-input']
    ...    [data-test='end-date-input']
    ...    error_locator=[data-test='date-range-error']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

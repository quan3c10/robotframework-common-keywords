*** Settings ***
Documentation    Self-tests for Validate Required Field against a local HTML
...              fixture. The fixture's Name input triggers an error span on
...              blur when empty.
Library          Browser
Resource         robot_common_keywords/form_validation/required_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Required Field Is Detected By Default Error Message
    [Tags]    p2    form-validation    required
    Validate Required Field    [data-test='name-input']

Required Field Is Detected With Explicit Error Locator
    [Tags]    p2    form-validation    required
    Validate Required Field    [data-test='name-input']
    ...    error_locator=[data-test='name-error']

Required Field Is Detected Via Submit Trigger
    [Tags]    p2    form-validation    required    submit-trigger
    Validate Required Field    [data-test='name-input']
    ...    error_locator=[data-test='submit-error']
    ...    trigger=submit
    ...    submit_locator=[data-test='submit-button']

Non-Required Field Raises A Clear Failure
    [Tags]    p2    form-validation    required    negative
    # The Nickname field is not validated as required — the keyword MUST fail
    # here, proving it doesn't silently pass when no error surfaces.
    Run Keyword And Expect Error    *
    ...    Validate Required Field    [data-test='nickname-input']
    ...    error_locator=[data-test='nickname-error-does-not-exist']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

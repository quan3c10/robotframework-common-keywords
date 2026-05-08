*** Settings ***
Documentation    Self-tests for every keyword in form_validation/text_field.resource.
...              Runs against the local HTML fixture where each field exercises
...              one specific validation behavior.
Library          Browser
Resource         ../form_validation/text_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Max Length Enforced By Maxlength Attribute
    [Tags]    p2    form-validation    text    max-length
    Validate Max Length    [data-test='bio-input']    10

Min Length Accepts Boundary And Rejects Under
    [Tags]    p2    form-validation    text    min-length
    Validate Min Length    [data-test='username-input']    3
    ...    error_locator=[data-test='username-error']

Length Range Composes Min And Max
    [Tags]    p2    form-validation    text    length-range
    Validate Length Range    [data-test='username-input']    3    8
    ...    error_locator=[data-test='username-error']

Allowed Characters Only — Alpha Field Rejects Numeric
    [Tags]    p2    form-validation    text    allowed-chars
    Validate Allowed Characters Only    [data-test='firstname-input']    alpha
    ...    error_locator=[data-test='firstname-error']

Forbidden Characters List Triggers Errors
    [Tags]    p2    form-validation    text    forbidden-chars
    @{angle_brackets}=    Create List    <    >
    Validate Forbidden Characters    [data-test='comment-input']    ${angle_brackets}
    ...    error_locator=[data-test='comment-error']

Whitespace Is Trimmed On Blur
    [Tags]    p2    form-validation    text    whitespace
    Validate Whitespace Trimmed    [data-test='email-input']

Case Is Preserved When Sensitive True
    [Tags]    p2    form-validation    text    case
    Validate Case Sensitivity    [data-test='nickname-input']    sensitive=${True}

Case Is Lowercased When Sensitive False
    [Tags]    p2    form-validation    text    case
    Validate Case Sensitivity    [data-test='domain-input']    sensitive=${False}


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/form_behavior.resource.
Library          Browser
Resource         robot_common_keywords/ui_validation/form_behavior.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Submit Button Gated On Required Fields
    [Tags]    p2    ui-validation    form-behavior    submit-gate
    Validate Submit Button Disabled Until Form Valid
    ...    [data-test='gated-submit']
    ...    [data-test='gated-a']
    ...    [data-test='gated-b']

Inline Validation Fires On Blur
    [Tags]    p2    ui-validation    form-behavior    inline-blur
    # The "name-input" from earlier phases is required-on-blur.
    # Valid ≔ non-empty. Invalid ≔ empty ("").
    Validate Inline Validation Triggers On Blur
    ...    [data-test='name-input']
    ...    valid_value=Ada
    ...    invalid_value=${EMPTY}
    ...    error_locator=[data-test='name-error']

Form Preserves Data Across Hide And Show
    [Tags]    p2    ui-validation    form-behavior    preservation
    Validate Form Preserves Data On Navigation    Take Hide-Show Trip
    ...    [data-test='preserve-alpha']
    ...    [data-test='preserve-beta']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

Take Hide-Show Trip
    [Documentation]    Concrete ``navigate_action`` for the preservation
    ...                self-test — clicks Hide then Show.
    Click    [data-test='preserve-hide']
    Click    [data-test='preserve-show']

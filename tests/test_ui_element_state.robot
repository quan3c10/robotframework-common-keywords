*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/element_state.resource.
Library          Browser
Resource         robot_common_keywords/ui_validation/element_state.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Enabled And Disabled Are Detected
    [Tags]    p2    ui-validation    state
    Validate Element Is Enabled     [data-test='enabled-input']
    Validate Element Is Disabled    [data-test='disabled-input']

Readonly Is Detected
    [Tags]    p2    ui-validation    state
    Validate Element Is Readonly    [data-test='readonly-input']

Visible And Hidden Are Detected
    [Tags]    p2    ui-validation    state
    Validate Element Is Visible    [data-test='always-visible-section']
    Validate Element Is Hidden     [data-test='always-hidden-section']

Focus Is Detected
    [Tags]    p2    ui-validation    state    focus
    Focus    [data-test='enabled-input']
    Validate Element Has Focus    [data-test='enabled-input']

Placeholder Is Detected And Compared
    [Tags]    p2    ui-validation    state    placeholder
    Validate Element Has Placeholder    [data-test='placeholder-input']
    Validate Element Has Placeholder    [data-test='placeholder-input']    Enter your name here


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

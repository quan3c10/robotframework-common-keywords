*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/radio.resource.
...              Exercises default selection detection and single-selection
...              enforcement against the priority/severity radio fixture in
...              tests/fixtures/text_form.html.
Library          Browser
Resource         ../ui_validation/radio.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}              chromium
${HEADLESS}             ${True}
${FIXTURE_URL}          file://${CURDIR}/fixtures/text_form.html
${PRIORITY_RADIOS}      [data-test='priority-radio']
${SEVERITY_RADIOS}      [data-test='severity-radio']


*** Test Cases ***
Default Selection — Pre-Checked Radio Detected Correctly
    [Documentation]    Positive: priority group has "medium" checked by default.
    [Tags]    p2    ui-validation    radio
    Validate Radio Default Selection    ${PRIORITY_RADIOS}    expected_value=medium

Default Selection — Wrong Expected Value Fails
    [Documentation]    Negative: asserting "high" is the default must FAIL (medium is).
    [Tags]    p2    ui-validation    radio
    Run Keyword And Expect Error    *
    ...    Validate Radio Default Selection    ${PRIORITY_RADIOS}    expected_value=high

Default Selection — Empty Group Has No Selection
    [Documentation]    Positive: severity group has nothing checked; no expected_value passes.
    [Tags]    p2    ui-validation    radio
    Validate Radio Default Selection    ${SEVERITY_RADIOS}

Default Selection — Empty Group Asserted Incorrectly Fails
    [Documentation]    Negative: asserting severity group has "minor" selected must FAIL.
    [Tags]    p2    ui-validation    radio
    Run Keyword And Expect Error    *
    ...    Validate Radio Default Selection    ${SEVERITY_RADIOS}    expected_value=minor

Single Selection — Priority Group Enforces Mutual Exclusion
    [Documentation]    Positive: clicking first radio then second radio shows only one
    ...                is checked at a time, and values differ.
    [Tags]    p2    ui-validation    radio
    Validate Radio Single Selection    ${PRIORITY_RADIOS}


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

*** Settings ***
Documentation    Self-tests for form_validation/text_area.resource.
...              Uses the notes textarea in tests/fixtures/text_form.html.
Library          Browser
Resource         robot_common_keywords/form_validation/text_area.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Text Area Multiline Content Is Preserved Round-Trip
    [Tags]    p2    form-validation    text-area    multiline
    Validate Text Area Multiline Preserved
    ...    [data-test='notes-textarea']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

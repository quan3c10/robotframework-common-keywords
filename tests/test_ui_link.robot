*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/link.resource.
...              Exercises URL-change navigation via the anchor link fixture in
...              tests/fixtures/text_form.html.
Library          Browser
Resource         robot_common_keywords/ui_validation/link.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}          chromium
${HEADLESS}         ${True}
${FIXTURE_URL}      file://${CURDIR}/fixtures/text_form.html
${JUMP_LINK}        [data-test='jump-link']


*** Test Cases ***
Link Navigates To Anchor Target
    [Documentation]    Positive: clicking the jump-link changes the URL to include
    ...                '#jump-target', confirming anchor navigation occurred.
    [Tags]    p2    ui-validation    link
    ${fragment}=    Set Variable    \#jump-target
    Validate Link Navigates To Target    ${JUMP_LINK}    ${fragment}

Link Navigation — Wrong Expected Substring Fails
    [Documentation]    Negative: asserting the URL contains '#wrong-fragment' after
    ...                clicking the jump-link must FAIL.
    [Tags]    p2    ui-validation    link
    ${bad_fragment}=    Set Variable    \#wrong-fragment
    Run Keyword And Expect Error    *
    ...    Validate Link Navigates To Target    ${JUMP_LINK}    ${bad_fragment}


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

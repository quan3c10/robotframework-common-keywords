*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/checkbox.resource.
...              Exercises default state, toggle, check-all group, indeterminate
...              state, and auto-check-all behaviours against the checkbox fixture
...              section in tests/fixtures/text_form.html.
Library          Browser
Resource         ../ui_validation/checkbox.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}           chromium
${HEADLESS}          ${True}
${FIXTURE_URL}       file://${CURDIR}/fixtures/text_form.html
${CB_UNCHECKED}      [data-test='checkbox-default-unchecked']
${CB_CHECKED}        [data-test='checkbox-default-checked']
${CB_TOGGLE}         [data-test='checkbox-toggle']
${CHECK_ALL}         [data-test='check-all']
${TASK_BOXES}        [data-test='task-checkbox']
${TASK_1}            [data-test='task-checkbox'][data-task='1']


*** Test Cases ***
Default State — Unchecked Is Detected
    [Documentation]    Positive: checkbox-default-unchecked starts unchecked.
    [Tags]    p2    ui-validation    checkbox
    Validate Checkbox Default State    ${CB_UNCHECKED}    checked=${False}

Default State — Checked Is Detected As Wrong Default
    [Documentation]    Negative: checkbox-default-checked is actually checked,
    ...                so asserting it is unchecked must FAIL.
    [Tags]    p2    ui-validation    checkbox
    Run Keyword And Expect Error    *
    ...    Validate Checkbox Default State    ${CB_CHECKED}    checked=${False}

Default State — Checked Is Detected
    [Documentation]    Positive: checkbox-default-checked starts checked.
    [Tags]    p2    ui-validation    checkbox
    Validate Checkbox Default State    ${CB_CHECKED}    checked=${True}

Default State — Unchecked Asserted As Checked Fails
    [Documentation]    Negative: asserting unchecked-by-default as checked must FAIL.
    [Tags]    p2    ui-validation    checkbox
    Run Keyword And Expect Error    *
    ...    Validate Checkbox Default State    ${CB_UNCHECKED}    checked=${True}

Toggle — Checkbox Flips Both Ways
    [Documentation]    Positive: toggle keyword clicks once (unchecked→checked)
    ...                then again (checked→unchecked) and asserts both transitions.
    [Tags]    p2    ui-validation    checkbox
    Validate Checkbox Toggle    ${CB_TOGGLE}

Toggle — Pre-Checked Checkbox Also Toggles
    [Documentation]    Positive: the pre-checked checkbox should also flip both ways.
    [Tags]    p2    ui-validation    checkbox
    Validate Checkbox Toggle    ${CB_CHECKED}

Check All Group — Toggles All On Then Off
    [Documentation]    Positive: clicking master checks all 3 members; clicking
    ...                again unchecks all 3 members.
    [Tags]    p2    ui-validation    checkbox
    Validate Check All Toggles Group    ${CHECK_ALL}    ${TASK_BOXES}

Check All Group — Wrong Master Locator Causes Failure
    [Documentation]    Negative: using the wrong locator for master (a member
    ...                checkbox instead) should cause an assertion error because
    ...                the wiring is not present on a member checkbox.
    [Tags]    p2    ui-validation    checkbox
    Run Keyword And Expect Error    *
    ...    Validate Check All Toggles Group    ${TASK_1}    ${TASK_BOXES}

Indeterminate — Unchecking One Member Sets Master Indeterminate
    [Documentation]    Positive: when all members are checked then one is
    ...                unchecked, the master enters indeterminate state.
    [Tags]    p2    ui-validation    checkbox
    Validate Check All Becomes Indeterminate When One Unchecked
    ...    ${CHECK_ALL}    ${TASK_BOXES}    ${TASK_1}

Auto Check All — Checking Each Member Individually Checks Master
    [Documentation]    Positive: clicking every member one by one until all
    ...                are checked causes master to become checked (not indeterminate).
    [Tags]    p2    ui-validation    checkbox
    Validate Check All Auto Checks When All Selected    ${CHECK_ALL}    ${TASK_BOXES}


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

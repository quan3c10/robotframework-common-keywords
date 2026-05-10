*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/button.resource.
...              Exercises conditional visibility (hidden until trigger action)
...              and debounce on rapid clicks against the ui-controls fixture in
...              tests/fixtures/text_form.html.
Library          Browser
Resource         ../ui_validation/button.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}              chromium
${HEADLESS}             ${True}
${FIXTURE_URL}          file://${CURDIR}/fixtures/text_form.html
${COND_BUTTON}          [data-test='conditional-submit-button']
${TRIGGER}              [data-test='enable-submit-trigger']
${DEBOUNCED_BTN}        [data-test='debounced-save-button']
${DEBOUNCE_COUNTER}     [data-test='debounced-counter']


*** Test Cases ***
Button Hidden Until Checkbox Checked — Passes With Check Action
    [Documentation]    Positive: button is initially hidden; checking the trigger
    ...                makes it visible; unchecking hides it again.
    [Tags]    p2    ui-validation    button
    Validate Button Hidden When Conditions Unmet
    ...    ${COND_BUTTON}    ${TRIGGER}    trigger_action=check

Button Hidden Until Conditions Met — Wrong Trigger Locator Fails
    [Documentation]    Negative: a nonexistent trigger locator causes a timeout
    ...                error when the keyword tries to click/check it.
    [Tags]    p2    ui-validation    button
    Run Keyword And Expect Error    *
    ...    Validate Button Hidden When Conditions Unmet
    ...    ${COND_BUTTON}    [data-test='no-such-element']    trigger_action=check

Debounce — Five Rapid Clicks Increment Counter By Exactly One
    [Documentation]    Positive: 5 rapid clicks on debounced button fire the handler
    ...                once after the debounce window, so counter goes from 0 to 1.
    [Tags]    p2    ui-validation    button
    Validate Button Debounces Rapid Clicks
    ...    ${DEBOUNCED_BTN}    ${DEBOUNCE_COUNTER}    click_count=5    debounce_window=400ms

Debounce — Wrong Counter Locator Fails
    [Documentation]    Negative: a nonexistent counter locator causes a timeout
    ...                error when the keyword tries to read the counter text.
    [Tags]    p2    ui-validation    button
    Run Keyword And Expect Error    *
    ...    Validate Button Debounces Rapid Clicks
    ...    ${DEBOUNCED_BTN}    [data-test='no-such-counter']    click_count=5    debounce_window=400ms


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

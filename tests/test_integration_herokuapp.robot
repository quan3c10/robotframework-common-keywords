*** Settings ***
Documentation    Integration proof: Validate Required Field works against a
...              real public demo site (the-internet.herokuapp.com/login).
...              The site validates on submit and shows a flash message for
...              an invalid username. Separate from the deterministic
...              fixture-based self-tests so network issues can be isolated.
...
...              Tag: ``network`` — exclude with ``-e network`` when offline.
Library          Browser
Resource         robot_common_keywords/form_validation/required_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${LOGIN_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}      chromium
${HEADLESS}     ${True}
${LOGIN_URL}    https://the-internet.herokuapp.com/login


*** Test Cases ***
Herokuapp Login Flags Empty Username On Submit
    [Tags]    p2    form-validation    required    network    integration
    Validate Required Field    [id='username']
    ...    error_message=Your username is invalid
    ...    trigger=submit
    ...    submit_locator=button[type='submit']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

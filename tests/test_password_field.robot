*** Settings ***
Documentation    Self-tests for Validate Password Field. Covers all three
...              presets in password_policies.yaml by reusing the same
...              keyword against three differently-configured fields — one
...              argument (``policy=``) is the only difference.
Library          Browser
Resource         robot_common_keywords/form_validation/password_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}            chromium
${HEADLESS}           ${True}
${FIXTURE_URL}        file://${CURDIR}/fixtures/text_form.html
${BANKING_USERNAME}   ada.lovelace


*** Test Cases ***
Policy Swap Demo — Same Keyword Applied With All Three Policies
    [Documentation]    The acceptance-criterion test: switching
    ...                ``policy=basic`` → ``policy=strong`` → ``policy=banking``
    ...                is a single-argument change. Each call exercises
    ...                strictly more rules than the previous one.
    [Tags]    p2    form-validation    password    policy-swap    demo

    Validate Password Field    [data-test='basic-password-input']
    ...    policy=basic    required=${False}
    ...    error_locator=[data-test='basic-password-error']

    Validate Password Field    [data-test='strong-password-input']
    ...    policy=strong    required=${False}
    ...    error_locator=[data-test='strong-password-error']

    Set Fixture Username    ${BANKING_USERNAME}
    Validate Password Field    [data-test='banking-password-input']
    ...    policy=banking    required=${False}
    ...    username=${BANKING_USERNAME}
    ...    error_locator=[data-test='banking-password-error']

Password Confirmation Must Match
    [Tags]    p2    form-validation    password    confirmation
    Validate Password Confirmation Match
    ...    [data-test='strong-password-input']
    ...    [data-test='confirm-password-input']
    ...    error_locator=[data-test='confirm-password-error']

Password Equal To Username Is Rejected
    [Tags]    p2    form-validation    password    username-check
    Set Fixture Username    ${BANKING_USERNAME}
    Validate Password Not Equal To Username
    ...    [data-test='banking-password-input']    ${BANKING_USERNAME}
    ...    error_locator=[data-test='banking-password-error']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

Set Fixture Username
    [Documentation]    Fixture-only: writes the test username to the JS
    ...                global ``window.currentUsername`` so the banking-policy
    ...                validator can check for the ``forbid_username_substring``
    ...                rule.
    [Arguments]    ${username}
    Evaluate JavaScript    ${None}    () => { window.currentUsername = "${username}"; }

*** Settings ***
Documentation    Self-tests for form_validation/datepicker.resource.
...              Uses the country-picker widget in tests/fixtures/text_form.html.
Library          Browser
Resource         ../form_validation/datepicker.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Datepicker Search Filter — Vietnam Matches Partial Query
    [Tags]    p2    form-validation    datepicker    search
    Validate Datepicker Search Filters Options
    ...    trigger_locator=[data-test='country-picker-trigger']
    ...    search_locator=[data-test='country-search']
    ...    option_locator=[data-test='country-option']
    ...    query=viet
    ...    expected_match_substring=Vietnam

Datepicker Selection — Clicking Option Populates Field
    [Tags]    p2    form-validation    datepicker    selection
    Validate Datepicker Selection Populates Field
    ...    trigger_locator=[data-test='country-picker-trigger']
    ...    field_locator=[data-test='country-input']
    ...    option_locator=[data-test='country-option']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

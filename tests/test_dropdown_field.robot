*** Settings ***
Documentation    Self-tests for every keyword in form_validation/dropdown_field.resource.
Library          Browser
Library          Collections
Resource         ../form_validation/dropdown_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Dropdown Options Match Exactly In DOM Order
    [Tags]    p2    form-validation    dropdown    options    exact-order
    @{expected}=    Create List
    ...    -- select country --
    ...    Vietnam
    ...    United States
    ...    Japan
    ...    United Kingdom
    Validate Dropdown Options Exactly    [data-test='country-select']    ${expected}

Dropdown Options Match Any Order
    [Tags]    p2    form-validation    dropdown    options    any-order
    @{expected}=    Create List
    ...    Japan
    ...    -- select country --
    ...    United Kingdom
    ...    United States
    ...    Vietnam
    Validate Dropdown Options Exactly    [data-test='country-select']    ${expected}
    ...    exact_order=${False}

Dropdown Default Is Placeholder
    [Tags]    p2    form-validation    dropdown    default
    Validate Dropdown Default Selection    [data-test='country-select']    -- select country --

Dropdown Is Required And Reports Error When Empty
    [Tags]    p2    form-validation    dropdown    required
    Validate Dropdown Is Required    [data-test='country-select']
    ...    error_locator=[data-test='country-error']

Searchable Dropdown Filters Options On Query
    [Tags]    p2    form-validation    dropdown    searchable
    Validate Dropdown Is Searchable
    ...    search_input_locator=[data-test='searchable-dropdown-input']
    ...    options_container_locator=[data-test='searchable-dropdown-options']
    ...    sample_query=Viet


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

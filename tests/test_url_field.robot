*** Settings ***
Documentation    Self-tests for Validate URL Field. Covers http/https default,
...              require_https enforcement, and the malformed-URL reject loop.
Library          Browser
Resource         ../form_validation/url_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
URL Field Accepts Http And Https By Default
    [Tags]    p2    form-validation    url    default
    Validate URL Field    [data-test='url-input']
    ...    required=${False}
    ...    error_locator=[data-test='url-error']

URL Field Requires HTTPS When Specified
    [Tags]    p2    form-validation    url    https-only
    Validate URL Field    [data-test='url-https-input']
    ...    require_https=${True}
    ...    required=${False}
    ...    error_locator=[data-test='url-https-error']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

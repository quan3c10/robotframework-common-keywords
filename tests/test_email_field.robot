*** Settings ***
Documentation    Self-tests for Validate Email Field against the local fixture.
Library          Browser
Resource         ../form_validation/email_field.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Email Field Fully Validated In One Line
    [Tags]    p2    form-validation    email
    Validate Email Field    [data-test='email-val-input']
    ...    required=${False}
    ...    error_locator=[data-test='email-val-error']

Email Field Accepts Every Curated Valid Sample
    [Tags]    p2    form-validation    email    valid-samples
    ${valid}=    Load YAML    ${CURDIR}/../test_data/valid_emails.yaml
    FOR    ${good}    IN    @{valid.valid_emails}
        Type Text    [data-test='email-val-input']    ${good}    delay=0 ms    clear=True
        Press Keys    [data-test='email-val-input']    Tab
        Wait For Elements State    [data-test='email-val-error']    hidden    timeout=2s
    END


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

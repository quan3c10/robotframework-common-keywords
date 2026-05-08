*** Settings ***
Documentation    Self-tests for every keyword in ui_validation/accessibility.resource.
...              These keywords are NOT a WCAG compliance check — they assert
...              three specific things. See the resource docstring.
Library          Browser
Resource         ../ui_validation/accessibility.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html


*** Test Cases ***
Aria Label Is Detected On A Button
    [Tags]    p2    ui-validation    accessibility    aria
    Validate Element Has Aria Label    [data-test='aria-button']
    Validate Element Has Aria Label    [data-test='aria-button']    Delete item

Tab Order Follows DOM Order
    [Tags]    p2    ui-validation    accessibility    tab-order
    # Focus starts on tab-a, then Tab should go → tab-b → tab-c.
    Validate Tab Order    [data-test='tab-a']
    ...    [data-test='tab-b']
    ...    [data-test='tab-c']

Labeled Form Passes The Has-Labels Check
    [Tags]    p2    ui-validation    accessibility    labels
    # labeled-a & labeled-b use <label for>; labeled-c uses aria-label.
    Validate Form Fields Have Labels    [data-test='labeled-form']

Unlabeled Form Fails The Has-Labels Check
    [Tags]    p2    ui-validation    accessibility    labels    negative
    Run Keyword And Expect Error    *Form fields without labels*
    ...    Validate Form Fields Have Labels    [data-test='unlabeled-form']


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

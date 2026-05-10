*** Settings ***
Documentation    Self-tests for form_validation/file_upload.resource.
...              Oversize files created mid-test are deleted in Test Teardown
...              — nothing should remain on disk after the suite completes.
Library          Browser
Resource         robot_common_keywords/form_validation/file_upload.resource
Suite Setup      Set Up Browser
Suite Teardown   Close Browser    ALL
Test Setup       Go To    ${FIXTURE_URL}
Test Teardown    Clean Up Temp Files


*** Variables ***
${BROWSER}        chromium
${HEADLESS}       ${True}
${FIXTURE_URL}    file://${CURDIR}/fixtures/text_form.html
${OVERSIZE_PATH}  ${EMPTY}


*** Test Cases ***
Type And Size Restrictions Are Both Enforced
    [Documentation]    Exercises both file-type restriction AND size-limit
    ...                rejection against the same upload field.
    [Tags]    p2    form-validation    file-upload    type    size

    # Type-restriction: jpg/png accepted, pdf/exe/txt rejected.
    @{allowed}=     Create List    jpg    png
    @{rejected}=    Create List    pdf    exe    txt
    Validate File Type Restriction    [data-test='file-input']
    ...    allowed_types=${allowed}
    ...    rejected_types=${rejected}
    ...    error_locator=[data-test='file-error']

    # Size-limit: tiny ok, 6 MB rejected. Keyword returns the oversize path
    # so Test Teardown can delete it.
    ${oversize}=    Validate File Size Limit    [data-test='file-input']
    ...    max_size_mb=5
    ...    error_locator=[data-test='file-error']
    Set Test Variable    ${OVERSIZE_PATH}    ${oversize}

Multiple Files Upload Attaches Every File
    [Tags]    p2    form-validation    file-upload    multi
    Validate Multiple Files Allowed    [data-test='multi-file-input']    allowed=${True}


*** Keywords ***
Set Up Browser
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    New Page

Clean Up Temp Files
    [Documentation]    Runs after every test. Deletes any oversize file this
    ...                test registered via ``${OVERSIZE_PATH}``.
    Run Keyword If Test Failed    Take Screenshot    fullPage=${True}
    Delete File If Exists    ${OVERSIZE_PATH}
    Set Test Variable    ${OVERSIZE_PATH}    ${EMPTY}

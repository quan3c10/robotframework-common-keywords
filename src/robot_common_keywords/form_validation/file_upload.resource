*** Settings ***
Documentation    File-upload validations. Relies on ``<input type="file">``
...              semantics — ``Upload File By Selector`` drives Playwright's
...              ``setInputFiles``, which fires the ``change`` event so
...              client-side validators run.
...
...              Sample files ship under ``test_data/sample_files/`` as
...              100-byte stubs with meaningful extensions. Oversize files
...              are generated at runtime and must be deleted by the caller
...              (typically in ``[Teardown]``).
Library          Browser
Library          Collections
Library          robot_common_keywords.libraries.file_helpers
Resource         _helpers.resource


*** Keywords ***
Validate File Type Restriction
    [Documentation]    Uploads a sample of every allowed extension and asserts
    ...                no error; uploads a sample of every rejected extension
    ...                and asserts an error.
    ...
    ...                ``allowed_types`` / ``rejected_types`` are lists of
    ...                extensions without a leading dot (e.g. ``jpg``, ``png``).
    [Arguments]    ${field_locator}
    ...            ${allowed_types}=${None}
    ...            ${rejected_types}=${None}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}

    IF    $allowed_types is None
        @{allowed_types}=    Create List    jpg    png
    END
    IF    $rejected_types is None
        @{rejected_types}=    Create List    exe    pdf
    END

    FOR    ${ext}    IN    @{allowed_types}
        ${path}=    Sample File Path    ${ext}
        Upload File By Selector    ${field_locator}    ${path}
        Validation Error Should Not Be Visible
        ...    error_message=${error_message}    error_locator=${error_locator}
    END

    FOR    ${ext}    IN    @{rejected_types}
        ${path}=    Sample File Path    ${ext}
        Upload File By Selector    ${field_locator}    ${path}
        Validation Error Should Be Visible
        ...    error_message=${error_message}    error_locator=${error_locator}
    END


Validate File Size Limit
    [Documentation]    Uploads a tiny sample file (accepted) and then a
    ...                runtime-generated file 1 MB over ``max_size_mb``
    ...                (rejected). **Caller must delete the oversize file
    ...                in test teardown** — use
    ...                ``Delete File If Exists    ${OVERSIZE_PATH}``.
    ...
    ...                Returns the absolute path of the oversize file so
    ...                the caller can register it for cleanup.
    [Arguments]    ${field_locator}    ${max_size_mb}=5    ${sample_extension}=jpg
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}

    # Happy path — tiny file of an allowed extension.
    ${small_path}=    Sample File Path    ${sample_extension}
    Upload File By Selector    ${field_locator}    ${small_path}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    # Oversize.
    ${oversize_mb}=    Evaluate    ${max_size_mb} + 1
    ${oversize_path}=    Create Oversize File    ${oversize_mb}    ${sample_extension}
    Upload File By Selector    ${field_locator}    ${oversize_path}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}
    RETURN    ${oversize_path}


Validate Multiple Files Allowed
    [Documentation]    Uploads two files at once and asserts the browser
    ...                accepted both. For ``allowed=${False}``, asserts the
    ...                input only retains the last one (most browsers
    ...                silently drop extras on single-file inputs).
    [Arguments]    ${field_locator}    ${allowed}=${True}
    ...            ${sample_extensions}=${None}

    IF    $sample_extensions is None
        @{sample_extensions}=    Create List    jpg    png
    ELSE
        @{sample_extensions}=    Set Variable    ${sample_extensions}
    END

    @{paths}=    Create List
    FOR    ${ext}    IN    @{sample_extensions}
        ${p}=    Sample File Path    ${ext}
        Append To List    ${paths}    ${p}
    END

    Upload File By Selector    ${field_locator}    @{paths}

    ${count}=    Evaluate JavaScript    ${field_locator}    (el) => el.files.length
    ${expected}=    Set Variable If    ${allowed}    ${{len($paths)}}    1
    Should Be Equal As Integers    ${count}    ${expected}
    ...    msg=Expected ${expected} file(s) attached, got ${count}.

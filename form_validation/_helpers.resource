*** Settings ***
Documentation    Internal helpers shared across form_validation/*.
...              Filename is underscore-prefixed to signal "not part of the
...              public API" — tests should call the validation keywords,
...              not these.
Library          Browser


*** Keywords ***
Trigger Field Validation
    [Documentation]    Fire whatever event the app watches to validate the
    ...                field. ``trigger=blur`` presses Tab on the field;
    ...                ``trigger=submit`` clicks ``${submit_locator}``.
    [Arguments]    ${field_locator}    ${trigger}=blur    ${submit_locator}=${EMPTY}
    IF    '${trigger}' == 'submit'
        Should Not Be Empty    ${submit_locator}
        ...    msg=submit_locator is required when trigger='submit'.
        Click    ${submit_locator}
    ELSE IF    '${trigger}' == 'blur'
        Press Keys    ${field_locator}    Tab
    ELSE
        Fail    Unknown trigger '${trigger}'. Use 'blur' or 'submit'.
    END

Validation Error Should Be Visible
    [Documentation]    Passes when either an element matching
    ...                ``${error_locator}`` is visible OR some visible element
    ...                contains ``${error_message}``. Caller must supply at
    ...                least one.
    [Arguments]    ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${timeout}=5s
    IF    $error_locator != ''
        Wait For Elements State    ${error_locator}    visible    timeout=${timeout}
        ...    message=Expected error element '${error_locator}' to become visible.
    ELSE IF    $error_message != ''
        Wait For Elements State    text=${error_message}    visible    timeout=${timeout}
        ...    message=Expected visible text matching '${error_message}'.
    ELSE
        Fail    Validation Error Should Be Visible: provide error_locator OR error_message.
    END

Validation Error Should Not Be Visible
    [Documentation]    Passes when ``${error_locator}`` is hidden and no
    ...                visible element contains ``${error_message}``.
    [Arguments]    ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${timeout}=2s
    IF    $error_locator != ''
        Wait For Elements State    ${error_locator}    hidden    timeout=${timeout}
        ...    message=Expected error element '${error_locator}' to remain hidden.
    ELSE IF    $error_message != ''
        Run Keyword And Expect Error    *
        ...    Wait For Elements State    text=${error_message}    visible    timeout=${timeout}
    END

Read Field Value
    [Documentation]    Returns the current ``.value`` of the input/textarea.
    [Arguments]    ${field_locator}
    ${value}=    Get Property    ${field_locator}    value
    RETURN    ${value}

*** Settings ***
Documentation    Required-field validation. Project-agnostic: the caller
...              passes the field's Playwright selector and (optionally) the
...              error text / locator they expect to surface.
Library          Browser
Resource         _helpers.resource


*** Keywords ***
Validate Required Field
    [Documentation]    Asserts that ``${field_locator}`` is treated as
    ...                mandatory by the app under test.
    ...
    ...                Behavior:
    ...                1. Clears the field.
    ...                2. Fires the configured trigger (``blur`` by default).
    ...                3. Expects either ``${error_locator}`` to become
    ...                   visible OR a visible element matching
    ...                   ``${error_message}``.
    ...
    ...                Arguments:
    ...                - ``field_locator``  — Playwright selector of the input.
    ...                - ``error_message``  — substring of the visible error
    ...                  text. Default: ``This field is required``.
    ...                - ``error_locator``  — optional selector for the error
    ...                  element (preferred when the error text isn't
    ...                  distinctive).
    ...                - ``trigger``        — ``blur`` (default) or ``submit``.
    ...                - ``submit_locator`` — required when ``trigger=submit``.
    [Arguments]    ${field_locator}
    ...            ${error_message}=This field is required
    ...            ${error_locator}=${EMPTY}
    ...            ${trigger}=blur
    ...            ${submit_locator}=${EMPTY}

    Fill Text    ${field_locator}    ${EMPTY}
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}
    ...    error_locator=${error_locator}

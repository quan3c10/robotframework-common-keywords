*** Settings ***
Documentation    Error-response validations. The "standard format" checked
...              here is the widely-used ``{error, message}`` envelope with
...              optional ``code`` and ``details``. Field names are
...              customisable per-API.
Library          robot_common_keywords.libraries.api_validation_helpers
*** Keywords ***
Error Response Should Follow Standard Format
    [Documentation]    Asserts the response body has at least an ``error``
    ...                and ``message`` field (both strings). Pass custom
    ...                field names if the API under test names them
    ...                differently (e.g. ``code`` / ``description``).
    [Arguments]    ${response}
    ...            ${error_field}=error
    ...            ${message_field}=message
    ${body}=    Response Body    ${response}
    Check Required Fields    ${body}    ${error_field}    ${message_field}
    Assert Response Field Type    ${body}    ${error_field}    string
    Assert Response Field Type    ${body}    ${message_field}  string

Validation Error Should Mention Field
    [Documentation]    Asserts the response body mentions ``field_name``
    ...                anywhere in its JSON representation — useful when
    ...                the exact error-path structure differs per API but
    ...                all you care about is that the offending field is
    ...                identified.
    [Arguments]    ${response}    ${field_name}
    ${body}=    Response Body    ${response}
    Error Response Mentions Field    ${body}    ${field_name}

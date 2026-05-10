*** Settings ***
Documentation    Response status-code assertions. All keywords accept a
...              ``response`` object (a ``requests.Response`` or anything
...              with a ``.status_code`` attribute). The caller is
...              responsible for obtaining that response — this package
...              does **not** manage HTTP sessions.
Library          ../libraries/api_validation_helpers.py


*** Keywords ***
Response Should Be Success
    [Documentation]    Asserts ``response.status_code`` is in the 2xx range.
    [Arguments]    ${response}
    ${code}=    Response Status Code    ${response}
    Should Be True    200 <= ${code} < 300
    ...    msg=Expected a 2xx response, got ${code}.

Response Should Be Client Error
    [Documentation]    Asserts ``response.status_code`` is in the 4xx range.
    [Arguments]    ${response}
    ${code}=    Response Status Code    ${response}
    Should Be True    400 <= ${code} < 500
    ...    msg=Expected a 4xx response, got ${code}.

Response Should Be Server Error
    [Documentation]    Asserts ``response.status_code`` is in the 5xx range.
    [Arguments]    ${response}
    ${code}=    Response Status Code    ${response}
    Should Be True    500 <= ${code} < 600
    ...    msg=Expected a 5xx response, got ${code}.

Response Status Should Be
    [Documentation]    Asserts ``response.status_code`` equals ``expected_code`` exactly.
    [Arguments]    ${response}    ${expected_code}
    ${code}=    Response Status Code    ${response}
    Should Be Equal As Integers    ${code}    ${expected_code}
    ...    msg=Expected status ${expected_code}, got ${code}.

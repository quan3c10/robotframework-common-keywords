*** Settings ***
Documentation    Response-time assertions. Reads ``response.elapsed`` — the
...              time between sending the request and receiving the final
...              byte of the response (excludes DNS). For end-to-end latency
...              tests that include DNS/TLS, use a dedicated performance tool.
Library          robot_common_keywords.libraries.api_validation_helpers
*** Keywords ***
Response Time Should Be Below
    [Documentation]    Asserts the response was received in under ``max_seconds``.
    [Arguments]    ${response}    ${max_seconds}
    ${elapsed}=    Response Elapsed Seconds    ${response}
    Should Be True    ${elapsed} < ${max_seconds}
    ...    msg=Response took ${elapsed}s, expected < ${max_seconds}s.

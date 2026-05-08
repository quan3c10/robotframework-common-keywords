*** Settings ***
Documentation    JSON-schema and field-level validations for API responses.
Library          ../libraries/api_validation_helpers.py


*** Keywords ***
Response Should Match Schema
    [Documentation]    Validates the response body against a JSON Schema
    ...                file (Draft 2020-12). Failures list every offending
    ...                pointer path on its own line.
    [Arguments]    ${response}    ${schema_path}
    ${body}=    Response Body    ${response}
    Validate JSON Schema    ${body}    ${schema_path}

Response Should Contain Required Fields
    [Documentation]    Asserts each of ``fields`` is present as a top-level
    ...                key in the response body. Call with multiple
    ...                positional args: ``... fields=id name email``.
    [Arguments]    ${response}    @{fields}
    ${body}=    Response Body    ${response}
    Check Required Fields    ${body}    @{fields}

Response Field Should Be Type
    [Documentation]    Asserts the value at ``json_path`` (dot-delimited)
    ...                has JSON type ``expected_type``. Accepts aliases:
    ...                ``int`` / ``integer``, ``str`` / ``string``,
    ...                ``list`` / ``array``, ``dict`` / ``object``,
    ...                ``bool`` / ``boolean``, ``number`` (int or float), ``null``.
    [Arguments]    ${response}    ${json_path}    ${expected_type}
    ${body}=    Response Body    ${response}
    Assert Response Field Type    ${body}    ${json_path}    ${expected_type}

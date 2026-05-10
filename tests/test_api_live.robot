*** Settings ***
Documentation    Self-tests for api_validation/* against jsonplaceholder.
...              Tagged ``network`` — exclude with ``-e network`` when offline.
...              RequestsLibrary session is created here; the common-keywords
...              package never manages sessions.
Library          RequestsLibrary
Library          Collections
Resource         robot_common_keywords/api_validation/status_codes.resource
Resource         robot_common_keywords/api_validation/response_schema.resource
Resource         robot_common_keywords/api_validation/response_time.resource
Suite Setup      Create Session    api    https://jsonplaceholder.typicode.com    verify=${True}
Suite Teardown   Delete All Sessions


*** Variables ***
${USER_SCHEMA}    ${CURDIR}/../src/robot_common_keywords/test_data/schemas/user.schema.json


*** Test Cases ***
GET User 1 Returns 2xx
    [Tags]    p2    api-validation    status    network
    ${r}=    GET On Session    api    /users/1
    Response Should Be Success    ${r}
    Response Status Should Be    ${r}    200

GET Unknown User Returns 4xx
    [Tags]    p2    api-validation    status    network
    ${r}=    GET On Session    api    /users/9999    expected_status=any
    Response Should Be Client Error    ${r}
    Response Status Should Be    ${r}    404

GET User 1 Matches User Schema
    [Tags]    p2    api-validation    schema    network
    ${r}=    GET On Session    api    /users/1
    Response Should Match Schema    ${r}    ${USER_SCHEMA}
    Response Should Contain Required Fields    ${r}    id    name    email
    Response Field Should Be Type    ${r}    id      integer
    Response Field Should Be Type    ${r}    name    string
    Response Field Should Be Type    ${r}    address.city    string
    Response Field Should Be Type    ${r}    company.name    string

Response Time Is Below Threshold
    [Tags]    p2    api-validation    performance    network
    ${r}=    GET On Session    api    /users/1
    Response Time Should Be Below    ${r}    5

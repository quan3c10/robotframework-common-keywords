*** Settings ***
Documentation    Self-tests for api_validation/* that do NOT need a live
...              HTTP server. Tests synthesise response bodies as dict
...              literals and call the helper keywords directly — this
...              exercises the validation logic deterministically and
...              runs in under a second.
Library          Collections
Library          robot_common_keywords.libraries.password_helpers
Resource         robot_common_keywords/api_validation/status_codes.resource
Resource         robot_common_keywords/api_validation/pagination.resource
Resource         robot_common_keywords/api_validation/error_responses.resource


*** Variables ***
${USER_SCHEMA}          ${CURDIR}/../src/robot_common_keywords/test_data/schemas/user.schema.json
${PAGINATED_SCHEMA}     ${CURDIR}/../src/robot_common_keywords/test_data/schemas/paginated_users.schema.json
${ERROR_SCHEMA}         ${CURDIR}/../src/robot_common_keywords/test_data/schemas/error.schema.json


*** Test Cases ***
Schema Validation Reports A Bad Field Clearly
    [Documentation]    Demonstrates the acceptance-criterion behaviour:
    ...                schema failure messages name the offending field.
    [Tags]    p2    api-validation    schema    demo
    ${bad_user}=    Create Dictionary
    ...    id=not-a-number
    ...    name=${EMPTY}
    ...    username=bret
    ...    email=x
    Run Keyword And Expect Error    *at 'id'*integer*
    ...    Validate JSON Schema    ${bad_user}    ${USER_SCHEMA}

Well-Formed User Passes Schema Validation
    [Tags]    p2    api-validation    schema
    ${good_user}=    Create Dictionary
    ...    id=${1}    name=Alice    username=alice    email=alice@example.com
    Validate JSON Schema    ${good_user}    ${USER_SCHEMA}

Required Fields Check Passes And Fails As Expected
    [Tags]    p2    api-validation    required-fields
    ${data}=    Create Dictionary    id=${1}    name=Alice
    Check Required Fields    ${data}    id    name
    Run Keyword And Expect Error    *Missing required fields: email*
    ...    Check Required Fields    ${data}    id    name    email

JSON Field Type Helper Returns Canonical Names
    [Tags]    p2    api-validation    field-type
    ${data}=    Evaluate
    ...    {"id": 1, "name": "Alice", "premium": True, "balance": 1.5, "tags": ["a"], "meta": {"x": None}}
    ${t_id}=      Get JSON Field Type    ${data}    id
    ${t_name}=    Get JSON Field Type    ${data}    name
    ${t_prem}=    Get JSON Field Type    ${data}    premium
    ${t_bal}=     Get JSON Field Type    ${data}    balance
    ${t_tags}=    Get JSON Field Type    ${data}    tags
    ${t_null}=    Get JSON Field Type    ${data}    meta.x
    Should Be Equal    ${t_id}      integer
    Should Be Equal    ${t_name}    string
    Should Be Equal    ${t_prem}    boolean
    Should Be Equal    ${t_bal}     number
    Should Be Equal    ${t_tags}    array
    Should Be Equal    ${t_null}    null

Pagination Metadata Is Valid When Self-Consistent
    [Tags]    p2    api-validation    pagination
    @{users}=    Create List
    ${u1}=    Create Dictionary    id=${1}    name=Alice      username=alice  email=a@x.com
    ${u2}=    Create Dictionary    id=${2}    name=Bob        username=bob    email=b@x.com
    Append To List    ${users}    ${u1}    ${u2}
    ${body}=    Create Dictionary
    ...    page=${1}    per_page=${10}    total=${42}    total_pages=${5}    data=${users}
    Validate JSON Schema    ${body}    ${PAGINATED_SCHEMA}
    Check Required Fields    ${body}    page    per_page    total    data
    Assert Response Field Type    ${body}    page        integer
    Assert Response Field Type    ${body}    per_page    integer
    Assert Response Field Type    ${body}    total       integer
    Assert Response Field Type    ${body}    data        array

Error Response Standard Shape Is Validated
    [Tags]    p2    api-validation    error-format
    ${err}=    Create Dictionary
    ...    error=not_found    message=User 9999 does not exist    code=${404}
    Validate JSON Schema    ${err}    ${ERROR_SCHEMA}
    Check Required Fields    ${err}    error    message
    Assert Response Field Type    ${err}    error    string
    Assert Response Field Type    ${err}    message  string

Error Response Mentions A Specific Field
    [Tags]    p2    api-validation    error-format
    ${err}=    Create Dictionary
    ...    error=validation_failed
    ...    message=email is required
    Error Response Mentions Field    ${err}    email
    Run Keyword And Expect Error    *Expected error response to mention 'phone'*
    ...    Error Response Mentions Field    ${err}    phone

# --- Response-object wrappers exercised via mock responses ------------------

Server Error Wrapper Recognises 5xx Status
    [Tags]    p2    api-validation    status    server-error
    ${mock}=    Create Mock Response    503    ${None}
    Response Should Be Server Error    ${mock}
    Response Status Should Be    ${mock}    503

Paginated Response Wrapper Validates Envelope And Metadata
    [Tags]    p2    api-validation    pagination    wrapper
    @{users}=    Create List
    ${u1}=    Create Dictionary    id=${1}    name=Alice
    Append To List    ${users}    ${u1}
    ${body}=    Create Dictionary
    ...    page=${1}    per_page=${10}    total=${42}    total_pages=${5}    data=${users}
    ${mock}=    Create Mock Response    200    ${body}
    Response Should Be Paginated         ${mock}
    Pagination Metadata Should Be Valid  ${mock}

Error Response Wrapper Validates Standard Format And Field Mention
    [Tags]    p2    api-validation    error-format    wrapper
    ${body}=    Create Dictionary    error=validation_failed    message=email is required    code=${400}
    ${mock}=    Create Mock Response    400    ${body}
    Error Response Should Follow Standard Format    ${mock}
    Validation Error Should Mention Field    ${mock}    email

Policy As JSON Serialises A Loaded Policy
    [Tags]    p2    password    helper
    ${p}=        Load Password Policy    basic
    ${raw}=      Policy As JSON    ${p}
    ${parsed}=   Evaluate    __import__('json').loads($raw)
    Dictionary Should Contain Key    ${parsed}    min_length
    Dictionary Should Contain Key    ${parsed}    require_uppercase
    Should Be Equal As Integers    ${parsed}[min_length]    8

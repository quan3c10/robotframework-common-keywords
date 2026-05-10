*** Settings ***
Documentation    Self-tests for Phase 2 data-generator helpers. Proves the
...              boundary generator, Faker wrapper, and invalid-data lists
...              behave as documented.
Library          String
Library          Collections
Library          robot_common_keywords.libraries.boundary_generator
Library          robot_common_keywords.libraries.faker_wrapper
Resource         robot_common_keywords/data_generators/invalid_data.resource


*** Test Cases ***
Boundary Generator Returns Exact Length
    [Tags]    p2    data-generators    boundary
    ${s}=    Generate String With Length    10
    Length Should Be    ${s}    10

Boundary Generator Supports Numeric Charset
    [Tags]    p2    data-generators    boundary
    ${s}=    Generate String With Length    20    numeric
    Length Should Be    ${s}    20
    Should Match Regexp    ${s}    ^\\d{20}$

Boundary Generator Supports Alpha Charset
    [Tags]    p2    data-generators    boundary
    ${s}=    Generate String With Length    15    alpha
    Length Should Be    ${s}    15
    Should Match Regexp    ${s}    ^[A-Za-z]{15}$

Boundary Generator Supports Alphanumeric Charset
    [Tags]    p2    data-generators    boundary
    ${s}=    Generate String With Length    15    alphanumeric
    Length Should Be    ${s}    15
    Should Match Regexp    ${s}    ^[A-Za-z0-9]{15}$

Boundary Generator Supports Special Charset
    [Tags]    p2    data-generators    boundary
    ${s}=    Generate String With Length    10    special
    Length Should Be    ${s}    10
    Should Not Match Regexp    ${s}    [A-Za-z0-9]

Boundary Generator Supports Unicode Charset
    [Tags]    p2    data-generators    boundary
    ${s}=    Generate String With Length    8    unicode
    Length Should Be    ${s}    8

Boundary Generator Handles Length Zero
    [Tags]    p2    data-generators    boundary    edge-case
    ${s}=    Generate String With Length    0
    Should Be Equal    ${s}    ${EMPTY}

Unknown Charset Raises Clear Error
    [Tags]    p2    data-generators    negative
    Run Keyword And Expect Error    *Unknown charset*
    ...    Generate String With Length    5    bogus_charset

Negative Length Raises Clear Error
    [Tags]    p2    data-generators    negative
    Run Keyword And Expect Error    *length must be*
    ...    Generate String With Length    -1

Fake Email Produces Valid Shape
    [Tags]    p2    data-generators    faker
    ${email}=    Generate Fake Email
    Should Match Regexp    ${email}    ^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$

Fake Name Is Nonempty String
    [Tags]    p2    data-generators    faker
    ${name}=    Generate Fake Name
    Should Not Be Empty    ${name}

Fake Phone For US Is Nonempty
    [Tags]    p2    data-generators    faker
    ${phone}=    Generate Fake Phone    US
    Should Not Be Empty    ${phone}

Fake Phone Works For Multiple Countries
    [Tags]    p2    data-generators    faker    country-aware
    FOR    ${country}    IN    US    VN    JP    UK
        ${phone}=    Generate Fake Phone    ${country}
        Should Not Be Empty    ${phone}
    END

Fake Address For US Is Multi-Line
    [Tags]    p2    data-generators    faker
    ${addr}=    Generate Fake Address    US
    Should Not Be Empty    ${addr}
    Should Contain    ${addr}    \n

Invalid Emails List Has 20 Plus Entries
    [Tags]    p2    data-generators    invalid-data
    ${count}=    Get Length    ${INVALID_EMAILS}
    Should Be True    ${count} >= 20

SQL Injection Strings List Has 10 Plus Entries
    [Tags]    p2    data-generators    invalid-data
    ${count}=    Get Length    ${SQL_INJECTION_STRINGS}
    Should Be True    ${count} >= 10

XSS Strings List Has 10 Plus Entries
    [Tags]    p2    data-generators    invalid-data
    ${count}=    Get Length    ${XSS_STRINGS}
    Should Be True    ${count} >= 10

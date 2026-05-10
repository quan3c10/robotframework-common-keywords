*** Settings ***
Documentation    Pagination envelope validations. Assumes a response body
...              shaped roughly as ``{page, per_page, total, data: [...]}``.
...              Field names are customisable per-API via arguments.
Library          ../libraries/api_validation_helpers.py


*** Keywords ***
Response Should Be Paginated
    [Documentation]    Asserts the response body contains (at minimum) the
    ...                data field and each pagination metadata field.
    ...
    ...                Default contract: ``{page, per_page, total, data}``.
    ...                Pass custom field names for APIs that use different
    ...                keys (e.g. ``page_field=pageNumber``).
    [Arguments]    ${response}
    ...            ${data_field}=data
    ...            ${page_field}=page
    ...            ${per_page_field}=per_page
    ...            ${total_field}=total
    ${body}=    Response Body    ${response}
    Check Required Fields    ${body}    ${data_field}    ${page_field}    ${per_page_field}    ${total_field}
    Assert Response Field Type    ${body}    ${data_field}    array

Pagination Metadata Should Be Valid
    [Documentation]    Asserts each pagination field is an integer and the
    ...                numbers are self-consistent:
    ...                - ``page      >= 1``
    ...                - ``per_page  >= 1``
    ...                - ``total     >= 0``
    ...                - ``len(data) <= per_page``
    ...                - ``len(data) <= total``
    [Arguments]    ${response}
    ...            ${data_field}=data
    ...            ${page_field}=page
    ...            ${per_page_field}=per_page
    ...            ${total_field}=total

    ${body}=    Response Body    ${response}
    Assert Response Field Type    ${body}    ${page_field}      integer
    Assert Response Field Type    ${body}    ${per_page_field}  integer
    Assert Response Field Type    ${body}    ${total_field}     integer
    Assert Response Field Type    ${body}    ${data_field}      array

    ${page}=        Evaluate    $body["${page_field}"]
    ${per}=         Evaluate    $body["${per_page_field}"]
    ${total}=       Evaluate    $body["${total_field}"]
    ${data_len}=    Evaluate    len($body["${data_field}"])

    Should Be True    $page >= 1          page must be >= 1, got ${page}.
    Should Be True    $per >= 1           per_page must be >= 1, got ${per}.
    Should Be True    $total >= 0         total must be >= 0, got ${total}.
    Should Be True    $data_len <= $per   Page has ${data_len} items but per_page is ${per}.
    Should Be True    $data_len <= $total     Page has ${data_len} items but total is ${total}.

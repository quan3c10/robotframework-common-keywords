*** Settings ***
Documentation    Date-field validations.
...
...              Supported formats (see libraries/date_helpers.py):
...                - ``YYYY-MM-DD`` (ISO, default)
...                - ``YY-MM-DD``
...                - ``MM/DD/YYYY`` (US)
...                - ``DD/MM/YYYY`` (EU)
...
...              Out of scope: month names, timezones, non-Gregorian calendars.
Library          Browser
Library          Collections
Library          String
Library          ../libraries/date_helpers.py
Resource         _helpers.resource


*** Keywords ***
Validate Date Field
    [Documentation]    Exercises format, min / max boundaries.
    ...
    ...                - A well-formed date is accepted.
    ...                - Malformed strings (``abc``, ``2026/04/24`` with wrong
    ...                  format) are rejected.
    ...                - If ``${min_date}`` is set, a date one day earlier is
    ...                  rejected.
    ...                - If ``${max_date}`` is set, a date one day later is
    ...                  rejected.
    [Arguments]    ${field_locator}
    ...            ${format}=YYYY-MM-DD
    ...            ${min_date}=${None}    ${max_date}=${None}
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}

    # Happy: a plausibly-valid date in-range (or today if unbounded).
    ${today}=    Today As Date    ${format}
    Accept Sample    ${field_locator}    ${today}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

    # Malformed strings.
    Reject Sample    ${field_locator}    abc    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    9999    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

    IF    $min_date is not None
        ${before_min}=    Date Relative To Today    -3650    ${format}
        Reject Sample    ${field_locator}    ${before_min}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END

    IF    $max_date is not None
        ${after_max}=    Date Relative To Today    3650    ${format}
        Reject Sample    ${field_locator}    ${after_max}    ${trigger}    ${submit_locator}
        ...    ${error_locator}    ${error_message}
    END

Validate Date Is Future
    [Arguments]    ${field_locator}
    ...            ${format}=YYYY-MM-DD
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    ${future}=    Future Date    30    ${format}
    ${past}=      Past Date      30    ${format}
    Accept Sample    ${field_locator}    ${future}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    ${past}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

Validate Date Is Past
    [Arguments]    ${field_locator}
    ...            ${format}=YYYY-MM-DD
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}
    ${past}=      Past Date      30    ${format}
    ${future}=    Future Date    30    ${format}
    Accept Sample    ${field_locator}    ${past}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}
    Reject Sample    ${field_locator}    ${future}    ${trigger}    ${submit_locator}
    ...    ${error_locator}    ${error_message}

Validate Date Range
    [Documentation]    Accepts ``start < end``; rejects ``start >= end``.
    ...                Both fields must accept ``YYYY-MM-DD``.
    [Arguments]    ${start_locator}    ${end_locator}
    ...            ${format}=YYYY-MM-DD
    ...            ${error_message}=${EMPTY}    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}

    ${start}=    Date Relative To Today    0     ${format}
    ${end}=      Date Relative To Today    7     ${format}

    # Valid range.
    Type Text    ${start_locator}    ${start}    delay=0 ms    clear=True
    Trigger Field Validation    ${start_locator}    ${trigger}    ${submit_locator}
    Type Text    ${end_locator}      ${end}      delay=0 ms    clear=True
    Trigger Field Validation    ${end_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

    # Inverted range — start >= end.
    Type Text    ${start_locator}    ${end}    delay=0 ms    clear=True
    Trigger Field Validation    ${start_locator}    ${trigger}    ${submit_locator}
    Type Text    ${end_locator}      ${start}    delay=0 ms    clear=True
    Trigger Field Validation    ${end_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}


# --- Internal ---

Accept Sample
    [Arguments]    ${field_locator}    ${sample}    ${trigger}    ${submit_locator}
    ...            ${error_locator}    ${error_message}
    Type Text    ${field_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Not Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

Reject Sample
    [Arguments]    ${field_locator}    ${sample}    ${trigger}    ${submit_locator}
    ...            ${error_locator}    ${error_message}
    Type Text    ${field_locator}    ${sample}    delay=0 ms    clear=True
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}

*** Settings ***
Documentation    Project-agnostic assertions about radio-button group selection.
...              Both keywords drive the Browser Library directly and accept
...              locators as arguments — no business-specific selectors are
...              hard-coded here.
Library          Browser
Library          Collections


*** Keywords ***
Validate Radio Default Selection
    [Documentation]    Asserts the initial checked state of a radio-button group on page load.
    ...
    ...                Enumerates all radios matching ``group_locator``, finds the one
    ...                whose ``checked`` property is ``True``, and compares its ``value``
    ...                attribute to ``expected_value``.
    ...
    ...                1. If ``expected_value`` is non-empty: assert the selected radio's
    ...                   value matches ``expected_value``.
    ...                2. If ``expected_value`` is empty (default): assert no radio is checked.
    ...
    ...                Arguments:
    ...                - ``group_locator``  — Playwright selector matching all radios in the group.
    ...                - ``expected_value`` — Expected value attribute of the pre-checked radio.
    ...                                       Pass ``${EMPTY}`` (or omit) to assert none is selected.
    [Arguments]    ${group_locator}    ${expected_value}=${EMPTY}
    ${radios}=    Get Elements    ${group_locator}
    ${selected_value}=    Set Variable    ${EMPTY}
    FOR    ${radio}    IN    @{radios}
        ${is_checked}=    Get Property    ${radio}    checked
        IF    ${is_checked}
            ${val}=    Get Property    ${radio}    value
            ${selected_value}=    Set Variable    ${val}
        END
    END
    IF    '${expected_value}' == '${EMPTY}'
        Should Be Equal    ${selected_value}    ${EMPTY}
        ...    msg=Radio group '${group_locator}': expected no radio to be selected, but '${selected_value}' is checked.
    ELSE
        Should Be Equal    ${selected_value}    ${expected_value}
        ...    msg=Radio group '${group_locator}': expected default selection '${expected_value}', but got '${selected_value}'.
    END


Validate Radio Single Selection
    [Documentation]    Asserts that a radio-button group enforces mutual exclusion.
    ...
    ...                1. Click the first radio. Assert exactly one radio in the group
    ...                   is checked and record its value.
    ...                2. Click the second radio. Assert exactly one radio is checked.
    ...                   Record its value. Assert the second value differs from the first.
    ...                3. Assert the first radio is now unchecked.
    ...
    ...                Arguments:
    ...                - ``group_locator`` — Playwright selector matching all radios in the group.
    [Arguments]    ${group_locator}
    ${radios}=    Get Elements    ${group_locator}
    ${first}=    Get From List    ${radios}    0
    ${second}=    Get From List    ${radios}    1
    # Step 1: click first radio.
    Click    ${first}
    ${count_after_first}=    _Count Checked Radios    ${group_locator}
    Should Be Equal As Integers    ${count_after_first}    1
    ...    msg=Radio group '${group_locator}': expected exactly 1 checked after clicking first radio, got ${count_after_first}.
    ${first_value}=    Get Property    ${first}    value
    # Step 2: click second radio.
    Click    ${second}
    ${count_after_second}=    _Count Checked Radios    ${group_locator}
    Should Be Equal As Integers    ${count_after_second}    1
    ...    msg=Radio group '${group_locator}': expected exactly 1 checked after clicking second radio, got ${count_after_second}.
    ${second_value}=    Get Property    ${second}    value
    Should Not Be Equal    ${first_value}    ${second_value}
    ...    msg=Radio group '${group_locator}': first value '${first_value}' equals second value '${second_value}' — radios may share the same value attribute.
    # Step 3: first radio must now be unchecked.
    ${first_now_checked}=    Get Property    ${first}    checked
    Should Not Be True    ${first_now_checked}
    ...    msg=Radio group '${group_locator}': expected first radio ('${first_value}') to be unchecked after selecting second radio ('${second_value}'), but it is still checked.


_Count Checked Radios
    [Documentation]    Internal helper. Returns the number of checked radios matching
    ...                ``group_locator``.
    [Arguments]    ${group_locator}
    ${radios}=    Get Elements    ${group_locator}
    ${count}=    Set Variable    ${0}
    FOR    ${radio}    IN    @{radios}
        ${checked}=    Get Property    ${radio}    checked
        IF    ${checked}
            ${count}=    Evaluate    ${count} + 1
        END
    END
    RETURN    ${count}

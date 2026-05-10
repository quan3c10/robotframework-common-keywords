*** Settings ***
Documentation    Project-agnostic assertions about checkbox state and check-all
...              group behaviour. All 5 keywords drive the Browser Library directly
...              and accept locators as arguments — no business-specific selectors
...              are hard-coded here.
Library          Browser
Library          Collections


*** Keywords ***
Validate Checkbox Default State
    [Documentation]    Asserts a checkbox is in the expected initial state on page load.
    ...
    ...                Reads the element's ``checked`` DOM property and compares it
    ...                to the expected value. Useful for verifying that a form opens
    ...                with the correct pre-selected or pre-cleared defaults.
    ...
    ...                Arguments:
    ...                - ``checkbox_locator`` — Playwright selector of the checkbox input.
    ...                - ``checked``          — Expected initial state; ``${False}`` (default)
    ...                                         or ``${True}``.
    [Arguments]    ${checkbox_locator}    ${checked}=${False}
    ${actual}=    Get Property    ${checkbox_locator}    checked
    Should Be Equal    ${actual}    ${checked}
    ...    msg=Default state mismatch for '${checkbox_locator}': expected checked=${checked}, got checked=${actual}.


Validate Checkbox Toggle
    [Documentation]    Asserts that clicking a checkbox toggles its state and
    ...                clicking again restores it.
    ...
    ...                1. Reads the initial ``checked`` state.
    ...                2. Clicks the checkbox; asserts the state has flipped.
    ...                3. Clicks the checkbox again; asserts the state returned to original.
    ...
    ...                Arguments:
    ...                - ``checkbox_locator`` — Playwright selector of the checkbox input.
    [Arguments]    ${checkbox_locator}
    ${initial}=    Get Property    ${checkbox_locator}    checked
    Click    ${checkbox_locator}
    ${after_first}=    Get Property    ${checkbox_locator}    checked
    ${expected_after_first}=    Evaluate    not ${initial}
    Should Be Equal    ${after_first}    ${expected_after_first}
    ...    msg=Toggle failed for '${checkbox_locator}': after first click expected checked=${expected_after_first}, got checked=${after_first}.
    Click    ${checkbox_locator}
    ${after_second}=    Get Property    ${checkbox_locator}    checked
    Should Be Equal    ${after_second}    ${initial}
    ...    msg=Toggle failed for '${checkbox_locator}': after second click expected checked=${initial} (restored), got checked=${after_second}.


Validate Check All Toggles Group
    [Documentation]    Asserts that a "Check All" master checkbox toggles the whole group.
    ...
    ...                1. Ensures a clean start: unchecks any member that is already checked.
    ...                2. Clicks the master; asserts every member is checked.
    ...                3. Clicks the master again; asserts every member is unchecked.
    ...
    ...                The keyword verifies the app's check-all wiring — it does not implement
    ...                the wiring itself.
    ...
    ...                Arguments:
    ...                - ``check_all_locator`` — Playwright selector for the master checkbox.
    ...                - ``group_locator``     — Playwright selector matching all member checkboxes.
    [Arguments]    ${check_all_locator}    ${group_locator}
    # Precondition: ensure master is unchecked, then uncheck members individually.
    ${master_checked}=    Get Property    ${check_all_locator}    checked
    IF    ${master_checked}
        Click    ${check_all_locator}
    END
    ${members}=    Get Elements    ${group_locator}
    FOR    ${member}    IN    @{members}
        ${is_checked}=    Get Property    ${member}    checked
        IF    ${is_checked}
            Click    ${member}
        END
    END
    # Step 1 → click master → all members must be checked.
    Click    ${check_all_locator}
    FOR    ${member}    IN    @{members}
        ${member_checked}=    Get Property    ${member}    checked
        Should Be True    ${member_checked}
        ...    msg=Check-all failed: member '${member}' of '${group_locator}' is NOT checked after clicking '${check_all_locator}'.
    END
    # Step 2 → click master again → all members must be unchecked.
    Click    ${check_all_locator}
    FOR    ${member}    IN    @{members}
        ${member_checked}=    Get Property    ${member}    checked
        Should Not Be True    ${member_checked}
        ...    msg=Uncheck-all failed: member '${member}' of '${group_locator}' is STILL checked after second click on '${check_all_locator}'.
    END


Validate Check All Becomes Indeterminate When One Unchecked
    [Documentation]    Asserts that when all members are checked and one is unchecked,
    ...                the master check-all enters indeterminate state.
    ...
    ...                1. Uses the master to set all members to checked.
    ...                2. Unchecks ``one_member_locator``.
    ...                3. Asserts master's ``indeterminate`` property is ``${True}``
    ...                   and ``checked`` property is ``${False}``.
    ...
    ...                Arguments:
    ...                - ``check_all_locator``  — Playwright selector for the master checkbox.
    ...                - ``group_locator``      — Playwright selector matching all member checkboxes.
    ...                - ``one_member_locator`` — Playwright selector for a single member to uncheck.
    [Arguments]    ${check_all_locator}    ${group_locator}    ${one_member_locator}
    # Precondition: ensure master is unchecked, then click it to check all members.
    ${master_checked}=    Get Property    ${check_all_locator}    checked
    IF    ${master_checked}
        Click    ${check_all_locator}
    END
    Click    ${check_all_locator}
    # Now uncheck one member.
    Click    ${one_member_locator}
    # Assert master is indeterminate and not checked.
    ${indeterminate}=    Get Property    ${check_all_locator}    indeterminate
    Should Be True    ${indeterminate}
    ...    msg=Expected '${check_all_locator}' to be indeterminate after unchecking '${one_member_locator}', but indeterminate=${indeterminate}.
    ${master_now}=    Get Property    ${check_all_locator}    checked
    Should Not Be True    ${master_now}
    ...    msg=Expected '${check_all_locator}' to be unchecked (indeterminate), but checked=${master_now}.


Validate Check All Auto Checks When All Selected
    [Documentation]    Asserts that when all members are individually checked one-by-one,
    ...                the master automatically becomes checked (not merely indeterminate).
    ...
    ...                1. Ensures all members start unchecked (via master if needed).
    ...                2. Iterates over each member and clicks it.
    ...                3. After every member is clicked, asserts master is
    ...                   ``checked=True`` and ``indeterminate=False``.
    ...
    ...                Arguments:
    ...                - ``check_all_locator`` — Playwright selector for the master checkbox.
    ...                - ``group_locator``     — Playwright selector matching all member checkboxes.
    [Arguments]    ${check_all_locator}    ${group_locator}
    # Precondition: uncheck all members.
    ${master_checked}=    Get Property    ${check_all_locator}    checked
    IF    ${master_checked}
        Click    ${check_all_locator}
    END
    ${members}=    Get Elements    ${group_locator}
    FOR    ${member}    IN    @{members}
        ${is_checked}=    Get Property    ${member}    checked
        IF    ${is_checked}
            Click    ${member}
        END
    END
    # Click each member individually.
    FOR    ${member}    IN    @{members}
        Click    ${member}
    END
    ${count}=    Get Length    ${members}
    # After all members clicked, master must be fully checked (not indeterminate).
    ${master_checked_final}=    Get Property    ${check_all_locator}    checked
    Should Be True    ${master_checked_final}
    ...    msg=After all ${count} members of '${group_locator}' were individually checked, expected '${check_all_locator}' to be checked, but checked=${master_checked_final}.
    ${indeterminate_final}=    Get Property    ${check_all_locator}    indeterminate
    Should Not Be True    ${indeterminate_final}
    ...    msg=After all ${count} members of '${group_locator}' were individually checked, expected '${check_all_locator}' indeterminate=False, but got indeterminate=${indeterminate_final}.

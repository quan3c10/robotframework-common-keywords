*** Settings ***
Documentation    Project-agnostic assertions about button visibility and debounce
...              behaviour. Both keywords drive the Browser Library directly and
...              accept locators as arguments — no business-specific selectors are
...              hard-coded here.
Library          Browser


*** Keywords ***
Validate Button Hidden When Conditions Unmet
    [Documentation]    Asserts a button is hidden until a trigger action makes it visible,
    ...                and returns to hidden when the trigger is reversed.
    ...
    ...                1. Wait for ``button_locator`` to be hidden initially.
    ...                2. Perform ``trigger_action`` on ``trigger_locator``
    ...                   (``click`` or ``check``).
    ...                3. Wait for ``button_locator`` to become visible.
    ...                4. Reverse the trigger (click again, or uncheck).
    ...                5. Wait for ``button_locator`` to be hidden again.
    ...
    ...                Arguments:
    ...                - ``button_locator``  — Playwright selector for the button.
    ...                - ``trigger_locator`` — Playwright selector for the element that
    ...                                         triggers the button's visibility.
    ...                - ``trigger_action``  — ``click`` (default) or ``check``.
    [Arguments]    ${button_locator}    ${trigger_locator}    ${trigger_action}=click
    # Step 1: button must start hidden.
    Wait For Elements State    ${button_locator}    hidden    timeout=5s
    ...    message=Expected '${button_locator}' to be hidden initially before trigger.
    # Step 2: perform trigger.
    IF    '${trigger_action}' == 'click'
        Click    ${trigger_locator}
    ELSE IF    '${trigger_action}' == 'check'
        Check Checkbox    ${trigger_locator}
    ELSE
        Fail    Unsupported trigger_action '${trigger_action}'. Use 'click' or 'check'.
    END
    # Step 3: button must now be visible.
    Wait For Elements State    ${button_locator}    visible    timeout=5s
    ...    message=Expected '${button_locator}' to become visible after '${trigger_action}' on '${trigger_locator}'.
    # Step 4: reverse the trigger.
    IF    '${trigger_action}' == 'click'
        Click    ${trigger_locator}
    ELSE IF    '${trigger_action}' == 'check'
        Uncheck Checkbox    ${trigger_locator}
    END
    # Step 5: button must be hidden again.
    Wait For Elements State    ${button_locator}    hidden    timeout=5s
    ...    message=Expected '${button_locator}' to be hidden again after reversing '${trigger_action}' on '${trigger_locator}'.


Validate Button Debounces Rapid Clicks
    [Documentation]    Asserts that rapid repeated clicks on a button only increment
    ...                a counter once (debounce behaviour), not once per click.
    ...
    ...                1. Read the initial counter value from ``counter_locator``.
    ...                2. Click ``button_locator`` ``click_count`` times without pausing.
    ...                3. Sleep ``debounce_window`` to let the debounce timer fire.
    ...                4. Read the counter value again.
    ...                5. Assert the counter incremented by exactly 1.
    ...
    ...                Arguments:
    ...                - ``button_locator``   — Playwright selector for the debounced button.
    ...                - ``counter_locator``  — Playwright selector for the element showing the count.
    ...                - ``click_count``      — Number of rapid clicks to perform (default: 5).
    ...                - ``debounce_window``  — How long to wait after clicks for the handler to fire
    ...                                          (default: 500ms). Must be longer than the app's debounce.
    [Arguments]    ${button_locator}    ${counter_locator}    ${click_count}=5    ${debounce_window}=500ms
    # Step 1: read initial counter.
    ${initial_text}=    Get Text    ${counter_locator}
    ${initial_count}=    Convert To Integer    ${initial_text}
    # Step 2: rapid clicks.
    FOR    ${_}    IN RANGE    ${click_count}
        Click    ${button_locator}
    END
    # Step 3: wait for debounce window to elapse.
    Sleep    ${debounce_window}
    # Step 4: read counter again.
    ${final_text}=    Get Text    ${counter_locator}
    ${final_count}=    Convert To Integer    ${final_text}
    # Step 5: assert exactly 1 increment.
    ${actual_increment}=    Evaluate    ${final_count} - ${initial_count}
    Should Be Equal As Integers    ${actual_increment}    1
    ...    msg=Debounce failed for '${button_locator}': after ${click_count} rapid clicks expected counter at '${counter_locator}' to increment by 1, but it changed by ${actual_increment} (from ${initial_count} to ${final_count}).

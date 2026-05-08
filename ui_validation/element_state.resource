*** Settings ***
Documentation    Project-agnostic assertions about element state — enabled /
...              disabled / readonly / visible / hidden / focused — plus a
...              placeholder check. All keywords are thin wrappers around
...              Browser Library's ``Wait For Elements State``.
Library          Browser


*** Variables ***
${UI_DEFAULT_TIMEOUT}    5s


*** Keywords ***
Validate Element Is Enabled
    [Arguments]    ${locator}    ${timeout}=${UI_DEFAULT_TIMEOUT}
    Wait For Elements State    ${locator}    enabled    timeout=${timeout}
    ...    message=Expected '${locator}' to be enabled.

Validate Element Is Disabled
    [Arguments]    ${locator}    ${timeout}=${UI_DEFAULT_TIMEOUT}
    Wait For Elements State    ${locator}    disabled    timeout=${timeout}
    ...    message=Expected '${locator}' to be disabled.

Validate Element Is Readonly
    [Arguments]    ${locator}    ${timeout}=${UI_DEFAULT_TIMEOUT}
    Wait For Elements State    ${locator}    readonly    timeout=${timeout}
    ...    message=Expected '${locator}' to be readonly.

Validate Element Is Visible
    [Arguments]    ${locator}    ${timeout}=${UI_DEFAULT_TIMEOUT}
    Wait For Elements State    ${locator}    visible    timeout=${timeout}
    ...    message=Expected '${locator}' to be visible.

Validate Element Is Hidden
    [Arguments]    ${locator}    ${timeout}=${UI_DEFAULT_TIMEOUT}
    Wait For Elements State    ${locator}    hidden    timeout=${timeout}
    ...    message=Expected '${locator}' to be hidden.

Validate Element Has Focus
    [Arguments]    ${locator}    ${timeout}=${UI_DEFAULT_TIMEOUT}
    Wait For Elements State    ${locator}    focused    timeout=${timeout}
    ...    message=Expected '${locator}' to have focus.

Validate Element Has Placeholder
    [Documentation]    Asserts the element's ``placeholder`` attribute is
    ...                present. If ``expected`` is provided, asserts exact
    ...                string match.
    [Arguments]    ${locator}    ${expected}=${None}
    ${actual}=    Get Property    ${locator}    placeholder
    IF    $expected is None
        Should Not Be Empty    ${actual}
        ...    msg=Element '${locator}' has no placeholder attribute.
    ELSE
        Should Be Equal    ${actual}    ${expected}
        ...    msg=Placeholder mismatch: expected '${expected}', got '${actual}'.
    END

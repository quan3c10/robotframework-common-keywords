*** Settings ***
Documentation    Project-agnostic assertions about link navigation. The single
...              keyword drives the Browser Library directly and accepts
...              locators as arguments — no business-specific selectors are
...              hard-coded here. Works for in-page anchor links (URL gets
...              a #fragment) and full-page navigation.
Library          Browser
Library          String


*** Keywords ***
Validate Link Navigates To Target
    [Documentation]    Asserts that clicking a link changes the URL toward the expected target.
    ...
    ...                1. Capture the initial URL (``Get Url``).
    ...                2. Click ``link_locator``.
    ...                3. Wait briefly for navigation or scroll to settle.
    ...                4. Capture the new URL.
    ...                5. Assert new URL contains ``expected_url_substring``.
    ...                6. Assert new URL differs from initial URL (link must have done something).
    ...
    ...                Arguments:
    ...                - ``link_locator``           — Playwright selector for the anchor element.
    ...                - ``expected_url_substring`` — Substring expected in the URL after navigation
    ...                                               (e.g. ``#jump-target`` or ``/dashboard``).
    [Arguments]    ${link_locator}    ${expected_url_substring}
    # Step 1: capture initial URL.
    ${initial_url}=    Get Url
    # Step 2: click the link.
    Click    ${link_locator}
    # Step 3: wait briefly for navigation/scroll.
    Sleep    200ms
    # Step 4: capture new URL.
    ${new_url}=    Get Url
    # Step 5: assert new URL contains expected substring.
    Should Contain    ${new_url}    ${expected_url_substring}
    ...    msg=Link '${link_locator}': expected URL to contain '${expected_url_substring}' after click, but URL is '${new_url}'.
    # Step 6: assert URL changed.
    Should Not Be Equal    ${new_url}    ${initial_url}
    ...    msg=Link '${link_locator}': URL did not change after click (remained '${initial_url}'). The link may be non-functional or the expected_url_substring '${expected_url_substring}' was already present.

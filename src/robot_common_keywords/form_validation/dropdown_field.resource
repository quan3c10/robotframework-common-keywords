*** Settings ***
Documentation    Dropdown-field validations. Targets standard
...              ``<select>`` elements; ``Validate Dropdown Is Searchable``
...              targets custom-component dropdowns (filterable list + input).
Library          Browser
Library          Collections
Resource         _helpers.resource
Resource         required_field.resource


*** Keywords ***
Validate Dropdown Options Exactly
    [Documentation]    Reads every ``<option>`` text and compares it to
    ...                ``expected_options``.
    ...
    ...                ``exact_order=${True}`` (default) requires the same
    ...                order. ``exact_order=${False}`` compares sorted lists
    ...                so the test tolerates reorderings.
    [Arguments]    ${field_locator}    ${expected_options}    ${exact_order}=${True}

    ${actual}=    Read Dropdown Option Texts    ${field_locator}

    IF    ${exact_order}
        Lists Should Be Equal    ${actual}    ${expected_options}
        ...    msg=Option order differs. Expected ${expected_options}, got ${actual}.
    ELSE
        ${sorted_actual}=      Copy List    ${actual}
        ${sorted_expected}=    Copy List    ${expected_options}
        Sort List    ${sorted_actual}
        Sort List    ${sorted_expected}
        Lists Should Be Equal    ${sorted_actual}    ${sorted_expected}
        ...    msg=Option contents differ (order ignored). Expected ${expected_options}, got ${actual}.
    END


Validate Dropdown Default Selection
    [Documentation]    Asserts the initially-selected option's text equals
    ...                ``expected``. Call before any interaction with the
    ...                dropdown; once the user changes the selection this
    ...                naturally stops reflecting the default.
    [Arguments]    ${field_locator}    ${expected}
    ${actual}=    Evaluate JavaScript    ${field_locator}
    ...    (el) => el.options[el.selectedIndex].textContent.trim()
    Should Be Equal    ${actual}    ${expected}
    ...    msg=Expected default '${expected}', got '${actual}'.


Validate Dropdown Is Required
    [Documentation]    Selects the empty-value option (usually the
    ...                placeholder), triggers validation, and asserts the
    ...                required-field error surfaces.
    [Arguments]    ${field_locator}
    ...            ${error_message}=required    ${error_locator}=${EMPTY}
    ...            ${trigger}=blur    ${submit_locator}=${EMPTY}

    Evaluate JavaScript    ${field_locator}
    ...    (el) => { el.value = ''; el.dispatchEvent(new Event('change', { bubbles: true })); }
    Trigger Field Validation    ${field_locator}    ${trigger}    ${submit_locator}
    Validation Error Should Be Visible
    ...    error_message=${error_message}    error_locator=${error_locator}


Validate Dropdown Is Searchable
    [Documentation]    Types ``sample_query`` into ``search_input_locator``
    ...                and asserts that the options list under
    ...                ``options_container_locator`` actually filters —
    ...                strictly more than zero and strictly less than
    ...                the total become visible.
    ...
    ...                Intended for custom-component dropdowns (Select2,
    ...                React-Select, custom divs). Plain ``<select>``
    ...                elements aren't searchable by default — use one of
    ...                the other dropdown keywords instead.
    [Arguments]    ${search_input_locator}    ${options_container_locator}
    ...            ${sample_query}=v
    ...            ${hidden_class}=hidden

    ${total}=    Get Element Count    ${options_container_locator} > *
    Should Be True    ${total} > 1
    ...    msg=Options list has ${total} items; filtering can't be demonstrated.

    Type Text    ${search_input_locator}    ${sample_query}    delay=0 ms    clear=True

    ${visible}=    Get Element Count    ${options_container_locator} > *:not(.${hidden_class})
    Should Be True    0 < ${visible} < ${total}
    ...    msg=Expected filtering on '${sample_query}': 1..${{ ${total} - 1 }} visible, got ${visible}.


# --- Internal -----------------------------------------------------------------

Read Dropdown Option Texts
    [Arguments]    ${field_locator}
    ${texts}=    Evaluate JavaScript    ${field_locator}
    ...    (el) => Array.from(el.options).map(o => o.textContent.trim())
    RETURN    ${texts}

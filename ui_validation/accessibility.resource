*** Settings ***
Documentation    Focused accessibility assertions — three specific, discrete
...              checks that can be automated reliably.
...
...              **These keywords do NOT verify WCAG compliance.** They
...              answer specific questions:
...                - does this element have an ``aria-label``?
...                - do keyboard users tab through these elements in the
...                  expected order?
...                - does every form field in this form have *some* form of
...                  label (aria-label, aria-labelledby, ``<label for>``, or
...                  a wrapping ``<label>``)?
...
...              For full WCAG / Section 508 compliance use a dedicated tool
...              like axe-core (``@axe-core/playwright``).
Library          Browser
Library          Collections


*** Keywords ***
Validate Element Has Aria Label
    [Documentation]    Asserts the element has an ``aria-label`` attribute.
    ...                If ``expected`` is provided, the attribute value must
    ...                match it exactly.
    [Arguments]    ${locator}    ${expected}=${None}
    ${actual}=    Get Attribute    ${locator}    aria-label
    Should Not Be Equal    ${actual}    ${None}
    ...    msg=Element '${locator}' has no aria-label attribute.
    Should Not Be Empty    ${actual}
    ...    msg=Element '${locator}' has an empty aria-label.
    IF    $expected is not None
        Should Be Equal    ${actual}    ${expected}
        ...    msg=aria-label mismatch: expected '${expected}', got '${actual}'.
    END


Validate Tab Order
    [Documentation]    Focuses ``initial_locator``, then presses Tab once
    ...                per entry in ``expected_selectors`` and asserts the
    ...                focused element matches each selector in order.
    ...
    ...                Selectors are plain CSS — works for any focusable
    ...                element (input, button, link, anything with
    ...                ``tabindex``).
    [Arguments]    ${initial_locator}    @{expected_selectors}

    Should Not Be Empty    ${expected_selectors}
    ...    msg=expected_selectors must list at least one selector to Tab to.

    Focus    ${initial_locator}

    FOR    ${selector}    IN    @{expected_selectors}
        Keyboard Key    press    Tab
        ${matches}=    Element Matches Focus    ${selector}
        IF    not ${matches}
            ${actual}=    Describe Focused Element
            Fail    Tab order broken: after Tab, expected '${selector}', got ${actual}.
        END
    END


Validate Form Fields Have Labels
    [Documentation]    Walks every ``<input>`` / ``<select>`` / ``<textarea>``
    ...                inside ``form_locator`` (skipping hidden/button/submit
    ...                types) and asserts each one has a label via any of:
    ...                  - ``aria-label`` attribute
    ...                  - ``aria-labelledby`` attribute
    ...                  - sibling ``<label for="field-id">``
    ...                  - wrapping ``<label>``
    [Arguments]    ${form_locator}
    ${unlabeled}=    Evaluate JavaScript    ${form_locator}
    ...    (form) => {
    ...        const out = [];
    ...        form.querySelectorAll('input, select, textarea').forEach(el => {
    ...            const type = (el.type || '').toLowerCase();
    ...            if (['hidden','button','submit','reset'].includes(type)) return;
    ...            const hasAriaLabel = el.hasAttribute('aria-label') && el.getAttribute('aria-label').trim() !== '';
    ...            const hasAriaLabelledBy = el.hasAttribute('aria-labelledby');
    ...            const hasIdLabel = el.id && document.querySelector('label[for="' + el.id + '"]');
    ...            const hasImplicitLabel = el.closest('label') !== null;
    ...            if (!hasAriaLabel && !hasAriaLabelledBy && !hasIdLabel && !hasImplicitLabel) {
    ...                const ident = el.dataset.test ? '[data-test="' + el.dataset.test + '"]' : (el.id ? '#' + el.id : el.tagName);
    ...                out.push(ident);
    ...            }
    ...        });
    ...        return out;
    ...    }
    Should Be Empty    ${unlabeled}
    ...    msg=Form fields without labels: ${unlabeled}


# --- Internal -----------------------------------------------------------------

Element Matches Focus
    [Arguments]    ${selector}
    ${sel_json}=    Evaluate    __import__('json').dumps($selector)
    ${matches}=    Evaluate JavaScript    ${None}
    ...    () => !!document.activeElement && document.activeElement.matches(${sel_json})
    RETURN    ${matches}

Describe Focused Element
    ${desc}=    Evaluate JavaScript    ${None}
    ...    () => {
    ...        const a = document.activeElement;
    ...        if (!a || a === document.body) return '(no focus)';
    ...        const tag = a.tagName.toLowerCase();
    ...        const dt = a.dataset && a.dataset.test ? '[data-test=' + a.dataset.test + ']' : '';
    ...        const id = a.id ? '#' + a.id : '';
    ...        return tag + id + dt;
    ...    }
    RETURN    ${desc}

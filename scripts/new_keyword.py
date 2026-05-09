"""Scaffolder for new common-keywords.

Generates `.resource` (default) or Python `@keyword` (`--python`) keyword
files plus a self-test stub, and appends a placeholder row to
docs/COVERAGE.md.

See PROJECT_CONTEXT.md §5.2 for the manual checklist that follows the
scaffold.
"""

from __future__ import annotations


_RESOURCE_TEMPLATE = """\
*** Settings ***
Documentation    {name}. TODO(new_keyword.py): one-line summary of what
...              this keyword validates.
Library          Browser
Resource         _helpers.resource


*** Keywords ***
{name}
    [Documentation]    TODO(new_keyword.py): describe what is checked.
    ...                When composing multiple checks, list them in a
    ...                numbered sequence.
    ...
    ...                Arguments:
    ...                - ``field_locator``  — Playwright selector of the input.
    ...                - ``error_message``  — substring of the visible error text.
    ...                - ``error_locator``  — optional selector for the error element.
    ...                - ``trigger``        — ``blur`` (default) or ``submit``.
    ...                - ``submit_locator`` — required when ``trigger=submit``.
    [Arguments]    ${{field_locator}}
    ...            ${{error_message}}=TODO(new_keyword.py): default error text
    ...            ${{error_locator}}=${{EMPTY}}
    ...            ${{trigger}}=blur
    ...            ${{submit_locator}}=${{EMPTY}}

    # TODO(new_keyword.py): replace this body with the validation steps.
    Fill Text    ${{field_locator}}    ${{EMPTY}}
    Trigger Field Validation    ${{field_locator}}    ${{trigger}}    ${{submit_locator}}
    Validation Error Should Be Visible
    ...    error_message=${{error_message}}
    ...    error_locator=${{error_locator}}
"""


def render_resource(name: str, module: str, domain: str) -> str:
    """Return the body of a new <domain>/<module>.resource file."""
    return _RESOURCE_TEMPLATE.format(name=name, module=module, domain=domain)

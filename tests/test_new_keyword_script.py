"""Pytest coverage for scripts/new_keyword.py.

This is the only Python unit test in the repo (other tests are Robot
self-tests). pytest is used here to avoid pulling the Browser stack into
a file-generator test.
"""

from __future__ import annotations

import new_keyword


def test_render_resource_substitutes_name_module_and_domain():
    rendered = new_keyword.render_resource(
        name="Validate Postal Code Field",
        module="postal_code_field",
        domain="form_validation",
    )
    assert "Validate Postal Code Field" in rendered
    assert "*** Keywords ***" in rendered
    assert "[Documentation]" in rendered
    assert "[Arguments]    ${field_locator}" in rendered
    assert "TODO(new_keyword.py)" in rendered
    # module and domain appear in the generated-by provenance line.
    assert "form_validation/postal_code_field.resource" in rendered
    # Settings imports the internal helpers and Browser library.
    assert "Library          Browser" in rendered
    assert "Resource         _helpers.resource" in rendered


def test_render_self_test_links_back_to_module_under_test():
    rendered = new_keyword.render_self_test(
        name="Validate Postal Code Field",
        module="postal_code_field",
        domain="form_validation",
    )
    assert "../form_validation/postal_code_field.resource" in rendered
    assert "Validate Postal Code Field Smoke" in rendered
    assert "fixtures/text_form.html" in rendered
    assert "Set Up Browser" in rendered
    assert "TODO(new_keyword.py)" in rendered
    # Stub must fail until edited — protects against silently-passing tests.
    assert "Fail    TODO(new_keyword.py)" in rendered

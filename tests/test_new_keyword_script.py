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


def test_render_python_library_uses_keyword_decorator():
    rendered = new_keyword.render_python_library(
        name="Compute Postal Code Region",
        module="postal_code_helpers",
    )
    # Decorator preserves the human keyword name.
    assert '@keyword("Compute Postal Code Region")' in rendered
    # Function name is snake_case derived from the keyword name.
    assert "def compute_postal_code_region(" in rendered
    # Mandatory module-level scaffolding.
    assert 'ROBOT_LIBRARY_SCOPE = "GLOBAL"' in rendered
    assert "from robot.api.deco import keyword" in rendered
    assert "from __future__ import annotations" in rendered
    # Stub raises until edited.
    assert "raise NotImplementedError" in rendered
    assert "TODO(new_keyword.py)" in rendered


def test_python_function_name_lowercases_and_underscores_keyword_name():
    # Internal helper exposed for the renderer.
    assert new_keyword.keyword_to_function_name("Validate Email Field") == "validate_email_field"
    assert new_keyword.keyword_to_function_name("Response Status Should Be") == "response_status_should_be"
    # Already-snake input must round-trip cleanly.
    assert new_keyword.keyword_to_function_name("foo bar") == "foo_bar"

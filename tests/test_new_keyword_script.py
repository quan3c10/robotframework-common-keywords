"""Pytest coverage for scripts/new_keyword.py.

This is the only Python unit test in the repo (other tests are Robot
self-tests). pytest is used here to avoid pulling the Browser stack into
a file-generator test.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import new_keyword

REPO_ROOT = Path(__file__).resolve().parent.parent


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


def test_coverage_row_format():
    row = new_keyword.coverage_row(
        name="Validate Postal Code Field",
        module="postal_code_field",
    )
    # Markdown table row, terminating newline.
    assert row.endswith("\n")
    assert row.startswith("| `Validate Postal Code Field` |")
    assert "test_postal_code_field.robot" in row
    assert "TODO" in row


def test_append_coverage_row_appends_to_existing_file(tmp_path):
    coverage = tmp_path / "COVERAGE.md"
    coverage.write_text("# Coverage\n\n| Keyword | Test | Coverage |\n|---|---|---|\n")
    new_keyword.append_coverage_row(
        coverage_path=coverage,
        name="Validate Postal Code Field",
        module="postal_code_field",
    )
    contents = coverage.read_text()
    assert contents.count("Validate Postal Code Field") == 1
    assert contents.endswith("\n")


def _run_scaffolder(repo_root: Path, *args: str) -> subprocess.CompletedProcess:
    """Invoke scripts/new_keyword.py inside ``repo_root`` as cwd."""
    return subprocess.run(
        [sys.executable, str(REPO_ROOT / "scripts" / "new_keyword.py"), *args],
        cwd=repo_root,
        capture_output=True,
        text=True,
    )


def _seed_minimal_layout(repo_root: Path) -> None:
    (repo_root / "form_validation").mkdir()
    (repo_root / "libraries").mkdir()
    (repo_root / "tests").mkdir()
    (repo_root / "docs").mkdir()
    (repo_root / "docs" / "COVERAGE.md").write_text(
        "# Coverage\n\n| Keyword | Test | Coverage |\n|---|---|---|\n"
    )


def test_main_creates_resource_test_and_coverage(tmp_path):
    _seed_minimal_layout(tmp_path)
    result = _run_scaffolder(
        tmp_path,
        "--domain", "form_validation",
        "--name", "Validate Postal Code Field",
        "--module", "postal_code_field",
    )
    assert result.returncode == 0, result.stderr
    assert (tmp_path / "form_validation" / "postal_code_field.resource").is_file()
    assert (tmp_path / "tests" / "test_postal_code_field.robot").is_file()
    coverage = (tmp_path / "docs" / "COVERAGE.md").read_text()
    assert "Validate Postal Code Field" in coverage
    # Manual checklist printed to stdout.
    assert "TODO" in result.stdout


def test_main_refuses_to_overwrite(tmp_path):
    _seed_minimal_layout(tmp_path)
    args = (
        "--domain", "form_validation",
        "--name", "Validate Postal Code Field",
        "--module", "postal_code_field",
    )
    first = _run_scaffolder(tmp_path, *args)
    assert first.returncode == 0
    second = _run_scaffolder(tmp_path, *args)
    assert second.returncode != 0
    assert "exists" in second.stderr.lower()


def test_main_python_mode_creates_library(tmp_path):
    _seed_minimal_layout(tmp_path)
    result = _run_scaffolder(
        tmp_path,
        "--domain", "form_validation",
        "--name", "Compute Postal Code Region",
        "--module", "postal_code_helpers",
        "--python",
    )
    assert result.returncode == 0, result.stderr
    library = (tmp_path / "libraries" / "postal_code_helpers.py").read_text()
    assert '@keyword("Compute Postal Code Region")' in library
    # Python mode skips the Robot self-test stub but prints a reminder.
    assert not (tmp_path / "tests" / "test_postal_code_helpers.robot").exists()
    assert "consuming" in result.stdout.lower() or "test" in result.stdout.lower()


def test_main_rejects_unknown_domain(tmp_path):
    _seed_minimal_layout(tmp_path)
    result = _run_scaffolder(
        tmp_path,
        "--domain", "not_a_real_domain",
        "--name", "Foo",
        "--module", "foo",
    )
    assert result.returncode != 0

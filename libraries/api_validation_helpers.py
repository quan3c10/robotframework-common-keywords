"""Helpers for api_validation/*.resource.

Two flavors of keywords:

1. **Response accessors** (``Response Status Code``, ``Response Body``,
   ``Response Elapsed Seconds``) — extract common fields from any
   ``requests.Response``-compatible object.

2. **Body validators** (``Validate JSON Schema``, ``Check Required Fields``,
   ``Get JSON Field Type``, ``Assert Response Field Type``,
   ``Error Response Mentions Field``) — operate on the parsed body dict,
   so tests can use them on real responses **or** on synthetic dict
   literals without needing a live HTTP call.
"""

from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import jsonschema
from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"


# --- Test helper: mock Response object ---------------------------------------

@keyword("Create Mock Response")
def create_mock_response(status_code, body=None, elapsed_seconds: float = 0.1):
    """Build a ``requests.Response``-shaped stand-in for self-tests.

    Exposes ``.status_code``, ``.json()``, and ``.elapsed.total_seconds()`` —
    the exact surface the ``api_validation/*.resource`` wrappers rely on.
    Intended for self-tests that need to exercise the Robot wrappers
    without an HTTP round-trip.
    """
    sc = int(status_code)
    es = float(elapsed_seconds)
    return SimpleNamespace(
        status_code=sc,
        elapsed=SimpleNamespace(total_seconds=lambda _s=es: _s),
        json=lambda _b=body: _b,
    )


# --- Response accessors -------------------------------------------------------

@keyword("Response Status Code")
def response_status_code(response) -> int:
    """Return ``response.status_code`` as an int."""
    return int(response.status_code)


@keyword("Response Body")
def response_body(response):
    """Return the response body parsed as JSON. Raises on non-JSON bodies."""
    try:
        return response.json()
    except Exception as exc:  # pragma: no cover - defensive
        raise AssertionError(f"Response body is not valid JSON: {exc}")


@keyword("Response Elapsed Seconds")
def response_elapsed_seconds(response) -> float:
    """Return ``response.elapsed`` as seconds (float)."""
    return float(response.elapsed.total_seconds())


# --- Schema / required-fields / type assertions -------------------------------

@keyword("Validate JSON Schema")
def validate_json_schema(data, schema_path: str):
    """Validate ``data`` against the JSON schema at ``schema_path``.

    Raises ``AssertionError`` with one line per failure, each quoting the
    pointer path and the validator's message. Uses Draft 2020-12.
    """
    schema_file = Path(schema_path)
    if not schema_file.exists():
        raise FileNotFoundError(f"Schema file not found: {schema_path}")

    with schema_file.open(encoding="utf-8") as fh:
        schema = json.load(fh)

    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path))
    if not errors:
        return

    lines = [f"JSON Schema validation failed ({schema_file.name}):"]
    for err in errors:
        pointer = "/".join(str(p) for p in err.absolute_path) or "(root)"
        lines.append(f"  - at '{pointer}': {err.message}")
    raise AssertionError("\n".join(lines))


@keyword("Check Required Fields")
def check_required_fields(data, *required_fields: str):
    """Raise ``AssertionError`` listing any of ``required_fields`` missing
    from ``data`` (a dict)."""
    if not isinstance(data, dict):
        raise AssertionError(
            f"Expected object for required-fields check, got {type(data).__name__}."
        )
    missing = [f for f in required_fields if f not in data]
    if missing:
        raise AssertionError(f"Missing required fields: {', '.join(missing)}.")


_TYPE_ALIASES: dict[str, str] = {
    "string":  "string",  "str":     "string",
    "integer": "integer", "int":     "integer",
    "number":  "number",  "float":   "number",
    "boolean": "boolean", "bool":    "boolean",
    "array":   "array",   "list":    "array",
    "object":  "object",  "dict":    "object",
    "null":    "null",    "none":    "null",
}


@keyword("Get JSON Field Type")
def get_json_field_type(data, path: str) -> str:
    """Return the JSON type name (``string`` / ``integer`` / ``number`` /
    ``boolean`` / ``array`` / ``object`` / ``null``) of the value at a
    dot-delimited path into ``data``."""
    return _json_type(_walk_path(data, path))


@keyword("Assert Response Field Type")
def assert_response_field_type(data, path: str, expected_type: str):
    """Assert the value at ``path`` has JSON type ``expected_type``.

    Accepts aliases (``int`` for ``integer``, ``list`` for ``array``, etc.).
    ``number`` also accepts integers.
    """
    canonical = _TYPE_ALIASES.get(expected_type.lower())
    if canonical is None:
        valid = sorted(set(_TYPE_ALIASES.values()))
        raise ValueError(
            f"Unknown type '{expected_type}'. Valid: {', '.join(valid)}."
        )
    actual = _json_type(_walk_path(data, path))
    if actual == canonical:
        return
    if canonical == "number" and actual == "integer":
        return
    raise AssertionError(
        f"Field '{path}' has type '{actual}', expected '{canonical}'."
    )


# --- Error-response inspector -------------------------------------------------

@keyword("Error Response Mentions Field")
def error_response_mentions_field(data, field_name: str):
    """Raise ``AssertionError`` if ``field_name`` doesn't appear anywhere
    in the JSON representation of ``data`` (case-insensitive).
    """
    flat = json.dumps(data).lower()
    if field_name.lower() not in flat:
        raise AssertionError(
            f"Expected error response to mention '{field_name}', got: {json.dumps(data)}"
        )


# --- Internal -----------------------------------------------------------------

def _walk_path(data, path: str):
    """Traverse ``data`` using dot-delimited ``path``. Numeric segments index
    into arrays; string segments index into objects. Raises AssertionError
    with a clear message on a missing path."""
    result = data
    for part in str(path).split("."):
        try:
            if part.isdigit():
                result = result[int(part)]
            else:
                result = result[part]
        except (KeyError, IndexError, TypeError) as exc:
            raise AssertionError(
                f"Path '{path}' not found in response at segment '{part}' ({exc})."
            )
    return result


def _json_type(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__

"""Generate strings of exact length for boundary-value testing.

Exposes the ``Generate String With Length`` keyword. Intended for max-length,
min-length, off-by-one, and character-class tests against form fields.
"""

from __future__ import annotations

import random
import string

from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"

_SPECIAL_CHARS = "!@#$%^&*()-_=+[]{}|;:,.<>?/"
_UNICODE_CHARS = "áéíóúñçäëïöü中文русский日本語αβγδ€£¥"

CHARSETS: dict[str, str] = {
    "alpha":        string.ascii_letters,
    "alphanumeric": string.ascii_letters + string.digits,
    "numeric":      string.digits,
    "special":      _SPECIAL_CHARS,
    "unicode":      _UNICODE_CHARS,
}


@keyword("Generate String With Length")
def generate_string_with_length(length: int | str, charset: str = "alpha") -> str:
    """Return a string of exactly ``length`` characters sampled from ``charset``.

    Supported charsets: ``alpha``, ``alphanumeric``, ``numeric``, ``special``,
    ``unicode``. An unknown charset raises ``ValueError``. Length 0 returns
    the empty string.
    """
    length = int(length)
    if length < 0:
        raise ValueError(f"length must be >= 0, got {length}")
    if charset not in CHARSETS:
        raise ValueError(
            f"Unknown charset '{charset}'. Expected one of: "
            f"{', '.join(sorted(CHARSETS))}."
        )
    pool = CHARSETS[charset]
    return "".join(random.choice(pool) for _ in range(length))

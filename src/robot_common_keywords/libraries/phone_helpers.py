"""Python-side phone-number helpers that wrap ``phonenumbers``.

Used by ``form_validation/phone_field.resource`` and available to tests that
need to cross-check numbers against libphonenumber's rules (e.g. to sanity
check that a YAML sample is genuinely valid for the stated country).
"""

from __future__ import annotations

import phonenumbers
from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"


@keyword("Is Valid Phone Number For Country")
def is_valid_phone_number_for_country(number: str, country: str) -> bool:
    """Returns ``True`` if ``number`` is a valid phone number for ``country``.

    ``country`` is the ISO 3166-1 alpha-2 code (``US``, ``VN``, ...). A
    number that fails to parse (random garbage, wrong shape) returns
    ``False`` rather than raising.
    """
    try:
        parsed = phonenumbers.parse(number, country.upper())
    except phonenumbers.NumberParseException:
        return False
    return phonenumbers.is_valid_number(parsed)


@keyword("Format Phone Number As E164")
def format_phone_number_as_e164(number: str, country: str) -> str:
    """Returns the E.164 form of ``number`` (e.g. ``+14155552671``).

    Raises ``NumberParseException`` on unparseable input — use this after
    ``Is Valid Phone Number For Country`` if you need the side effect of
    raising on bad input.
    """
    parsed = phonenumbers.parse(number, country.upper())
    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)

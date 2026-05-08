"""Thin wrapper around the Faker library, exposing Robot keywords.

Country codes are 2-letter ISO codes (e.g. ``US``, ``VN``, ``JP``). Unknown
country codes fall back to ``en_US`` so tests don't fail on a typo — the
fallback is logged via the returned data, not a Robot warning.
"""

from __future__ import annotations

from faker import Faker
from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"

# ISO 3166-1 alpha-2 → Faker locale.
_LOCALE_BY_COUNTRY: dict[str, str] = {
    "US": "en_US",
    "UK": "en_GB",
    "GB": "en_GB",
    "VN": "vi_VN",
    "JP": "ja_JP",
    "DE": "de_DE",
    "FR": "fr_FR",
    "ES": "es_ES",
    "IT": "it_IT",
    "CN": "zh_CN",
    "KR": "ko_KR",
    "BR": "pt_BR",
    "IN": "en_IN",
    "AU": "en_AU",
    "CA": "en_CA",
}

_FAKER_CACHE: dict[str, Faker] = {}


def _faker_for(country: str = "US") -> Faker:
    locale = _LOCALE_BY_COUNTRY.get(country.upper(), "en_US")
    if locale not in _FAKER_CACHE:
        _FAKER_CACHE[locale] = Faker(locale)
    return _FAKER_CACHE[locale]


@keyword("Generate Fake Email")
def generate_fake_email() -> str:
    """Return a plausible fake email address (user@domain.tld)."""
    return _faker_for().email()


@keyword("Generate Fake Name")
def generate_fake_name(country: str = "US") -> str:
    """Return a plausible fake full name for the given country."""
    return _faker_for(country).name()


@keyword("Generate Fake Phone")
def generate_fake_phone(country: str = "US") -> str:
    """Return a plausible fake phone number formatted for the given country.

    Faker's output is locale-styled but not guaranteed to be E.164-valid.
    For strict validation, use ``phonenumbers`` via ``Validate Phone Field``.
    """
    return _faker_for(country).phone_number()


@keyword("Generate Fake Address")
def generate_fake_address(country: str = "US") -> str:
    """Return a plausible multi-line fake postal address for the country."""
    return _faker_for(country).address()

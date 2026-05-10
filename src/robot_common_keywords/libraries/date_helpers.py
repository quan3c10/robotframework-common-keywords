"""Date utility keywords for form_validation/date_field.resource.

Supported format tokens (input to ``Format Date``):

    YYYY  → 4-digit year        (e.g. ``2026``)
    YY    → 2-digit year        (e.g. ``26``)
    MM    → 2-digit month        (``01``-``12``)
    DD    → 2-digit day         (``01``-``31``)

Out of scope: month names, timezone-aware dates, non-Gregorian calendars.
"""

from __future__ import annotations

from datetime import date, timedelta

from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"


@keyword("Today As Date")
def today_as_date(format: str = "YYYY-MM-DD") -> str:
    """Return today's date formatted per ``format``."""
    return format_date(date.today(), format)


@keyword("Future Date")
def future_date(days: int = 30, format: str = "YYYY-MM-DD") -> str:
    """Return today + ``days`` formatted per ``format``."""
    return format_date(date.today() + timedelta(days=int(days)), format)


@keyword("Past Date")
def past_date(days: int = 30, format: str = "YYYY-MM-DD") -> str:
    """Return today - ``days`` formatted per ``format``."""
    return format_date(date.today() - timedelta(days=int(days)), format)


@keyword("Date Relative To Today")
def date_relative_to_today(offset_days: int, format: str = "YYYY-MM-DD") -> str:
    """Return today + offset_days formatted per ``format``. Negative = past."""
    return format_date(date.today() + timedelta(days=int(offset_days)), format)


@keyword("Format Date")
def format_date(value: date, format: str = "YYYY-MM-DD") -> str:
    """Render a ``date`` using the framework's limited format tokens."""
    out = format
    out = out.replace("YYYY", f"{value.year:04d}")
    out = out.replace("YY",   f"{value.year % 100:02d}")
    out = out.replace("MM",   f"{value.month:02d}")
    out = out.replace("DD",   f"{value.day:02d}")
    return out

"""Minimal YAML loader exposed as a Robot keyword.

Used by ``form_validation/*`` resources that pull country / sample data
from ``test_data/*.yaml``. Returns a recursive ``DotDict`` so callers
can use either attribute-style access (``${data.countries.VN}``) or the
standard bracket / Collections forms (``${data}[countries]``,
``Get From Dictionary    ${data}    countries``).
"""

from __future__ import annotations

import yaml
from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"


class DotDict(dict):
    """Dict subclass that exposes string keys as attributes."""

    def __getattr__(self, name):
        try:
            return self[name]
        except KeyError as exc:
            raise AttributeError(name) from exc


def _to_dotdict(obj):
    if isinstance(obj, dict):
        return DotDict({k: _to_dotdict(v) for k, v in obj.items()})
    if isinstance(obj, list):
        return [_to_dotdict(v) for v in obj]
    return obj


@keyword("Load YAML")
def load_yaml(path: str):
    """Reads ``path`` and returns the parsed YAML document as a ``DotDict``."""
    with open(path, encoding="utf-8") as fp:
        return _to_dotdict(yaml.safe_load(fp))

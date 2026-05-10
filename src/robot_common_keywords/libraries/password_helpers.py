"""Helpers for policy-driven password validation."""

from __future__ import annotations

import json
import random
from pathlib import Path

import yaml
from robot.api.deco import keyword
from robot.utils import DotDict

ROBOT_LIBRARY_SCOPE = "GLOBAL"

# Every call to Load Password Policy returns a dict filled with these keys so
# downstream Robot code can use `${policy.require_uppercase}` without
# worrying whether the YAML explicitly set it.
_POLICY_DEFAULTS: dict = {
    "min_length": 0,
    "max_length": 0,
    "require_uppercase": False,
    "require_lowercase": False,
    "require_number": False,
    "require_special": False,
    "forbid_common_passwords": False,
    "forbid_sequential_chars": False,
    "forbid_username_substring": False,
}

# Small curated list — matched exactly by the fixture's JS validator.
COMMON_PASSWORDS: set[str] = {
    "password", "password123", "12345678", "qwerty", "admin123",
    "letmein", "welcome123", "monkey123", "abc123", "iloveyou",
}

_DEFAULT_PATH = Path(__file__).resolve().parent.parent / "test_data" / "password_policies.yaml"


@keyword("Load Password Policy")
def load_password_policy(policy_name: str, path: str | None = None) -> DotDict:
    """Load ``policy_name`` from ``password_policies.yaml`` and merge defaults.

    The returned DotDict always has every key listed in ``_POLICY_DEFAULTS``,
    so ``${policy.require_uppercase}`` is safe without a `Get From Dictionary`.
    """
    yaml_path = Path(path) if path else _DEFAULT_PATH
    with yaml_path.open(encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    policies = data.get("policies", {})
    if policy_name not in policies:
        available = ", ".join(sorted(policies))
        raise ValueError(
            f"Password policy '{policy_name}' not found. Available: {available}"
        )
    merged = {**_POLICY_DEFAULTS, **(policies[policy_name] or {})}
    return DotDict(merged)


@keyword("Generate Compliant Password")
def generate_compliant_password(policy, username: str = "") -> str:
    """Generate a random password satisfying every rule in ``policy``.

    Attempts up to 100 times; raises if the policy is too restrictive for
    the generator's current strategy.
    """
    p = dict(policy)
    min_len = int(p.get("min_length") or 0)
    max_len = int(p.get("max_length") or 0)

    target = max(min_len, 12)
    if max_len > 0:
        target = min(target, max_len)

    # One seed per required class. The `2`/`b`/etc. are specifically chosen so
    # they do NOT sit next to each other alphabetically (sequential-chars rule).
    seeds = []
    if p.get("require_uppercase"):
        seeds.append("Q")
    if p.get("require_lowercase"):
        seeds.append("k")
    if p.get("require_number"):
        seeds.append("7")
    if p.get("require_special"):
        seeds.append("!")

    # Pool chosen to avoid 0/O/l/1 visual confusion AND avoid consecutive codepoints.
    alpha_pool = "QWRTPKFHMNBVZXqwrtpkfhmnbvzx"
    digit_pool = "24679"
    safe_pool = alpha_pool + digit_pool

    for _ in range(100):
        body = list(seeds)
        remaining = target - len(body)
        body.extend(random.choices(safe_pool, k=remaining))
        random.shuffle(body)
        candidate = "".join(body)

        if p.get("forbid_common_passwords") and candidate.lower() in COMMON_PASSWORDS:
            continue
        if p.get("forbid_sequential_chars") and _has_sequential(candidate):
            continue
        if p.get("forbid_username_substring") and username:
            if username.lower() in candidate.lower():
                continue
        return candidate

    raise RuntimeError(
        "Could not generate a compliant password after 100 attempts. "
        "Policy may be too restrictive for the current generator strategy."
    )


@keyword("Policy As JSON")
def policy_as_json(policy) -> str:
    """Serialize a policy dict to JSON for injection into browser JS."""
    return json.dumps(dict(policy))


def _has_sequential(s: str) -> bool:
    """True if ``s`` contains 3+ ascending or descending consecutive codepoints."""
    for i in range(len(s) - 2):
        a, b, c = ord(s[i]), ord(s[i + 1]), ord(s[i + 2])
        if b == a + 1 and c == b + 1:
            return True
        if b == a - 1 and c == b - 1:
            return True
    return False

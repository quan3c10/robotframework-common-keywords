"""File-related helpers for form_validation/file_upload.resource.

Three keywords:

- ``Sample File Path``    ext → absolute path to ``sample_files/tiny.${ext}``.
- ``Create Oversize File``    size_mb    extension → writes ``size_mb``
  megabytes of zero bytes to a tempfile and returns the absolute path.
  **Caller is responsible for cleanup.**
- ``Delete File If Exists``    path → idempotent delete for test teardown.
"""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

from robot.api.deco import keyword

ROBOT_LIBRARY_SCOPE = "GLOBAL"

_SAMPLES_DIR = Path(__file__).resolve().parent.parent / "test_data" / "sample_files"


@keyword("Sample File Path")
def sample_file_path(extension: str) -> str:
    """Return the absolute path to ``tiny.${extension}`` in sample_files/.

    Raises ``FileNotFoundError`` if no sample exists for the extension —
    caller should add one to ``test_data/sample_files/`` or use a different
    extension.
    """
    ext = extension.lstrip(".").lower()
    path = _SAMPLES_DIR / f"tiny.{ext}"
    if not path.exists():
        available = sorted(p.name for p in _SAMPLES_DIR.glob("tiny.*"))
        raise FileNotFoundError(
            f"No sample file for '.{ext}'. Available: {', '.join(available)}. "
            f"Add one to {_SAMPLES_DIR}."
        )
    return str(path)


@keyword("Create Oversize File")
def create_oversize_file(size_mb: float = 6, extension: str = "jpg") -> str:
    """Write ``size_mb`` megabytes of NULs to a tempfile and return its path.

    Intended for negative size-limit tests — committing a 6 MB blob to git
    is silly, so we regenerate it per run and the caller deletes it in
    teardown via ``Delete File If Exists``.
    """
    size_bytes = int(float(size_mb) * 1024 * 1024)
    ext = extension.lstrip(".").lower()
    fd, path = tempfile.mkstemp(suffix=f".{ext}", prefix="oversize_")
    try:
        with os.fdopen(fd, "wb") as fh:
            # Write in 1 MB chunks so we're not building a massive bytes object.
            chunk = b"\x00" * (1024 * 1024)
            remaining = size_bytes
            while remaining > 0:
                if remaining >= len(chunk):
                    fh.write(chunk)
                    remaining -= len(chunk)
                else:
                    fh.write(b"\x00" * remaining)
                    remaining = 0
    except Exception:
        Path(path).unlink(missing_ok=True)
        raise
    return path


@keyword("Delete File If Exists")
def delete_file_if_exists(path: str) -> None:
    """Idempotent delete for test teardown. Silently skips missing files."""
    if not path:
        return
    try:
        Path(path).unlink(missing_ok=True)
    except Exception:
        pass

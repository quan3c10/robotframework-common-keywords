"""robot_common_keywords — reusable validation keywords for Robot Framework."""

try:
    from .__version__ import __version__
except ImportError:
    # Fallback when this file is loaded outside of the installed package
    # context (e.g. by pytest's Package collector in the repo root).
    __version__ = "0.0.0.dev0"

__all__ = ["__version__"]

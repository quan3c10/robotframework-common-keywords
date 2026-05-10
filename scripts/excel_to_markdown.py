#!/usr/bin/env python3
"""
Convert each sheet of an Excel workbook (.xlsx) into GitHub-flavored Markdown tables.

By default, each ``{SheetName}.md`` is written next to the workbook; use ``-o`` for another folder.
Use repeatable ``-s`` / ``--sheet`` to export only chosen sheets (default: all).

Requires: pip install pandas tabulate openpyxl
(openpyxl is the engine pandas uses for .xlsx files.)
"""

from __future__ import annotations

import argparse
import os
import re
from collections.abc import Hashable

import pandas as pd
import pandas.api.types as ptypes
from tabulate import tabulate

PLACEHOLDER = "-"
_UNNAMED_COL_RE = re.compile(r"^Unnamed:\s*\d+\s*$", re.IGNORECASE)
_GENERATED_COL_RE = re.compile(r"^col\d+$", re.IGNORECASE)


def default_output_dir_for_workbook(xlsx_path: str) -> str:
    """Directory containing the workbook (same folder as the input .xlsx)."""
    path = os.path.abspath(xlsx_path)
    parent = os.path.dirname(path)
    return parent if parent else os.getcwd()


def sanitize_sheet_name(name: str) -> str:
    """Turn a sheet name into a safe filename stem (no extension)."""
    s = name.strip()
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r'[<>:"/\\|?*\x00]', "", s)
    s = re.sub(r"[^\w.\-]+", "_", s, flags=re.UNICODE)
    s = re.sub(r"_+", "_", s).strip("._")
    return s or "sheet"


def _is_empty_value(val: object) -> bool:
    if val is None:
        return True
    if isinstance(val, str) and val.strip() == "":
        return True
    try:
        if pd.isna(val):
            return True
    except (TypeError, ValueError):
        pass
    return False


def optimize_cell(val: object) -> str | int | float | bool:
    """Trim strings, round floats, collapse null/empty to a single dash."""
    if _is_empty_value(val):
        return PLACEHOLDER

    if isinstance(val, str):
        out = val.strip()
        return PLACEHOLDER if out == "" else out

    if isinstance(val, bool):
        return val

    try:
        if pd.isna(val):
            return PLACEHOLDER
    except (TypeError, ValueError):
        pass

    if ptypes.is_integer(val):
        return int(val)

    if ptypes.is_float(val):
        r = round(float(val), 2)
        return int(r) if r == int(r) else r

    if isinstance(val, pd.Timestamp):
        return val.isoformat()

    text = str(val).strip()
    return PLACEHOLDER if text == "" else text


def _column_label_str(name: object) -> str:
    if name is None:
        return ""
    try:
        if pd.isna(name):
            return ""
    except (TypeError, ValueError):
        pass
    return str(name).strip()


def _is_pandas_unnamed_column_label(label: str) -> bool:
    return bool(label and _UNNAMED_COL_RE.match(label))


def _count_unnamed_columns(df: pd.DataFrame) -> int:
    return sum(1 for c in df.columns if _is_pandas_unnamed_column_label(_column_label_str(c)))


def _row_looks_like_table_header(row: pd.Series, ncols: int) -> bool:
    """True if this row is likely real column headers (not a 2-col key/value label row)."""
    filled: list[str] = []
    for v in row:
        if _is_empty_value(v):
            continue
        s = str(v).strip()
        if s:
            filled.append(s)
    need = max(3, int(0.55 * ncols + 0.999))
    if len(filled) < need:
        return False
    return all(len(s) <= 120 for s in filled)


def _header_cell_from_first_row(value: object) -> str:
    if _is_empty_value(value):
        return PLACEHOLDER
    s = str(value).strip()
    return PLACEHOLDER if s == "" else s


def _rename_unnamed_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Replace pandas default 'Unnamed: k' headers with col1, col2, …"""
    new_cols: list = []
    for i, c in enumerate(df.columns):
        label = _column_label_str(c)
        if _is_pandas_unnamed_column_label(label):
            new_cols.append(f"col{i + 1}")
        else:
            new_cols.append(c)
    out = df.copy()
    out.columns = new_cols
    return out


def fix_excel_banner_header_row(df: pd.DataFrame) -> pd.DataFrame:
    """
    When row 0 is a merged title and real headers are in row 1, pandas leaves
    'Unnamed: N' column names. Promote the first data row to headers when it
    looks like a real table header; otherwise rename Unnamed:* to colK.
    """
    if df.empty:
        return df
    ncols = df.shape[1]
    if ncols < 3:
        return _rename_unnamed_columns(df)
    if _count_unnamed_columns(df) == 0:
        return df
    if len(df) < 2:
        return _rename_unnamed_columns(df)
    first = df.iloc[0]
    if not _row_looks_like_table_header(first, ncols):
        return _rename_unnamed_columns(df)
    new_names = [_header_cell_from_first_row(v) for v in first]
    out = df.iloc[1:].copy()
    out.columns = new_names
    return _rename_unnamed_columns(out)


def _eligible_for_strip_all_empty_columns(name: object) -> bool:
    """Strip only spacer columns pandas invented; keep real headers even when all body cells are empty."""
    label = _column_label_str(name)
    if _is_pandas_unnamed_column_label(label):
        return True
    if label and _GENERATED_COL_RE.match(label):
        return True
    return False


def _drop_placeholder_empty_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Drop columns that only contain placeholders and were never real headers — after
    promoting a banner row we still want columns like Actual/Status kept for templates.
    """
    if df.empty:
        return df
    drops: list[Hashable] = []
    for c in df.columns:
        if not _eligible_for_strip_all_empty_columns(c):
            continue
        series = df[c]
        if bool(series.map(_is_empty_value).all()):
            drops.append(c)
    if drops:
        return df.drop(columns=drops)
    return df


def dataframe_to_lean_markdown(df: pd.DataFrame) -> str:
    """Drop empty rows/columns, optimize cells, emit GitHub Markdown table."""
    if df.empty:
        return ""

    df = fix_excel_banner_header_row(df.copy())
    df = df.dropna(axis=0, how="all")
    df = _drop_placeholder_empty_columns(df)
    if df.empty:
        return ""

    df = df.copy()
    df.columns = [optimize_cell(c) if isinstance(c, Hashable) else PLACEHOLDER for c in df.columns]

    mapper = getattr(df, "map", None)
    optimized = mapper(optimize_cell) if callable(mapper) else df.applymap(optimize_cell)

    return tabulate(
        optimized.values.tolist(),
        headers=[str(h) for h in optimized.columns.tolist()],
        tablefmt="github",
        disable_numparse=True,
    )


def unique_path(dir_path: str, base: str, ext: str = ".md") -> str:
    """Avoid overwriting when sanitized sheet names collide."""
    candidate = os.path.join(dir_path, f"{base}{ext}")
    if not os.path.exists(candidate):
        return candidate
    n = 2
    while True:
        alt = os.path.join(dir_path, f"{base}_{n}{ext}")
        if not os.path.exists(alt):
            return alt
        n += 1


def _dedupe_sheet_requests(names: list[str]) -> list[str]:
    """Preserve order; drop repeats (after strip)."""
    seen: set[str] = set()
    out: list[str] = []
    for raw in names:
        n = raw.strip()
        if not n or n in seen:
            continue
        seen.add(n)
        out.append(n)
    return out


def _resolve_sheet_key(workbook_name: str, requested: str, sheets: dict):
    """
    Match user input to a pandas sheet key (exact, trim, then case-fold).
    Returns that key or raises ValueError.
    """
    want = requested.strip()
    available = list(sheets.keys())

    for k in sheets:
        if str(k) == want:
            return k

    trimmed_matches = [k for k in sheets if str(k).strip() == want]
    if len(trimmed_matches) == 1:
        return trimmed_matches[0]
    if len(trimmed_matches) > 1:
        raise ValueError(
            f"Sheet name {requested!r} is ambiguous in {workbook_name!r}: "
            + ", ".join(repr(str(m)) for m in trimmed_matches)
        )

    fold = want.casefold()
    folded = [
        k
        for k in sheets
        if str(k).strip().casefold() == fold
    ]
    if len(folded) == 1:
        return folded[0]
    if len(folded) > 1:
        raise ValueError(
            f"Sheet name {requested!r} is ambiguous (case-fold) in {workbook_name!r}: "
            + ", ".join(repr(str(m)) for m in folded)
        )

    avail_display = ", ".join(repr(str(k)) for k in available)
    raise ValueError(
        f"No sheet named {requested!r} in {workbook_name!r}. Available: [{avail_display}]"
    )


def _filter_sheets(
    workbook_name: str,
    sheets: dict,
    sheet_names: list[str] | None,
) -> dict:
    """If sheet_names is set, keep only those sheets (order follows sheet_names)."""
    if not sheet_names:
        return sheets
    deduped = _dedupe_sheet_requests(sheet_names)
    if not deduped:
        raise ValueError(
            "No valid sheet names in -s/--sheet (use non-empty names, or omit -s to export all sheets)."
        )
    order: list = []
    picked: dict = {}
    for req in deduped:
        key = _resolve_sheet_key(workbook_name, req, sheets)
        if key not in picked:
            order.append(key)
            picked[key] = sheets[key]
    return {k: picked[k] for k in order}


def convert_workbook(
    xlsx_path: str,
    output_dir: str | None = None,
    sheet_names: list[str] | None = None,
) -> None:
    path = os.path.abspath(xlsx_path)
    if not os.path.isfile(path):
        raise FileNotFoundError(f"Not a file: {path}")

    if output_dir is None:
        output_dir = default_output_dir_for_workbook(path)
    output_dir = os.path.abspath(output_dir)

    os.makedirs(output_dir, exist_ok=True)

    sheets = pd.read_excel(path, sheet_name=None, engine="openpyxl")
    if not isinstance(sheets, dict):
        sheets = {"Sheet1": sheets}

    wb_label = os.path.basename(path)
    try:
        sheets = _filter_sheets(wb_label, sheets, sheet_names)
    except ValueError as e:
        raise SystemExit(str(e)) from e

    for sheet_name, df in sheets.items():
        print(f"Processing sheet: {sheet_name!r} …")

        stem = sanitize_sheet_name(str(sheet_name))
        out_path = unique_path(output_dir, stem)

        table = dataframe_to_lean_markdown(df)
        if table:
            body = table
        else:
            body = PLACEHOLDER

        with open(out_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(body)
            if not body.endswith("\n"):
                f.write("\n")

        try:
            display_path = os.path.relpath(out_path, os.getcwd())
        except ValueError:
            display_path = out_path
        print(f"  → wrote {display_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export each Excel sheet as a UTF-8 Markdown file (GitHub tables).",
    )
    parser.add_argument("xlsx", help="Path to the .xlsx workbook")
    parser.add_argument(
        "-o",
        "--output-dir",
        default=None,
        metavar="DIR",
        help="Output directory (default: same folder as the workbook)",
    )
    parser.add_argument(
        "-s",
        "--sheet",
        action="append",
        dest="sheets",
        metavar="NAME",
        help="Export only this sheet (repeat -s for multiple). Default: all sheets.",
    )
    args = parser.parse_args()
    convert_workbook(
        args.xlsx,
        output_dir=args.output_dir,
        sheet_names=args.sheets,
    )


if __name__ == "__main__":
    main()

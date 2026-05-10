# Excel to Markdown

This project includes a utility that converts every sheet of an `.xlsx` workbook into a separate Markdown file with [GitHub-style tables](https://github.github.com/gfm/#tables-extension-), UTF-8 encoding, and token-oriented cleanup (trimmed text, dashes for empty cells, float rounding).

## Prerequisites

- **Python** 3.10 or newer on your PATH as `python3` or `python` (the bash wrapper checks this first).
- **Network** on first run only: creating `.venv/` and installing `pandas`, `tabulate`, `openpyxl` uses `pip` (pypi.org).

### Install dependencies

**Via Bash (recommended):** you normally need **nothing** beyond Python. `./scripts/run-excel-to-markdown.sh` creates `repo-root/.venv/`, installs the three packages there on first run, then always runs through `.venv/bin/python`. No manual `pip install`.

**Alternate (aligned with `pyproject.toml`):** if you maintain the venv yourself, you can install the optional extra instead:

```bash
cd /path/to/robotframework-common-keywords
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e ".[excel-markdown]"
```

Calling `excel_to_markdown.py` **without** the bash wrapper still requires installing those packages into whatever interpreter you use.

## Run with Bash (recommended)

From the repository root:

```bash
chmod +x scripts/run-excel-to-markdown.sh   # once, if needed
./scripts/run-excel-to-markdown.sh path/to/workbook.xlsx
```

By default, Markdown files are written to **the same directory as the workbook** (e.g. `~/Exports/report.xlsx` → `~/Exports/Sheet1.md`, …). The wrapper `cd`s to the repo root before running Python; only the workbook path determines the output folder.

Override the output directory:

```bash
./scripts/run-excel-to-markdown.sh path/to/workbook.xlsx -o ~/Desktop/md-export
./scripts/run-excel-to-markdown.sh --output-dir ./my-export path/to/workbook.xlsx
```

Export only specific sheets (repeat `-s` / `--sheet`; names are matched exactly, or after trim / case‑fold):

```bash
./scripts/run-excel-to-markdown.sh path/to/workbook.xlsx -s "Summary" -s Data
python scripts/excel_to_markdown.py path/to/workbook.xlsx --sheet Summary
```

Omit `-s` to export **all** sheets. Unknown names exit with an error listing available sheet names.

CLI help:

```bash
./scripts/run-excel-to-markdown.sh --help
```

The wrapper bootstraps `python3`/`python` to build `.venv/`, ensures the three packages are installed there, then runs the converter.

## Run with Python directly

```bash
cd /path/to/robotframework-common-keywords
python scripts/excel_to_markdown.py path/to/workbook.xlsx
python scripts/excel_to_markdown.py path/to/workbook.xlsx -o ~/some/other/folder
python scripts/excel_to_markdown.py path/to/workbook.xlsx -s Sheet1 -s "My Data"
```

## Output

- **Directory:** same folder as the input `.xlsx` by default (the directory is created if you pass `-o` and it does not exist yet).
- **Sheets:** all sheets by default; use `-s` / `--sheet` to limit which sheets become `.md` files.
- **Files:** one `.md` per exported sheet, named from the sheet title with characters sanitized for safe filenames (e.g. spaces become underscores). If two sheets normalize to the same name, the script appends `_2`, `_3`, etc.
- **Encoding:** UTF-8 with Unix newlines.

## Troubleshooting

| Issue | What to do |
|--------|------------|
| `ERROR: Python is not installed` | Install Python 3.10+ and ensure `python3` (or `python`) is on `PATH`. |
| `ERROR: Need Python ≥3.10` | Upgrade the Python used to create `.venv` (remove `.venv` and re-run the script if it was built with an old interpreter). |
| `venv` / `pip install` fails | Needs internet to PyPI. On Debian/Ubuntu, if `python3 -m venv` fails: `sudo apt install python3-venv`. |
| `ModuleNotFoundError: openpyxl` (running **only** `.py`) | Install `pandas`, `tabulate`, `openpyxl` into that interpreter, or use the bash wrapper. |
| Empty or `-` only file | Sheet had no data after dropping fully empty rows and columns; the file still contains a single placeholder line `-`. |
| `No sheet named …` | Use `-s` with a tab name from the workbook; the message lists **Available:** names. Fix typos or quoting. |

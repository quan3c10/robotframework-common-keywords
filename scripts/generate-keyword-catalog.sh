#!/usr/bin/env bash
# Regenerate common-keywords/docs/keyword-catalog/*.html via libdoc.
# Re-run after adding or editing keywords in common-keywords/.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [ ! -d ".venv" ]; then
    echo "ERROR: .venv/ not found. Run ./scripts/install.sh from the project root first." >&2
    exit 1
fi
# shellcheck disable=SC1091
source .venv/bin/activate

OUT_DIR="common-keywords/docs/keyword-catalog"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*.html

# Collect every .resource + Python library. Skip _helpers (internal),
# __init__.py, and __pycache__ noise.
TARGETS=()
while IFS= read -r f; do TARGETS+=("$f"); done < <(
    find common-keywords/form_validation \
         common-keywords/api_validation \
         common-keywords/ui_validation \
         common-keywords/data_generators \
         common-keywords/libraries \
         \( -name '*.resource' -o -name '*.py' \) \
         ! -name '__init__.py' \
    | grep -v __pycache__ \
    | sort
)

for target in "${TARGETS[@]}"; do
    # Turn "common-keywords/form_validation/email_field.resource" into
    # "form_validation-email_field.html" so every file is uniquely named
    # without having to mirror the directory tree.
    stem=$(echo "$target" \
        | sed -E 's#^common-keywords/##; s#\.[^.]+$##; s#/#-#g')
    out="$OUT_DIR/${stem}.html"
    echo "==> libdoc $target → $out"
    python -m robot.libdoc --format HTML "$target" "$out"
done

echo ""
echo "Catalog regenerated. See common-keywords/docs/keyword-catalog/."

#!/usr/bin/env bash
# Regenerate docs/keyword-catalog/*.html via libdoc.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -d ".venv" ]; then
    echo "ERROR: .venv/ not found. Create one and pip install -e . first." >&2
    exit 1
fi
# shellcheck disable=SC1091
source .venv/bin/activate

OUT_DIR="docs/keyword-catalog"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*.html

PREFIX="src/robot_common_keywords"
TARGETS=()
while IFS= read -r f; do TARGETS+=("$f"); done < <(
    find "${PREFIX}/form_validation" \
         "${PREFIX}/api_validation" \
         "${PREFIX}/ui_validation" \
         "${PREFIX}/data_generators" \
         "${PREFIX}/libraries" \
         \( -name '*.resource' -o -name '*.py' \) \
         ! -name '__init__.py' \
    | grep -v __pycache__ \
    | sort
)

for target in "${TARGETS[@]}"; do
    rest="${target#"${PREFIX}/"}"
    stem=$(printf '%s' "$rest" | sed -E 's#\.[^.]+$##; s#/#-#g')
    out="$OUT_DIR/${stem}.html"
    echo "==> libdoc $target → $out"
    python -m robot.libdoc --format HTML "$target" "$out"
done

echo ""
echo "Catalog regenerated. See ${OUT_DIR}/."

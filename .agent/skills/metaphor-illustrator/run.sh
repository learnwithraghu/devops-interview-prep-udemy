#!/usr/bin/env bash
# Placeholder script for the metaphor-illustrator skill.
# In a real implementation this would invoke an image generation model (e.g., DALL·E) and post‑process with Rough.js.
# Arguments:
#   $1 – input text (or path to a guide.md file)
#   $2 – output directory
#   $3 – number of illustrations (default 4)
#   $4 – format: svg|png|excalidraw (default svg)

set -euo pipefail

INPUT_TEXT="$1"
OUT_DIR="$2"
COUNT="${3:-4}"
FORMAT="${4:-svg}"

mkdir -p "$OUT_DIR"

for i in $(seq 1 "$COUNT"); do
  # Dummy SVG placeholder – replace with real generated image.
  cat > "$OUT_DIR/${i}.${FORMAT}" <<'EOF'
<svg width="1024" height="576" xmlns="http://www.w3.org/2000/svg">
  <rect width="1024" height="576" fill="white"/>
  <text x="512" y="288" font-size="48" text-anchor="middle" fill="black">Placeholder $i</text>
</svg>
EOF
  echo "Generated placeholder $i.$FORMAT"
done

echo "✅ $COUNT $FORMAT illustration(s) saved to $OUT_DIR"

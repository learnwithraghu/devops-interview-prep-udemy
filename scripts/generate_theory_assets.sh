#!/usr/bin/env bash
# generate_theory_assets.sh
# Scan the repository for any newly created or updated theory guide.md files
# and invoke the metaphor-illustrator skill to produce SVG/Excalidraw assets.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

find "$REPO_ROOT" -path "*/theory/*/guide.md" | while read -r GUIDE; do
  GUIDE_DIR=$(dirname "$GUIDE")
  ASSETS_DIR="$GUIDE_DIR/assets"
  mkdir -p "$ASSETS_DIR"
  echo "Generating assets for $GUIDE..."
  # Call the skill via Codex CLI (placeholder command). The real implementation
  # would invoke the skill's run.sh or the Codex CLI "use metaphor-illustrator".
  # Here we just call the placeholder run.sh which creates dummy SVGs.
  "$REPO_ROOT/.agent/skills/metaphor-illustrator/run.sh" "$(cat "$GUIDE")" "$ASSETS_DIR" 4 "svg"
  echo "Assets saved to $ASSETS_DIR"
done

echo "✅ All theory guide assets generated."

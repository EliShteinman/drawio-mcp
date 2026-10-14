#!/usr/bin/env bash
# Copy shared/ references into every plugin's bundled skill folder so the
# skill works offline. Run after pulling from upstream jgraph/drawio-mcp.
set -euo pipefail
cd "$(dirname "$0")/.."

FILES="xml-essentials.md xml-reference.md mermaid-reference.md style-reference.md mxfile.xsd"

for dest in \
  plugins/claude-code/skills/drawio/references \
  plugins/codex/drawio/skills/drawio/references \
  plugins/copilot/skills/drawio/references; do
  [ -d "$(dirname "$dest")" ] || continue
  mkdir -p "$dest"
  for f in $FILES; do cp "shared/$f" "$dest/$f"; done
  sed -i.bak \
    -e 's#https://github.com/jgraph/drawio-mcp/blob/main/shared/style-reference.md#`style-reference.md` (same directory as this file)#' \
    -e 's#https://github.com/jgraph/drawio-mcp/blob/main/shared/mxfile.xsd#`mxfile.xsd` (same directory as this file)#' \
    "$dest/xml-reference.md"
  sed -i.bak \
    -e 's#\[`mxfile.xsd`\](https://github.com/jgraph/drawio-mcp/blob/main/shared/mxfile.xsd)#`mxfile.xsd` (same directory as this file)#' \
    "$dest/style-reference.md"
  rm -f "$dest"/*.bak
  echo "synced $dest"
done

if grep -rn "raw.githubusercontent" plugins/*/skills/drawio/SKILL.md plugins/*/drawio/skills/drawio/SKILL.md 2>/dev/null; then
  echo "WARNING: a SKILL.md still fetches references from GitHub (upstream changed it?)" >&2
  exit 1
fi

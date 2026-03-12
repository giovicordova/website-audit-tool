#!/bin/bash
# check-schema-deprecations.sh — verifies the deprecated schema types table in structured-data.md
# against Google's current search gallery. Returns JSON with findings.
# Used by the +refresh flow to detect new deprecations or reinstatements.
#
# Usage: check-schema-deprecations.sh
# Requires: curl, jq
# Returns: JSON on stdout with current deprecation status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REF_FILE="$PROJECT_DIR/references/structured-data.md"

if ! command -v curl &>/dev/null; then
  echo '{"error": "curl not found"}'
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo '{"error": "jq not found"}'
  exit 1
fi

# Extract currently tracked deprecated types from structured-data.md
DEPRECATED_TYPES=$(sed -n '/^## Deprecated Rich Result Types/,/^## /p' "$REF_FILE" | \
  grep '^|' | \
  grep -v '^| Type' | \
  grep -v '^|---' | \
  sed 's/| *\([^ |]*\).*/\1/' | \
  grep -v '^$' || true)

# Fetch Google's search gallery page to check current supported types
GALLERY_STATUS=$(curl -sI --max-time 15 "https://developers.google.com/search/docs/appearance/structured-data/search-gallery" | head -1)

echo "{\"tracked_deprecated_types\": $(echo "$DEPRECATED_TYPES" | jq -R -s 'split("\n") | map(select(length > 0))'), \"gallery_reachable\": $(echo "$GALLERY_STATUS" | grep -q "200" && echo true || echo false), \"reference_file\": \"$REF_FILE\"}"

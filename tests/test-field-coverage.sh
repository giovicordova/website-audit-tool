#!/bin/bash
# test-field-coverage.sh — validates that extraction.js returns all fields required by reference files
# Parses "## Required Extraction Fields" sections from each reference file and checks
# that extraction.js's return object includes each field name.
# Runs in <1 second. No browser or network needed.

set -euo pipefail
source "$(dirname "$0")/lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EXTRACTION="$PROJECT_DIR/modules/extraction.js"
REFS_DIR="$PROJECT_DIR/references"

# Preconditions
if [ ! -f "$EXTRACTION" ]; then
  echo "ABORT: modules/extraction.js not found" >&2
  exit 1
fi

# Extract the return object field names from extraction.js
# Look for lines like "fieldName:" or "fieldName," in the return statement
EXTRACTION_FIELDS=$(sed -n '/^  return {/,/^  };$/p' "$EXTRACTION" | \
  grep -oE '^\s+[a-zA-Z0-9_]+' | \
  sed 's/^ *//' | \
  sort -u)

# For each reference file, parse Required Extraction Fields and check against extraction.js
for REF in "$REFS_DIR"/*.md; do
  REF_NAME=$(basename "$REF" .md)

  # Extract field names from "## Required Extraction Fields" section
  # Fields are lines like "- fieldName — description"
  REQUIRED=$(sed -n '/^## Required Extraction Fields/,/^## /p' "$REF" | \
    grep '^- ' | \
    sed 's/^- \([a-zA-Z0-9_]*\).*/\1/' | \
    sort -u || true)

  if [ -z "$REQUIRED" ]; then
    # No Required Extraction Fields section — skip (ai-bots.md, etc.)
    continue
  fi

  while IFS= read -r field; do
    [ -z "$field" ] && continue

    # Some fields come from Playwright response, not extraction.js — skip those
    # (they're documented with "(from Playwright response, not extraction.js)" in the ref file)
    FIELD_LINE=$(sed -n '/^## Required Extraction Fields/,/^## /p' "$REF" | grep "^- $field" || true)
    if echo "$FIELD_LINE" | grep -q "not extraction.js"; then
      continue
    fi

    if echo "$EXTRACTION_FIELDS" | grep -qx "$field"; then
      assert_eq "$REF_NAME:$field" "present" "present"
    else
      assert_eq "$REF_NAME:$field" "present" "MISSING"
    fi
  done <<< "$REQUIRED"
done

test_summary

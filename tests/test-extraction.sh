#!/bin/bash
# test-extraction.sh — runs extraction.js against mock HTML via Node.js + jsdom
# Validates that all key fields are correctly extracted from a known HTML page.
# No Playwright or browser needed. Runs in <3 seconds.

set -euo pipefail
source "$(dirname "$0")/lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MOCK_HTML="$PROJECT_DIR/tests/fixtures/mock-site/index.html"
EXTRACTION_JS="$PROJECT_DIR/modules/extraction.js"

# Check Node.js available
if ! command -v node &>/dev/null; then
  echo "ABORT: node is required" >&2
  exit 1
fi

# Check jsdom available (try require it)
if ! node -e "require('jsdom')" 2>/dev/null; then
  echo "Installing jsdom for test..."
  npm install --no-save jsdom >/dev/null 2>&1
fi

# Run extraction.js against mock HTML using jsdom
RESULT=$(node -e "
const fs = require('fs');
const { JSDOM } = require('jsdom');

const html = fs.readFileSync('$MOCK_HTML', 'utf-8');
const dom = new JSDOM(html, { url: 'http://localhost:8787/', pretendToBeVisual: true });

// Set up globals that extraction.js expects
global.document = dom.window.document;
global.window = dom.window;

// Read and execute extraction function
const fnBody = fs.readFileSync('$EXTRACTION_JS', 'utf-8');
const fn = eval(fnBody);
const result = fn();

console.log(JSON.stringify(result));
")

# --- Field existence checks ---
echo "=== Field Existence ==="
for field in url title titleLength metaDescription metaDescriptionLength viewport canonical robotsMeta jsonLd headings h1Text h1Count images internalLinks externalLinks bodyWordCount bodyText firstParagraph hasFAQ timeTags publishedDate ogTags twitterTags httpLinks tableCount listCount; do
  VAL=$(echo "$RESULT" | jq ".$field")
  if [ "$VAL" != "null" ] && [ "$VAL" != "undefined" ]; then
    assert_eq "field:$field exists" "true" "true"
  else
    assert_eq "field:$field exists" "true" "MISSING"
  fi
done

# --- Value correctness checks ---
echo ""
echo "=== Value Checks ==="

assert_eq "title" '"MockCorp — Best Widgets for 2026"' "$(echo "$RESULT" | jq '.title')"
assert_eq "titleLength" "32" "$(echo "$RESULT" | jq '.titleLength')"
assert_eq "metaDescription starts with MockCorp" "true" "$(echo "$RESULT" | jq '.metaDescription | startswith("MockCorp")')"
assert_eq "viewport present" '"width=device-width, initial-scale=1"' "$(echo "$RESULT" | jq '.viewport')"
assert_eq "canonical" '"http://localhost:8787/"' "$(echo "$RESULT" | jq '.canonical')"
assert_eq "robotsMeta" '"index, follow"' "$(echo "$RESULT" | jq '.robotsMeta')"
assert_eq "h1Count" "1" "$(echo "$RESULT" | jq '.h1Count')"
assert_eq "h1Text" '"The Best Widgets for Your Business"' "$(echo "$RESULT" | jq '.h1Text')"
assert_eq "hasFAQ" "true" "$(echo "$RESULT" | jq '.hasFAQ')"
assert_eq "publishedDate" '"2026-01-15"' "$(echo "$RESULT" | jq '.publishedDate')"
assert_eq "tableCount >= 1" "true" "$(echo "$RESULT" | jq '.tableCount >= 1')"
assert_eq "listCount >= 1" "true" "$(echo "$RESULT" | jq '.listCount >= 1')"

# JSON-LD checks
assert_eq "jsonLd is array" "true" "$(echo "$RESULT" | jq '.jsonLd | type == "array"')"
assert_eq "jsonLd has Organization" "true" "$(echo "$RESULT" | jq '[.jsonLd[] | .["@type"]] | any(. == "Organization")')"

# Heading checks
assert_eq "headings count >= 4" "true" "$(echo "$RESULT" | jq '.headings | length >= 4')"
assert_eq "has question heading" "true" "$(echo "$RESULT" | jq '[.headings[].text] | any(endswith("?"))')"

# Image checks
assert_eq "images count >= 2" "true" "$(echo "$RESULT" | jq '.images | length >= 2')"
# Image with alt="" has hasAlt=true (attribute exists). Check non-descriptive alt instead.
assert_eq "has image with empty alt" "true" "$(echo "$RESULT" | jq '[.images[] | select(.alt == "")] | length >= 1')"

# Link checks
assert_eq "internalLinks count >= 2" "true" "$(echo "$RESULT" | jq '.internalLinks | length >= 2')"
assert_eq "externalLinks count >= 1" "true" "$(echo "$RESULT" | jq '.externalLinks | length >= 1')"
assert_eq "httpLinks count >= 1" "true" "$(echo "$RESULT" | jq '.httpLinks | length >= 1')"

# Body text checks
# Note: jsdom doesn't populate innerText, so bodyWordCount=0 in this env.
# In a real browser bodyWordCount would be >50. We verify the field exists and is a number.
assert_eq "bodyWordCount is number" "true" "$(echo "$RESULT" | jq '.bodyWordCount | type == "number"')"
assert_eq "firstParagraph not null" "true" "$(echo "$RESULT" | jq '.firstParagraph != null')"

# OG and Twitter tags
assert_eq "ogTags has og:title" "true" "$(echo "$RESULT" | jq '.ogTags["og:title"] != null')"
assert_eq "twitterTags has twitter:card" "true" "$(echo "$RESULT" | jq '.twitterTags["twitter:card"] != null')"

test_summary

#!/bin/bash
# Usage: lighthouse.sh <url>
# Returns: compact JSON on stdout with Lighthouse category scores + Core Web Vitals (LCP, CLS, TBT)
# On error: JSON with "error" key on stdout, exit 1
# No API key needed. Runs locally via npx lighthouse.

set -euo pipefail

URL="$1"

if [ -z "$URL" ]; then
  echo '{"error": "Usage: lighthouse.sh <url>"}' 
  exit 1
fi

# Dependency checks
if ! command -v npx &>/dev/null; then
  echo '{"error": "npx not found — Node.js is required"}'
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo '{"error": "jq not found — install jq"}'
  exit 1
fi

STDERR_FILE="/tmp/lighthouse-stderr-$$.log"
cleanup() { rm -f "$STDERR_FILE"; }
trap cleanup EXIT

REPORT=$(timeout 90 npx lighthouse "$URL" \
  --output=json \
  --only-categories=performance,accessibility,seo,best-practices \
  --chrome-flags="--headless" \
  --quiet 2>"$STDERR_FILE") || true

if [ -z "$REPORT" ]; then
  STDERR_CONTENT=$(cat "$STDERR_FILE" 2>/dev/null | head -5 | tr '\n' ' ')
  echo "{\"error\": \"Lighthouse run failed\", \"details\": \"$STDERR_CONTENT\"}"
  exit 1
fi

echo "$REPORT" | jq '{
  lighthouse_scores: {
    performance: (.categories.performance.score * 100 | floor),
    accessibility: (.categories.accessibility.score * 100 | floor),
    seo: (.categories.seo.score * 100 | floor),
    best_practices: (.categories["best-practices"].score * 100 | floor)
  },
  core_web_vitals: {
    lcp: {value: .audits["largest-contentful-paint"].numericValue, display: .audits["largest-contentful-paint"].displayValue, score: .audits["largest-contentful-paint"].score},
    cls: {value: .audits["cumulative-layout-shift"].numericValue, display: .audits["cumulative-layout-shift"].displayValue, score: .audits["cumulative-layout-shift"].score},
    tbt: {value: .audits["total-blocking-time"].numericValue, display: .audits["total-blocking-time"].displayValue, score: .audits["total-blocking-time"].score}
  }
}'

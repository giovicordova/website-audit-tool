#!/bin/bash
# Usage: lighthouse.sh <url>
# Returns: compact JSON with Lighthouse category scores + Core Web Vitals (LCP, CLS, TBT)
# No API key needed. Runs locally via npx lighthouse.

URL="$1"

if [ -z "$URL" ]; then
  echo "Usage: lighthouse.sh <url>" >&2
  exit 1
fi

REPORT=$(npx lighthouse "$URL" \
  --output=json \
  --only-categories=performance,accessibility,seo,best-practices \
  --chrome-flags="--headless" \
  --quiet 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$REPORT" ]; then
  echo '{"error": "Lighthouse run failed"}' >&2
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

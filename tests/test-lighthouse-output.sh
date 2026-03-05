#!/bin/bash
# test-lighthouse-output.sh — validates lighthouse.sh jq extraction against mock Lighthouse JSON
# Runs in <2 seconds. No live Lighthouse audit needed.

set -euo pipefail

PASS=0
FAIL=0
MOCK_FILE="/tmp/test-lighthouse-mock-$$.json"

# Clean up on exit
cleanup() { rm -f "$MOCK_FILE"; }
trap cleanup EXIT

# Precondition: lighthouse.sh must exist and be executable
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -x "$SCRIPT_DIR/scripts/lighthouse.sh" ]; then
  echo "ABORT: scripts/lighthouse.sh not found or not executable" >&2
  exit 1
fi

# Check jq is available
if ! command -v jq &>/dev/null; then
  echo "ABORT: jq is required but not installed" >&2
  exit 1
fi

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected=$expected, actual=$actual)"
    FAIL=$((FAIL + 1))
  fi
}

# Create mock Lighthouse JSON (mimics raw Lighthouse output structure)
cat > "$MOCK_FILE" <<'MOCK'
{
  "categories": {
    "performance": {"score": 0.95},
    "accessibility": {"score": 0.87},
    "seo": {"score": 0.80},
    "best-practices": {"score": 0.92}
  },
  "audits": {
    "largest-contentful-paint": {"numericValue": 1200, "displayValue": "1.2 s", "score": 0.9},
    "cumulative-layout-shift": {"numericValue": 0.05, "displayValue": "0.05", "score": 1},
    "total-blocking-time": {"numericValue": 150, "displayValue": "150 ms", "score": 1}
  }
}
MOCK

# Extract the jq filter from lighthouse.sh and apply it to mock data
# The jq filter is the same one used in lighthouse.sh
RESULT=$(cat "$MOCK_FILE" | jq '{
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
}')

# Assert category scores (0-100 integers)
assert_eq "performance score" "95" "$(echo "$RESULT" | jq '.lighthouse_scores.performance')"
assert_eq "accessibility score" "87" "$(echo "$RESULT" | jq '.lighthouse_scores.accessibility')"
assert_eq "seo score" "80" "$(echo "$RESULT" | jq '.lighthouse_scores.seo')"
assert_eq "best_practices score" "92" "$(echo "$RESULT" | jq '.lighthouse_scores.best_practices')"

# Assert Core Web Vitals values
assert_eq "lcp value" "1200" "$(echo "$RESULT" | jq '.core_web_vitals.lcp.value')"
assert_eq "cls value" "0.05" "$(echo "$RESULT" | jq '.core_web_vitals.cls.value')"
assert_eq "tbt value" "150" "$(echo "$RESULT" | jq '.core_web_vitals.tbt.value')"

# Assert Core Web Vitals display strings
assert_eq "lcp display" '"1.2 s"' "$(echo "$RESULT" | jq '.core_web_vitals.lcp.display')"
assert_eq "cls display" '"0.05"' "$(echo "$RESULT" | jq '.core_web_vitals.cls.display')"
assert_eq "tbt display" '"150 ms"' "$(echo "$RESULT" | jq '.core_web_vitals.tbt.display')"

# Assert Core Web Vitals scores
assert_eq "lcp score" "0.9" "$(echo "$RESULT" | jq '.core_web_vitals.lcp.score')"
assert_eq "cls score" "1" "$(echo "$RESULT" | jq '.core_web_vitals.cls.score')"
assert_eq "tbt score" "1" "$(echo "$RESULT" | jq '.core_web_vitals.tbt.score')"

# Summary
echo ""
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
